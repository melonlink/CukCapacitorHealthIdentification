# Cuk 能量传递电容健康辨识验证摘要

## 结论

最终评定为 **B — Supported with Engineering Constraints**。T12/T13/T15/T16/T17 在 Model A 和独立 Simscape Model B 中均得到支持；CCM 下 `rank(Phi)=2`、`rank(O)=3`。方案可以进入硬件实验，但结论必须限定为同步采样、明确噪声口径、协方差下限和 ESL 边沿外推成立时有效。

## 核心数值

| 项目 | 结果 |
|---|---:|
| Model A 电流重构 NRMSE | 0 |
| Model B 电流重构 NRMSE | 1.2443e-7 |
| Model A 边沿 ESR MAPE | 2.14e-12% |
| Model B 边沿 ESR MAPE | 0.6574% |
| 理想 RLS C/ESR MAPE | 0.000357% / 0.1203% |
| 理想 TS-LTVKF C/ESR MAPE | 0.0234% / 1.0023% |
| 51 个 CCM 工况，自适应 KF 最大 C/ESR MAPE | 0.2021% / 1.1263% |
| 30 dB 纹波 RMS 噪声，KF 中位 C/ESR MAPE | 0.0956% / 0.9688% |
| 20 nH ESL，naive / 外推 ESR MAPE | 658.7% / 1.159% |
| 负载/输入瞬态最大稳态虚假 C/ESR 偏差 | 0.0621% / 1.007% |

## 工程边界

- 75 个工况中 24 个进入 DCM，未纳入 CCM 算法成功统计。
- 固定且过小的 KF 测量协方差会在高占空比工况严重发散；自适应协方差后通过。
- “30 dB”只有在相对纹波 RMS 定义时足够；相对 40 V 全信号 RMS 定义时不足。
- 当前量程下，TS-LTVKF 的最低明确通过组合为 16-bit、16 points/cycle。
- 20 ns（0.001 Ts）偏移已使边沿关联失败，因此硬件必须做 PWM 同步与通道延迟标定。
- ESL 使直接峰值法失效；线性边沿外推是当前可行修正。

完整审查材料见 `RESULT_FOR_CHATGPT.md`，统一机器可读数据见 `results/tables/result_metrics.csv`。
