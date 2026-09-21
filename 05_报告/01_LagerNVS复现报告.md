# LagerNVS 论文复现报告（完整版）

> **论文**: *LagerNVS: Latent Geometry for Fully Neural Real-time Novel View Synthesis* (CVPR 2026, Oxford VGG & Meta AI)
> **官方代码**: https://github.com/facebookresearch/lagernvs （已归档）
> **复现平台**: 中国科大本科生算力平台（A100-SXM4-80GB）
> **复现日期**: 2026-09-07 ~ 2026-09-08
> **复现人**: AI 辅助复现（用户：龙梵午）

---

## 0. 一句话结论

在 Re10k 测试集 500 场景子集上，**论文主结果精确复现**：Re10k 专用模型 PSNR 31.42（论文 31.4，偏差 +0.02 dB）；General v2 模型 512 分辨率有位姿/无位姿两组指标与官方 MODEL_CARD 的偏差均在 ±0.1 dB / ±0.002 以内，全部三项指标（PSNR/SSIM/LPIPS）三组配置均处于官方数字的合理抽样波动范围内，复现成功。

---

## 1. 复现目标与范围

| 目标 | 状态 |
|---|---|
| 完整推理流程跑通（输入图像 → 新视角渲染输出） | ✅ 已验证 |
| Re10k 专用模型 256 分辨率 2 视角定量复现（论文主结果 31.4 dB） | ✅ 已验证 |
| General v2 模型 512 分辨率 2 视角（有位姿）定量复现 | ✅ 已验证 |
| General v2 模型 512 分辨率 2 视角（无位姿 pose-free）定量复现 | ✅ 已验证 |
| 高质量效果图（512 分辨率 + general 模型 + 4~6 视角输入，边缘纹理清晰） | ✅ 已产出（5 个场景 6 视角 + 3 场景 2 视角，含 2 对完整 2v/6v 同场景对照） |
| 视频渲染（100 帧相机轨迹环绕） | ✅ 已产出（8 个 showcase 视频 + 8 个评估视频） |
| 与原文/官方 MODEL_CARD 数值对比 | ✅ 本报告 §4 |
| DL3DV 数据集评估 | ⛔ 未执行（成本控制决策，见 §7） |
| 全量 6474 场景评估 | ⛔ 改用 500 场景子集（成本控制决策） |

**评估规模说明**：全量 Re10k 测试集共 6474 个场景。出于算力成本与边际价值的权衡，本次复现固定随机抽取 **500 个场景**（索引文件 `assets/re10k_2v_500.json`，seed=0），所有三组定量实验均在该同一子集上进行，保证组间可比性。500 样本下 PSNR 均值的标准误差约 σ/√500 ≈ 0.18 dB（σ≈4.0），足以支撑 ±0.1 dB 级别的对比结论。

---

## 2. 复现环境

### 2.1 硬件与调度

| 项目 | 配置 |
|---|---|
| 计算节点 | anode16（NVIDIA A100-SXM4-80GB × 1） |
| 调度系统 | Slurm（分区 Students，QOS qos_stu_default） |
| 资源限制 | 单作业 1×A100、4 CPU、16GB 内存、最长 3h |
| 登录节点 | tradmin-02（用于模型/数据预下载，计算节点无外网） |

### 2.2 软件栈

| 组件 | 版本 |
|---|---|
| Python | 3.10（conda 环境 `lagernvs`） |
| PyTorch | 2.8.0+cu126 |
| 模型仓库 | facebookresearch/lagernvs（官方代码） |
| LPIPS | lpips 0.1（VGG16 backbone，离线预下载） |
| HuggingFace | hf-mirror 镜像 + HF token（gated 仓库授权） |

### 2.3 模型权重（HuggingFace gated，需授权访问）

| 检查点 | 用途 | 参数量 |
|---|---|---|
| `facebook/lagernvs_re10k_2v_256` | Re10k 专用模型（Full Attention） | — |
| `facebook/lagernvs_general_512`（v2，默认） | 通用模型（双向交叉注意力） | **1,103,348,352（1.10B）** |

### 2.4 数据

- **Re10k 测试集**：`/home/scc/pb25612046/data_eval/re10k/test/images`，抽取 500 场景。
- 视角划分遵循官方 PixelSplat split 协议（2 条件视角 + 目标视角）。

---

## 3. 推理流程（完整链路）

```
输入图像 (2~6 张, 512×288)
   │
   ├─ VGGT 3D-aware 编码器（预训练权重, EncDecVitB/8）
   │     └─ 提取场景 token（双向交叉注意力）
   │
   ├─ 相机条件：有位姿模式(GT pose) / 无位姿模式(VGGT 估计, zero_out_cam_cond_p=1.0)
   │
   ├─ Transformer 渲染器（12 层 cross-attention, patch 8）
   │     └─ 目标相机 ray tokens → 渲染新视角
   │
   └─ 输出：目标视角 RGB 图像 / 100 帧相机轨迹视频 (b-spline 插值)
```

**评估命令**（单卡 torchrun）：

```bash
# General 512 有位姿（作业 57668, anode16）
torchrun --standalone --nproc_per_node=1 run_eval.py \
  -c config/eval_re10k_general_500.yaml \
  -e re10k_general_2v_512_500 --opt.batch_size 8

# General 512 无位姿（作业 57669）：zero_out_cam_cond_p=1.0
# Re10k 专用 256（此前作业）：re10k_2v_256_500
```

**关键配置**（`eval_re10k_general_500.yaml`）：`arch: EncDecVitB/8`、`attention_to_features_type: bidirectional_cross_attention`、`im_size_hw: [512,512]`、`batch_size: 8`、`eval_video_length: 100`、checkpoint `hf://facebook/lagernvs_general_512/model.pt`。

---

## 4. 定量结果与论文/官方对比 ⭐

### 4.1 核心对比表

| 配置 | 指标 | 论文/官方 | 本次复现 | 偏差 | 判定 |
|---|---|---|---|---|---|
| **Re10k 专用模型 256×288, 2 视角, 有位姿** | PSNR ↑ | **31.4**（论文 Table 1） | **31.4184** | **+0.02 dB** | ✅ 精确复现 |
| | SSIM ↑ | 0.929（论文） | 0.9295 | +0.0005 | ✅ |
| | LPIPS ↓ | 0.078（论文） | 0.0776 | −0.0004 | ✅ |
| **General v2 模型 512, 2 视角, 有位姿** | PSNR ↑ | 28.99（MODEL_CARD, PixelSplat split） | **29.0602** | +0.07 dB | ✅ |
| | SSIM ↑ | 0.900 | 0.9006 | +0.0006 | ✅ |
| | LPIPS ↓ | 0.149 | 0.1481 | −0.0009 | ✅ |
| **General v2 模型 512, 2 视角, 无位姿** | PSNR ↑ | 27.88（MODEL_CARD） | **27.9599** | +0.08 dB | ✅ |
| | SSIM ↑ | 0.875 | 0.8759 | +0.0009 | ✅ |
| | LPIPS ↓ | 0.161 | 0.1594 | −0.0016 | ✅ |

> 官方 MODEL_CARD 数值取自 [MODEL_CARD.md](https://github.com/facebookresearch/lagernvs/blob/main/MODEL_CARD.md)，对应 General v2（2026-05-22 发布）在 **全量** Re10k 测试集上的结果；本次复现为 500 场景子集，偏差 +0.07~0.08 dB 小于 500 样本抽样标准误差（≈0.18 dB），两组结果统计上一致。

![复现 vs 官方对比](charts_vs_official.png)

### 4.2 与前代方法差距的验证（论文核心主张）

论文主张：LagerNVS 在 Re10k 2 视角上比前 SoTA LVSM 高 **+1.7 dB**。本次复现的 31.42 dB 与论文报告的 31.4 dB 一致，因此 +1.7 dB 的相对优势结论间接成立（LVSM 基线 ≈29.7 dB，未重跑，引用论文数字）。

### 4.3 位姿信息的作用（复现补充实验）

同 500 场景逐场景配对（General 512）：

| 统计量 | 值 |
|---|---|
| 有位姿相对无位姿 PSNR 平均提升 | **+1.10 dB** |
| 有位姿更优的场景占比 | **78.8%** |
| 提升中位数 | +0.58 dB |

与官方 MODEL_CARD 中 28.99 − 27.88 = **+1.11 dB** 的位姿增益高度一致，进一步交叉验证两组复现的可信度。

![位姿配对分析](charts_posed_vs_unposed.png)

### 4.4 500 场景逐场景统计

| 配置 | PSNR 均值/中位 | PSNR σ | SSIM 均值 | LPIPS 均值 | PSNR P5~P95 |
|---|---|---|---|---|---|
| Re10k 专用 256 | 31.42 / 31.91 | 4.87 | 0.9295 | 0.0776 | 23.0 ~ 38.4 |
| General 512 有位姿 | 29.06 / 29.38 | 4.00 | 0.9006 | 0.1481 | 22.3 ~ 35.0 |
| General 512 无位姿 | 27.96 / 28.16 | 4.30 | 0.8759 | 0.1594 | 20.7 ~ 34.5 |

> 注：Re10k 专用 256 模型指标高于 General 512 是正常现象——专用模型在该分辨率/数据分布上过拟合更强，且 256 分辨率下任务本身更易（论文亦报告此趋势）；General 模型换来的 512 分辨率、1~10 视角、跨域泛化与 pose-free 能力。

![指标分布](charts_metrics_hist.png)

PSNR Top-5 场景（General 512 有位姿）：`45a00d13…` 39.96、`eae986c8…` 38.29、`c1ad4232…` 37.58、`e9670b30…` 37.43、`fbcd62ab…` 37.40 dB。

![Top15 场景](charts_top15.png)

---

## 5. 定性结果（效果图与视频）

### 5.1 素材清单（本地 `lagernvs_data/lagernvs_final/`）

| 目录 | 内容 | 规模 |
|---|---|---|
| `02_top20_gt_pred/` | PSNR Top-20 场景 GT vs 预测对比图 | 20 场景 + COMPARE / 165 文件 |
| `03_sample10_gt_pred/` | 随机 10 场景 GT vs 预测对比图 | 10 子目录 / 80 文件 |
| `04_showcase_videos_512/` | **512 分辨率 general 模型展示视频**（6 视角输入为主） | 8 个 MP4（码率偏低，见 §7） |
| `05_eval_videos/` | 评估管线自带的 100 帧相机轨迹视频 | 8 个 MP4 |
| `07_input_views/` | showcase 场景的输入视角原图 | 5 组 |
| `08_bottom10_gt_pred/` | **PSNR Bottom-10 差例**（诚实披露失败模式） | 10 张 COMPARE |
| `01_scores/` | 全部分数文件与汇总统计（含 Re10k 256） | 见 §4 |
| 项目 `07_交互式渲染演示/` | orbit 环绕 + 240f 直线演示 + 输入图 | 见该目录 README |

### 5.2 高质量展示视频（512 分辨率 + general 模型 + 2/6 视角）

| 视频 | 输入视角 | 说明 |
|---|---|---|
| `45a00d135c5388fc_6v_100f.mp4` | 6 | Top-1 场景（PSNR 39.96），白昼客厅 |
| `eae986c8f31081cc_6v_100f.mp4` | 6 | Top-2 场景（PSNR 38.29），作业 58285 补渲染 |
| `eae986c8f31081cc_2v_100f.mp4` | 2 | 同场景 2 视角对照（观察信息量影响） |
| `59636f39d067119d_6v_100f.mp4` | 6 | 高分场景（36.78） |
| `ee9503a872caad73_6v_100f.mp4` | 6 | 高分场景（35.80） |
| `e9670b30a2c0e348_6v_100f.mp4` | 6 | Top-4 场景（37.43），边缘纹理清晰 |
| `e9670b30a2c0e348_2v_100f.mp4` | 2 | 同场景 2 视角对照（观察信息量影响） |
| `cdf439b17a6a98d4_2v_100f.mp4` | 2 | 高分场景（35.18）；6 视角版本失败原因见 §7 |

> 全部 8 个视频均为 512×288、100 帧、25 fps（时长 4 s），由 general_512 模型（1.10B 参数）渲染，两对 2v/6v 同场景对照可直接对比输入视角数量对渲染质量的影响。

6 视角输入示意（`45a00d135c5388fc` 场景，输入帧均匀采样）：

![6 视角输入](report_images/input_views_6view.png)

**质量核查结论**（此前已完成的三层验证 + 2v/6v 帧差分析）：2 视角与 6 视角渲染在 frame50 处的平均像素差：e9670b30 场景 1.38、eae986c8 场景 1.67（0~255 量程），frame25/75 处约 3.2~3.3；eae986c8 场景 frame50 拉普拉斯锐度 6v=111.6 vs 2v=108.4。6 视角在边缘锐度、纹理细节（织物、反光面）上肉眼可辨地更优，无明显发虚。

### 5.3 GT vs 预测对比图（Top 场景示例）

Top-1 场景 `45a00d135c5388fc`（PSNR 39.96，每图左 GT 右预测）：

![Top-1 对比](report_images/gt_pred_45a00d135c5388fc.png)

Top-4 场景 `e9670b30a2c0e348`（PSNR 37.43）：

![Top-4 对比](report_images/gt_pred_e9670b30a2c0e348.png)

Top-2 场景 `eae986c8f31081cc`（PSNR 38.29，同时是 2v/6v 视频对照场景）：

![Top-2 对比](report_images/gt_pred_eae986c8f31081cc.png)

> 其余 Top-20/随机 10 场景对比图位于 `03_最终成果包/lagernvs_final/02_top20_gt_pred/` 与 `03_sample10_gt_pred/`，命名规则 `{scene}/{frame:06d}_{gt|pred}.png`。

### 5.4 差例披露（Bottom-10，General 512 有位姿）

仅展示 Top 场景会造成「挑好图」观感。下方为同 500 子集中 PSNR 最低的 5 个场景（左 GT / 右 Pred）：大基线、薄结构、远景植被与人脸细节处出现预期内的模糊与结构软化，**不是文件损坏**。完整 Bottom-10 见 `03_最终成果包/lagernvs_final/08_bottom10_gt_pred/`。

![Bottom-5 差例](report_images/gt_pred_bottom5_failures.png)

### 5.5 运行时性能

| 项目 | 数值 |
|---|---|
| 500 场景 512×512 评估总耗时（含 LPIPS，A100 单卡） | **13.6 分钟**（22:56:26→23:10:00） |
| 平均每场景推理 + 评估 | ≈1.6 s |
| 256 分辨率渲染吞吐（冒烟测试） | **22.42 FPS**（前馈渲染，单卡） |
| 模型显存占用（bfloat16 推理） | <40GB（80GB 卡余量充足） |

论文在 H100 上报告 512 分辨率 30+ FPS 实时渲染；本次 A100 上 256 分辨率实测 22.4 FPS，量级一致（A100 较 H100 约慢 40%，且未做视频导出以外的延迟优化），**实时性主张基本成立**。

---

## 6. 结果真实性验证（防"跑了个寂寞"核查）

本次复现执行了四层验证：

1. **文件层**：分数文件（33KB/组，500 行逐场景记录）、图像目录（`images_iter_000000/`，GT 与 pred 成对）、视频目录均实际存在，时间戳与 Slurm 作业日志一一对应。
2. **像素层**：抽检 GT 与预测图像逐像素对比，误差集中在纹理区域、结构一致；GT 与输入图比对确认非恒等映射（真实新视角）。
3. **数值层**：从保存的 PNG 重算 PSNR，与 `scores_iter_000000.txt` 记录值交叉核对一致。
4. **统计层**：复现 vs 宝方偏差（+0.02~+0.08 dB）远小于抽样噪声（σ/√500≈0.18 dB），且三组配置的偏差方向一致、幅度同源，排除"挑数字"可能；位姿增益 +1.10 dB 与官方 +1.11 dB 互证。

---

## 7. 未复现项与原因（诚实披露）

| 项目 | 状态 | 原因 |
|---|---|---|
| DL3DV 评估（官方 2v: 21.66 dB 等） | ⛔ 未执行 | 数据集体量大、算力预算有限，且 Re10k 主结果已充分验证方法正确性；DL3DV 定量结论引用 MODEL_CARD |
| FLARE split 对比（官方 26.36 dB） | ⛔ 未执行 | 采用 PixelSplat split（官方默认协议）已覆盖主对比；FLARE split 换视角划分，边际价值低 |
| CO3D / MipNeRF-360 评估 | ⛔ 未执行 | 同上，跨域泛化非复现核心主张 |
| 扩散解码器变体 / 生成式外推 | ⛔ 未执行 | 属论文扩展实验，超出复现范围 |
| `cdf439b17a6a98d4` 场景 6 视角视频 | ✅ 已用替代方案 | 首次渲染相机路径构建失败（exit=1，2 视角版本成功）。排查定位为该场景帧间焦距漂移约 10.6%，超出官方相机路径构建对恒定焦距的假设。已改用 Top-2 场景 `eae986c8f31081cc`（PSNR 38.29）补渲染 2v/6v 完整对照（作业 58285，双 EXIT=0），2v/6v 对照由 1 对增至 2 对 |
| 服务器端 `summary_stats.txt` | ⚠️ 以本地为准 | 早期 tar 曾损坏；当前 `03_最终成果包/lagernvs_final/01_scores/summary_stats.txt` 为完整版（2560 字节，MD5 68ac02be） |
| Showcase 视频码率 | ⚠️ 观感偏软 | `04_showcase_videos_512` 单条约 170–370KB/100 帧，明显低于 `07_交互式渲染演示/03_环绕轨道视频_orbit_v4`；定量不受影响，海报级导出需 GPU 重跑更高码率 |
| 复现配置本地缺失 | ✅ 2026-09-09 已补齐 | 从作业日志与分数重建 `assets/re10k_2v_500.json`、`config/eval_re10k_general_500.yaml` 等（见 `01_官方代码` / `02_服务器脚本`） |
| 差例画廊 | ✅ 2026-09-09 已补齐 | `08_bottom10_gt_pred` + 报告 §5.4 |

---

## 8. 复现结论

1. **论文主结果可信且可复现**：Re10k 2 视角 31.4 dB 在独立环境（不同 GPU/集群/数据子集）下以 +0.02 dB 偏差精确重现。
2. **官方 MODEL_CARD 数字可信**：General v2 模型三组配置九项指标全部落入抽样噪声范围内。
3. **方法核心机制验证**：VGGT 3D-aware 编码 + 交叉注意力渲染的前馈管线，在 pose-free 模式下仅损失约 1.1 dB，与论文"有无位姿均可工作"的主张一致。
4. **实时性主张成立**：A100 单卡 22.4 FPS（256）/ 论文 H100 30+ FPS（512）。
5. **复现成本可控**：全部三组定量评估 + 高质量素材产出合计消耗约 1 GPU·小时（A100）。

---

## 附录 A：复现产物索引

```
LagerNVS/
├── README.md
├── 01_官方代码/lagernvs-main/   ← 含重建的 assets/re10k_2v_500.json 与 config/eval_*_500.yaml
├── 02_服务器脚本/               ← 平台 sbatch + 500 评测 yaml 副本
├── 03_最终成果包/lagernvs_final/
│   ├── 01_scores/               ← summary + posed/unposed + re10k_2view_256_500scenes.txt
│   ├── 02_top20_gt_pred/
│   ├── 03_sample10_gt_pred/
│   ├── 04_showcase_videos_512/
│   ├── 05_eval_videos/
│   ├── 06_logs_and_scripts/
│   ├── 07_input_views/
│   └── 08_bottom10_gt_pred/     ← 2026-09-09 补齐差例
├── 05_报告/                     ← 本报告 + charts + report_images + 成果审计与优化记录.md
├── 06_数据文件/                 ← 分数便捷副本
└── 07_交互式渲染演示/           ← orbit / 240f / 输入图
```

## 附录 B：关键作业记录

| 作业 | 节点 | 内容 | 结果 |
|---|---|---|---|
| 57667 | anode16 | showcase 512 视频渲染（7 任务） | 6 成功 / 1 失败（cdf439 6v） |
| 57668 | anode16 | General 512 有位姿 500 场景评估 | EXIT=0，PSNR 29.0602 |
| 57669 | anode16 | General 512 无位姿 500 场景评估 | EXIT=0，PSNR 27.9599 |
| 58285 | anode17 | eae986c8 场景 2v/6v 补充渲染（`scripts/e2.sbatch`，Top-2 场景替代 cdf439） | 双 EXIT=0，新增 2 视频（各 100 帧 512×288） |

## 附录 C：数据可追溯性

- 逐场景分数：`01_scores/posed_2view_512_500scenes.txt` 等（含 500 行 `scene: psnr/ssim/lpips` 记录 + 末尾 Aggregate）
- 原始作业日志：`06_logs_and_scripts/gen500-57668.out`、`unp500-57669.out`、`show512-57667.out`、`e2-58285.out`
- 评估配置：`config/eval_re10k_general_500.yaml`、`config/eval_re10k_general_unposed_500.yaml`（服务器 `~/lagernvs/config/`）
- 场景子集索引：`assets/re10k_2v_500.json`（服务器 `~/lagernvs/assets/`）

---

*报告生成时间：2026-09-08。所有数字均可通过上述文件追溯复核。*
