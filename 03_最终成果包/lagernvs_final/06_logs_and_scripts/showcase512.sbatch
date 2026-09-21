#!/bin/bash
#SBATCH -J lnvs_show512
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -t 02:00:00
#SBATCH -o logs/show512-%j.out
#SBATCH -e logs/show512-%j.err
source ~/.bashrc
export HF_ENDPOINT=https://hf-mirror.com
export HF_HOME=/home/scc/pb25612046/.cache/huggingface
export HF_HUB_OFFLINE=1
cd /home/scc/pb25612046/lagernvs
PY=/home/scc/pb25612046/.conda/envs/lagernvs/bin/python
echo "=== NODE: $(hostname) GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader) ==="
$PY -c "import torch; print(torch.__version__, torch.cuda.is_available())"
$PY scripts/showcase512.py
echo "SHOWCASE_EXIT=$?"
