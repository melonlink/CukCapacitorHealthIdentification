# Codex 执行任务 — Paper Verification v1.1
# Ćuk 能量传递电容 C–ESR 论文最终理论与证据链补强

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **阶段**：Paper Verification v1.1  
> **前置结果**：Paper Verification v1 + verification_v1/v2/v2.1/v2.2/v2.3  
> **冻结算法**：TS-SLTVKE  
> **本轮性质**：论文写作前最后一次理论/仿真补强  
> **禁止事项**：不再修改 TS-SLTVKE 核心结构；不再做 ADC/AFE 优化；不再重新进行大规模 SOTA 文献检索；不允许为了获得更好的排名重新调参。
>
> **本轮只解决两个问题：**
>
> 1. **Observation × Estimator factorial verification**  
>    将“Ćuk 拓扑特异观测设计”与“估计器形式”分离，证明论文创新主要来自哪里。
>
> 2. **Stronger theory closure**  
>    将现有抽象 PE 假设提升为由 Ćuk CCM 物理工作条件直接推出的 PE 下界，并在不依赖参数 projection 的前提下给出显式 covariance contraction / steady-state upper bound。
>
> 完成本轮后，如果没有新的结构性失败：
>
> \[
> \boxed{\text{FREEZE THEORY + SIMULATION FOR MANUSCRIPT}}
> \]

---

# 0. 当前 Paper Verification v1 已确认的事实

本轮以以下结果为既有事实，不重复做相同测试。

## 0.1 SOTA 对比

统一 blind set：

\[
48\ \text{physical cases}
\times
4\ \text{noise profiles}
\times
4\ \text{residual skew levels}
\times
6\ \text{algorithms}
=
4608
\]

保留全部失败/饱和行。

当前 TS-SLTVKE：

\[
MAPE_C=0.301\%
\]

\[
MAPE_{ESR}=0.577\%
\]

p95：

\[
1.116\%,\qquad 2.134\%
\]

但：

- B3 Dual EKF 在平均 C 误差上更低；
- B1 RLS 在平均 ESR 误差上更低；
- TS-SLTVKE divergence=0，收敛快，并具有明确 topology-synchronous C/R observation directions、excitation gates、confidence 和 scalar-update 结构。

因此本轮**禁止把目标改成“让 TS-SLTVKE 静态 MAPE 排第一”**。

---

## 0.2 Ablation

A0→A6：

\[
C:\ 0.394\%\rightarrow0.170\%
\]

\[
ESR:\ 3.807\%\rightarrow3.101\%
\]

Joint 95% coverage：

\[
0.168\rightarrow0.989
\]

但：

- A1 timestamp reconstruction 是 ESR 静态误差最优附近；
- A2/A3 对 aggregate static accuracy 存在负 gain；
- A4 主要改善 confidence consistency；
- A5 对 C 最有利但会暴露 ESR bias；
- A6 是鲁棒/受保护的最终 estimator，而不是 static-accuracy optimum。

因此论文不得把 A0–A6 描述为“每增加一个模块都提高精度”。

---

## 0.3 当前理论

已有：

### Proposition 1
finite-window structural identifiability。

### Proposition 2
mean-square boundedness proof sketch。

### Corollary
low excitation/DCM 时 freeze。

当前需要加强的地方：

1. PE 被作为抽象 Assumption 3/4 直接假设；
2. boundedness proof 中 projection 容易被误解成有界性的主要来源；
3. 尚缺一个显式、可计算的 finite-window covariance bound。

---

# Part I — Observation × Estimator 因子实验

# 1. 核心科学问题

必须回答：

\[
\boxed{
\text{论文性能提升主要来自 topology-specific observation design，
还是来自 TS-SLTVKE estimator 本身？}
}
\]

Paper Verification v1 已证明：

- conventional RLS / Dual EKF 在某些静态精度指标上优于 TS-SLTVKE；
- 因此不能把论文写成“新滤波器数值精度 SOTA”。

本轮必须把：

\[
\text{Observation Design}
\]

和：

\[
\text{Estimator Kernel}
\]

作为两个独立实验因子。

---

# 2. Factor A — Observation family

定义两套观测信息。

---

## O0 — Conventional / mixed observation

目标：

> 表示“没有使用本文 edge/charge 物理解耦设计”时，从相同传感器能得到的常规联合参数信息。

使用同样传感器：

\[
v_T,\ i_1,\ i_2,\ u,\ timestamp
\]

但不允许使用：

- timestamp-extrapolated ESR-only pseudo measurement；
- safe-window C-only pseudo measurement；
- C/R direction-specific observation separation。

允许使用统一 integral relation：

\[
\Delta v_T
=
\frac{q}{C_b}\bar\alpha
+
\Delta i_C\,r_C
+
\nu
\]

对应 mixed measurement row：

\[
\boxed{
H_{O0,k}
=
\begin{bmatrix}
q_k/C_b & \Delta i_{C,k}
\end{bmatrix}
}
\]

区间使用统一、预先锁定的 generic within-cycle windows。

不得为了让 O0 故意变差而使用已知错误的 adjacent-edge assignment。

### 重要

O0 不是“错误方法”。

它是：

\[
\boxed{
\text{physically valid but non-decoupled mixed parameter observation}
}
\]

---

## O1 — Proposed topology-decoupled observation

使用论文最终设计：

### C direction

\[
z_C
=
\Delta v_T-\hat r_C\Delta i_C
\]

\[
H_C=
\begin{bmatrix}
q/C_b&0
\end{bmatrix}
\]

### ESR direction

\[
z_R
=
\hat v_T^- - \hat v_T^+
\]

\[
H_R=
\begin{bmatrix}
0&k_RI_\Sigma
\end{bmatrix}
\]

要求：

- timestamped linear edge reconstruction；
- safe-window charge；
- disjoint raw sample policy；
- 同一 locked calibration；
- 同一 F28379D acquisition/noise budget。

---

# 3. Factor B — Estimator kernel

为了真正形成 factorial comparison，估计器因子只比较其更新规则，不改变观测信息。

至少三个 estimator kernels。

---

## E1 — Projected / constrained RLS

参数：

\[
\theta=
\begin{bmatrix}
\bar\alpha\\
r_C
\end{bmatrix}
\]

### O0+E1

对 mixed row：

\[
z_k=H_{O0,k}\theta+\nu_k
\]

做 conventional RLS。

### O1+E1

按 C-only、R-only 行分别递推 RLS。

这一步非常重要：

> 如果 O1+RLS 明显改善 robustness，则直接证明 Observation Design 本身有价值，而不是只有 TS-SLTVKE 有价值。

---

## E2 — Dual EKF

保持 Paper Verification v1 已锁定 Dual EKF 结构。

### O0+E2

使用原 conventional/raw observation。

### O1+E2

参数滤波器接收相同 C/R pseudo measurements：

\[
z_C,\ z_R
\]

状态滤波器仍保持 Dual EKF 的 state update。

不得为了 O1 单独重新发明一个新 EKF。

---

## E3 — LTV/Joseph structured kernel

### O0+E3

建立不做 C/R 方向分离的 mixed LTV/Joseph estimator：

\[
H_{O0,k}
=
[q/C_b,\Delta i_C]
\]

参数 random walk：

\[
\theta_{k+1}=\theta_k+w_k
\]

普通 Kalman/Joseph update。

该方法命名：

```text
Mixed-LTVKE
```

不要称为 TS-SLTVKE。

### O1+E3

使用冻结的：

\[
\boxed{\text{TS-SLTVKE}}
\]

---

# 4. 最终 2×3 因子矩阵

必须实际运行：

| | E1 RLS | E2 Dual EKF | E3 LTV/Joseph |
|---|---|---|---|
| O0 Mixed | O0-E1 | O0-E2 | O0-E3 |
| O1 Proposed | O1-E1 | O1-E2 | O1-E3 = TS-SLTVKE |

共：

\[
\boxed{6\ \text{factorial cells}}
\]

---

# 5. 公平性约束

六组必须使用完全相同：

- blind case IDs；
- raw observation source；
- Model-B trace anchor；
- F28379D noise/timing realization；
- initial C/r factors；
- random seeds；
- valid/invalid CCM flags；
- parameter physical bounds；
- training/blind split。

---

# 6. Hyperparameter 规则

允许每个 estimator family：

- E1；
- E2；
- E3；

在同一个 training set 上各锁定一组参数。

但：

\[
\boxed{
\text{O0 和 O1 不允许分别重新调 estimator hyperparameters}
}
\]

例如 E1 的 forgetting factor：

\[
\lambda_{E1}
\]

对 O0/O1 保持一致。

这样才能把 Observation effect 与 Estimator effect 分开。

如果某参数物理上只适用于 O1 edge measurement covariance，则允许 measurement-derived \(R_R\)，但估计器 tuning 不改变。

所有规则写入：

```text
FACTORIAL_PROTOCOL.md
LOCKED_FACTORIAL_HYPERPARAMETERS.csv
```

---

# 7. 测试数据

优先复用 Paper Verification v1 的 blind set。

至少：

\[
48
\]

physical cases。

每个：

- 4 noise profiles；
- 4 residual skews。

即每 cell：

\[
48\times4\times4=768
\]

rows。

总：

\[
768\times6=4608
\]

factorial result rows。

---

# 8. Dynamic subset

额外测试：

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

六个 factorial cells 全部运行。

---

# 9. Factorial 指标

至少：

## Accuracy

\[
MAPE_C
\]

\[
MAPE_R
\]

p50 / p95 / max。

---

## Robustness

- divergence rate；
- projection saturation；
- invalid updates；
- timing failure。

---

## Dynamic

- convergence time；
- C-step tracking；
- ESR-step tracking；
- false cross-coupling。

---

## Statistical

- bias；
- variance；
- NIS；
- NEES / CI（如 estimator 支持）。

对 RLS 不能强制要求 Kalman CI，但至少报告 empirical variance。

---

# 10. 直接计算 Observation Effect

对每一个 estimator \(E_j\)：

\[
\boxed{
\Delta_{\text{Obs},j}
=
M(O0,E_j)-M(O1,E_j)
}
\]

其中 \(M\) 分别取：

- C MAPE；
- ESR MAPE；
- p95；
- timing failure；
- convergence。

正值：

\[
O1
\]

更好。

负值：

\[
O0
\]

更好。

不得隐藏负值。

---

# 11. 直接计算 Estimator Effect

在相同 observation 下比较：

\[
E1,\ E2,\ E3
\]

例如：

\[
\Delta_{E3-E1|O1}
=
M(O1,E1)-M(O1,E3)
\]

用来回答：

> 在 proposed observation 已经固定后，TS-SLTVKE 比 RLS / Dual EKF 还贡献了什么？

---

# 12. Interaction Effect

计算一个简单可解释的 interaction：

\[
\boxed{
I_{E3}
=
[M(O0,E3)-M(O1,E3)]
-
[M(O0,E1)-M(O1,E1)]
}
\]

也可对 E2 类似计算。

目标：

> 判断 topology-decoupled observation 是否与 structured LTV estimator 存在协同，而不仅是两个独立增益相加。

---

# 13. Paired statistical confidence

所有方法在同一 blind cases 上配对。

对主要指标计算：

\[
\Delta M_i
=
M_{O0,i}-M_{O1,i}
\]

使用 paired bootstrap：

\[
N_{boot}=10000
\]

报告：

- mean/median paired effect；
- 95% bootstrap CI；
- fraction improved。

不要求为了论文“统计显著”而不断增加样本。

如 CI 穿过 0：

明确报告。

---

# 14. Factorial 最终判定

必须选择以下之一：

## F-A

```text
OBSERVATION_FRAMEWORK_IS_PRIMARY_INNOVATION
```

如果 O1 在 RLS、Dual EKF、LTV 三个 estimator 中都稳定改善鲁棒性/时序/解耦。

---

## F-B

```text
OBSERVATION_AND_ESTIMATOR_HAVE_COMPLEMENTARY_VALUE
```

如果 O1 单独有价值，同时 O1+E3 在 convergence/confidence/robustness 上进一步获益。

---

## F-C

```text
ESTIMATOR_IS_PRIMARY_INNOVATION
```

如果 O1 对其他 estimator 基本无益，而只有 TS-SLTVKE 工作。

---

## F-D

```text
STRUCTURAL_NOVELTY_WEAKENED
```

如果 O1 几乎不改善任何 estimator，且 E3 也无明显综合优势。

F-D 必须触发论文创新重新评估。

---

# 15. Factorial 输出

必须生成：

```text
OBSERVATION_FACTORIAL_RESULTS.md
table_observation_estimator_factorial.csv
table_observation_effect_bootstrap.csv
table_factorial_dynamic.csv
```

图：

```text
fig_pv11_01_factorial_C.png
fig_pv11_02_factorial_ESR.png
fig_pv11_03_observation_effect.png
fig_pv11_04_factorial_timing.png
fig_pv11_05_factorial_dynamic.png
fig_pv11_06_accuracy_robustness_pareto.png
```

---

# Part II — Proposition 1 加强：从 Ćuk 物理条件推出 PE 下界

# 16. 当前问题

Paper Verification v1 采用：

\[
\sum
\frac{h_C^2}{R_C}
\ge\mu_C>0
\]

\[
\sum
\frac{h_R^2}{R_R}
\ge\mu_R>0
\]

作为 Assumption。

虽然数学正确，但论文理论应进一步回答：

> 为什么 Ćuk 在有效 CCM 工作区能够提供这种 PE？

本轮必须从拓扑物理量推出可计算下界。

---

# 17. C 方向物理下界

safe window 内：

\[
h_C=\frac{q}{C_b}
\]

\[
q=\int_{t_a}^{t_b}i_C(t)\,dt
\]

在单一 topology interval 内，若：

\[
i_C(t)
\]

不变号，并且：

\[
|i_C(t)|
\ge
I_{C,\min}
>
0
\]

窗口有效长度：

\[
T_w=t_b-t_a
\]

则：

\[
\boxed{
|q|
\ge
I_{C,\min}T_w
}
\tag{P1}
\]

因此：

\[
\boxed{
|h_C|
\ge
\frac{I_{C,\min}T_w}{C_b}
}
\tag{P2}
\]

若：

\[
R_C\le R_{C,\max}
\]

单次有效 C update 的最小信息：

\[
\boxed{
\mathcal I_{C,\min}
\ge
\frac{
(I_{C,\min}T_w/C_b)^2
}{
R_{C,\max}
}
}
\tag{P3}
\]

一个 finite window 内至少有：

\[
m_C
\]

个有效 C observations：

\[
\boxed{
\mu_C
\ge
m_C
\frac{
(I_{C,\min}T_{w,\min}/C_b)^2
}{
R_{C,\max}
}
}
\tag{P4}
\]

---

# 18. ESR 方向物理下界

\[
h_R=k_RI_\Sigma
\]

其中：

\[
I_\Sigma=i_1+i_2
\]

如果：

\[
k_R\ge k_{R,\min}>0
\]

\[
I_\Sigma\ge I_{\Sigma,\min}>0
\]

以及：

\[
R_R\le R_{R,\max}
\]

则单次 ESR observation：

\[
\boxed{
\mathcal I_{R,\min}
\ge
\frac{
k_{R,\min}^2
I_{\Sigma,\min}^2
}{
R_{R,\max}
}
}
\tag{P5}
\]

若 finite window 内有：

\[
m_R
\]

个有效 edge observations：

\[
\boxed{
\mu_R
\ge
m_R
\frac{
k_{R,\min}^2
I_{\Sigma,\min}^2
}{
R_{R,\max}
}
}
\tag{P6}
\]

---

# 19. 必须把下界和 Ćuk operating envelope 联系起来

不得只把：

\[
I_{C,\min},I_{\Sigma,\min},T_{w,\min}
\]

再当作抽象假设。

从冻结的：

- CCM blind set；
- Model B traces；
- F28379D E1 sampling schedule；
- D range；
- load range；

实际求出：

\[
I_{C,\min}^{emp}
\]

\[
I_{\Sigma,\min}^{emp}
\]

\[
T_{w,\min}^{schedule}
\]

\[
k_{R,\min}^{cal}
\]

\[
R_{C,\max}^{locked}
\]

\[
R_{R,\max}^{locked}
\]

然后计算理论：

\[
\underline\mu_C
\]

\[
\underline\mu_R
\]

与经验窗口信息：

\[
\mu_C^{emp},\quad\mu_R^{emp}
\]

比较。

必须验证：

\[
\boxed{
\mu^{emp}\ge\underline\mu
}
\]

如不成立，推导或取值有问题。

---

# 20. Operating-condition PE theorem

将 Proposition 1 改写成更强版本。

建议形式：

## Proposition 1 — Ćuk operating-condition-induced finite-window identifiability

若：

1. converter remains in valid CCM；
2. safe charge window is wholly contained in one switching topology；
3. \(|i_C|\ge I_{C,\min}>0\) over the accepted C window；
4. \(I_\Sigma\ge I_{\Sigma,\min}>0\) at accepted ESR edges；
5. measurement covariances are bounded above；
6. finite window contains at least \(m_C,m_R\ge1\) accepted observations；

则：

\[
G_\theta
=
\sum H_k^TR_k^{-1}H_k
\]

满足：

\[
\boxed{
G_\theta
\succeq
\begin{bmatrix}
\underline\mu_C&0\\
0&\underline\mu_R
\end{bmatrix}
\succ0
}
\]

因此：

\[
\boxed{
(C,r_C)
}
\]

在该 finite window 内局部结构可辨识。

---

# 21. 说明 topology 的作用

论文必须明确：

Cuk 的：

\[
+i_{L1}\leftrightarrow-i_{L2}
\]

带来：

### charge window

\[
|i_C|>0
\]

且单一拓扑内不变号；

### switching edge

\[
I_\Sigma=i_1+i_2>0
\]

因此 C 与 ESR 两个 observation directions 在正常 CCM 能量传输过程中周期性出现。

这就是：

\[
\boxed{
\text{natural topology-induced PE}
}
\]

的物理来源。

不得写成“PWM 本身自动保证所有工况 PE”。

低负载、DCM、无效 window 仍然可能不满足，因此保留 gate/freeze。

---

# Part III — Proposition 2 加强：不依赖 projection 的 covariance contraction

# 22. 理论目标

当前 proof sketch 使用：

- bounded process noise；
- bounded measurement noise；
- compact projection；

说明 mean-square bounded。

本轮必须先**移除 projection 作为稳定性来源**。

projection 只能作为：

\[
\boxed{
\text{physical safety constraint}
}
\]

而不是理论 covariance boundedness 的核心原因。

---

# 23. Scalar parameter information recursion

对任一参数方向：

\[
\theta
\]

random walk：

\[
\theta_{k+1}=\theta_k+w_k
\]

finite-window aggregate process covariance：

\[
Q_N
\]

假设当前 posterior covariance：

\[
P
\]

经过一个窗口传播：

\[
\boxed{
P^-\le P+Q_N
}
\tag{P7}
\]

窗口累计 information：

\[
\mu>0
\]

则窗口末 posterior：

\[
\boxed{
P^+
\le
\left[
\frac{1}{P+Q_N}
+
\mu
\right]^{-1}
}
\tag{P8}
\]

即：

\[
\boxed{
P^+
\le
f(P)
=
\frac{
P+Q_N
}{
1+\mu(P+Q_N)
}
}
\tag{P9}
\]

---

# 24. 显式 fixed point

若：

\[
Q_N>0,\quad\mu>0
\]

令：

\[
P=f(P)
\]

得到：

\[
\mu P(P+Q_N)=Q_N
\]

即：

\[
P^2+Q_NP-\frac{Q_N}{\mu}=0
\]

正根：

\[
\boxed{
P^*
=
\frac{
-Q_N+
\sqrt{
Q_N^2+\frac{4Q_N}{\mu}
}
}{2}
}
\tag{P10}
\]

必须证明/说明：

\[
f(P)
\]

对：

\[
P\ge0
\]

单调、有界，并将 covariance 推向有限 invariant interval。

给出：

\[
\boxed{
P_k
\le
\max(P_0,P^*)+\epsilon
}
\]

或更严格的迭代上界。

---

# 25. Q=0 特例

若：

\[
Q_N=0
\]

则：

\[
P^+
\le
\frac{P}{1+\mu P}
\]

信息形式：

\[
\boxed{
(P_n)^{-1}
\ge
(P_0)^{-1}
+n\mu
}
\tag{P11}
\]

因此：

\[
\boxed{
P_n
\le
\frac{1}
{
P_0^{-1}+n\mu
}
\rightarrow0
}
\tag{P12}
\]

在：

- correct model；
- unbiased measurements；
- recurring PE；

的理想参数常值情形下，covariance 收缩。

这并不等于宣称真实参数误差全局渐近收敛；必须区分。

---

# 26. 两个健康方向分别给 bound

分别使用：

\[
\mu_C,\ Q_{C,N}
\]

得到：

\[
\boxed{
P_C^*
}
\]

使用：

\[
\mu_R,\ Q_{R,N}
\]

得到：

\[
\boxed{
P_R^*
}
\]

将 v2.1/v2.3 locked process spectral density 转成实际 finite-window：

\[
Q_N
\]

不得混用“per sample Q”和“continuous-time spectral density”。

---

# 27. Mean-square error 与 covariance 的关系

在：

- linearized/conditional structured observation；
- correct zero-mean measurement model；
- unbiased process noise；

条件下：

\[
E[\tilde\theta^2]
\]

由 Kalman covariance 描述/上界。

对于 bounded conditional mismatch：

\[
d_k
\]

引入：

\[
E[d_k^2]\le\bar d
\]

则不要强求 zero-error convergence。

给出：

\[
\boxed{
\limsup
E[\tilde\theta_k^2]
\le
P^*
+
B_d
}
\tag{P13}
\]

其中：

\[
B_d
\]

可以是显式保守上界或 proof sketch 中的有限 mismatch-dependent term。

若无法严格得到漂亮闭式：

- 给出充分条件；
- 给出有限界存在性；
- 不得伪造精确常数。

---

# 28. Projection 的最终理论位置

理论章节明确写：

> Projection is not required to establish the covariance contraction result in Proposition 2. It is retained in implementation only to enforce physical parameter bounds and protect against invalid/non-PE data.

必须做一个 numerical check：

### projection ON

最终算法。

### projection OFF

在合法 CCM / no-outlier blind subset。

比较：

- covariance；
- parameter error；
- divergence。

如果 projection OFF 在合法 PE 区域仍稳定，支持上述理论定位。

如果 projection OFF 大量失败：

必须分析 Proposition 2 的实际假设是否没有满足，不能隐藏。

---

# 29. Proposition 2 最终建议形式

## Proposition 2 — Finite-window covariance boundedness and contraction

For each structured health direction, suppose:

1. finite-window information satisfies:
   \[
   \mu_\theta\ge\underline\mu_\theta>0
   \]
2. finite-window process covariance:
   \[
   0\le Q_{\theta,N}\le\bar Q_{\theta,N}<\infty
   \]
3. measurement covariance is positive finite；
4. valid updates recur infinitely often。

Then the posterior covariance satisfies:

\[
P_{n+1}
\le
\frac{
P_n+\bar Q_N
}{
1+
\underline\mu(P_n+\bar Q_N)
}
\]

and is uniformly bounded by the positive fixed point neighborhood of Eq. (P10).

If:

\[
Q_N=0
\]

then:

\[
P_n\rightarrow0
\]

under recurring PE.

With bounded conditional mismatch, the mean-square estimation error remains in a finite mismatch-dependent neighborhood; global asymptotic convergence of the nonlinear physical estimator is not claimed.

---

# 30. Corollary — freeze/gating

当：

\[
|q|<q_{min}
\]

或：

\[
I_\Sigma<I_{min}
\]

或：

- DCM；
- invalid edge；
- failed NIS gate；

时，当前 finite-window lower bound 不成立。

冻结 parameter update。

恢复 valid CCM 后：

\[
\underline\mu_C,\underline\mu_R>0
\]

重新成立，covariance contraction resumes。

---

# Part IV — 理论数值闭环

# 31. 验证 physical PE lower bound

至少对：

\[
36
\]

representative CCM cases。

输出：

```text
case
I_C_min
I_sum_min
T_w_min
kR_min
R_C_max
R_R_max
mu_C_lower
mu_C_empirical
mu_R_lower
mu_R_empirical
ratio_C
ratio_R
```

必须：

\[
ratio=\frac{\mu_{empirical}}{\mu_{lower}}\ge1
\]

如有 <1：

立即修正理论/数值定义。

---

# 32. 验证 covariance fixed-point bound

分别 C、ESR。

至少：

### Case 1
nominal。

### Case 2
low CCM margin。

### Case 3
high D。

### Case 4
noisy。

### Case 5
ESR=2×。

对每个：

- compute \(\underline\mu\)；
- compute \(Q_N\)；
- compute \(P^*\)；
- simulate posterior covariance sequence；
- empirical parameter variance。

检查：

\[
P_{KF}(k)
\]

是否落在理论 envelope 内。

输出：

```text
fig_pv11_07_covariance_bound_C.png
fig_pv11_08_covariance_bound_ESR.png
table_covariance_bound_validation.csv
```

---

# 33. 验证 Q=0 contraction

只用于理论 sanity check。

设置：

\[
Q_\theta=0
\]

correct model / no mismatch。

运行多个 valid windows。

比较：

\[
P_n
\]

与：

\[
\frac1{P_0^{-1}+n\mu}
\]

不作为最终实际算法 tuning。

---

# 34. Projection ON/OFF

在合法 PE subset：

至少 200 Monte Carlo seeds。

输出：

- error；
- covariance；
- divergence；
- projection activation fraction。

目标：

> 证明 projection 不是正常工作区稳定性的主要来源。

---

# 35. 理论文件

更新生成：

```text
PAPER_THEORY_PROOF_V11.md
```

必须包含：

1. Notation；
2. Cuk operating assumptions；
3. Physical PE lower-bound lemma；
4. Proposition 1；
5. Proof；
6. Scalar covariance recursion lemma；
7. Proposition 2；
8. Proof；
9. Q=0 corollary；
10. gating/freeze corollary；
11. bounded mismatch discussion；
12. projection role；
13. numerical verification；
14. limitations；
15. authoritative references。

---

# Part V — 论文冻结判定

# 36. 本轮最终必须回答

## Q1

O1 proposed observation 是否在 RLS / Dual EKF / LTV 三个 estimator 中都显示价值？

---

## Q2

TS-SLTVKE 的额外价值究竟是什么：

- accuracy？
- timing robustness？
- convergence？
- confidence？
- zero divergence？
- gating？
- complexity？

必须按结果回答，不预设。

---

## Q3

论文主创新应该是：

### Option A
new estimator；

### Option B
new observation framework；

### Option C
observation + structured estimator co-design。

必须选一个。

---

## Q4

能否从：

\[
\text{CCM operating bounds}
\]

直接得到：

\[
\underline\mu_C,\underline\mu_R>0
\]

而不再把 PE 完全作为抽象假设？

---

## Q5

covariance boundedness 是否能在 projection OFF 的合法 PE 区域得到数值支持？

---

## Q6

是否可以冻结理论/仿真进入 manuscript？

---

# 37. 最终判定枚举

只能选择：

## A

```text
FREEZE_FOR_MANUSCRIPT
```

---

## B

```text
FREEZE_WITH_THEORY_CAVEAT
```

---

## C

```text
OBSERVATION_NOVELTY_WEAK
```

---

## D

```text
COVARIANCE_THEORY_NOT_SUPPORTED
```

---

## E

```text
REOPEN_ALGORITHM
```

除非 C/D/E，不允许再次创建新的算法验证大版本。

---

# 38. 强制输出文件

```text
FACTORIAL_PROTOCOL.md
OBSERVATION_FACTORIAL_RESULTS.md
PAPER_THEORY_PROOF_V11.md
PAPER_VERIFICATION_V11_RESULT.md
PAPER_READY_UPDATE_V11.md
result_metrics_paper_v11.csv
```

---

# 39. 强制表格

```text
table_observation_estimator_factorial.csv
table_observation_effect_bootstrap.csv
table_factorial_dynamic.csv
table_physical_PE_lower_bound.csv
table_covariance_bound_validation.csv
table_projection_on_off.csv
table_paper_final_claims_v11.csv
```

---

# 40. 强制图

```text
fig_pv11_01_factorial_C.png
fig_pv11_02_factorial_ESR.png
fig_pv11_03_observation_effect.png
fig_pv11_04_factorial_timing.png
fig_pv11_05_factorial_dynamic.png
fig_pv11_06_accuracy_robustness_pareto.png
fig_pv11_07_covariance_bound_C.png
fig_pv11_08_covariance_bound_ESR.png
fig_pv11_09_PE_lower_bound.png
fig_pv11_10_projection_on_off.png
```

---

# 41. PAPER_VERIFICATION_V11_RESULT.md 固定结构

## 1. Executive Decision

## 2. Observation × Estimator Result

## 3. Primary Innovation Decision

明确：

```text
OBSERVATION
ESTIMATOR
CO-DESIGN
```

## 4. RLS with Proposed Observation

这是重点，必须单独回答。

## 5. Dual EKF with Proposed Observation

## 6. TS-SLTVKE Incremental Value

## 7. Factor Interaction

## 8. Physical PE Lower Bound

给：

\[
\underline\mu_C,\underline\mu_R
\]

最弱工况。

## 9. Covariance Fixed-Point Bound

给：

\[
P_C^*,P_R^*
\]

## 10. Projection Independence

## 11. Final Proposition Text

给论文可直接改写版本。

## 12. Final Safe Claims

## 13. Claims Removed

## 14. Manuscript Freeze Decision

---

# 42. PAPER_READY_UPDATE_V11.md

只提供最终写论文要使用的新结论。

必须包括：

- factorial 核心数字；
- observation effect；
- estimator effect；
- final Proposition 1；
- final Proposition 2；
- final Corollary；
- PE lower bounds；
- covariance bounds；
- final contribution wording；
- final limitations。

不得包含 Codex 调试记录。

---

# 43. 一键入口

创建：

```text
scripts/run_paper_verification_v11.m
```

要求：

1. load frozen Paper Verification v1 data；
2. run 2×3 factorial；
3. bootstrap effects；
4. compute physical PE bounds；
5. run covariance-bound checks；
6. run projection ON/OFF；
7. generate all tables/figures；
8. generate reports；
9. audit.

---

# 44. 审计

创建：

```text
scripts/validate_paper_verification_v11.m
```

必须检查：

- six factorial cells all present；
- same blind cases；
- same seeds；
- same estimator hyperparameters between O0/O1；
- no per-cell retuning；
- no deleted negative observation effects；
- PE empirical >= theoretical lower bound；
- covariance theory equations match report；
- projection OFF failures retained；
- all report numbers trace to CSV。

---

# 45. 停止条件

只有以下全部完成才结束：

- [ ] O0/O1 定义冻结
- [ ] E1/E2/E3 定义冻结
- [ ] 2×3 全部运行
- [ ] paired bootstrap 完成
- [ ] observation effect 完成
- [ ] estimator effect 完成
- [ ] interaction 完成
- [ ] dynamic factorial 完成
- [ ] physical PE lower bound 推导完成
- [ ] empirical PE ≥ lower bound 核对完成
- [ ] Proposition 1 更新完成
- [ ] covariance recursion 推导完成
- [ ] explicit fixed point 完成
- [ ] Q=0 sanity 完成
- [ ] projection ON/OFF 完成
- [ ] Proposition 2 更新完成
- [ ] PAPER_VERIFICATION_V11_RESULT.md 完成
- [ ] PAPER_READY_UPDATE_V11.md 完成
- [ ] audit PASS

---

# 46. Codex 最终执行指令

**读取 Paper Verification v1 及 verification_v1–v2.3 的冻结结果。建立 `paper_verification_v11`。本轮禁止修改 TS-SLTVKE 核心算法，也禁止为了让 proposed 获胜而重新调参。首先实施严格 2×3 Observation × Estimator 因子实验：O0 为有效但未做 C/ESR 物理解耦的 mixed observation；O1 为 timestamped ESR edge + safe-window C charge 的 proposed topology-decoupled observation；E1/E2/E3 分别为 RLS、Dual EKF 和 LTV/Joseph estimator。必须在相同 blind cases、seeds、initialization 和 estimator-family-locked hyperparameters 下运行全部六个 cells，使用 paired bootstrap 直接量化 observation effect 与 estimator effect。如果 O1+RLS 也改善鲁棒性，应把论文核心创新上移为 observation framework，而不是继续声称滤波器数值 SOTA。理论方面，从 Ćuk CCM 的 `|i_C|>=I_C,min`、`I_sum>=I_sum,min`、safe-window length、kR 和 measurement covariance 上界直接推出 finite-window `mu_C`、`mu_R` 的显式正下界；然后在不依赖 parameter projection 的情况下，用 finite-window information recursion 推导 `P_next <= (P+Q_N)/(1+mu(P+Q_N))` 及其显式正 fixed point，分别给 C/ESR covariance upper bound。Projection 只作为物理 safety constraint。必须做 projection ON/OFF 数值核对。完成后给出唯一论文主创新判定：OBSERVATION、ESTIMATOR 或 CO-DESIGN，并选择是否 `FREEZE_FOR_MANUSCRIPT`。负结果不得隐藏。**

---

## Version

- **Paper Verification v1.1**
- Date: **2026-08-22**
- Purpose: **final observation-vs-estimator attribution and stronger PE/covariance theory before manuscript writing**
- Core algorithm status: **frozen TS-SLTVKE**
