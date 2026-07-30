#!/bin/bash

# 1. 記録対象トピックの設定
# --qos-profiles-from-topics が使えないため，トピックを羅列します
TOPICS=(
  "/devices/left_camera/detector/bbox_image"
  "/devices/right_camera/detector/bbox_image"
  "/detected_points"
  "/tf"
  "/tf_static"
  "/clock"
  "/harvest_crop_list/left/markers"
  "/harvest_crop_list/right/markers"
  "/debug/obstacle_points"
  "/obstacle_best_bin_marker"
  "/rosout"
  "/debug/right/peduncle3_fruit_points"
  "/debug/left/peduncle3_fruit_points"

)

echo "--------------------------------------------------"
echo "Starting ROS2 Bag Recording"
echo "--------------------------------------------------"

# 2. rosbagの保存先とファイル名を設定
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HR1_REPO=${HR1_REPO:-"$SCRIPT_DIR/../../hr1"}
# HR1_REPO=${HR1_REPO:-"/home/ubuntu/ros2_ws/src/hr1"} #収穫ロボット


if ! HR1_REPO_ABS=$(cd "$HR1_REPO" 2>/dev/null && pwd); then
    echo "Error: hr1 repository not found: $HR1_REPO" >&2
    exit 1
fi

HR1_BRANCH=$(git -C "$HR1_REPO_ABS" branch --show-current 2>/dev/null)
if [ -z "$HR1_BRANCH" ]; then
    HR1_COMMIT=$(git -C "$HR1_REPO_ABS" rev-parse --short HEAD 2>/dev/null)
    if [ -z "$HR1_COMMIT" ]; then
        echo "Error: failed to get hr1 branch name: $HR1_REPO_ABS" >&2
        exit 1
    fi
    HR1_BRANCH="detached-${HR1_COMMIT}"
fi

# ブランチ名に "/" が含まれる場合でも1つのディレクトリ名として扱います
HR1_BRANCH_DIR=${HR1_BRANCH//\//_}
BAG_DATE=$(date +%Y-%m-%d)
BAG_DIR="$HOME/rosbag/$BAG_DATE/$HR1_BRANCH_DIR"
mkdir -p "$BAG_DIR"

BAG_INDEX=1
while [ -e "$BAG_DIR/auto_harvest_$BAG_INDEX" ]; do
    BAG_INDEX=$((BAG_INDEX + 1))
done
BAG_PATH="$BAG_DIR/auto_harvest_$BAG_INDEX"

echo "Save directory: $BAG_DIR"
echo "Output bag: $BAG_PATH"
echo "--------------------------------------------------"

# 3. バックグラウンドで記録を開始
# QoSの問題を避けるため，必要最低限の構成にしています
ros2 bag record -o "$BAG_PATH" "${TOPICS[@]}" &
BAG_PID=$!

# レコーダーが立ち上がるまで十分に待機
sleep 5

# 4. robot_state_publisher を終了させる
# respawn=True 設定により，自動再起動時に全 tf_static が再送出されます
echo "Restarting robot_state_publisher to re-publish all TFs..."
RSP_PID=$(pgrep -f "robot_state_publisher")

if [ -n "$RSP_PID" ]; then
    kill $RSP_PID
    echo "robot_state_publisher (PID: $RSP_PID) restarted."
else
    echo "Warning: robot_state_publisher node not found. Check if it is running."
fi

echo "--------------------------------------------------"
echo "Recording in progress..."
echo "Press [Ctrl+C] to stop recording safely."
echo "--------------------------------------------------"

# 5. スクリプト終了（Ctrl+C）時の処理
trap "echo 'Stopping recording...'; kill -INT $BAG_PID; exit" SIGINT SIGTERM

wait $BAG_PID
