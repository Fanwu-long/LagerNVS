# 08_浏览器交互 WebUI（Browser Viewer）

> 对应官方 README：**Browser Viewer (headless remote GPU)**  
> 入口代码：`run_interactive_server.py` + `interactive_viewer.html`  
> **不是** Open3D 桌面版（那是 `run_interactive.py`）

独立工作副本（可单独打开）：`d:\新建文件夹\LagerNVS-BrowserWebUI`

---

## 这是什么

远程 GPU 上跑 LagerNVS 神经网络，按你在浏览器里拖动的相机位姿**实时渲染**新视角，经 WebSocket 把 JPEG 帧推到本机浏览器。

```
test_data 照片 → VGGT 估位姿 → LagerNVS 编码
        ↑                              ↓
   浏览器拖拽/WASD  ←── WebSocket JPEG ←── A100 渲染
```

---

## 本目录结构

| 子目录 | 内容 |
|---|---|
| `01_官方Browser_Viewer代码` | `run_interactive_server.py`、`interactive_viewer.html`、依赖的 `run_interactive.py`、优化包 tgz |
| `02_平台启动脚本` | sbatch / shell / 补丁同步 |
| `03_示例场景_test_data` | `demo/`、`scene_a/` 示例输入图 |
| `04_说明文档` | 本说明的拆分副本（见 `README_快速启动.md`） |

---

## 平台启动（需要 A100）

在登录节点（代码已在 `~/lagernvs` 的前提下）：

```bash
# 1) 同步本目录示例场景（可选）
# 把 03_示例场景_test_data/* 拷到 ~/lagernvs/test_data/

# 2) 提交 WebUI 作业
cd ~/lagernvs
sbatch 路径/到/01_run_webui_live.sbatch
# 或交互：
srun -p Students --qos=qos_stu_default --gres=gpu:A100:1 \
  --cpus-per-task=4 --mem=16G -t 1:00:00 --pty bash
bash 06_run_interactive.sh --scenes demo --jpeg_quality 95
```

本机隧道：

```bash
ssh -L 8765:localhost:8765 <user>@107.ustc.edu.cn
# 若服务在计算节点，需再跳一层或改成 -L 8765:<gpu-ip>:8765
```

浏览器打开：`http://localhost:8765`

---

```bash
python ../07_交互式渲染演示/06_交互功能优化/serve_offline_demo.py
```

---

## 操作键（浏览器）

拖拽旋转 · WASD 移动 · Q/E 升降 · O 环绕 · 1–9 切场景 · Low/Med/High 画质

---

## 与 `07_` 的分工

| | `07_交互式渲染演示` | `08_浏览器交互WebUI`（本目录） |
|---|---|---|
| 产物 | 预渲染 orbit / 离线播放 | **真·WebUI 实时服务** 工程包 |
| 是否要 GPU | 离线不要 | 要 |
| 官方对应 | 录制结果归档 | Browser Viewer |
