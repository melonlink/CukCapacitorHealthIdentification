# Paper Verification v1 — Codex 执行任务
# Ćuk 能量传递电容 C–ESR 在线辨识论文证据链补强

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **阶段**：Paper Verification v1  
> **任务性质**：论文级算法验证与理论补强  
> **前置基线**：verification_v1 / v2 / v2.1 / v2.2 / v2.3  
> **冻结算法基线**：**TS-SLTVKE — Topology-Synchronous Structured LTV Kalman Estimator**  
> **本轮原则**：除非发现明确理论错误，**禁止继续修改核心 TS-SLTVKE 结构**。本轮目标不是继续降低某个单点 MAPE，而是补齐论文投稿前仍欠缺的三类证据：
>
> 1. **State-of-the-art baseline comparison（SOTA 公平对比）**
> 2. **Ablation study（创新组件消融）**
> 3. **Boundedness / convergence theory（有界性、收敛与持续激励条件）**
>
> 完成本轮后，应能够形成一篇完整的“理论 + 算法 + 高保真仿真”论文正文。硬件实验作为后续独立阶段补入。

---

# 0. 论文当前冻结主张

本轮所有工作围绕以下主线展开，不重新定义研究问题。

## 0.1 Ćuk 特异的天然双向激励

\[
i_C=(1-u)i_{L1}-u i_{L2}
\]

在 CCM 下：

\[
+i_{L1}\leftrightarrow-i_{L2}
\]

形成每个 PWM 周期内的天然双向电容电流激励。

---

## 0.2 两类物理解耦信息

### ESR

基于 timestamped edge reconstruction：

\[
z_R=\hat v_T^- - \hat v_T^+
\]

理想关系：

\[
z_R\approx k_R(i_1+i_2)r_C+\nu_R
\]

### Capacitance

基于 safe-window charge-domain observation：

\[
z_C=\Delta v_T-\hat r_C\Delta i_C
\]

\[
z_C=\frac{q}{C_b}\bar\alpha+\nu_C,
\qquad
\bar\alpha=\frac{C_b}{C}
\]

---

## 0.3 最终 estimator

状态：

\[
x=
\begin{bmatrix}
v_C & \bar\alpha & r_C
\end{bmatrix}^{T}
\]

采用 topology-synchronous、timestamp-aware、multi-rate、structured scalar Kalman/Joseph updates。

最终名称保持：

\[
\boxed{
\text{TS-SLTVKE}
}
\]

除非 Paper Verification v1 的理论审计证明名称与数学实现不符。

---

# 1. 目录与版本

建立：

```text
Cuk_Capacitor_Health_Identification/
├─ verification_v1/
├─ verification_v2/
├─ verification_v21/
├─ verification_v22/
├─ verification_v23/
└─ paper_verification_v1/
   ├─ README.md
   ├─ literature/
   ├─ baselines/
   ├─ ablation/
   ├─ theory/
   ├─ scripts/
   ├─ results/
   │  ├─ raw/
   │  ├─ tables/
   │  └─ figures/
   ├─ PAPER_THEORY_PROOF.md
   ├─ SOTA_COMPARISON.md
   ├─ ABLATION_RESULTS.md
   ├─ PAPER_VERIFICATION_RESULT.md
   ├─ PAPER_READY_RESULTS.md
   └─ result_metrics_paper_v1.csv
```

不得覆盖 verification_v23。

---

# 2. 本轮固定仿真平台

优先复用 v2.3 已验证模型。

## 2.1 Plant

- Model A：仅用于理想/快速算法批处理；
- Model B：Simscape Electrical 独立电路模型；
- F28379D device-realistic sampling chain：使用 v2.3 已冻结参数；
- 最终主要算法比较至少在 Model B 或由 Model B 生成的统一 observation dataset 上完成。

---

## 2.2 CCM 范围

第一篇论文明确限定：

\[
\boxed{\text{CCM}}
\]

DCM 只做 detection/freeze，不扩展第三拓扑状态。

---

## 2.3 Temperature

第一篇不做完整老化寿命模型。

但是所有结论明确表述为：

\[
\hat r_C(T,f_s,\text{aging})
\]

若本轮时间允许，增加一个简单 temperature-normalized sensitivity appendix；不允许为了温度扩展改变主任务。

---

# Part I — SOTA Baseline Comparison

# 3. 目标

必须回答：

> TS-SLTVKE 相对于已有通用 C/ESR 在线估计方法，优势究竟来自哪里？

比较必须公平。

不能：

- 给 Proposed method 用真实参数初始化；
- 给 baseline 用错误参数；
- 只挑 proposed 有利工况；
- 把不适合 Ćuk 的文献原封不动搬过来然后宣布失败；
- 把“跨拓扑改编方法”写成“原论文方法完全复现”。

---

# 4. 第一阶段：系统检索 baseline 文献

Codex 使用可访问的 Web / Browser / MCP / Scholar / IEEE Xplore / ScienceDirect / MDPI 等检索。

优先时间：

\[
2020\sim2026
\]

同时保留公认经典方法。

关键词至少：

```text
capacitor ESR capacitance online estimation power converter
DC-link capacitor condition monitoring ESR capacitance
Boost converter capacitor ESR estimation Kalman
power converter capacitor RLS parameter estimation
inherent signal capacitor ESR capacitance estimation
wavelet capacitor current reconstruction Kalman filter
online capacitor condition monitoring converter
Cuk converter capacitor fault diagnosis
Cuk converter capacitor parameter estimation
```

---

# 5. 文献筛选规则

每篇文献记录：

```text
title
authors
year
journal/conference
DOI
converter topology
capacitor role
estimated parameters
required sensors
external signal injection?
method
experimental validation?
reported C error
reported ESR error
sampling requirement
open source/code?
adaptable to Cuk?
```

形成：

```text
literature/SOTA_LITERATURE_MATRIX.csv
literature/SOTA_REVIEW.md
```

最低收录：

\[
N\ge20
\]

其中：

- 直接 C/ESR 联合估计 ≥8；
- Kalman 类 ≥4；
- RLS/least-squares 类 ≥4；
- inherent-signal / no-extra-injection 类 ≥3；
- wavelet/signal reconstruction 类 ≥2；
- Ćuk fault/diagnosis/prognostic 相关 ≥3。

---

# 6. 文献创新边界必须重新确认

最终明确回答：

1. 是否已有论文对 **Ćuk energy-transfer capacitor** 同时在线估计 C 和 ESR？
2. 是否已有论文利用：
   \[
   +i_{L1}\leftrightarrow-i_{L2}
   \]
   的拓扑换相做参数解耦？
3. 是否已有论文采用 timestamped edge extrapolation 做 Cuk ESR estimation？
4. 是否已有论文采用 structured multi-rate LTV estimator 做 Cuk capacitor health monitoring？
5. 哪一条创新可以安全写“to the best of our knowledge”？
6. 哪一条绝对不能写“first”？

输出：

```text
literature/NOVELTY_BOUNDARY.md
```

若发现直接高度重合工作，必须报告，不得隐瞒。

---

# 7. 最终 baseline 至少包含五类

## B0 — Closed-form physics baseline

Edge：

\[
\hat r_C=
\frac{\Delta v_{edge}}{i_1+i_2}
\]

C：

\[
\hat C=\frac{Q}{\Delta v_C}
\]

使用相同 timestamped edge reconstruction。

目的：

> 证明 Kalman/structured fusion 相对于简单闭式估计的价值。

---

## B1 — Conventional RLS

参数：

\[
\theta=
\begin{bmatrix}
1/C\\
r_C
\end{bmatrix}
\]

统一 integral regression：

\[
\Delta v_T=q/C+r_C\Delta i_C
\]

实现：

- forgetting factor；
- projection；
- 与 v1/v2 的 Topology-RLS 保持一致。

---

## B2 — Augmented-State EKF

状态至少：

\[
x=
[v_C,\ C,\ r_C]^T
\]

直接使用非线性：

\[
v_{C,k+1}=v_{C,k}+\frac{q_k}{C_k}
\]

以及真实 terminal voltage observation。

必须使用标准 Jacobian。

这是最重要的 generic nonlinear state-parameter baseline。

---

## B3 — Dual / Parameter Kalman Baseline

可选择：

### B3a Dual EKF

状态估计和参数估计分成两个滤波器；

或：

### B3b UKF

若 Dual EKF 不稳定，可使用 UKF。

选择必须提前写入：

```text
BASELINE_PROTOCOL.md
```

不能跑完后根据谁更差再挑。

---

## B4 — Signal-Reconstruction / Wavelet-KF-like Baseline

根据公开论文中可迁移到 Ćuk 的思路实现：

- Haar wavelet / band decomposition；
- capacitor current or ripple reconstruction；
- Kalman parameter update。

如果文献公开信息不足以严格复现：

明确命名：

```text
Cuk-adapted wavelet-KF baseline
```

不得称为 exact reproduction。

---

# 8. 可选第六类：inherent-signal RLS adaptation

如果文献公式足够公开，增加：

\[
\boxed{\text{B5 — inherent-signal/RLS adapted method}}
\]

但必须区分：

- 原 NPC/DC-link 方法；
- 我们迁移到 Ćuk 后的 adaptation。

如果无法公平迁移，写入 literature discussion，不强行做 baseline。

---

# 9. 所有 baseline 必须使用相同资源

统一：

- \(v_T\)；
- \(i_1\)；
- \(i_2\)；
- PWM timestamp。

如果某 baseline 原方法要求额外传感器：

有两组对比：

### Sensor-Fair

只允许使用与 Proposed 相同信号。

### Method-Native

允许 baseline 使用原论文要求的信号。

表格中分别标记。

---

# 10. 公平初始化

真实：

\[
C=C_{true}
\]

\[
r=r_{true}
\]

baseline 初始参数统一从误差分布采样：

\[
\hat C_0/C_{true}
\in[0.7,1.3]
\]

\[
\hat r_0/r_{true}
\in[0.5,1.5]
\]

随机种子固定。

不允许 Proposed 采用 nominal truth，而 baseline 使用远离真值初值。

---

# 11. 参数调优公平性

每个算法都允许使用**独立 training set**确定：

- Q/R；
- forgetting factor；
- gates；
- window；
- wavelet scale。

确定后：

\[
\boxed{\text{lock}}
\]

Blind test 不允许逐工况再调。

所有 tuning parameter 写入：

```text
baselines/LOCKED_HYPERPARAMETERS.csv
```

---

# 12. SOTA 比较测试矩阵

至少：

## Operating

\[
V_{in}=[19.2,24,28.8]V
\]

\[
D=[0.30,0.40,0.55,0.65]
\]

三类 CCM load：

- low-margin CCM；
- nominal；
- high load。

---

## Health

\[
C/C_0=[0.8,0.9,1.0]
\]

\[
ESR/ESR_0=[1,1.5,2]
\]

采用 stratified/LHS，至少：

\[
N\ge36
\]

blind points。

---

## Noise

至少：

```text
nominal
5 mV / 2 mA
10 mV / 5 mA
device-realistic F28379D Monte Carlo
```

---

## Timing

至少：

```text
0 ns
20 ns
50 ns
100 ns residual skew
```

---

## Dynamic

### load step

\[
25\%\rightarrow75\%
\]

### C step

\[
C_0\rightarrow0.8C_0
\]

### ESR step

\[
r_0\rightarrow2r_0
\]

---

# 13. SOTA 比较指标

每个算法：

### Accuracy

\[
MAPE_C
\]

\[
MAPE_R
\]

### Robustness

p50 / p95 / max。

### Dynamic

- convergence time；
- step tracking；
- false cross-coupling。

### Statistics

- bias；
- variance。

### Resource

- sensors；
- external injection；
- samples/cycle；
- state dimension；
- matrix dimension；
- multiplications/update；
- memory；
- estimated execution time。

### Failure

- divergence rate；
- projection saturation；
- invalid estimate。

---

# 14. 最终 SOTA 表必须论文可用

输出：

```text
table_paper_sota_comparison.csv
fig_paper_01_sota_accuracy.png
fig_paper_02_sota_noise.png
fig_paper_03_sota_timing.png
fig_paper_04_sota_dynamic.png
```

以及论文可直接使用的：

```text
SOTA_COMPARISON.md
```

必须包含：

> Proposed method 不一定在每一个理想工况精度第一，但在什么综合指标上具有优势？

禁止只挑最漂亮数字。

---

# Part II — Ablation Study

# 15. 目标

回答：

> TS-SLTVKE 中到底哪些组件是必要的？

---

# 16. 固定消融顺序

必须按以下定义，不允许随意重命名。

## A0 — Naive adjacent edge

v1 相邻点方法：

- adjacent samples；
- no timestamp extrapolation。

目的：

展示 timing cliff。

---

## A1 — Timestamp edge only

A0 +

- timestamped linear edge extrapolation。

C 仍使用原 integral/RLS-like method。

目的：

量化 edge reconstruction 的贡献。

---

## A2 — + Charge-domain C observation

增加 safe-window charge pseudo measurement：

\[
z_C
\]

但不使用 structured conditional state update。

---

## A3 — + Structured V/C/R directions

采用：

\[
H_V=[1,0,0]
\]

\[
H_C=[0,q/C_b,0]
\]

\[
H_R=[0,0,k_RI_\Sigma]
\]

但允许 raw data overlap。

目的：

量化 structured formulation。

---

## A4 — + Disjoint sample policy

禁止 V/C/R same-sample reuse。

目的：

检查 double-counting 与 covariance consistency。

---

## A5 — + Multi-cycle fusion

加入最终 1024-cycle information accumulation。

---

## A6 — Full TS-SLTVKE

加入：

- calibrated kR；
- NIS gating；
- parameter projection；
- locked covariance；
- DCM freeze。

---

# 17. 消融矩阵

至少选择六类代表性场景：

1. ideal nominal；
2. noisy nominal；
3. timing 50 ns；
4. low CCM margin；
5. \(C=0.8C_0\)；
6. \(ESR=2r_0\)；
7. device-realistic F28379D Monte Carlo。

---

# 18. Ablation 指标

每一 A0–A6：

\[
C\ MAPE
\]

\[
ESR\ MAPE
\]

\[
bias
\]

\[
variance
\]

\[
NIS
\]

\[
NEES
\]

\[
CI\ coverage
\]

\[
timing\ tolerance
\]

\[
convergence
\]

\[
computation
\]

---

# 19. 必须给每个组件“增益”

定义：

\[
Gain_k=
Metric(A_{k-1})-Metric(A_k)
\]

以及相对增益：

\[
RelativeGain_k=
\frac{Metric(A_{k-1})-Metric(A_k)}
{Metric(A_{k-1})}
\]

对 C/ESR 分别统计。

不能只给最终 A6。

---

# 20. Ablation 图

至少：

```text
fig_paper_05_ablation_C.png
fig_paper_06_ablation_ESR.png
fig_paper_07_ablation_timing.png
fig_paper_08_ablation_confidence.png
```

最终：

```text
ABLATION_RESULTS.md
table_paper_ablation.csv
```

---

# Part III — TS-SLTVKE 理论有界性 / 收敛性

# 21. 理论目标

不追求不现实的：

\[
\tilde\theta_k\rightarrow0
\]

全局严格收敛证明。

目标是建立一个**与实际 estimator 一致的有限窗口、有界噪声条件下的稳定性命题**。

至少证明/建立：

\[
\boxed{
\text{parameter estimation error is mean-square bounded}
}
\]

在无偏、持续激励和正确模型极限下，估计误差协方差收缩到有界邻域。

---

# 22. 先冻结数学模型

定义归一化参数：

\[
\theta=
\begin{bmatrix}
\bar\alpha\\
r_C
\end{bmatrix}
\]

其中：

\[
\bar\alpha=\frac{C_b}{C}
\]

参数慢变：

\[
\theta_{k+1}
=
\theta_k+w_{\theta,k}
\]

\[
E[w_{\theta,k}]=0
\]

\[
E[w_{\theta,k}w_{\theta,k}^T]
=
Q_{\theta,k}
\]

---

# 23. 两个健康参数的主要 measurement directions

C：

\[
z_{C,k}
=
h_{C,k}\bar\alpha_k+\nu_{C,k}
\]

\[
h_{C,k}=\frac{q_k}{C_b}
\]

R：

\[
z_{R,k}
=
h_{R,k}r_{C,k}+\nu_{R,k}
\]

\[
h_{R,k}=k_RI_{\Sigma,k}
\]

条件电压：

\[
z_{V,k}
=
v_{C,k}+\nu_{V,k}^{*}
\]

其中：

\[
\nu_V^*
\]

包含：

- voltage noise；
- current noise；
- ESR uncertainty propagation；
- model mismatch。

---

# 24. 明确假设集合

至少定义：

### Assumption 1 — bounded physical parameters

\[
0<C_{min}\le C_k\le C_{max}
\]

\[
0<r_{min}\le r_k\le r_{max}
\]

---

### Assumption 2 — bounded noise covariance

\[
0<R_{min}I\preceq R_k\preceq R_{max}I
\]

\[
0\preceq Q_k\preceq Q_{max}I
\]

---

### Assumption 3 — persistent excitation for C

存在 \(N_C,\mu_C>0\)：

\[
\sum_{j=k}^{k+N_C}
\frac{h_{C,j}^2}{R_{C,j}}
\ge\mu_C
\]

---

### Assumption 4 — persistent excitation for ESR

存在 \(N_R,\mu_R>0\)：

\[
\sum_{j=k}^{k+N_R}
\frac{h_{R,j}^2}{R_{R,j}}
\ge\mu_R
\]

---

### Assumption 5 — valid CCM/gating

只有：

\[
q_k\ge q_{min}
\]

和：

\[
I_{\Sigma,k}\ge I_{min}
\]

且 observation gate valid 时更新健康参数。

---

### Assumption 6 — bounded conditional-observation mismatch

由于：

\[
z_V=v_T-\hat r_Ci_C
\]

依赖当前估计，定义额外误差：

\[
d_{V,k}
\]

满足：

\[
E[d_{V,k}^2]\le \bar d_V
\]

或：

\[
|d_{V,k}|\le d_{max}
\]

---

# 25. 建议证明路线 A：uniform complete observability/controllability

对于 LTV Kalman Filter 的经典稳定性结果：

如果：

- 系统 uniformly completely observable；
- process excitation/covariance bounded；
- noise covariance positive definite；

则：

\[
P_k
\]

保持有界，filter error mean-square bounded。

Codex 必须检索权威来源并将其定理映射到 TS-SLTVKE。

不能把现成 theorem 直接复制；需要：

1. 给文献；
2. 写 theorem 条件；
3. 对照我们的 \(F_k,H_k,Q_k,R_k\)；
4. 明确哪些条件满足；
5. 哪些只在 CCM/gating window 内成立。

---

# 26. 建议证明路线 B：参数信息递推

因为 C 与 R 的结构化 pseudo measurement 是标量线性参数更新，可对参数 covariance 单独分析。

对于：

\[
P_{\alpha,k}^{-1}
=
P_{\alpha,k-1}^{-1}
+
\frac{h_{C,k}^2}{R_{C,k}}
\]

在无 process noise 理想情形：

持续激励可推出：

\[
P_{\alpha,k}
\]

单调下降。

ESR 同理：

\[
P_{r,k}^{-1}
=
P_{r,k-1}^{-1}
+
\frac{h_{R,k}^2}{R_{R,k}}
\]

若有：

\[
Q_{\theta}>0
\]

则 covariance 不趋零，而稳定在有限正下界/上界区间。

这条路线与我们 structured estimator 更贴合。

---

# 27. 至少形成两个正式命题

## Proposition 1 — Structural finite-window identifiability

在：

\[
q_k\neq0
\]

和：

\[
I_{\Sigma,k}\neq0
\]

以及有限窗口 PE 条件下：

\[
C,\ r_C
\]

局部结构可辨识。

这可继承现有 rank 证明，但要重新写成论文定理格式。

---

## Proposition 2 — Mean-square boundedness of TS-SLTVKE health parameters

在 Assumptions 1–6 下，存在有限：

\[
\bar P_C,\ \bar P_R
\]

使：

\[
E[\tilde\theta_k\tilde\theta_k^T]
\]

保持有界。

若：

\[
Q_\theta=0
\]

并满足无偏测量、持续激励，则参数 covariance 随累计信息增加而收缩。

若：

\[
Q_\theta>0
\]

则稳定到由：

- process noise；
- measurement noise；
- model mismatch；

共同决定的邻域。

---

# 28. 如果可以，再形成 Corollary

## Corollary — operating-condition gating

如果当前：

\[
q_k<q_{min}
\]

或：

\[
I_\Sigma<I_{min}
\]

导致 PE 不满足，则冻结 parameter update 可防止 covariance/parameter drift。

恢复 CCM 且 PE 满足后，估计器重新获得有限窗口可观测性。

这与当前 DCM freeze / low-excitation gate 直接对应。

---

# 29. 不允许过度证明

如果无法严格证明：

\[
\text{global asymptotic convergence}
\]

明确写：

> Global asymptotic convergence is not claimed.

重点：

\[
\boxed{
\text{boundedness + finite-window PE + covariance contraction}
}
\]

比一个错误的“global convergence theorem”更好。

---

# 30. 理论数值验证

理论命题必须用数值结果呼应。

扫描：

\[
\mu_C
\]

\[
\mu_R
\]

与：

- load；
- D；
- q；
- \(I_\Sigma\)；
- CRLB；
- empirical variance；
- convergence time。

验证：

\[
\mu\downarrow
\Rightarrow
variance\uparrow
\]

和：

\[
convergence\ slower
\]

输出：

```text
fig_paper_09_PE_vs_variance.png
fig_paper_10_information_vs_convergence.png
table_paper_PE_analysis.csv
```

---

# 31. 理论文档

生成：

```text
PAPER_THEORY_PROOF.md
```

必须包含：

1. Notation；
2. Assumptions；
3. Proposition 1；
4. Proof；
5. Proposition 2；
6. Proof / proof sketch；
7. Corollary；
8. Limitations；
9. Connection to simulation；
10. References。

---

# Part IV — Paper-Ready Verification Package

# 32. 最终必须输出一个论文级结果集

不是项目日志，而是：

```text
PAPER_READY_RESULTS.md
```

---

# 33. 推荐最终论文图控制在 10–12 张

从现有所有图中筛选。

建议：

### Fig. 1
Ćuk topology + C1 current directions。

### Fig. 2
Edge/charge decoupling conceptual waveform。

### Fig. 3
TS-SLTVKE architecture。

### Fig. 4
Identifiability / normalized information。

### Fig. 5
SOTA accuracy comparison。

### Fig. 6
Noise/timing robustness comparison。

### Fig. 7
Ablation。

### Fig. 8
Dynamic tracking。

### Fig. 9
PE / variance / convergence theoretical validation。

### Fig. 10
Device-realistic F28379D Monte Carlo。

### Fig. 11
Selected representative waveform。

如需要再加 Fig. 12。

不要把 50 张工程验证图都放论文正文。

---

# 34. 论文表格建议

## Table I
Symbols / parameters。

## Table II
Literature comparison。

## Table III
Algorithms and sensor requirements。

## Table IV
SOTA numerical comparison。

## Table V
Ablation。

## Table VI
Computational complexity。

## Table VII
Device-realistic simulation。

---

# 35. Complexity analysis

每个算法计算：

- state dimension；
- matrix inversion dimension；
- scalar divisions；
- multiplications；
- additions；
- memory；
- samples required；
- latency。

尤其：

\[
TS\text{-}SLTVKE
\]

因为使用 scalar sequential updates，应该明确说明复杂度优势。

输出：

```text
table_paper_complexity.csv
```

---

# 36. 最终论文可安全写的 contribution draft

Codex 最后基于真实结果生成一版建议，不直接决定最终文字。

要求四条以内。

建议结构：

### Contribution 1
Ćuk-specific natural bidirectional excitation。

### Contribution 2
Physically decoupled charge/edge observations + identifiability proof。

### Contribution 3
TS-SLTVKE structured multi-rate estimator + boundedness/PE analysis。

### Contribution 4
Timestamp edge reconstruction + extensive SOTA/device-realistic verification。

输出：

```text
PAPER_CONTRIBUTIONS_DRAFT.md
```

---

# 37. 失败判定

本轮必须接受以下可能结果：

## Case A

Proposed 明显优于所有 baseline。

正常报告。

## Case B

某 baseline 理想精度高于 proposed，但 proposed 在 timing/noise/sensors/complexity 综合更好。

同样可以形成高质量论文。

## Case C

Proposed 与普通 EKF/RLS 几乎无优势。

必须降低创新主张，并分析 TS-SLTVKE 是否仍有 topology/interpretability 价值。

## Case D

发现现有文献已经高度重合。

暂停论文撰写，重新评估 novelty。

不允许隐藏。

---

# 38. 最终 PASS 标准

Paper Verification v1 通过必须满足：

### SOTA

至少 5 个公平 baseline 完成。

### Novelty

未发现与核心方法高度重合的已发表方案，或差异已明确。

### Ablation

A0–A6 完成且至少关键组件的作用能被定量解释。

### Theory

至少两个正式 proposition 可成立。

### Statistics

blind test 结果无选择性删除。

### Complexity

TS-SLTVKE 的计算开销可明确量化。

### Reproducibility

所有图表可由一个入口脚本重生成。

---

# 39. 强制输出表格

```text
literature/SOTA_LITERATURE_MATRIX.csv
baselines/LOCKED_HYPERPARAMETERS.csv
results/tables/table_paper_sota_comparison.csv
results/tables/table_paper_ablation.csv
results/tables/table_paper_PE_analysis.csv
results/tables/table_paper_complexity.csv
results/tables/table_paper_blind_cases.csv
result_metrics_paper_v1.csv
```

---

# 40. 强制输出图

```text
fig_paper_01_sota_accuracy.png
fig_paper_02_sota_noise.png
fig_paper_03_sota_timing.png
fig_paper_04_sota_dynamic.png
fig_paper_05_ablation_C.png
fig_paper_06_ablation_ESR.png
fig_paper_07_ablation_timing.png
fig_paper_08_ablation_confidence.png
fig_paper_09_PE_vs_variance.png
fig_paper_10_information_vs_convergence.png
fig_paper_11_complexity.png
fig_paper_12_summary_radar_or_pareto.png
```

最后一张如果 radar 不适合论文，可以改为 Pareto：

\[
accuracy\leftrightarrow complexity
\]

不强制雷达图。

---

# 41. PAPER_VERIFICATION_RESULT.md 固定结构

## 1. Executive Decision

选择：

```text
PAPER_READY_SIMULATION
PAPER_READY_WITH_MINOR_GAPS
NOVELTY_RISK
THEORY_GAP
BASELINE_NOT_SUPPORTED
```

---

## 2. Novelty Boundary

明确回答：

- 哪几条创新成立；
- 哪几条不能写 first。

---

## 3. SOTA Baseline

谁最好？

Proposed 优势是什么？

---

## 4. Ablation

哪些组件真正必要？

---

## 5. Theory

两个 Proposition 是否成立？

证明强度是什么？

---

## 6. Persistent Excitation

最弱工况在哪里？

---

## 7. Complexity

嵌入式成本是否合理？

---

## 8. Final Simulation Claims

允许论文写哪些数字？

---

## 9. Limitations

至少包括：

- CCM only；
- temperature normalization；
- hardware pending；
- physical ringing/AFE hardware pending。

---

## 10. Journal Readiness

分别评价：

```text
IEEE TPEL
IEEE TIE
IEEE JESTPE
IET Power Electronics
IEEE Access
```

只能评价 paper fit/readiness，不做录用概率承诺。

---

## 11. Hardware Dependency

明确：

> 哪些结论现在已经不依赖硬件？
>
> 哪些结论必须等待硬件？

---

# 42. PAPER_READY_RESULTS.md

这是给论文作者直接看的文件。

必须只有：

- 最终数字；
- 最终图；
- 最终表；
- final captions；
- final result statements。

不要夹杂 Codex 调试过程。

---

# 43. 一个入口脚本

创建：

```text
scripts/run_paper_verification_v1.m
```

执行：

1. load frozen datasets；
2. run baselines；
3. run ablations；
4. run PE/theory numerical checks；
5. compute complexity；
6. regenerate tables；
7. regenerate figures；
8. validate outputs。

---

# 44. 审计脚本

创建：

```text
scripts/validate_paper_verification_v1.m
```

检查：

- missing baseline；
- missing literature metadata；
- NaN；
- cherry-picked rows；
- inconsistent random seeds；
- different test sets between algorithms；
- unlocked hyperparameters；
- missing failure rows；
- missing citations；
- mismatch between report numbers and CSV。

---

# 45. 最终停止条件

只有以下全部完成才结束：

- [ ] ≥20 篇文献矩阵
- [ ] novelty boundary 完成
- [ ] B0–B4 全部完成
- [ ] 可选 B5 有明确决定
- [ ] 所有 baseline 使用同一 blind set
- [ ] hyperparameters 锁定
- [ ] A0–A6 完成
- [ ] ablation quantitative gains 完成
- [ ] Proposition 1 完成
- [ ] Proposition 2 完成
- [ ] Corollary 或明确不采用
- [ ] PE 数值验证完成
- [ ] complexity 完成
- [ ] 论文主图 10–12 张筛选完成
- [ ] PAPER_VERIFICATION_RESULT.md 完成
- [ ] PAPER_READY_RESULTS.md 完成
- [ ] PAPER_CONTRIBUTIONS_DRAFT.md 完成
- [ ] 一键复现实验通过
- [ ] 审计脚本 PASS

---

# 46. Codex 最终执行指令

**读取 verification_v1、v2、v2.1、v2.2、v2.3 的全部冻结结果和源码，建立 `paper_verification_v1`。本轮禁止为了获得更漂亮结果继续修改 TS-SLTVKE 核心结构。目标是补齐论文投稿前的三项证据缺口：SOTA baseline、ablation 和 boundedness/convergence theory。首先系统检索并建立至少 20 篇 C/ESR 在线估计与 Ćuk 电容故障相关文献矩阵，明确 novelty boundary；然后在完全相同的 blind dataset、初始化、传感器资源和锁定调参规则下，比较 closed-form、RLS、augmented-state EKF、dual/UKF、wavelet-KF-like 和 proposed TS-SLTVKE。随后严格执行 A0–A6 消融，定量说明 timestamp extrapolation、charge-domain observation、structured update、disjoint samples 和 multi-cycle fusion 分别带来什么。理论部分不要追求不现实的 global asymptotic convergence，重点建立有限窗口 persistent excitation 下的 structural identifiability、parameter covariance contraction 和 mean-square boundedness，并用 numerical PE/Fisher-information/CRLB 结果呼应。所有负面结果必须保留。如果发现现有论文与核心创新高度重合，立即标记 NOVELTY_RISK，不得隐藏。最终生成可直接用于论文的图、表、定理、复杂度和结果数字，不再生成新的 ADC/硬件优化版本。**

---

## Version

- **Paper Verification v1**
- Date: **2026-08-22**
- Target: **close algorithm-paper evidence gaps before manuscript drafting**
- Frozen method: **TS-SLTVKE**
- Hardware status: **F28379D internal ADC confirmed with AFE constraints in v2.3; hardware experiment remains future validation**
