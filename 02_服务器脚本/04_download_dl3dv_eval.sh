#!/bin/bash
# ============================================================
# DL3DV 测试集下载脚本
# 下载 6 视图评测所需的 DL3DV benchmark scenes
# 使用方法：
#   1. 先在登录节点运行：bash scripts/04_download_dl3dv_eval.sh
#   2. 数据量较大，建议在交互式任务中运行
# 前置条件：
#   1. HF token 已配置（DL3DV 也是 gated dataset）
#   2. 已申请 DL3DV 数据集访问权限
# ============================================================

set -euo pipefail

module load miniconda/py312
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate lagernvs

cd ~/LagerNVS

# 配置 HuggingFace
export HF_ENDPOINT=https://hf-mirror.com
if [ -f ~/.cache/huggingface/token ]; then
    export HF_TOKEN=$(cat ~/.cache/huggingface/token)
fi

# 数据根目录
export LAGERNVS_DATA_ROOT=${LAGERNVS_DATA_ROOT:-"$HOME/LagerNVS_data"}
mkdir -p "$LAGERNVS_DATA_ROOT/dl3dv"

echo "=========================================="
echo "  DL3DV 评测数据下载"
echo "=========================================="
echo "数据根目录: $LAGERNVS_DATA_ROOT/dl3dv"
echo "视图配置: assets/dl3dv_6v.json（6 视图）"
echo ""

echo "注意: DL3DV 数据集在 HuggingFace 上是 gated 的"
echo "请先在 https://huggingface.co/datasets/DL3DV/DL3DV-ALL-960P 申请访问权限"
echo ""

# 验证 HF 登录状态
echo "验证 HuggingFace 访问权限..."
python -c "
from huggingface_hub import HfApi
api = HfApi()
try:
    api.dataset_info('DL3DV/DL3DV-ALL-960P')
    print('  DL3DV-ALL-960P: 可访问')
except Exception as e:
    print(f'  DL3DV-ALL-960P: 无法访问 - {e}')
    print('  请先申请访问权限！')
    exit(1)
" || exit 1

echo ""
echo "开始下载（可能需要较长时间）..."
cd data_prep/dl3dv

python download_eval.py \
    --output_dir "$LAGERNVS_DATA_ROOT/dl3dv" \
    --view_indices_path ../../assets/dl3dv_6v.json

echo ""
echo "=========================================="
echo "  下载完成！"
echo "=========================================="
echo "数据目录: $LAGERNVS_DATA_ROOT/dl3dv"
echo ""
echo "验证数据结构:"
ls "$LAGERNVS_DATA_ROOT/dl3dv/" | head -20
echo ""
echo "测试集列表:"
head -5 "$LAGERNVS_DATA_ROOT/dl3dv/full_list_test.txt" 2>/dev/null || echo "  (未找到)"
