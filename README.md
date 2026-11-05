# hr_debug

収穫ロボットのデバッグ用 ROS 2 パッケージです．

- RViz デバッグ設定
- rosbag 記録スクリプト

## ビルド

```bash
cd ~/ros2_ws
colcon build --packages-select hr_debug
source install/setup.bash
```

## RViz の起動


収穫動作のチェック用
```bash
ros2 launch hr_debug harvesting_debug.launch.py
```

果柄検出のチェック用
```bash
ros2 launch hr_debug detect_peduncle_debug.launch.py
```


## rosbag の記録

```bash
cd ~/ros2_ws/src/hr_debug
./scripts/rosbag_record.sh
```

bag 名を指定する場合は，第1引数に渡してください（拡張子は不要です）．

```bash
./scripts/rosbag_record.sh test_run
```

省略時は従来どおり `auto_harvest_N` を使用します．指定した名前がすでに存在する場合は，エラーで終了します．
名前はディレクトリ名として扱うため，`/` を含む名前や `.`，`..` は指定できません．

終了するときは `Ctrl+C` を押してください．
書き込み完了後に，bag の保存ディレクトリ全体のディスク使用量を表示します（メタデータを含みます）．

## rosbag の保存先

bag 名を省略した場合の保存先は次の形式です．

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

bag 名を指定した場合は，末尾の `auto_harvest_N` が指定した名前になります．

ブランチ名に `/` が含まれる場合は `_` に置き換えられます．

## hr1 リポジトリの場所

デフォルトでは，`~/ros2_ws/src/hr1` を参照します．

別の場所にある場合:

```bash
HR1_REPO=/path/to/hr1 ./scripts/rosbag_record.sh
```

## メモ

- 記録対象トピックは `scripts/rosbag_record.sh` の `TOPICS` で設定しています．
- `rosbag_record.sh` は `/tf_static` を記録しやすくするため，記録開始後に `robot_state_publisher` を再起動します．
