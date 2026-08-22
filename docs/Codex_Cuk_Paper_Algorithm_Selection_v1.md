# Codex 执行任务 — Paper Algorithm Selection v1
# Ćuk 能量传递电容 C–ESR：最终估计器选择与论文方法性能对比

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **阶段**：Paper Algorithm Selection v1  
> **前置结果**：verification_v1–v2.3、Paper Verification v1、Paper Verification v1.1  
> **已冻结的核心创新**：Ćuk topology-synchronous decoupled observation framework  
> **当前主问题**：在同一 proposed observation framework 下，第一篇论文应采用哪一个 estimator 作为主实现？
>
> **主要候选**：
>
> 1. **O1-RLS**：proposed topology-decoupled observation + recursive least squares  
> 2. **O1-TS-SLTVKE**：proposed topology-decoupled observation + structured LTV Kalman estimator
>
> **辅助参考**：
>
> 3. **O1-Dual EKF**：仅作为已冻结的第三参考算法  
> 4. **O1-Closed-form**：仅在部分场景作为物理下限/非融合参考
>
> 本轮结果未来直接用于论文中的：
>
> - estimator performance comparison；
> - dynamic tracking comparison；
> - robustness comparison；
> - computational complexity comparison；
> - method-selection discussion；
> - limitations；
> - final method architecture。
>
> **禁止事项**：
>
> - 不修改 O1 edge/charge observation；
> - 不重新设计 TS-SLTVKE；
> - 不增加 adaptive-Q/change-detector 使 TS-SLTVKE“赢回来”；
> - 不重新调 RLS 或 Dual EKF 以针对单一场景；
> - 不删除 TS-SLTVKE 已发现的 abrupt-step failure；
> - 不把非真实的 abrupt health step 当成唯一动态评价；
> - 不为了论文排名选择性报告结果。

---

# 0. 本轮必须继承的事实

Paper Verification v1.1 已得到：

## 0.1 Observation 是主要创新

2×3 factorial 结果判定：

```text
OBSERVATION_FRAMEWORK_IS_PRIMARY_INNOVATION
```

使用 O1 proposed observation 后：

### RLS

\[
C\ MAPE=0.3727\%
\]

\[
ESR\ MAPE=0.2222\%
\]

\[
t_{conv}=13.19\ cycles
\]

### Dual EKF

\[
C\ MAPE=0.3043\%
\]

\[
ESR\ MAPE=1.1923\%
\]

\[
t_{conv}=40.57\ cycles
\]

### TS-SLTVKE

\[
C\ MAPE=0.3011\%
\]

\[
ESR\ MAPE=0.6428\%
\]

\[
t_{conv}=33.04\ cycles
\]

因此 TS-SLTVKE 并非 universal accuracy winner。

---

## 0.2 TS-SLTVKE abrupt-step stress failure

在：

\[
C:C_0\rightarrow0.8C_0
\]

和：

\[
r_C:r_0\rightarrow2r_0
\]

的瞬时阶跃压力测试中，O1-TS-SLTVKE 在 257 个 post-step cycles 内未达到收敛判据。

记录的 tail error：

\[
e_C\approx19.29\%
\]

\[
e_R\approx49.94\%
\]

该负面结果必须保留。

---

## 0.3 理论已经可以冻结

Paper Verification v1.1 已建立：

### Physical PE lower bounds

\[
\underline\mu_C>0
\]

\[
\underline\mu_R>0
\]

### Covariance recursion

\[
P_{n+1}
\le
\frac{P_n+Q_N}
{1+\mu(P_n+Q_N)}
\]

### Positive fixed point

\[
P^*
=
\frac{
-Q_N+\sqrt{Q_N^2+4Q_N/\mu}
}{2}
\]

以及 projection-OFF 合法 PE 区域无 divergence 的数值证据。

**本轮不再修改 Proposition 1 / Proposition 2。**

---

# 1. 本轮科学问题

必须明确回答：

## Q1

在真实健康监测场景下：

\[
\boxed{
\text{O1-RLS 与 O1-TS-SLTVKE 谁更适合作为主 estimator？}
}
\]

---

## Q2

TS-SLTVKE 的 abrupt-step failure 是：

### A
真实健康跟踪能力不足；

还是：

### B
由于其被设计成 slow-aging estimator，因此只在非物理的瞬时大阶跃 stress test 中表现差？

---

## Q3

在更符合电容退化的：

\[
\boxed{\text{slow C↓ / ESR↑ trajectories}}
\]

下，两者实际跟踪差异是什么？

---

## Q4

如果 O1-RLS 综合更好，能否将第一篇论文简化为：

\[
\boxed{
\text{Topology-Synchronous Decoupled RLS}
}
\]

而 TS-SLTVKE 退居 uncertainty-aware extension？

---

## Q5

目前 Paper Verification 中的算法比较结果能否直接整理成论文的：

> “Performance comparison with alternative estimators”

章节？

---

# 2. 本轮算法冻结

建立：

```text
paper_algorithm_selection_v1/
```

目录：

```text
paper_algorithm_selection_v1/
├─ README.md
├─ protocol/
├─ algorithms/
├─ datasets/
├─ scripts/
├─ results/
│  ├─ raw/
│  ├─ tables/
│  └─ figures/
├─ FINAL_ESTIMATOR_DECISION.md
├─ PAPER_METHOD_COMPARISON.md
├─ PAPER_DYNAMIC_RESULTS.md
├─ PAPER_READY_ALGORITHM_SELECTION.md
└─ result_metrics_algorithm_selection_v1.csv
```

---

# 3. Proposed observation O1 完全冻结

所有 estimator 必须接收**同一 O1 observation stream**。

---

## 3.1 C observation

\[
z_C
=
\Delta v_T-\hat r_C\Delta i_C
\]

对应：

\[
h_C=\frac{q}{C_b}
\]

---

## 3.2 ESR observation

\[
z_R
=
\hat v_T^- - \hat v_T^+
\]

对应：

\[
h_R=k_RI_\Sigma
\]

---

## 3.3 必须一致

所有主算法使用相同：

- timestamped linear edge reconstruction；
- safe-window charge；
- disjoint sample policy；
- kR calibration；
- F28379D acquisition model；
- noise realization；
- timing realization；
- CCM gate；
- invalid-observation flags。

不能给某 estimator 更好的 observation。

---

# 4. 主算法

---

## M1 — O1-RLS

暂时命名：

```text
TS-D-RLS
```

即：

**Topology-Synchronous Decoupled Recursive Least Squares**

如果最终论文决定使用该名称，再正式冻结。

参数：

\[
\theta=
\begin{bmatrix}
\bar\alpha\\
r_C
\end{bmatrix}
\]

C、R 两个 direction-specific observations 可采用：

### Sequential scalar RLS

或等价 block-diagonal RLS。

保持 Paper Verification v1.1 锁定：

\[
\lambda=0.9975
\]

除非之前锁定文件中数值不同，以锁定文件为准。

---

## M2 — O1-TS-SLTVKE

完全使用冻结实现。

不得：

- adaptive Q；
- covariance reset；
- parameter-change detector；
- step-mode；
- fast/slow mode switching。

本轮就是评价当前算法，而不是修复它。

---

## M3 — O1-Dual EKF

作为第三参考。

保持 Paper Verification v1 已锁定版本。

目的：

> 给论文比较图一个中间复杂度的 nonlinear estimator anchor。

不参与主要“RLS vs TS-SLTVKE”决策权重。

---

## M0 — O1 Closed-form

仅用于部分：

- nominal；
- noise；
- timing；

比较。

不要求它完成所有动态测试。

---

# 5. 两种公平比较模式

这是本轮必须新增的部分。

---

## Mode A — Native estimator operation

每个算法按照自身自然递推方式运行。

评价：

- fastest achievable tracking；
- natural estimator behavior；
- actual update count；
- computation。

该模式用于回答：

> “算法本身实际表现如何？”

---

## Mode B — Equal observation budget / equal reporting cadence

所有算法：

- 接收完全相同 accepted O1 observation count；
- 使用同一 observation timestamps；
- 每：
  \[
  1024\ PWM\ cycles
  \]
  输出一次 health report。

即：

\[
T_H=
\frac{1024}{50k}
=
20.48ms
\]

算法内部允许递推，但最终 paper-facing health output 在同一时间点比较。

该模式用于避免：

> RLS 因更新更频繁而天然占优。

报告必须同时给 Native 与 Equal-Report 两种结果。

---

# 6. 静态 blind performance

复用 Paper Verification v1 的：

\[
48
\]

physical blind cases。

覆盖：

\[
V_{in}
\]

\[
D
\]

\[
load
\]

\[
C/C_0=[0.8,0.9,1.0]
\]

\[
ESR/ESR_0=[1,1.5,2]
\]

以及：

- 4 noise profiles；
- residual skew：
  \[
  [0,20,50,100]ns
  \]

---

# 7. 静态指标

每个 M1/M2/M3：

\[
MAPE_C
\]

\[
MAPE_R
\]

报告：

- mean；
- median；
- p95；
- max；
- bias；
- variance；
- divergence；
- projection activation；
- invalid-update rate；
- convergence observations；
- convergence physical time。

---

# 8. Abrupt step 仍然必须保留

它不是主要健康工况，而是：

\[
\boxed{\text{stress test}}
\]

---

## S1 — C abrupt step

\[
C:
1.0C_0
\rightarrow
0.8C_0
\]

ESR 不变。

---

## S2 — ESR abrupt step

\[
r:
1.0r_0
\rightarrow
2.0r_0
\]

C 不变。

---

## S3 — joint abrupt step

\[
C:
1.0\rightarrow0.8
\]

\[
ESR:
1.0\rightarrow2.0
\]

同步变化。

---

# 9. Abrupt-step 指标

不能只报告 settle/not-settle。

包括：

- 10% detection delay；
- 50% tracking delay；
- 90% tracking delay；
- settling time；
- tail error @ 20 ms；
- tail error @ 100 ms；
- tail error @ 500 ms；
- max overshoot；
- false cross-coupling。

如果算法永不收敛：

保留 NaN / FAIL。

---

# 10. 主要动态评价：慢速退化 ramp

这是本轮最重要的新实验。

真实电容健康变化远慢于一个 PWM 周期。

必须构造：

---

## R1 — Capacitance degradation

\[
C:
1.0C_0
\rightarrow
0.8C_0
\]

ESR 保持不变。

---

## R2 — ESR degradation

\[
r:
1.0r_0
\rightarrow
2.0r_0
\]

C 保持不变。

---

## R3 — coupled degradation

同时：

\[
C:
1.0\rightarrow0.8
\]

\[
ESR:
1.0\rightarrow2.0
\]

---

# 11. Ramp duration

至少：

\[
T_{ramp}=
[0.1,\ 1,\ 10,\ 100]s
\]

对应 50 kHz：

\[
5\times10^3
\]

到：

\[
5\times10^6
\]

PWM cycles。

**不要求全部使用 full Simscape switching simulation。**

---

# 12. 长时间 ramp 的仿真策略

为了避免无意义地跑 5 百万 switching cycles：

## Layer 1 — estimator/observation-layer long ramp

使用：

- 冻结 Model-B anchor；
- verified Ćuk equations；
- F28379D sampling/noise budget；
- current operating-point interpolation；
- O1 observation generator。

运行全部：

\[
0.1,\ 1,\ 10,\ 100s
\]

ramp。

---

## Layer 2 — switching-level cross-check

至少对：

\[
T_{ramp}=0.1s
\]

或可接受的最短两档，使用：

- Model A switching equations；
- 如运行时间允许，Model B selected segment。

验证 observation-layer trajectory 没有产生明显不真实偏差。

必须明确区分：

```text
FULL_SWITCHING
TRACE_DERIVED_OBSERVATION
```

论文中不得把后者写成 full Simscape transient。

---

# 13. Ramp shape

至少测试：

### Linear

\[
C(t)=C_0-\Delta C\,t/T
\]

\[
r(t)=r_0+\Delta r\,t/T
\]

### Smooth sigmoid

使用：

\[
s(t)=3\xi^2-2\xi^3
\]

或 logistic。

目的：

> 判断 estimator 对 degradation rate 而非数学导数不连续的响应。

最终论文主图优先 linear。

---

# 14. Ramp tracking 指标

每个参数：

## Normalized tracking RMSE

\[
NRMSE_\theta
=
\sqrt{
\frac{
\int(\hat\theta-\theta)^2dt
}{
\int(\theta-\theta_0)^2dt+\epsilon
}
}
\]

---

## Integrated absolute tracking error

\[
IAE_\theta
=
\int
|\hat\theta-\theta|dt
\]

归一化：

\[
nIAE
=
\frac{IAE}
{T_{ramp}\Delta\theta}
\]

---

## Effective lag

用：

- cross-correlation lag；
- 50% degradation crossing delay；

两种方法。

---

## End-point error

\[
e_{end}
\]

---

## Maximum tracking error

\[
e_{max}
\]

---

## False cross-coupling

R1：

\[
\max|\Delta\hat r/r_0|
\]

R2：

\[
\max|\Delta\hat C/C_0|
\]

---

# 15. Degradation threshold detection

为了让结果更贴近 condition monitoring，定义若干 health thresholds。

例如 C：

\[
C/C_0=
0.95,\ 0.90,\ 0.85
\]

ESR：

\[
r/r_0=
1.25,\ 1.50,\ 1.75
\]

比较算法：

- true threshold crossing time；
- detected crossing time；
- detection delay；
- early/late alarm。

这组结果非常适合论文 Discussion。

---

# 16. Operating transient robustness

健康参数保持完全不变。

---

## T1 — load step

\[
25\%\rightarrow75\%
\]

---

## T2 — load down-step

\[
100\%\rightarrow50\%
\]

---

## T3 — Vin step

\[
0.8pu\rightarrow1.2pu
\]

---

## T4 — duty change

在保持 CCM 的两个 duty 之间切换。

---

# 17. Transient false-health metrics

测：

\[
\Delta\hat C_{peak}
\]

\[
\Delta\hat r_{peak}
\]

以及：

- recovery time；
- false health-alarm count；
- NIS rejection rate。

这一组是 TS-SLTVKE 可能相对 RLS 真正有优势的地方。

---

# 18. Noise / timing robustness

不重新做全矩阵，只选论文代表点。

---

## Noise

至少：

```text
low
nominal
high
F28379D-realistic
```

---

## Timing

\[
0,\ 20,\ 50,\ 100ns
\]

residual channel mismatch。

---

# 19. Complexity 必须用相同口径

每算法报告：

- multiplications / accepted update；
- additions；
- divisions；
- state/parameter scalars；
- covariance scalars；
- RAM；
- observation storage；
- estimated F28379D time；
- health-output latency。

不得使用一套算法按“per scalar update”，另一套按“per health frame”。

至少给：

### Per accepted observation

和：

### Per 20.48 ms health frame

两个复杂度口径。

---

# 20. RLS confidence 问题必须公平处理

RLS 本身没有完整 Kalman state covariance。

不能因为这一点直接判输。

实现一个**不改变点估计**的辅助 uncertainty readout：

\[
\hat\sigma_{RLS}
\]

基于：

- weighted residual variance；
- information matrix inverse；
- sandwich/robust covariance（若适合）。

只能作为：

```text
RLS uncertainty diagnostic
```

不得偷偷改变 RLS parameter update。

比较：

- empirical coverage；
- calibration；
- cost。

如果 RLS confidence 明显不足，TS-SLTVKE 可保留为 uncertainty-aware extension。

---

# 21. Primary comparison table

最终至少产生：

| Metric | O1-RLS | O1-Dual EKF | O1-TS-SLTVKE |
|---|---:|---:|---:|
| C mean MAPE | | | |
| ESR mean MAPE | | | |
| C p95 | | | |
| ESR p95 | | | |
| static convergence | | | |
| 0.1 s C ramp nRMSE | | | |
| 1 s C ramp nRMSE | | | |
| 10 s C ramp nRMSE | | | |
| 0.1 s ESR ramp nRMSE | | | |
| 1 s ESR ramp nRMSE | | | |
| 10 s ESR ramp nRMSE | | | |
| abrupt C step settle | | | |
| abrupt ESR step settle | | | |
| load-step false C | | | |
| load-step false ESR | | | |
| 50 ns timing p95 | | | |
| divergence | | | |
| multiplications/frame | | | |
| estimated DSP time/frame | | | |
| uncertainty support | | | |

---

# 22. Paired statistics

所有主要静态和 ramp 指标采用同一 case 配对。

至少：

\[
N_{boot}=10000
\]

paired bootstrap。

报告：

- mean paired difference；
- median；
- 95% CI；
- fraction M1 better；
- fraction M2 better。

不要把 p-value 当作唯一证据。

---

# 23. Pareto 分析

构造至少两个 Pareto 图：

## Accuracy vs complexity

x：

\[
\text{compute cost}
\]

y：

\[
\text{combined normalized C/ESR error}
\]

---

## Tracking vs robustness

x：

\[
\text{ramp tracking error}
\]

y：

\[
\text{operating-transient false health error}
\]

用来说明：

> 哪个 estimator 适合“最简参数辨识”，哪个适合“带置信度的健康监控”。

---

# 24. 主算法决策规则

不要用任意加权总分。

按科学支配关系判断。

---

## Decision A

```text
PRIMARY_TS_D_RLS
```

如果：

1. RLS 在 ESR、动态 ramp、收敛、复杂度上明显优；
2. C 精度满足 <3%，且相对 TS-SLTVKE 无工程上重要损失；
3. operating-transient false-health 可接受；
4. uncertainty diagnostic 至少能满足基本 paper reporting。

此时：

- 第一篇主算法使用 TS-D-RLS；
- TS-SLTVKE 作为 uncertainty-aware extension / comparison。

---

## Decision B

```text
PRIMARY_TS_SLTVKE
```

只有如果：

1. 慢速健康 ramp 下 TS-SLTVKE 不再存在明显 tracking deficiency；
2. 它在 operating-transient rejection / CI / robustness 上有清楚优势；
3. 这些优势足以抵消其 ESR/complexity/step tracking 劣势。

---

## Decision C

```text
DUAL_REALIZATION
```

如果结果非常清楚地表明：

- RLS = fastest/lowest-complexity parameter identification；
- TS-SLTVKE = confidence-aware health reporting；

且两者适合不同层级。

论文可以定义：

\[
\boxed{
\text{Core observation framework}
+
\begin{cases}
\text{RLS realization}\\
\text{Kalman realization}
\end{cases}
}
\]

但正文必须选择一个主要 realization，另一个作为 extension。

---

## Decision D

```text
ESTIMATOR_SELECTION_UNRESOLVED
```

只有真正出现互相矛盾且无法解释的结果才使用。

---

# 25. 方法名称检查

如果 RLS 成为主算法，检查以下名称：

### Preferred candidate

**Topology-Synchronous Decoupled RLS**

简称：

\[
\boxed{\text{TS-D-RLS}}
\]

要求名称只描述实际结构，不夸大 novelty。

---

# 26. 论文主线随最终算法调整

如果：

```text
PRIMARY_TS_D_RLS
```

则论文标题/主线应突出：

\[
\boxed{
\text{topology-synchronous decoupled C–ESR identification}
}
\]

而不是 estimator 名称。

---

如果：

```text
PRIMARY_TS_SLTVKE
```

才允许在标题中突出：

\[
\text{structured LTV Kalman estimator}
\]

---

# 27. 本轮生成的论文素材

这次所有比较结果必须保存成将来论文能直接使用的材料。

---

## 27.1 强制表格

```text
table_algorithm_static_comparison.csv
table_algorithm_abrupt_step.csv
table_algorithm_ramp_tracking.csv
table_algorithm_threshold_detection.csv
table_algorithm_operating_transients.csv
table_algorithm_noise_timing.csv
table_algorithm_complexity.csv
table_algorithm_uncertainty.csv
table_algorithm_paired_bootstrap.csv
table_algorithm_final_selection.csv
```

---

## 27.2 强制图

```text
fig_alg_01_static_C_ESR.png
fig_alg_02_static_p95.png
fig_alg_03_C_abrupt_step.png
fig_alg_04_ESR_abrupt_step.png
fig_alg_05_C_ramp_tracking.png
fig_alg_06_ESR_ramp_tracking.png
fig_alg_07_joint_ramp_tracking.png
fig_alg_08_threshold_detection.png
fig_alg_09_load_transient_false_health.png
fig_alg_10_noise_timing_comparison.png
fig_alg_11_complexity_accuracy_pareto.png
fig_alg_12_tracking_robustness_pareto.png
```

---

# 28. 图必须区分 stress test 与 health-realistic test

Figure caption 中明确：

### Abrupt step

```text
stress test, not intended as a physical aging trajectory
```

### Slow ramp

```text
health-tracking trajectory
```

避免 reviewer 把瞬时参数跳变当成真实老化假设。

---

# 29. PAPER_METHOD_COMPARISON.md

必须按论文结果章节格式写。

结构：

## 1. Static estimation

## 2. Noise and timing robustness

## 3. Abrupt parameter stress tests

## 4. Slow degradation tracking

## 5. Operating-point transient immunity

## 6. Computational complexity

## 7. Uncertainty reporting

## 8. Final estimator choice

不能夹杂 Codex 调试日志。

---

# 30. PAPER_DYNAMIC_RESULTS.md

专门保存动态部分。

必须给：

- C step；
- ESR step；
- C ramp；
- ESR ramp；
- coupled ramp；
- load step；
- Vin step。

每张图对应：

- exact dataset；
- metric table；
- caption；
- final result statement。

---

# 31. FINAL_ESTIMATOR_DECISION.md

必须回答：

1. O1-RLS 是否仍保持 Paper Verification v1.1 的静态优势？
2. TS-SLTVKE abrupt-step failure 是否复现？
3. 在 0.1 s ramp 下谁更好？
4. 1 s？
5. 10 s？
6. 100 s？
7. TS-SLTVKE 在真实慢健康变化下是否仍明显滞后？
8. RLS 的 false-health transient 是否更严重？
9. TS-SLTVKE 的 confidence 是否具有实质优势？
10. 哪个算法 F28379D 实现成本更低？
11. 哪个最适合作为第一篇论文主 realization？
12. 另一个算法在论文中应扮演什么角色？
13. 是否可以开始正式 manuscript？

最终输出：

```text
PRIMARY_TS_D_RLS
PRIMARY_TS_SLTVKE
DUAL_REALIZATION
ESTIMATOR_SELECTION_UNRESOLVED
```

---

# 32. PAPER_READY_ALGORITHM_SELECTION.md

只保留未来论文会使用的最终信息：

- final estimator；
- comparison numbers；
- final method names；
- dynamic metrics；
- static metrics；
- complexity；
- limitations；
- selected figures；
- selected tables；
- caption-ready statements。

---

# 33. 长时间 ramp 的性能要求

不要求 estimator 对 100 s ramp 误差极低。

重点观察：

\[
\text{tracking lag}
\]

相对于：

\[
T_{ramp}
\]

的比例。

定义：

\[
\boxed{
L_{norm}
=
\frac{t_{lag}}{T_{ramp}}
}
\]

如果：

\[
L_{norm}\ll1
\]

说明对该退化速度可视为 quasi-static tracking。

---

# 34. 额外健康跟踪带宽

从不同 ramp duration 估计一个：

\[
\boxed{
\text{maximum reliable degradation rate}
}
\]

例如 C：

\[
\left|
\frac{1}{C_0}
\frac{dC}{dt}
\right|_{\max}
\]

ESR：

\[
\left|
\frac{1}{r_0}
\frac{dr}{dt}
\right|_{\max}
\]

定义在：

\[
MAPE<3\%/5\%
\]

或：

\[
L_{norm}<5\%
\]

的条件下。

这会成为论文很有价值的动态规格。

---

# 35. 不允许把人为 fast ramp 当成真实 aging rate

如果：

\[
0.1s
\]

ramp 失败而：

\[
1s
\]

或：

\[
10s
\]

通过，正确结论是：

> estimator has a finite health-tracking bandwidth.

而不是：

> estimator fails capacitor aging monitoring.

---

# 36. 数据追溯

每个结果 row 必须包含：

```text
method
mode
case_id
source_model
trajectory_type
trajectory_duration_s
health_report_period_s
noise_profile
skew_ns
C_true
ESR_true
C_est
ESR_est
C_error
ESR_error
accepted_C_updates
accepted_R_updates
compute_count
failure_flag
notes
```

---

# 37. 一键入口

创建：

```text
scripts/run_paper_algorithm_selection_v1.m
```

必须完成：

1. load frozen O1 observation generator；
2. load locked algorithms；
3. run static blind；
4. run abrupt stress；
5. run slow ramps；
6. run operating transients；
7. run noise/timing subset；
8. compute complexity；
9. compute uncertainty diagnostics；
10. paired bootstrap；
11. create tables；
12. create figures；
13. create final decision；
14. audit。

---

# 38. 审计脚本

创建：

```text
scripts/validate_paper_algorithm_selection_v1.m
```

检查：

- same O1 observations；
- same cases；
- same seeds；
- no algorithm retuning；
- TS-SLTVKE checksum unchanged；
- RLS lambda unchanged；
- step failures retained；
- trace-derived vs full-switching correctly labeled；
- no deleted ramp failures；
- result/report numbers match CSV。

---

# 39. 最终停止条件

只有全部满足才结束：

- [ ] M1/M2/M3 frozen
- [ ] Native mode 完成
- [ ] Equal-report mode 完成
- [ ] static blind 完成
- [ ] C abrupt step 完成
- [ ] ESR abrupt step 完成
- [ ] joint abrupt step 完成
- [ ] C ramps 0.1/1/10/100 s 完成
- [ ] ESR ramps 0.1/1/10/100 s 完成
- [ ] joint ramps 完成
- [ ] threshold detection 完成
- [ ] load/Vin/duty transients 完成
- [ ] noise/timing subset 完成
- [ ] complexity 完成
- [ ] RLS uncertainty diagnostic 完成
- [ ] paired bootstrap 完成
- [ ] Pareto analysis 完成
- [ ] FINAL_ESTIMATOR_DECISION.md 完成
- [ ] PAPER_METHOD_COMPARISON.md 完成
- [ ] PAPER_DYNAMIC_RESULTS.md 完成
- [ ] PAPER_READY_ALGORITHM_SELECTION.md 完成
- [ ] audit PASS

---

# 40. Codex 最终执行指令

**读取 Paper Verification v1/v1.1 以及 verification_v1–v2.3 的冻结结果，建立 `paper_algorithm_selection_v1`。本轮不再修改 topology-decoupled O1 observation，也不允许增加 adaptive-Q/change-detector 去修复 TS-SLTVKE。主要比较 O1-RLS、O1-TS-SLTVKE，并保留 O1-Dual EKF 作为第三参考。所有算法使用完全相同的 timestamped edge、safe-window charge、disjoint samples、kR calibration、F28379D noise/timing realization 和 blind cases。必须同时运行 Native estimator mode 和 Equal observation/reporting mode。保留 C/ESR 瞬时大阶跃作为 stress test，但把 0.1/1/10/100 s 的 C↓、ESR↑ 和 coupled degradation ramps 作为主要 health-tracking 动态验证，并计算 nRMSE、nIAE、tracking lag、threshold detection delay 和 false cross-coupling。长时间 ramp 可以使用冻结 Model-B anchor + verified observation generator，不要求全部跑数百万 full Simscape switching cycles，但必须明确标记 source_model，并用 selected switching-level segments 做交叉核对。最终结果必须直接形成论文方法性能比较素材，包括静态、噪声、时序、动态、复杂度、uncertainty 和 Pareto 图表。不要使用任意加权总分，按科学支配关系在 PRIMARY_TS_D_RLS、PRIMARY_TS_SLTVKE、DUAL_REALIZATION、ESTIMATOR_SELECTION_UNRESOLVED 中做最终选择。若 RLS 综合更好，应接受简化主算法，不得为了保留 Kalman 名称而继续增加复杂模块。**

---

## Version

- **Paper Algorithm Selection v1**
- Date: **2026-08-22**
- Purpose: **final estimator selection and manuscript-ready performance comparison**
- Frozen innovation: **Cuk topology-synchronous edge/charge observation framework**
- Primary candidates: **TS-D-RLS vs TS-SLTVKE**
