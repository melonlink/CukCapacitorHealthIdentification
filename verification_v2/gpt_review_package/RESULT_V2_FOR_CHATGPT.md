# Verification v2 Result for GPT Review

## 1. Executive Result

**Grade C — partially supported.**

TR-TS-LTVKF 修复了 v1 的样本归属断崖，在锁定协方差下保持 51/51 CCM 通过，并在独立 Simscape Model B 的 20 nH + 200 ns + 20 ns RMS jitter 点达到 C<3%、ESR<5%。但 Model A 的激进 ESL/ringing 注入在 Stress A/B/C 全部失败，且 500 ns 和低带宽前端明确不可用。因此工程方向成立，尚不足以给出“强硬件支持”评级。

## 2. Baseline Cliff Diagnosis

v1 的所谓 20 ns 限制不是物理可辨识性极限。在更细扫描中，样本源索引于 ±10 ns 已发生整数切换，pre/post 点进入同一 PWM 状态，ESR raw MAPE 从 0.1535% 跳到约 100%；`rank(Phi)=2` 始终不变。参数投影只负责把错误结果显示成 90% 平台。Gate A PASS。

## 3. Timestamped Edge Extrapolation

比较了 adjacent、timestamped linear 和 robust local polynomial。最终选用 linear：它在 ±200 ns common offset 内 ESR MAPE 约 4.17% 以下，计算量和方差建模更简单；robust polynomial 没有稳定收益。边沿前后窗口分别拟合并外推到同一个 PWM 时间戳，电流也在同一时间坐标外推，不再要求 ADC 恰落在边沿相邻点。

默认工程窗口为 guard=0.5 µs、width=1.5–2.0 µs、每侧至少 3 点。窗口扫描 120 组中 108 组有效且通过；12 组因可用样本不足无有效拟合，而不是被记作低误差。

## 4. TR-TS-LTVKF Formulation Used

实际状态为

\[
x_k=[v_C,\ \bar\alpha,\ r_C]^T,\qquad \bar\alpha=10^{-4}/C.
\]

每个采样步的传播矩阵为

\[
F_k=\begin{bmatrix}
1&q_k/10^{-4}&0\\0&1&0\\0&0&1
\end{bmatrix}.
\]

三类异步观测为

\[
H_V=[1,0,i_C],\quad H_C=[0,q/10^{-4},0],\quad H_R=[0,0,i_1+i_2].
\]

实现中 stable V update 只校正内部电压状态；C 只由远离边沿的 charge pseudo update 校正；ESR 只由 timestamped edge pseudo update 校正。安全电荷过小则跳过 C 更新；ESR 窗口拟合完成后异步更新。DCM 内冻结两个健康参数，连续两个 CCM 周期后恢复。

## 5. Timing Tolerance

支持的 common PWM timestamp offset 为 ±200 ns；线性边沿法 ESR MAPE 从 0 ns 的 0.0946% 连续增加到 -200/+200 ns 的 4.17%/3.97%。±500 ns 已失败，不能宣称 Stretch。Gate B PASS，误差曲线不再出现 0→20 ns 的无物理断崖。

## 6. Channel Delay / Jitter

单电压通道：±200 ns 通过，±500 ns 起失败。单 i1/i2：扫描到 ±1 µs 仍通过。三通道 ±1 µs LHS 总通过率仅 23%，说明 inter-channel differential timing 而非单通道绝对延迟是主要风险。

50-seed jitter 结果：三种模式在 ≤100 ns RMS 全部 100% 通过；200 ns RMS 为 common 98%、independent 100%、PWM 98%；500 ns RMS 分别为 46%、60%、74%。推荐硬件目标 ≤50 ns RMS，不把 200 ns Monte Carlo 边界当作设计值。

## 7. ESL + Timing

Model B 实际 Simscape 结果：

- nominal 1 nH：C/ESR MAPE≈0.00119%/0.0611%，PASS；
- 1 nH + 200 ns：约 0.038%/4.24%，PASS；
- 20 nH + 200 ns + 20 ns RMS jitter：0.0384%/4.257%，PASS；
- 20 nH + 500 ns + 50 ns RMS jitter：0.2508%/11.025%，FAIL。

Model A 的导数+衰减振铃注入更激进：5 nH 起多数工况失败，Stress A/B/C 各 20 seeds 均 0% 通过。这一分歧是本轮最大未决项，不能用 Model B 单点覆盖。

## 8. ADC / Sampling Phase

在 3 bits × 5 samples/cycle × 16 phases × 2 algorithms 的 480 行扫描中，TR 方法的所有 14-bit 和 16-bit 配置均达到 100% phase pass；12-bit 仅 0%–25%。因此隔离量化/相位条件下最低支持 14-bit、8 samples/cycle。旧 TS-LTVKF 在相同扫描中最高仅 50% pass，且表现非单调。

最低支持不等于推荐硬件。推荐 16-bit、≥16 samples/cycle，为模拟噪声、时间校准和窗口点数留裕量。Gate E PASS。

## 9. Absolute Noise

独立于量化和 jitter 的绝对噪声结果：0.5 mV/0.1 mA 至 10 mV/5 mA 的每个 20-seed 等级均 100% 通过；20 mV/10 mA 为 85%；50 mV 电压噪声仅 25%。推荐将输入等效 RMS 控制在约 10 mV/5 mA 以下，并在硬件阶段联合量化、jitter 和前端噪声复测。

## 10. Normalized Observability

采用 `S=diag(Vb,1/Cnom,rnom)` 做状态尺度归一化。64 个工况/窗口/观测集合的 rank 全为 3，condition number 约 557–2282，minimum singular value 约 0.0592–1.273。最差 condition number 是 mid-load、3-cycle、stable-only，约 2282。Gate D PASS，但短窗口只是满秩，不代表信息充足。

## 11. Information Matrix

Nominal、20-cycle 下 `lambda_min(Wo)`：stable-only≈2.0094e5，+C≈2.0107e5，+R≈2.2882e5，full≈2.2898e5。C pseudo 对全局最弱特征值增加约 0.06%，ESR pseudo 约 13.9%，完整约 14.0%。C pseudo 的主要收益是方向解耦和对边沿失配的隔离，而不是显著提高这个单一标量。

## 12. Covariance / NIS Consistency

nominal/high-D/noisy 三组训练集一次性确定并锁定：

- `Q_vC=5.032e-6`，来自一步传播残差绝对值 97.5th percentile 的平方；
- `Q_alpha=Q_ESR=1e-10`；
- `R_V=2.9521e-6`；
- `R_C_floor=5.3297e-6`；
- `R_R_floor=7.8075e-6`；
- 三类 NIS gate=9。

51 CCM 的跨工况 median NIS p95 为 V≈1.215、C≈0.00107、R≈0.0147。C/R 明显保守；V 的平均拒绝率约 11.1%，C/R 约 1.1%。Gate F PASS（无逐工况调参），但协方差统计仍应在硬件噪声数据上再校准。

## 13. 51-CCM Regression

同一套锁定超参数在 51/51 CCM 工况全部通过：

- C median/max MAPE = 0.000914% / 0.0661%；
- ESR median/max MAPE = 0.143% / 1.227%；
- median/max convergence time ≈30/39.5 µs。

24 个 v1 DCM 工况保持排除并冻结健康更新。CCM→DCM→CCM 的 DCM 段跨度约 C=0.000733%、ESR=0.120%，恢复后更新重新开启。

## 14. Model B Cross-Validation

实际使用 MATLAB R2023b/Simscape Electrical，通过 `Simulink.SimulationInput` 运行 `cuk_simscape_circuit_model_v2.slx`。为避免 Simscape 的 L>0 约束，nominal 使用物理 1 nH 而非数学 0 H；压力点使用物理 20 nH。4 个要求工况中 3 个通过，500 ns/50 ns RMS 压力点失败。Gate G PASS，但只支持 Preferred、不支持 Stretch。

## 15. Remaining Failure Cases

1. Model A 激进 ESL/ringing 注入从 5 nH 起产生大幅 C/ESR 偏差；Stress A/B/C 全部失败。
2. Model B 的 20 nH + 500 ns + 50 ns RMS jitter ESR≈11.0%，失败。
3. matched front end ≤500 kHz 失败；数字时间戳不足以补偿波形幅相失真。
4. 三通道 ±1 µs 随机组合只有 23% 通过。
5. 12-bit ADC 在未知相位下不能可靠通过。
6. 20 mV/10 mA 噪声只有 85% 通过，50 mV 仅 25%。

所有 v2 失败行都保存 `pre_projection_C/ESR` 极端原始诊断与投影后最终估计；相等表示该失败没有被投影裁剪。Gate C PASS。

## 16. Scientific Assessment

1. **v1 的 20 ns 是不是物理极限？** 不是，是样本归属错误，90% 平台另含 projection 显示效应。
2. **新方法是否真正放宽硬件时序要求？** 是，从约 ±4 ns 的实现安全区放宽到支持 ±200 ns common/voltage timing，并对 ≤100 ns RMS jitter 保持 100% Monte Carlo 通过。
3. **edge extrapolation 是否应该成为正式论文方法的一部分？** 应该；线性外推是最终方法，robust polynomial 作为对照。
4. **rank(O)=3 之外，归一化信息量是否足以支持联合参数估计？** 在 blind CCM 和 Model B Preferred 点足够；短窗 stable-only 信息较弱，ESR pseudo 明显改善最弱方向。
5. **当前 ADC 要求是什么，置信度如何？** 最低仿真支持 14-bit/8 samples per cycle；硬件推荐 16-bit/≥16。对纯量化/相位结论置信度高，对联合前端/ESL 条件置信度中等。
6. **TS-LTVKF 是否仍应作为主算法？** 应以 TR-TS-LTVKF 版本作为主算法；旧 adjacent 版本不应进入硬件。
7. **是否可以进入实物实验？** 可以进入受控台架实验，但评级为 C，必须先做同步采样、时序标定和寄生参数分层测试。
8. **论文创新主句应该怎样改写？** 强调 timestamp-aware multi-rate fusion：C 来自安全窗口电荷，ESR 来自边沿窗口外推，归一化信息和协方差在训练后锁定。
9. **哪一条主张仍然证据不足？** 对真实 ESL/高频振铃与模拟前端传递函数变化的普适鲁棒性。

## 17. Recommended Hardware Experiment

- ADC bits：推荐 16-bit；14-bit 仅作为最低支持验证。
- Voltage range：0–100 V。
- Current range：±5 A，i1/i2 两通道。
- Minimum sampling rate：400 kS/s（8 samples/cycle@50 kHz）；推荐 ≥800 kS/s。
- PWM-trigger strategy：PWM 定时器同源时间戳/捕获；保存真实 edge timestamp，不依赖“相邻样本就是边沿两侧”。
- Front-end bandwidth：电压通道至少 1 MHz，推荐匹配 1–2 MHz；电流通道至少 250 kHz，并测量完整传递函数。
- Timing calibration：校准固定 channel skew 到 ±200 ns 内，设计 jitter ≤50 ns RMS；用阶跃/注入信号标定群延迟并进行数字补偿或反卷积。
- Required channels：vT、i1、i2、PWM edge timestamp；记录母线 Vin 与负载用于工况标注。
- Edge window：默认 guard 0.5 µs、width 1.5–2.0 µs、每侧 ≥3 点；避开可测振铃持续区。
- Simultaneous-sampling ADC：**preferred**，可显著降低差分通道 skew；若使用复用 ADC，必须逐通道时间戳并标定孔径延迟。

建议硬件测试顺序：nominal→注入 ±100/±200 ns skew→20/50 ns jitter→可控 5/10/20 nH ESL→带宽 2/1/0.5 MHz→联合压力点。每一步同时保存 raw waveform、edge fit residual、NIS 和 projection-before/after trace。

## 18. File Index

- `BASELINE_REPRODUCTION.md`：v1 cliff 机制。
- `V1_V2_COMPARISON.md`：固定 10 节 v1/v2 对比。
- `result_metrics_v2.csv`：所有测试统一长表，含 v1 字段与 v2 新字段。
- `results/tables/`：14 个专项表及统一指标副本。
- `results/figures/`：`fig_v2_01`–`fig_v2_20` 的 PNG 与 FIG。
- `results/raw/locked_covariance.mat`：训练后锁定超参数。
- `results/raw/timing_doe_summary.mat`、`analysis_summary.mat`：聚合与追踪数据。
- `model/cuk_simscape_circuit_model_v2.slx`：带物理 ESL 的独立 Model B。
- `scripts/run_v2_all.m`：完整重现实验入口。
- `gpt_review_package/`：给 GPT/外部审核的集中资料目录。
