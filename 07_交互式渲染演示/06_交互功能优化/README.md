# 06_交互功能优化

神经网络 **Interactive Viewer** 功能优化包（**不重跑** 500 场景评测）。

## 内容

| 文件 | 作用 |
|------|------|
| `interactive_viewer.html` | 优化后的浏览器客户端 |
| `run_interactive_server.py` | 优化后的 WebSocket 渲染服务 |
| `offline_orbit_viewer.html` | **本地离线** orbit 演示（无需 GPU） |
| `README.md` | 本说明 |

权威补丁同步在：`01_官方代码/lagernvs-main/`  
平台启动脚本：`02_服务器脚本/06_run_interactive.sh`（同步后为 `~/lagernvs/06_run_interactive.sh`）

## 相对官方新增能力

**Viewer**
- WebSocket 自动跟随 `location.host`（支持 SSH 隧道；可用 `?ws=` 覆盖）
- 画质 Low/Med/High（60/85/95 JPEG，运行时发 `settings`）
- `O` 自动环绕 / `P` 截图 / `H` 帮助开关
- 显示更平滑（`image-rendering: auto`）
- 按 render-fps 自适应 pose 发送，减轻无效请求

**Server**
- 运行时调整 `jpeg_quality`（40–98）
- 帧头带回当前画质；`--bind` 可配

## 离线 Interactive demo（推荐，无需 GPU）

```bash
cd 07_交互式渲染演示/06_交互功能优化
python serve_offline_demo.py
```

浏览器打开 `http://127.0.0.1:8766/`

- **HQ stills**：Top 场景 GT|Pred 原生 512 静帧（画质最清晰）
- **Orbit explore**：横向拖拽 scrub 预渲染环绕路径（orbit_v4；640 包可能偏软）
- 文案对齐官方 Interactive demo（sparse photo captures）

## 平台启动（要 GPU，但不是评测重跑）

```bash
srun -p Students --qos=qos_stu_default --gres=gpu:A100:1 \
  --cpus-per-task=4 --mem=16G -t 1:00:00 --pty bash

cd ~/lagernvs
bash 06_run_interactive.sh          # 默认 512 竖构图
# 或更快预览：
bash 06_run_interactive.sh --wide
```

本机隧道：

```bash
ssh -L 8765:localhost:8765 <user>@<login-or-gpu-host>
```

浏览器打开 `http://localhost:8765`。

## 说明

- 场景数据已在平台 `~/lagernvs/test_data/{demo,scene_a,scene_b}`
- HF token 使用 `~/.cache/huggingface/token`
- 原始未改文件备份：`01_官方代码/lagernvs-main/_orig_backup/`
