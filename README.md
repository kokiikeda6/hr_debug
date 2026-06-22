# hr_debug

収穫ロボットのデバッグ用 ROS 2 パッケージです．

- RViz デバッグ設定
- rosbag 記録スクリプト

## ビルド

```bash
cd ~/hr_ws
colcon build --packages-select hr_debug
source install/setup.bash
```

## RViz の起動

```bash
ros2 launch hr_debug detect_peduncle_debug.launch.py
```

シミュレーション時など `/clock` を使う場合:

```bash
ros2 launch hr_debug detect_peduncle_debug.launch.py use_sim_time:=true
```

## rosbag の記録

```bash
cd ~/hr_ws/src/hr_debug
./scripts/rosbag_record.sh
```

終了するときは `Ctrl+C` を押してください．

## rosbag の保存先

保存先は次の形式です．

```text
~/rosbag/YYYY-MM-DD/<hr1_branch>/auto_harvest_N
```

例:

```text
~/rosbag/2026-06-23/main/auto_harvest_1
```

- `YYYY-MM-DD`: 記録日
- `<hr1_branch>`: `hr1` リポジトリの Git ブランチ名
- `auto_harvest_N`: 同じ保存先に既存 bag がある場合，自動で連番

ブランチ名に `/` が含まれる場合は `_` に置き換えられます．

## hr1 リポジトリの場所

デフォルトでは，`~/hr_ws/src/hr1` を参照します．

別の場所にある場合:

```bash
HR1_REPO=/path/to/hr1 ./scripts/rosbag_record.sh
```

## メモ

- 記録対象トピックは `scripts/rosbag_record.sh` の `TOPICS` で設定しています．
- `rosbag_record.sh` は `/tf_static` を記録しやすくするため，記録開始後に `robot_state_publisher` を再起動します．
