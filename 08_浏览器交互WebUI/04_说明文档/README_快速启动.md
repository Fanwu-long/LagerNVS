# Browser WebUI 快速启动

## 1. 它是什么

官方 **Browser Viewer**：GPU 节点上的 `run_interactive_server.py` + 浏览器里的 `interactive_viewer.html`。  
实时神经渲染，不是离线视频。

## 2. 平台三步

1. 环境：conda `lagernvs`，HF token，权重已在登录节点缓存。  
2. 数据：`~/lagernvs/test_data/demo/` 下放 2+ 张同场景图（可用本包 `03_示例场景_test_data`）。  
3. 启动：

```bash
sbatch 02_平台启动脚本/01_run_webui_live.sbatch
```

看日志里的节点 IP / Listening，然后本机：

```bash
ssh -L 8765:<gpu节点IP>:8765 pb25612046@107.ustc.edu.cn
```

打开 http://localhost:8765

## 3. 常用参数

```bash
python run_interactive_server.py --scenes demo --jpeg_quality 95 --port 8765 --bind 0.0.0.0
# 更快预览可加 --wide（更糊）
```

## 4. 已知坑

- `test_data/` 根目录不要乱放零散 jpg（`find_scene_dirs` 会把根当成场景，焦距 assert 炸）。  
- sbatch 日志路径用**绝对路径**，不要写 `~/...`。  
- SCOW 网页代理对 WebSocket 不友好；优先 SSH 隧道或临时 cloudflared。  
- 学生 QOS：1×A100 / 4 CPU / ≤16G / 时长有限，用完 `scancel`。
