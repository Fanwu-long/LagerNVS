# 02_服务器脚本

平台作业与配置（USTC 107 / Students / A100）。

| 文件 | 说明 |
|---|---|
| `00_平台环境配置与复现指南.md` | 操作权威指南（环境、数据、踩坑） |
| `01_setup_env.sh` | 登录节点环境安装 |
| `02_smoke_infer.sbatch` | 冒烟推理作业 |
| `03_eval_re10k.sbatch` | Re10k 定量评测作业 |
| `04_download_dl3dv_eval.sh` / `05_eval_dl3dv.sbatch` | DL3DV（本次未作为主结论） |
| `06_run_interactive.sh` / `run_interactive_live.sbatch` | Interactive 实时服务 |
| `eval_re10k_*500.yaml` | 三组 500 场景评测配置 |
| `assets/re10k_2v_500.json` | 固定 500 场景列表 |
| `apply_interactive_opt.sh` | 同步 Interactive 优化补丁 |

