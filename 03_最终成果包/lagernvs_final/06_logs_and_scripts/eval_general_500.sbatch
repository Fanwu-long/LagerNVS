#!/bin/bash
#SBATCH -J lnvs_gen500
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -t 03:00:00
#SBATCH -o logs/gen500-%j.out
#SBATCH -e logs/gen500-%j.err
source ~/.bashrc
export LAGERNVS_DATA_ROOT=/home/scc/pb25612046/data_eval
export HF_ENDPOINT=https://hf-mirror.com
export HF_HOME=/home/scc/pb25612046/.cache/huggingface
export HF_HUB_OFFLINE=1
export LAGERNVS_VIDEO_LIMIT=8
cd /home/scc/pb25612046/lagernvs
PY=/home/scc/pb25612046/.conda/envs/lagernvs/bin/python
echo "=== NODE: $(hostname) GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader) ==="
$PY -c "import torch; print(torch.__version__, torch.cuda.is_available())"
echo "=== general model 2-view POSED 512 on 500 scenes ==="
/home/scc/pb25612046/.conda/envs/lagernvs/bin/torchrun --standalone --nproc_per_node=1 run_eval.py -c config/eval_re10k_general_500.yaml -e re10k_general_2v_512_500 --opt.batch_size 8
EC=$?
echo "EVAL_EXIT=$EC"
echo "=== scores ==="
cat output/re10k_general_2v_512_500/Dgen500/scores_iter_*.txt 2>/dev/null | tail -30
