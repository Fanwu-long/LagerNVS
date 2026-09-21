#!/bin/bash
# LagerNVS Browser WebUI — USTC Students partition
#SBATCH -J lager-webui
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH -c 4
#SBATCH --mem=16G
#SBATCH -t 1:00:00
#SBATCH -o /home/scc/pb25612046/lagernvs/logs/webui-%j.out
#SBATCH -e /home/scc/pb25612046/lagernvs/logs/webui-%j.err

set -euo pipefail
export PYTHONUNBUFFERED=1
mkdir -p /home/scc/pb25612046/lagernvs/logs

module load miniconda/py312
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate lagernvs

cd /home/scc/pb25612046/lagernvs
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
export HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
if [ -z "${HF_TOKEN:-}" ] && [ -f "$HOME/.cache/huggingface/token" ]; then
  export HF_TOKEN="$(cat "$HOME/.cache/huggingface/token")"
fi

# Root-level stray jpgs break find_scene_dirs (scene=".")
mkdir -p test_data/_raw_sidecars
mv -f test_data/scene_a_raw.jpg test_data/scene_b_raw.jpg test_data/_raw_sidecars/ 2>/dev/null || true

echo "HOST=$(hostname) JOB=${SLURM_JOB_ID:-na} IP=$(hostname -I | awk '{print $1}')"
python -c "import torch; print(torch.__version__, torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# Official Browser Viewer: 384x512, jpeg 95, demo scene
exec python run_interactive_server.py \
  --scenes demo \
  --jpeg_quality 95 \
  --port 8765 \
  --bind 0.0.0.0
