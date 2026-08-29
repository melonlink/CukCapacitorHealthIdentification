# Codex 执行任务 v2.1
# Ćuk 能量传递电容 C–ESR 健康辨识：理论—仿真闭环与硬件参数一致性核对

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **任务版本**：v2.1 — Theory–Simulation Closure  
> **执行环境**：本机 MATLAB R2023b + Simulink + Simscape Electrical + 已配置 MATLAB MCP  
> **前置版本**：verification_v1、verification_v2  
> **核心算法**：TR-TS-LTVKF（Timing-Robust Topology-Synchronous LTV Kalman Framework）  
> **任务目的**：不是继续证明“算法能跑”，而是关闭 v2 中仍存在的理论、采样、模拟前端和寄生模型矛盾，使仿真结论能够形成一套内部自洽、可用于硬件设计和论文 Methods/Simulation 部分的最终技术规格。

---

# 0. 为什么需要 v2.1

v2 已经完成并支持以下结论：

1. v1 的 20 ns cliff 不是物理可辨识极限，而是 adjacent-edge sample association artifact；
2. timestamped linear edge extrapolation 消除了无物理意义的断崖；
3. common/voltage timing 在约 ±200 ns 范围内可保持 C<3%、ESR<5%；
4. TR-TS-LTVKF 在同一套锁定协方差下 51/51 个 CCM 工况通过；
5. 归一化可观测矩阵 rank=3；
6. Simscape Model B 在 20 nH + 200 ns + 20 ns RMS jitter 压力点通过；
7. 14-bit/8 samples per cycle 在“纯量化+采样相位”的 nominal Model A 扫描中可通过；
8. 模拟前端 Model A 扫描表明电压通道约 1 MHz 才勉强通过，2 MHz 明显更好。

但是 v2 结果中仍存在四组必须关闭的矛盾。

---

## 0.1 矛盾 A：ADC 采样率、edge window 和每侧采样点数不一致

v2 报告建议：

- 推荐 16-bit；
- ≥16 samples/cycle；
- fsw=50 kHz；
- edge guard≈0.5 µs；
- edge window≈1.5–2.0 µs；
- 每侧至少 3 个点。

但是：

\[
f_{ADC}=16\times50k=800\,kS/s
\]

因此：

\[
T_{ADC}=1.25\ \mu s
\]

均匀采样中 3 个点至少跨越：

\[
2T_{ADC}=2.5\ \mu s
\]

所以不能同时满足：

\[
W=1.5\sim2.0\ \mu s
\]

与：

\[
N_w\ge3
\]

v2 的 ADC phase 数据实际上已经自动使用了不同 window：

- 8 spc → 6 µs；
- 12 spc → 5 µs；
- 16 spc → 3.75 µs；
- 24 spc → 2.5 µs；
- 32 spc → 1.875 µs。

因此“16 spc 推荐”和“1.5–2 µs window 推荐”来自不同条件，当前硬件建议不自洽。

---

## 0.2 矛盾 B：模拟前端带宽与 ADC Nyquist/抗混叠不一致

v2 的 front-end 测试：

- 500 kHz：C/ESR≈16.7%/17.3%，FAIL；
- 1 MHz：≈2.62%/4.06%，PASS；
- 2 MHz：≈0.076%/1.33%，PASS。

因此推荐电压前端至少约 1 MHz。

但是如果 ADC 仅：

\[
800\,kS/s
\]

Nyquist：

\[
400\,kHz
\]

则 1–2 MHz 前端明显放行超过 Nyquist 的大量开关频谱。

v2 的 ADC phase 测试与 front-end 测试是分开进行的，没有真正验证：

\[
\text{analog bandwidth}
+
\text{anti-aliasing}
+
\text{ADC sampling}
+
\text{edge extrapolation}
\]

的联合系统。

---

## 0.3 矛盾 C：Model A 的人工 ESL/ringing 与独立 Simscape Model B 不一致

v2：

- Model B：20 nH + 200 ns + 20 ns RMS jitter 通过；
- Model A 的 derivative + decaying ringing 注入：5 nH 起大量失败；
- Model A 还出现部分非单调现象，例如某些更大 ESL/偏移点反而比相邻点误差更低。

说明当前 Model A 高频寄生注入不是足够可信的物理寄生模型。

必须建立一个能与 Model B 边沿波形在：

- ringing frequency；
- damping；
- overshoot；
- settling time；
- edge extrapolation bias；

上对应的 reduced-order physical parasitic model。

---

## 0.4 矛盾 D：实际 TR-TS-LTVKF 是“结构化更新”，理论表达仍不够严格

v2 实际实现中：

- stable voltage update 主要/只更新 \(v_C\)；
- charge pseudo update 只更新 \(1/C\)；
- edge pseudo update 只更新 ESR。

但原始：

\[
H_V=[1,0,i_C]
\]

理论上同时含有 ESR 信息。

如果代码通过 mask 人为阻止 H_V 更新 ESR，则必须回答：

> 这是一个标准 KF、constrained KF、Schmidt-like estimator，还是工程上人为 mask？

此外：

- C pseudo measurement 使用电压/电流窗口数据；
- V update 也可能使用同一批数据；
- 如果同一原始 ADC 样本同时形成两个“独立”测量而忽略其相关噪声，会发生 information double counting。

因此 v2.1 必须把 estimator 的概率/线性模型写严谨，而不是只凭结果好就接受。

---

# 1. v2.1 总目标

本轮必须最终回答四个工程—理论问题：

\[
\boxed{
f_{ADC},\ N_w,\ W,\ guard,\ D
}
\]

能否形成一个严格可行的采样几何区域？

\[
\boxed{
f_{AFE},\ f_{ADC},\ anti-aliasing
}
\]

能否形成无明显混叠、同时保留 ESR 边沿信息的联合测量链？

\[
\boxed{
\text{Reduced Model A-P}
\leftrightarrow
\text{Simscape Model B}
}
\]

能否在高频寄生特征和算法误差上定量一致？

\[
\boxed{
\text{TR-TS-LTVKF}
}
\]

能否被重新表达成数学上自洽、无测量重复计数、协方差可解释的结构化 LTV 状态—参数估计器？

只有以上四项关闭后，才允许冻结“仿真最终算法版本”。

---

# 2. 版本与目录

不得覆盖 v1/v2。

建立：

```text
Cuk_Capacitor_Health_Identification/
├─ verification_v1/
├─ verification_v2/
└─ verification_v21/
   ├─ README_V21.md
   ├─ THEORY_CLOSURE_V21.md
   ├─ SAMPLING_FEASIBILITY_V21.md
   ├─ PARASITIC_MODEL_RECONCILIATION.md
   ├─ ESTIMATOR_FORMULATION_AUDIT.md
   ├─ algorithms/
   ├─ model/
   ├─ scripts/
   ├─ results/
   │  ├─ raw/
   │  ├─ tables/
   │  └─ figures/
   ├─ logs/
   ├─ RESULT_V21_FOR_CHATGPT.md
   ├─ V2_V21_COMPARISON.md
   └─ result_metrics_v21.csv
```

复用 v2 文件时只读。

---

# 3. Task A — 建立采样几何可行性理论

这一项先做解析，不先仿真。

定义：

\[
T_s=\frac{1}{f_s}
\]

\[
T_a=\frac{1}{f_{ADC}}
\]

对于每侧拟合要求 \(N_w\) 个均匀采样点，则一个窗口至少需要：

\[
\boxed{
W_{\min}=(N_w-1)T_a
}
\tag{A1}
\]

设 edge guard 为：

\[
g
\]

则 pre/post 窗口完整位于当前开关子区间的必要条件：

\[
\boxed{
g+W
\le
T_{\text{state}}
}
\tag{A2}
\]

其中：

\[
T_{ON}=DT_s
\]

\[
T_{OFF}=(1-D)T_s
\]

如果要保证两个边沿两侧都存在足够拟合区间，则至少：

\[
\boxed{
g+W
\le
\min(D,1-D)T_s
}
\tag{A3}
\]

组合 A1/A3 得到 ADC 最低理论采样率：

\[
\boxed{
f_{ADC}
\ge
\frac{N_w-1}
{\min(D,1-D)T_s-g}
}
\tag{A4}
\]

但这个只是“能放下点”的几何下限，不是精度下限。

---

## 3.1 针对当前参数给出解析表

固定：

\[
f_s=50\,kHz,\quad T_s=20\,\mu s
\]

占空比：

\[
D=
[0.25,0.35,0.40,0.45,0.55,0.65]
\]

guard：

\[
g=
[0.2,0.5,1.0]\,\mu s
\]

拟合点：

\[
N_w=[3,4,5,6]
\]

窗口目标：

\[
W=[1.0,1.5,2.0,2.5,3.0,5.0,6.0]\,\mu s
\]

ADC rate：

\[
f_{ADC}=
[0.4,0.6,0.8,1.0,1.25,1.6,2.0,2.5,3.2,5.0,10]\,MS/s
\]

输出每一组合：

- `geometrically_feasible`
- available points per side；
- worst sampling phase available points；
- margin to ON boundary；
- margin to OFF boundary。

---

## 3.2 sampling phase 不能忽略

对于均匀采样栅格：

\[
t_n=nT_a+\phi
\]

其中：

\[
\phi\in[0,T_a)
\]

解析/枚举至少 64 个 phase，计算每个 edge window 实际包含点数。

最终必须区分：

### Mean feasible

大多数 phase 能放下。

### 95% phase feasible

≥95% phase 满足 \(N_w\)。

### 100% phase feasible

所有 phase 都满足 \(N_w\)。

硬件推荐至少基于：

\[
\boxed{
95\%\ \text{phase feasibility}
}
\]

如果 ADC 由 PWM 定时器同步触发、phase 可设计，则另外给：

\[
\boxed{
\text{designed-phase feasibility}
}
\]

不得把二者混在一起。

---

## 3.3 形成一个理论图

绘制：

\[
f_{ADC}
\]

对：

\[
D
\]

的最小可行区域。

至少给：

- \(N_w=3,g=0.5\mu s\)
- \(N_w=4,g=0.5\mu s\)
- \(N_w=3,g=1.0\mu s\)

输出：

```text
table_sampling_geometry_v21.csv
fig_v21_01_sampling_feasible_region.png
fig_v21_02_phase_point_availability.png
SAMPLING_FEASIBILITY_V21.md
```

---

# 4. Task B — 用理论误差传播选择 edge window，而不是只靠 brute force

线性外推：

\[
v(t)=at+b
\]

把 edge timestamp 设置为局部坐标：

\[
t=0
\]

对前侧或后侧 \(N_w\) 个点做 OLS。

若单点电压噪声方差为：

\[
\sigma_v^2
\]

则边沿外推值：

\[
\hat v(0)
\]

的预测方差应由标准线性回归公式计算。

Codex 必须推导并在 `THEORY_CLOSURE_V21.md` 写出：

\[
\boxed{
\mathrm{Var}[\hat v(0)]
=
\sigma_v^2
\left[
\frac1N+
\frac{\bar t^2}
{\sum(t_i-\bar t)^2}
\right]
}
\tag{B1}
\]

或实际实现对应的等价矩阵形式。

前后独立时：

\[
\mathrm{Var}[\Delta v_R]
=
\mathrm{Var}[\hat v^-]
+
\mathrm{Var}[\hat v^+]
\tag{B2}
\]

ESR：

\[
r_C=
\frac{\Delta v_R}{I_\Sigma}
\]

一阶误差：

\[
\boxed{
\sigma_r^2
\approx
\frac{\sigma_{\Delta v}^2}{I_\Sigma^2}
+
\frac{r_C^2\sigma_{I_\Sigma}^2}{I_\Sigma^2}
}
\tag{B3}
\]

---

## 4.1 建立 window bias–variance tradeoff

窗口太短：

- 点数少；
- extrapolation variance 高。

窗口太长：

- 子区间波形曲率；
- LC 低频变化；
- 非线性；
- 前端动态；

导致 bias 增大。

所以对每个：

\[
f_{ADC},W,g,N_w
\]

计算：

- theoretical variance；
- simulation bias；
- RMSE；
- predicted ESR CRLB/first-order bound；
- actual ESR Monte Carlo RMSE。

目标：

\[
\boxed{
\text{找到宽的 robust region，而非单一最优点}
}
\]

输出：

```text
table_edge_bias_variance_v21.csv
fig_v21_03_edge_bias_variance.png
fig_v21_04_predicted_vs_actual_esr_sigma.png
```

---

# 5. Task C — 建立 C 通道的信息量理论

safe-window C measurement 必须明确实际公式。

优先统一为：

\[
z_C
=
\Delta v_T-\hat r_C\Delta i_C
\]

在安全子区间：

\[
z_C=q\alpha+\nu_C,
\qquad
\alpha=\frac1C
\]

如果使用归一化：

\[
\bar\alpha=C_b/C
\]

则：

\[
\boxed{
z_C=\frac{q}{C_b}\bar\alpha+\nu_C
}
\tag{C1}
\]

必须明确：

- \(\Delta v_T\) 用哪些 ADC 样本；
- \(q\) 怎样积分；
- \(\Delta i_C\) 怎样获得；
- ESR 不确定性怎样进入 \(R_C\)。

一阶近似：

\[
\boxed{
R_C
\approx
R_{\Delta v}
+
(\Delta i_C)^2P_{rr}
+
\hat r_C^2 R_{\Delta i}
+
\alpha^2R_q
}
\tag{C2}
\]

如实际模型存在协方差项，写完整。

单个 C pseudo 对 \(\alpha\) 的信息：

\[
\boxed{
\mathcal I_C=
\frac{(q/C_b)^2}{R_C}
}
\tag{C3}
\]

多个窗口：

\[
\mathcal I_{C,N}
=
\sum_k
\frac{(q_k/C_b)^2}{R_{C,k}}
\tag{C4}
\]

由此给 C 参数理论标准差/CRLB。

输出：

```text
fig_v21_05_C_information_vs_load_duty.png
table_C_information_v21.csv
```

---

# 6. Task D — 重新定义“结构化 LTV estimator”，关闭 Kalman 理论矛盾

这是本轮理论核心。

必须对 v2 实际代码做 audit：

1. `H_V` 实际是什么？
2. Kalman gain 是否被 mask？
3. `H_C/H_R` 是否 sequential scalar update？
4. stable V 原始样本是否与 C pseudo 使用相同 ADC 数据？
5. edge window 样本是否又被 stable V update 使用？
6. measurement covariance 是否假定独立？
7. 若重复使用同一原始数据，是否发生 double counting？

输出：

`ESTIMATOR_FORMULATION_AUDIT.md`

---

# 7. 必须比较三种数学实现

## Variant 1 — v2 masked-gain implementation

完全复现当前 TR-TS-LTVKF。

记录其数学形式。

---

## Variant 2 — full LTV Kalman

使用物理测量：

\[
y_V=v_T
\]

\[
H_V=[1,0,i_C]
\]

允许标准 Kalman gain 更新所有相关状态。

C/R pseudo 继续存在，但必须处理样本相关性或使用 disjoint data。

目的：

> 判断“物理可解耦的 structured update”是否真的比 full KF 更鲁棒。

---

## Variant 3 — conditional/structured pseudo-measurement estimator

不要通过“mask Kalman gain”实现。

构造内部电容电压虚拟观测：

\[
\boxed{
z_V
=
v_T-\hat r_C i_C
}
\tag{D1}
\]

并使用：

\[
\boxed{
H_V^{*}=[1,0,0]
}
\tag{D2}
\]

对应观测方差至少包含：

\[
\boxed{
R_V^{*}
=
R_v
+
i_C^2P_{rr}
+
\hat r_C^2R_i
+\cdots
}
\tag{D3}
\]

C：

\[
H_C=[0,q/C_b,0]
\]

R：

\[
H_R=[0,0,I_\Sigma]
\]

这样三类观测在形式上各自对应一个状态/参数方向。

若此方案的严格协方差传播成立，则优先将其定义为最终：

\[
\boxed{
\text{Structured Multi-Rate LTV Estimator}
}
\]

而不依赖人为 gain mask。

---

# 8. 禁止 measurement double counting

设计两个方案对比：

## Data Policy A — disjoint raw samples

- stable V update：只用 safe mid-interval 点集 \(S_V\)；
- C pseudo：只用另一组安全端点/积分点 \(S_C\)；
- ESR edge：只用 edge windows \(S_R\)。

满足：

\[
S_V\cap S_C=\varnothing
\]

\[
S_V\cap S_R=\varnothing
\]

尽量：

\[
S_C\cap S_R=\varnothing
\]

这样近似可将测量噪声视为独立。

## Data Policy B — overlapping samples

复现 v2 可能的共享数据方式。

比较：

- parameter bias；
- covariance collapse；
- NIS；
- NEES；
- confidence interval coverage。

如果 overlapping 明显导致过度自信，则最终算法强制采用 disjoint policy，或显式建立 cross-covariance。

输出：

```text
table_measurement_reuse_v21.csv
fig_v21_06_double_counting_effect.png
```

---

# 9. Task E — 用 NIS + NEES 做统计一致性闭环

v2：

- C/R NIS p95 极低；
- 说明 covariance 明显保守。

本轮不能只看精度。

---

## 9.1 NIS

每个 scalar observation：

\[
NIS=e^2/S
\]

理想 1-DOF 情况：

\[
E[NIS]\approx1
\]

95% 分位理论参考：

\[
\chi^2_{1,0.95}\approx3.84
\]

报告：

- mean；
- p50；
- p95；
- 95% coverage；
- rejection fraction。

---

## 9.2 NEES

仿真知道 true states/parameters：

\[
\epsilon_k=x_k-\hat x_k
\]

\[
NEES=
\epsilon_k^TP_k^{-1}\epsilon_k
\]

分别计算：

### Full 3-state NEES

### Parameter-only 2-state NEES

\[
[\bar\alpha,r_C]
\]

### Scalar normalized errors

\[
\frac{(\hat\alpha-\alpha)^2}{P_{\alpha\alpha}}
\]

\[
\frac{(\hat r-r)^2}{P_{rr}}
\]

至少 100 Monte Carlo seeds：

- nominal；
- high D；
- low CCM margin；
- 10 mV / 5 mA；
- timing ±200 ns；
- Model B-compatible parasitic case。

计算 average NEES 与理论 chi-square confidence bounds。

---

## 9.3 协方差优化原则

只能使用 training set 校准：

- model discrepancy floors；
- fit variance scale factors；
- process noise。

然后 lock。

Blind set 不允许重新调。

目标不是强求 NIS/NEES 完美等于 1，而是：

\[
\boxed{
\text{既不过度自信，也不过度保守}
}
\]

最终必须给：

- empirical 95% confidence interval coverage；
- parameter CI calibration curve。

输出：

```text
table_NIS_NEES_v21.csv
fig_v21_07_NIS_NEES_consistency.png
fig_v21_08_CI_coverage.png
```

---

# 10. Task F — ADC + 前端 + anti-aliasing 联合设计

这次不允许再分开测试 ADC 和 AFE。

建立显式测量链：

```text
physical waveform
    ↓
analog front-end transfer function
    ↓
optional anti-alias filter / same AFE
    ↓
sampling at actual fs_ADC and phase
    ↓
sample-and-hold
    ↓
quantization
    ↓
timestamp / calibrated delay
    ↓
TR estimator
```

---

# 11. ADC rate 扫描

至少：

\[
f_{ADC}=
[0.4,0.8,1.0,1.6,2.5,5.0,10.0]\,MS/s/channel
\]

优先 simultaneous sampling。

bits：

\[
[14,16]
\]

12-bit 已被 v2 证明多数 phase 不稳定，可保留少量对照，不必成为主矩阵。

---

# 12. Front-end 扫描

Voltage:

\[
f_{c,V}=
[0.25,0.5,1.0,1.5,2.0,3.0]\,MHz
\]

Current:

\[
f_{c,I}=
[0.25,0.5,1.0,2.0]\,MHz
\]

至少测试：

1. 一阶 LPF；
2. 二阶 Butterworth 或实际可实现低通。

必须报告：

- attenuation @ fsw；
- group delay @ fsw；
- group delay in edge-relevant band；
- alias power ratio。

---

# 13. 定义 alias metric

不能只用 Nyquist 口头判断。

在 analog filtered waveform 的频谱上定义：

\[
P_{alias}
\]

为采样后折叠进入基带的超 Nyquist 功率。

定义：

\[
\boxed{
AR=
10\log_{10}
\frac{P_{alias}}{P_{base}}
}
\tag{F1}
\]

或者使用等价、清晰的 aliasing ratio。

要求将：

\[
AR
\]

与：

- C MAPE；
- ESR MAPE；

做相关图。

如果某种同步采样利用确定性相位仍能在 Nyquist 违反下得到低误差，必须额外做：

- sampling phase perturbation；
- fsw ±1%；
- asynchronous perturbation；

判断是否只是“同步欠采样偶然对齐”。

不能把偶然 synchronous alias cancellation 当作硬件鲁棒性。

输出：

```text
table_adc_afe_joint_v21.csv
fig_v21_09_adc_afe_pass_region.png
fig_v21_10_alias_error_correlation.png
```

---

# 14. 最终硬件设计区域必须由联合实验给出

最终不允许单独说：

> “最低 14-bit/8 samples per cycle”

或：

> “至少 1 MHz front end”。

必须给一个联合可行域，例如：

```text
ADC rate       Voltage AFE      Current AFE      bits      timing     result
x MS/s         y MHz            z MHz            16        ...        PASS
```

判定至少考虑：

- phase；
- quantization；
- analog noise；
- channel delay；
- jitter；
- aliasing；
- edge point count；
- duty feasibility。

---

# 15. Task G — Model A 高频寄生模型重建

删除/停用 v2 的“arbitrary derivative + decaying ringing injection”作为论文证据。

保留它只作为历史 stress model。

新建：

\[
\boxed{
\text{Model A-P}
}
\]

P = physical parasitic reduced-order model。

---

# 16. 从 Simscape Model B 提取物理边沿特征

在：

\[
L_{ESL}=
[1,5,10,20,50]\ nH
\]

至少三个 load：

\[
[25,50,100]\%
\]

至少三个 duty：

\[
[0.30,0.40,0.60]
\]

如果部分工况 DCM，则替换为 CCM 工况。

每个 edge 保存高分辨率：

- \(v_T(t)\)；
- \(i_C(t)\)；
- \(i_1(t)\)；
- \(i_2(t)\)；
- switch node voltage（若可获取）。

提取：

\[
f_{ring}
\]

damping ratio：

\[
\zeta
\]

overshoot：

\[
M_p
\]

settling time：

\[
t_{settle}
\]

first peak time；

edge slope；

edge extrapolation bias。

输出：

```text
table_modelB_edge_features_v21.csv
```

---

# 17. 建立物理 reduced-order model

优先路线：

### Option A — explicit parasitic RLC equivalent

包含：

- \(C_1\)；
- ESR；
- ESL；
- switching-loop inductance；
- equivalent damping resistance；
- relevant switch-node capacitance / equivalent capacitance；
- finite switch transition time。

### Option B — identified second-order edge transfer model

只有在 Option A 不能稳定简化时使用。

一般二阶形式：

\[
G_p(s)
=
\frac{\omega_n^2}
{s^2+2\zeta\omega_ns+\omega_n^2}
\]

参数必须由 Model B edge waveform 拟合，而不是人工指定。

---

# 18. Model A-P 与 Model B 的验收

对每个测试点比较：

- waveform NRMSE；
- ring frequency error；
- damping error；
- peak error；
- settling time error；
- linear extrapolated ESR error；
- TR estimator C/ESR error。

建议目标：

\[
|f_{ring,A-P}-f_{ring,B}|/f_{ring,B}<10\%
\]

\[
|\zeta_{A-P}-\zeta_B|/\zeta_B<20\%
\]

edge window 内：

\[
NRMSE_{v_T}<10\%
\]

最重要：

\[
|\Delta ESR_{\text{MAPE}}|<2\ \text{percentage points}
\]

如果无法达到，不强迫 PASS。

结论必须改成：

> Model A-P 不能替代 Model B 做寄生鲁棒性泛扫。

输出：

```text
PARASITIC_MODEL_RECONCILIATION.md
table_modelAP_vs_B_v21.csv
fig_v21_11_modelAP_modelB_edge_overlay.png
fig_v21_12_modelAP_modelB_error.png
```

---

# 19. Task H — 用 Model B/Model A-P 重新核对 ±200 ns 支持范围

不要只测试 nominal 单点。

在联合测量链下：

\[
delay=
[0,50,100,150,200,250,300,400,500]\ ns
\]

测试：

\[
ESL=
[1,10,20]\ nH
\]

jitter：

\[
[0,20,50]\ ns RMS
\]

至少：

- nominal load；
- high load；
- high D CCM；
- low CCM margin。

重点找：

\[
\boxed{
\text{95% pass timing boundary}
}
\]

而不是只报告某一个 +200 ns 点 PASS。

输出：

```text
fig_v21_13_timing_pass_probability.png
table_timing_boundary_v21.csv
```

---

# 20. Task I — 理论/仿真最终参数敏感性与 CRLB

对最终 structured estimator 构造噪声加权 Fisher information：

\[
\mathcal I
=
\sum
H_k^TR_k^{-1}H_k
\]

需要包含状态传播时使用 observability Gramian 等价形式。

输出 C/ESR 的：

- CRLB；
- empirical variance；
- RMSE / CRLB ratio。

跨：

- load；
- D；
- ADC rate；
- AFE bandwidth；
- timing error。

目标不是要求 estimator 达到 CRLB，而是回答：

> 哪些工况是“信息不足导致误差”，哪些是“模型失配导致误差”？

这是论文 Discussion 很重要的理论支撑。

输出：

```text
table_CRLB_v21.csv
fig_v21_14_empirical_vs_CRLB.png
```

---

# 21. Task J — 最终算法命名核对

根据 Task D 结果决定。

只有当实际实现确实符合标准 LTV Kalman recursion 时，保留：

\[
\text{TR-TS-LTVKF}
\]

如果最终采用：

- disjoint measurements；
- conditional \(v_C\) pseudo observation；
- parameter-direction-specific updates；
- structured covariance；

更准确的名称可改成：

### Candidate 1

**Topology-Synchronous Structured LTV Kalman Estimator**

\[
\text{TS-SLTVKE}
\]

### Candidate 2

**Timestamp-Aware Multi-Rate LTV State–Parameter Estimator**

### Candidate 3

**Topology-Decoupled Multi-Rate LTV Estimator**

Codex 不要自行追求“名字更酷”。

必须在报告中回答：

> 哪个名称与实际数学算法最一致？

---

# 22. 本轮仿真工况不需要重新大扫 1125 点

重点使用：

## Training/calibration

- nominal；
- high D；
- noisy；
- Model B parasitic nominal。

## Blind validation

至少 24–36 个代表性 CCM 点：

\[
V_{in}=[19.2,24,28.8]V
\]

\[
D=[0.30,0.40,0.55,0.65]
\]

loads 选能保持 CCM 的：

\[
[25,50,100]\%
\]

若 25% 在某点进入 DCM，替换为最接近的 CCM load。

再加入：

- C=80%,90%,100%；
- ESR=1x,1.5x,2x；

不需要全笛卡尔积，可采用分层/LHS，但必须覆盖参数边界。

---

# 23. 最终 PASS 不是只看 MAPE

每个主工况必须同时评价：

### Accuracy

\[
MAPE_C<3\%
\]

\[
MAPE_R<5\%
\]

### Sampling feasibility

窗口真实有足够采样点。

### Statistical consistency

NIS/NEES 不出现明显系统性过度自信。

### No double counting

采用独立数据或相关协方差正确处理。

### Alias robustness

不是依赖单一同步 phase 的偶然欠采样。

### Model agreement

关键寄生点 Model A-P 与 Model B 结论一致或差异被解释。

---

# 24. v2.1 关键 Gates

## Gate A — Sampling Geometry Closure

必须得到一个不存在内部矛盾的：

\[
f_{ADC}\leftrightarrow W\leftrightarrow N_w\leftrightarrow D
\]

设计区域。

---

## Gate B — ADC/AFE Closure

必须给出联合：

\[
f_{ADC}+f_{AFE}+bits
\]

PASS 区域。

若“800 kS/s + 1–2 MHz AFE”只有同步偶然条件下可用，则不得推荐。

---

## Gate C — Estimator Theory Closure

必须明确：

- 是否 gain mask；
- 是否 conditional pseudo measurement；
- 是否 double counting；
- covariance 如何传播。

必须形成可直接写论文公式的算法。

---

## Gate D — Statistical Consistency

至少在 Model A nominal/representative Monte Carlo 中：

- CI coverage 合理；
- NIS/NEES 没有数量级过保守或过度自信。

---

## Gate E — Parasitic Model Closure

Model A-P 必须与 Model B 在 edge waveform 和 estimator error 上达到可接受一致性。

若达不到：

> 正式放弃 Model A-P 的寄生泛扫，只以 Model B 为寄生鲁棒性证据。

这也算 Gate 关闭，不算项目失败。

---

## Gate F — Timing Boundary

必须把“±200 ns”从单点结论变成：

\[
\boxed{
\text{95% pass timing boundary under defined ADC/AFE/parasitic conditions}
}
\]

---

# 25. 强制表格

至少输出：

```text
table_sampling_geometry_v21.csv
table_edge_bias_variance_v21.csv
table_C_information_v21.csv
table_measurement_reuse_v21.csv
table_NIS_NEES_v21.csv
table_adc_afe_joint_v21.csv
table_modelB_edge_features_v21.csv
table_modelAP_vs_B_v21.csv
table_timing_boundary_v21.csv
table_CRLB_v21.csv
table_blind_validation_v21.csv
result_metrics_v21.csv
```

---

# 26. 强制图

至少：

```text
fig_v21_01_sampling_feasible_region.png
fig_v21_02_phase_point_availability.png
fig_v21_03_edge_bias_variance.png
fig_v21_04_predicted_vs_actual_esr_sigma.png
fig_v21_05_C_information_vs_load_duty.png
fig_v21_06_double_counting_effect.png
fig_v21_07_NIS_NEES_consistency.png
fig_v21_08_CI_coverage.png
fig_v21_09_adc_afe_pass_region.png
fig_v21_10_alias_error_correlation.png
fig_v21_11_modelAP_modelB_edge_overlay.png
fig_v21_12_modelAP_modelB_error.png
fig_v21_13_timing_pass_probability.png
fig_v21_14_empirical_vs_CRLB.png
fig_v21_15_final_design_region.png
```

---

# 27. result_metrics_v21.csv 新增字段

至少：

```text
fs_adc_Hz
adc_interval_s
adc_bits
sample_phase
window_requested_us
window_actual_us
points_available_pre
points_available_post
sampling_geometry_feasible
duty_on_margin_us
duty_off_margin_us
afe_order
afe_fc_v_Hz
afe_fc_i1_Hz
afe_fc_i2_Hz
alias_ratio_dB
edge_predicted_variance_V2
edge_empirical_variance_V2
esr_predicted_sigma_Ohm
esr_empirical_sigma_Ohm
C_information
ESR_information
estimator_variant
gain_mask_used
data_policy
double_counting_flag
NIS_V
NIS_C
NIS_R
NEES_full
NEES_param
CI_C_contains_true
CI_ESR_contains_true
parasitic_model
ring_freq_Hz
ring_zeta
ring_overshoot_V
ring_settle_s
modelB_waveform_NRMSE
CRLB_C
CRLB_ESR
rmse_to_crlb_C
rmse_to_crlb_ESR
```

---

# 28. THEORY_CLOSURE_V21.md 固定内容

必须包含完整数学推导，不允许只写结果：

## 1. Sampling geometry equations

Eq. A1–A4。

## 2. Linear edge extrapolation variance

Eq. B1–B3。

## 3. C pseudo measurement and covariance

Eq. C1–C4。

## 4. Final normalized state definition

## 5. Final state propagation matrix

## 6. Final three measurement models

## 7. Measurement covariance derivation

## 8. Handling of measurement correlation

## 9. NIS/NEES definitions

## 10. Fisher information / CRLB

## 11. Identifiability vs numerical information distinction

必须明确：

\[
rank=full
\]

只代表结构条件，不代表数值精度一定好。

---

# 29. RESULT_V21_FOR_CHATGPT.md 固定问题

必须逐项回答：

1. 16 spc 与 1.5–2 µs edge window 的矛盾是否确认？
2. 最终一致的 ADC rate / edge window / Nw 是什么？
3. 不同 D 下窗口是否都实际可放下？
4. 1–2 MHz AFE 与 ADC rate 的 aliasing 是否关闭？
5. 最终推荐 ADC rate 是多少？“最低支持”和“推荐值”分别是什么？
6. Model A v2 ringing model 为什么与 Model B 不一致？
7. 新 Model A-P 是否足以替代 Model B 泛扫？
8. v2 的 structured Kalman update 是否存在数学不严谨？
9. 最终采用 full KF、masked KF 还是 conditional structured estimator？
10. 是否存在 measurement double counting？
11. C/R covariance 是否仍明显过度保守？
12. NIS/NEES/CI coverage 是否支持“confidence”主张？
13. ±200 ns 是什么条件下的 95% timing boundary？
14. 哪些失败来自 information shortage？
15. 哪些失败来自 model mismatch？
16. 最终算法是否可以冻结进入硬件？
17. 最终论文可安全主张什么？
18. 哪些主张仍必须等待硬件证据？

---

# 30. V2_V21_COMPARISON.md 必须给出最终修改

至少对比：

| 项目 | v2 | v2.1 |
|---|---|---|
| ADC 最低支持 | | |
| ADC 推荐 | | |
| edge window | | |
| points/side | | |
| voltage AFE | | |
| current AFE | | |
| alias handling | | |
| timing boundary | | |
| estimator formulation | | |
| covariance consistency | | |
| Model A parasitic | | |
| Model B evidence | | |
| hardware readiness | | |

---

# 31. 最终硬件建议必须分两层

## Minimum Supported by Simulation

只写已经明确通过联合测试的最低配置。

## Recommended for First Bench Prototype

为了给研究留裕量，允许比最低配置更高。

例如如果联合测试最终证明：

\[
1.6MS/s
\]

已足够，不代表第一块硬件必须只选 1.6MS/s。

如果 5 MS/s simultaneous 16-bit ADC 能显著降低不确定性，应明确推荐作为科研台架。

---

# 32. 停止条件

只有以下全部完成才结束：

- [ ] Sampling geometry 解析闭环
- [ ] phase feasibility 完成
- [ ] edge bias/variance 理论与 Monte Carlo 对齐
- [ ] C information / CRLB 完成
- [ ] v2 estimator code audit 完成
- [ ] 三种 estimator variants 完成
- [ ] double counting audit 完成
- [ ] NIS + NEES + CI coverage 完成
- [ ] ADC + AFE + alias 联合测试完成
- [ ] Model B edge features 批量提取完成
- [ ] Model A-P 物理寄生模型完成或明确判定不可替代
- [ ] timing 95% boundary 完成
- [ ] representative blind validation 完成
- [ ] THEORY_CLOSURE_V21.md 完成
- [ ] RESULT_V21_FOR_CHATGPT.md 完成
- [ ] V2_V21_COMPARISON.md 完成
- [ ] result_metrics_v21.csv 完成

若某项无法完成：

- 标记 `BLOCKED`；
- 说明原因；
- 不得用假设值替代实测仿真值。

---

# 33. Codex 最终执行指令

**读取 verification_v1、verification_v2 的现有结果和源码，但不得覆盖。建立 verification_v21。v2.1 的目标不是继续提高漂亮的 MAPE，而是关闭当前理论与工程规格之间的矛盾。首先用解析公式核对 ADC rate、edge window、points-per-side、guard 和 duty-cycle 的几何可行性；其次建立包含模拟前端、抗混叠、真实 ADC 采样、phase、量化和时序误差的联合测量链，禁止再把 ADC 与前端带宽分开下结论；然后重建一个从 Simscape Model B 波形标定得到的物理 reduced-order parasitic Model A-P，替代 v2 的人工 ringing 注入；同时审核 TR-TS-LTVKF 的实际 gain masking、伪测量、原始数据重复使用和协方差传播，比较 masked/full/conditional structured 三个实现，使用 NIS、NEES、CI coverage 与 CRLB 而不只看 MAPE。最终输出一个内部无矛盾的硬件可行设计区域，以及可直接写入论文的最终状态空间和估计算法公式。任何不能被 Model B 或统计一致性支持的结论必须降级，不得为了保持原方案而强行解释。**

---

## 版本说明

- Version: **v2.1**
- Date: **2026-08-21**
- Phase: **Theory–Simulation Closure before hardware**
- Success criterion: **not “more PASS cases”, but a self-consistent theory, estimator, sampling chain, parasitic model, and hardware-oriented simulation specification.**
