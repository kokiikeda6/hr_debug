#!/bin/bash

# 第1引数でbagの名前を指定できます（省略時は従来の連番）
if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [bag_name]" >&2
    exit 2
fi

BAG_NAME=${1:-}
case "$BAG_NAME" in
    */*|.|..)
        echo "Error: bag name must not contain '/' or be '.' or '..': $BAG_NAME" >&2
        exit 2
        ;;
esac

# 1. 記録対象トピックの設定
# --qos-profiles-from-topics が使えないため，トピックを羅列します
TOPICS=(
#   "/left_head_camera/GN6601PBCA7110359/color/image_raw"
#   "/right_head_camera/GN6601PBCA7110273/color/image_raw"
#   "/devices/left_camera/detector/bbox_image"
#   "/devices/right_camera/detector/bbox_image"
  "/devices/right_camera/realsense_node/color/camera_info"
  "/devices/left_camera/realsense_node/color/camera_info"
  "/devices/left_camera/realsense_node/rgbd"
  "/devices/right_camera/realsense_node/rgbd"
  "/devices/left_camera/detector/yolo_results"
  "/devices/right_camera/detector/yolo_results"
  "/tf"
  "/tf_static"
  "/clock"
  "/rosout"
  "/harvest_crop_list/left/markers"
  "/harvest_crop_list/right/markers"
  "/detected_points"
  "/debug/right/obstacle_target_cylinder_points"
  "/debug/left/obstacle_target_cylinder_points"
  "/debug/right/obstacle_excluded_points"
  "/debug/left/obstacle_excluded_points"
  "/debug/right/obstacle_filtered_points"
  "/debug/left/obstacle_filtered_points"
  "/debug/right/obstacle_sector_marker"
  "/debug/left/obstacle_sector_marker"
  "/debug/right/obstacle_free_interval_marker"
  "/debug/left/obstacle_free_interval_marker"
  "/debug/right/obstacle_target_pose_marker"
  "/debug/left/obstacle_target_pose_marker"
  "/debug/left/peduncle3_depth_crop_metrics"
  "/debug/left/peduncle3_fruit_points"
  "/debug/left/peduncle3_pre_crop_points"
  "/debug/left/peduncle3_ransac_candidates"
  "/debug/left/peduncle3_ransac_inliers"
  "/debug/left/peduncle3_ransac_metrics"
  "/debug/left/peduncle3_root_candidate_metrics"
  "/debug/left/peduncle3_strip_points"
  "/debug/left/peduncle3_tf_points"
  "/debug/right/peduncle3_depth_crop_metrics"
  "/debug/right/peduncle3_fruit_points"
  "/debug/right/peduncle3_pre_crop_points"
  "/debug/right/peduncle3_ransac_candidates"
  "/debug/right/peduncle3_ransac_inliers"
  "/debug/right/peduncle3_ransac_metrics"
  "/debug/right/peduncle3_root_candidate_metrics"
  "/debug/right/peduncle3_strip_points"
  "/debug/right/peduncle3_tf_points"
  "/left_force_torque"
  "/right_force_torque"

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

if [ -n "$BAG_NAME" ]; then
    BAG_PATH="$BAG_DIR/$BAG_NAME"
    if [ -e "$BAG_PATH" ] || [ -L "$BAG_PATH" ]; then
        echo "Error: output bag already exists: $BAG_PATH" >&2
        exit 1
    fi
else
    BAG_INDEX=1
    while [ -e "$BAG_DIR/auto_harvest_$BAG_INDEX" ]; do
        BAG_INDEX=$((BAG_INDEX + 1))
    done
    BAG_PATH="$BAG_DIR/auto_harvest_$BAG_INDEX"
fi

echo "Save directory: $BAG_DIR"
echo "Output bag: $BAG_PATH"
echo "--------------------------------------------------"

print_bag_size() {
    if [ -d "$BAG_PATH" ]; then
        echo "--------------------------------------------------"
        echo "Recorded bag size (total disk usage):"
        du -sh -- "$BAG_PATH"
    fi
}

stop_recording() {
    # 終了処理中の追加のシグナルで wait が中断されないようにします
    trap '' SIGINT SIGTERM
    echo "Stopping recording..."
    kill -INT "$BAG_PID" 2>/dev/null
    # データとメタデータの書き込み完了を待ってから終了します
    wait "$BAG_PID"
}

# 3. バックグラウンドで記録を開始
# QoSの問題を避けるため，必要最低限の構成にしています
ros2 bag record -o "$BAG_PATH" "${TOPICS[@]}" &
BAG_PID=$!

# 起動待ちの間に終了した場合にも，記録を停止してから容量を表示します
trap print_bag_size EXIT
trap 'stop_recording; exit 130' SIGINT
trap 'stop_recording; exit 143' SIGTERM

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

# 5. レコーダーの終了を待つ（通常終了時も EXIT トラップで容量を表示）
wait "$BAG_PID"
