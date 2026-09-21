#!/bin/bash
# LagerNVS interactive neural viewer — USTC Students partition helper
# Run on a GPU compute node (srun/sbatch), NOT on login node.
# Usage:
#   srun -p Students --qos=qos_stu_default --gres=gpu:A100:1 --cpus-per-task=4 --mem=16G -t 1:00:00 --pty bash
#   bash ~/lagernvs/06_run_interactive.sh
#   # optional: --wide   for faster 288x512 preview
set -euo pipefail

module load miniconda/py312 2>/dev/null || true
if [ -f "$(conda info --base 2>/dev/null)/etc/profile.d/conda.sh" ]; then
  # shellcheck disable=SC1091
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate lagernvs
fi

cd "${LAGERNVS_ROOT:-$HOME/lagernvs}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
export HF_HOME="${HF_HOME:-$HOME/.cache/huggingface}"
if [ -z "${HF_TOKEN:-}" ] && [ -f "$HOME/.cache/huggingface/token" ]; then
  HF_TOKEN="$(cat "$HOME/.cache/huggingface/token")"
  export HF_TOKEN
fi
export HF_HUB_OFFLINE="${HF_HUB_OFFLINE:-0}"

echo "cwd=$(pwd)  host=$(hostname)"
python -c "import torch; print('torch', torch.__version__, 'cuda', torch.cuda.is_available())"
echo "Serving interactive viewer on :8765 (tunnel: ssh -L 8765:localhost:8765 ...)"
exec python run_interactive_server.py --jpeg_quality 90 --port 8765 --bind 0.0.0.0 "$@"
