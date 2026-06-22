# hr_debug

`hr_debug` は，収穫ロボットのデバッグ用に RViz 設定や rosbag 記録スクリプトをまとめた ROS 2 パッケージです．

## 内容

- `launch/detect_peduncle_debug.launch.py`
  - `rviz/detect_peduncle_debug.rviz` を指定して RViz2 を起動します．
- `scripts/rosbag_record.sh`
  - デバッグに必要なトピックを rosbag2 で記録します．
  - 記録開始後に `robot_state_publisher` を再起動し，`/tf_static` を再送出させます．

## ビルド

ワークスペースのルートでビルドします．

```bash
cd ~/hr_ws
colcon build --packages-select hr_debug
source install/setup.bash
```

## RViz の起動

実機またはシミュレーションのノードを起動した状態で，次を実行します．

```bash
ros2 launch hr_debug detect_peduncle_debug.launch.py
```

シミュレーション時など `/clock` を使う場合は `use_sim_time:=true` を指定します．

```bash
ros2 launch hr_debug detect_peduncle_debug.launch.py use_sim_time:=true
```

## rosbag の記録

ROS 2 環境を source した状態で，このリポジトリからスクリプトを直接実行します．

```bash
cd ~/hr_ws/src/hr_debug
./scripts/rosbag_record.sh
```

記録中は端末を開いたままにし，終了するときは `Ctrl+C` を押します．スクリプトは `ros2 bag record` に `SIGINT` を送り，安全に記録を終了します．

### 保存先

rosbag は次の形式で保存されます．

```text
$HOME/rosbag/YYYY-MM-DD/<hr1_branch>/auto_harvest_N
```

例:

```text
~/rosbag/2026-06-22/main/auto_harvest_1
```

- `YYYY-MM-DD` は記録を開始した日付です．
- `<hr1_branch>` は `hr1` リポジトリの現在の Git ブランチ名です．
- ブランチ名に `/` が含まれる場合は `_` に置き換えられます．
  - 例: `feature/debug-record` -> `feature_debug-record`
- detached HEAD の場合は `detached-<commit>` になります．
- `auto_harvest_N` の `N` は 1 から始まり，同じ保存先に既存の bag がある場合は自動で増えます．

### hr1 リポジトリの場所

デフォルトでは，スクリプトから見て `../../hr1` にある `hr1` リポジトリを参照します．通常のワークスペース構成では次の場所です．

```text
~/hr_ws/src/hr1
```

`hr1` が別の場所にある場合は，`HR1_REPO` を指定して実行します．

```bash
HR1_REPO=/path/to/hr1 ./scripts/rosbag_record.sh
```

### 記録対象トピック

現在の記録対象トピックは次の通りです．

```text
/devices/left_camera/detector/bbox_image
/devices/right_camera/detector/bbox_image
/detected_points
/tf
/tf_static
/clock
/harvest_crop_list/left/markers
/harvest_crop_list/right/markers
/debug/obstacle_points
/obstacle_best_bin_marker
```

トピックを追加・削除したい場合は，`scripts/rosbag_record.sh` の `TOPICS` 配列を編集してください．

## 注意事項

- `rosbag_record.sh` は `robot_state_publisher` のプロセスを終了します．`robot_state_publisher` が `respawn=True` で起動されている前提で，これにより全 `tf_static` を rosbag に含めやすくしています．
- `hr1` リポジトリが見つからない場合，または Git ブランチ/コミットを取得できない場合，スクリプトはエラーで終了します．
