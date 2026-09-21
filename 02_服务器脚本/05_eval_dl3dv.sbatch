#!/bin/bash
# ============================================================
# LagerNVS DL3DV 评测（单卡版）
# 论文预期指标（DL3DV 专项模型，6视图有位姿，256x256）：
#   PSNR: 29.45  SSIM: 0.904  LPIPS: 0.068
# 使用方法：sbatch scripts/05_eval_dl3dv.sbatch
# 前置条件：
#   1. 环境已搭建
#   2. HF token 已配置
#   3. DL3DV 测试数据已下载（运行 04_download_dl3dv_eval.sh）
# ============================================================

#SBATCH -J lagernvs_dl3dv_eval
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH -t 04:00:00
#SBATCH -o logs/%x-%j.out
#SBATCH -e logs/%x-%j.err

set -euo pipefail

# 加载环境
module load miniconda/py312
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate lagernvs

# 进入项目目录
cd ~/LagerNVS
mkdir -p logs output

# 配置 HuggingFace
export HF_ENDPOINT=https://hf-mirror.com
if [ -f ~/.cache/huggingface/token ]; then
    export HF_TOKEN=$(cat ~/.cache/huggingface/token)
fi

# 数据根目录
export LAGERNVS_DATA_ROOT=${LAGERNVS_DATA_ROOT:-"$HOME/LagerNVS_data"}

echo "=========================================="
echo "  DL3DV 评测 - 单卡版（6视图）"
echo "=========================================="
echo "数据根目录: $LAGERNVS_DATA_ROOT"
echo "配置文件: config/eval_dl3dv_single.yaml"
echo ""

# 检查数据
if [ ! -f "$LAGERNVS_DATA_ROOT/dl3dv/full_list_test.txt" ]; then
    echo "错误: 未找到 DL3DV 测试数据"
    echo "请先运行: bash scripts/04_download_dl3dv_eval.sh"
    exit 1
fi

echo "环境检查:"
nvidia-smi | head -5
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"

echo ""
echo "=========================================="
echo "  开始评测（约 1-2 小时）"
echo "=========================================="

torchrun --nproc_per_node=1 run_eval.py \
    -c config/eval_dl3dv_single.yaml \
    -e dl3dv_6v_256_single_gpu \
    --opt.batch_size 64

echo ""
echo "=========================================="
echo "  评测完成！"
echo "=========================================="
echo "结果目录: output/dl3dv_6v_256_single_gpu/"
