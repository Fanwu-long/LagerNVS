#!/bin/bash
# ============================================================
# LagerNVS 环境搭建脚本
# 使用方法：在登录节点执行  bash scripts/01_setup_env.sh
# ============================================================
set -euo pipefail

echo "=========================================="
echo "  LagerNVS 环境搭建开始"
echo "=========================================="

# 加载 miniconda 模块
module load miniconda/py312
source "$(conda info --base)/etc/profile.d/conda.sh"

# 配置中科大镜像源（加速下载）
echo "[1/5] 配置 conda/pip 镜像源..."
pip config set global.index-url https://mirrors.ustc.edu.cn/pypi/web/simple

# 创建 conda 环境（如果不存在）
ENV_NAME="lagernvs"
if ! conda env list | grep -q "^${ENV_NAME} "; then
    echo "[2/5] 创建 conda 环境: ${ENV_NAME} (Python 3.10)..."
    conda create -n ${ENV_NAME} python=3.10 -y
else
    echo "[2/5] conda 环境 ${ENV_NAME} 已存在，跳过创建"
fi

conda activate ${ENV_NAME}
echo "当前 Python: $(python -V)"
echo "当前 pip: $(which pip)"

# 安装 PyTorch 2.8.0 + CUDA 12.6
echo "[3/5] 安装 PyTorch 2.8.0 + CUDA 12.6..."
if python -c "import torch; assert torch.__version__.startswith('2.8')" 2>/dev/null; then
    echo "  PyTorch 已安装: $(python -c 'import torch; print(torch.__version__)')"
else
    pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 \
        --index-url https://download.pytorch.org/whl/cu126
fi

# 安装核心依赖
echo "[4/5] 安装核心依赖..."
pip install \
    "numpy>=1.21" \
    "pillow>=9" \
    "einops>=0.6" \
    "omegaconf>=2.3" \
    "lpips>=0.1.4" \
    "easydict>=1.9" \
    "huggingface_hub>=0.16" \
    "iopath>=0.1.10" \
    "scipy>=1.9" \
    "av>=10" \
    "timm==1.0.25" \
    tqdm \
    pandas \
    "opencv-python>=4.13,<4.14" \
    "websockets>=16" \
    tensorboard \
    2>&1 | tee ~/lagernvs_pip_core.log

# 安装 xformers（可选，失败不影响基础功能）
echo "[5/5] 安装 xformers 0.0.32.post2（可选）..."
pip install xformers==0.0.32.post2 2>&1 | tee ~/lagernvs_pip_xformers.log || \
    echo "  警告: xformers 安装失败，将使用默认注意力机制"

echo ""
echo "=========================================="
echo "  环境搭建完成！"
echo "=========================================="
echo ""
echo "验证环境（需要 GPU，请到计算节点运行）："
echo "  conda activate lagernvs"
echo "  python -c \"import torch; print(torch.__version__, torch.cuda.is_available())\""
echo ""
echo "下一步：配置 HF_TOKEN"
echo "  mkdir -p ~/.cache/huggingface"
echo "  echo '你的hf_token' > ~/.cache/huggingface/token"
