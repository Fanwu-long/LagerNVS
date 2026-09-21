#!/bin/bash
#SBATCH -J lnvs_e2
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -t 01:00:00
#SBATCH -o logs/e2-%j.out
#SBATCH -e logs/e2-%j.err
source ~/.bashrc
export HF_HOME=/home/scc/pb25612046/.cache/huggingface
export HF_HUB_OFFLINE=1
cd /home/scc/pb25612046/lagernvs
PY=/home/scc/pb25612046/.conda/envs/lagernvs/bin/python
D=/home/scc/pb25612046/data_eval/re10k/test/images/eae986c8f31081cc
$PY minimal_inference.py --images $D/00000.png $D/00021.png $D/00043.png $D/00064.png $D/00086.png $D/00107.png --video_length 100 --output outputs/showcase512/eae986c8f31081cc_6v_100f.mp4
echo SIX_V_EXIT=$?
$PY minimal_inference.py --images $D/00000.png $D/00107.png --video_length 100 --output outputs/showcase512/eae986c8f31081cc_2v_100f.mp4
echo TWO_V_EXIT=$?
echo E2_DONE