#!/bin/bash
# ============================================================
# LagerNVS Re10k 评测（单卡版）
# 论文预期指标（Re10k 专项模型，2视图有位姿，256x256）：
#   PSNR: 31.39  SSIM: 0.928  LPIPS: 0.078
# 使用方法：sbatch scripts/03_eval_re10k.sbatch
# 前置条件：
#   1. 环境已搭建
#   2. HF token 已配置
#   3. Re10k 测试数据已准备好（见 data_prep/ 目录）
# ============================================================

#SBATCH -J lagernvs_re10k_eval
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

# 数据根目录（如果设置了环境变量就用，否则用默认路径）
export LAGERNVS_DATA_ROOT=${LAGERNVS_DATA_ROOT:-"$HOME/LagerNVS_data"}

echo "=========================================="
echo "  Re10k 评测 - 单卡版"
echo "=========================================="
echo "数据根目录: $LAGERNVS_DATA_ROOT"
echo "配置文件: config/eval_re10k_single.yaml"
echo ""

# 检查数据是否存在
if [ ! -d "$LAGERNVS_DATA_ROOT/re10k/test" ]; then
    echo "错误: 未找到 Re10k 测试数据"
    echo "预期路径: $LAGERNVS_DATA_ROOT/re10k/test"
    echo ""
    echo "数据准备步骤："
    echo "  1. 下载 Re10k 数据（pixelSplat 版本）"
    echo "  2. 使用 LVSM 的 process_data.py 预处理"
    echo "  3. 设置环境变量: export LAGERNVS_DATA_ROOT=/path/to/data"
    exit 1
fi

echo "环境检查:"
nvidia-smi | head -5
python -c "import torch; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"

echo ""
echo "=========================================="
echo "  开始评测（约 1-2 小时）"
echo "=========================================="

# 单卡运行，batch size 从 512 降到 64（根据显存调整）
torchrun --nproc_per_node=1 run_eval.py \
    -c config/eval_re10k_single.yaml \
    -e re10k_2v_256_single_gpu \
    --opt.batch_size 64

echo ""
echo "=========================================="
echo "  评测完成！"
echo "=========================================="
echo "结果目录: output/re10k_2v_256_single_gpu/"
echo "查看指标: "
echo "  cat output/re10k_2v_256_single_gpu/metrics.txt"
