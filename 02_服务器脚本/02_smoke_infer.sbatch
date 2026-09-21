#!/bin/bash
# ============================================================
# LagerNVS 推理 Smoke Test（单卡）
# 验证：环境、权重下载、推理流程是否正常
# 使用方法：sbatch scripts/02_smoke_infer.sbatch
# 前置条件：
#   1. 环境已搭建（运行过 01_setup_env.sh）
#   2. HF token 已配置 (~/.cache/huggingface/token)
#   3. test_data/demo/ 目录下有至少 2 张图片 (.jpg/.png)
# ============================================================

#SBATCH -J lagernvs_smoke
#SBATCH -p Students
#SBATCH --qos=qos_stu_default
#SBATCH --gres=gpu:A100:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -t 01:00:00
#SBATCH -o logs/%x-%j.out
#SBATCH -e logs/%x-%j.err

set -euo pipefail

# 加载环境
module load miniconda/py312
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate lagernvs

# 进入项目目录
cd ~/LagerNVS
mkdir -p logs outputs test_data/demo

# 配置 HuggingFace
export HF_ENDPOINT=https://hf-mirror.com
if [ -f ~/.cache/huggingface/token ]; then
    export HF_TOKEN=$(cat ~/.cache/huggingface/token)
    echo "HF_TOKEN 已加载"
else
    echo "警告: 未找到 HF_TOKEN，请先配置"
    echo "  echo '你的token' > ~/.cache/huggingface/token"
fi

echo "=========================================="
echo "  环境检查"
echo "=========================================="
nvidia-smi
python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'显存: {torch.cuda.get_device_properties(0).total_mem / 1024**3:.1f} GB')
"

echo ""
echo "=========================================="
echo "  检查测试图片"
echo "=========================================="
imgs=(test_data/demo/*)
if [ ! -f "${imgs[0]:-}" ]; then
    echo "错误: test_data/demo/ 目录下没有图片"
    echo "请上传 2 张以上图片到 test_data/demo/ 后重新提交"
    echo "支持格式: .jpg, .jpeg, .png"
    exit 2
fi

# 收集图片（最多取前6张）
img_files=()
for f in test_data/demo/*; do
    if [[ "$f" == *.jpg || "$f" == *.jpeg || "$f" == *.png ]]; then
        img_files+=("$f")
    fi
done

if [ ${#img_files[@]} -lt 2 ]; then
    echo "错误: 至少需要 2 张图片，当前只有 ${#img_files[@]} 张"
    exit 2
fi

echo "找到 ${#img_files[@]} 张图片，使用前 2 张进行推理"
echo "  ${img_files[0]}"
echo "  ${img_files[1]}"

echo ""
echo "=========================================="
echo "  开始推理（minimal_inference）"
echo "=========================================="
echo "模型: facebook/lagernvs_general_512"
echo "帧数: 30 帧（smoke test 用较少帧数快速验证）"
echo "输出: outputs/smoke_demo.mp4"

python minimal_inference.py \
    --images "${img_files[0]}" "${img_files[1]}" \
    --video_length 30 \
    --output outputs/smoke_demo.mp4

echo ""
echo "=========================================="
echo "  Smoke Test 完成！"
echo "=========================================="
echo "输出文件:"
ls -lh outputs/smoke_demo.mp4
echo ""
echo "下一步可以尝试："
echo "  1. 增加视频帧数（修改 --video_length 为 100 或更多）"
echo "  2. 使用更多输入图片（2-10 张）"
echo "  3. 运行完整评测（见 03_eval_re10k.sbatch）"
