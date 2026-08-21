# Codex 补强验证任务书 v2.0  
## Ćuk 能量传递电容 C–ESR：Timing-Robust TS-LTVKF 与硬件可实现性验证

> **项目目录建议**：`Cuk_Capacitor_Health_Identification`  
> **任务性质**：第一次完整仿真后的专项补强验证，不重复做已经通过的基础理论证明。  
> **前置结果**：第一次验证已经支持 T12/T13/T15/T16/T17，Model A 与独立 Simscape Model B 一致；CCM 下 `rank(Phi)=2`、`rank(O)=3`，TS-LTVKF 在 51 个 CCM 工况中采用自适应/下限协方差后全部达到 C≤3%、ESR≤5%。  
> **第一次暴露出的主要问题**：
>
> 1. 当前 `adjacent-edge assignment` 实现对非零 PWM/采样偏移表现出断崖式失效：0 偏移可用，而最小测试 20 ns 已导致严重误差；
> 2. 这种 20 ns 断崖更可能来自样本边沿归属/观测构造，而不是 C–ESR 结构可辨识性的物理极限，需要专门证伪；
> 3. ESL 下 naive peak ESR 方法失效，但边沿两侧线性外推在 20 nH 时仍可把 ESR MAPE 控制在约 1.16%，说明“边沿估计”比“边沿采样”更合理；
> 4. 原 `cond(O)` 未做状态尺度归一化，不能直接解释成物理可观测性强弱；
> 5. ADC 位数、points/cycle 与 sampling phase 在第一次结果中高度耦合，不能据此简单宣称“最低必须 16-bit、16 points/cycle”；
> 6. TS-LTVKF 对测量协方差下限/自适应机制敏感，第二轮必须把协方差设计从“调参”提升为可重复的方法。
>
> **v2 核心目标**：  
> 将当前基于相邻边沿样本的 TS-LTVKF 改造成一个具有时间戳、边沿两侧窗口拟合、参数伪测量、归一化可观测性与一致性协方差设计的 **Timing-Robust TS-LTVKF（暂称 TR-TS-LTVKF）**，并判断其硬件可实现时序裕量。
>
> **重要原则**：  
> 不要试图证明改进方案一定成功。首先复现第一次的 20 ns 断崖，然后用独立时间偏移、通道延迟、抖动、前端群延迟、ADC 相位和 ESL 联合测试去攻击新方案。只有失败机制被清楚解释且改进方案在合理硬件误差下仍成立，才能提高论文等级。

---

# 0. 执行方式与版本管理

## 0.1 不覆盖 v1 结果

必须保留第一次验证目录和全部输出。

建议目录：

```text
Cuk_Capacitor_Health_Identification/
├─ verification_v1/                 # 原第一次结果，禁止覆盖
└─ verification_v2/
   ├─ README_V2.md
   ├─ BASELINE_REPRODUCTION.md
   ├─ algorithms/
   ├─ timing/
   ├─ observability/
   ├─ covariance/
   ├─ adc_sampling/
   ├─ nonideal/
   ├─ scripts/
   ├─ results/
   │  ├─ tables/
   │  ├─ figures/
   │  └─ raw/
   ├─ logs/
   ├─ RESULT_V2_FOR_CHATGPT.md
   ├─ V1_V2_COMPARISON.md
   └─ result_metrics_v2.csv
```

## 0.2 优先复用第一次模型

复用并锁定：

- Model A：开关分段状态方程模型；
- Model B：Simscape Electrical 独立电路模型；
- 第一轮基准参数；
- 第一轮 RLS；
- 第一轮 TS-LTVKF。

只允许在新分支/新文件中实现改进算法，不要破坏第一次可复现性。

## 0.3 必须真实运行

Codex 必须调用本机 MATLAB MCP / MATLAB R2023b / Simulink / Simscape Electrical 实际运行，不得只写代码和推测结论。

---

# 1. 第一任务：完整复现“20 ns 断崖”，并判断它是物理现象还是样本归属错误

这是 v2 的最高优先级。

## 1.1 复现旧算法

保持第一次：

- Vin = 24 V；
- D = 0.4；
- fs = 50 kHz；
- Ts = 20 µs；
- C1 = 100 µF；
- ESR = 50 mΩ；
- 其余基准参数不变。

使用原 `adjacent-edge assignment` 方法，重新测试**有正负号的细密偏移**：

\[
\Delta t/T_s =
[-0.01,-0.005,-0.002,-0.001,-0.0005,-0.0002,-0.0001,
0,
0.0001,0.0002,0.0005,0.001,0.002,0.005,0.01]
\]

50 kHz 下分别对应约：

\[
[-200,-100,-40,-20,-10,-4,-2,0,2,4,10,20,40,100,200]\text{ ns}
\]

必要时在断点附近继续细化到 1 ns。

必须输出：

- 每个偏移对应的 pre-edge index；
- post-edge index；
- 两点相对真实 PWM 边沿的位置；
- 两点的 PWM 状态；
- \(\Delta v_{edge}\)；
- \(\Delta i_C\)；
- ESR raw estimate；
- 参数投影前 estimate；
- 参数投影后 estimate。

### 必须回答

1. 误差是否在某个 sample index 变化时突然跳变？
2. 20 ns 后 ESR MAPE 约 90%/100% 是否由参数 projection/clipping 造成？
3. 在不做 projection 的诊断运行中，原始估计值实际跑到了哪里？
4. `rank(Phi)` 是否仍为 2？
5. 断崖发生时是结构可辨识性消失，还是观测量被错误构造？

输出：

```text
BASELINE_REPRODUCTION.md
table_v1_edge_assignment_diagnostics.csv
fig_v2_01_old_method_cliff.png
fig_v2_02_sample_index_transition.png
fig_v2_03_pre_projection_vs_projection.png
```

### Gate 1

若断崖与样本索引/状态归属切换高度对应，而 `rank(Phi)=2` 仍保持，则正式判定：

> **v1 的 <20 ns 不是物理可辨识极限，而是当前 adjacent-edge measurement construction 的实现限制。**

若不是，则继续寻找真正物理原因，不得预设该结论。

---

# 2. 新的边沿观测：从“边沿采样”改成“带时间戳的边沿估计”

新算法不允许要求 ADC 样本刚好落在 PWM 边沿左右相邻点。

已知 PWM 真正切换时间：

\[
t_s
\]

分别在边沿前后定义安全窗口：

\[
\mathcal W^-=
[t_s-\tau_{2-},\,t_s-\tau_{1-}]
\]

\[
\mathcal W^+=
[t_s+\tau_{1+},\,t_s+\tau_{2+}]
\]

边沿前后各至少使用：

\[
N_w\ge3
\]

个带真实时间戳的样本。

---

## 2.1 基础线性外推

分别拟合：

\[
v_T^-(t)=a_-t+b_-
\]

\[
v_T^+(t)=a_+t+b_+
\]

外推到同一物理时刻：

\[
\tilde v_T^- = v_T^-(t_s)
\]

\[
\tilde v_T^+ = v_T^+(t_s)
\]

构造：

\[
\boxed{
y_R=
\tilde v_T^--\tilde v_T^+
}
\]

理论模型：

\[
\boxed{
y_R=(i_1+i_2)r_C+\nu_R
}
\]

对应 ESR 伪测量矩阵：

\[
\boxed{
H_R=
\begin{bmatrix}
0&0&i_1+i_2
\end{bmatrix}
}
\]

电流也必须在**同一时间坐标**上插值/外推到 \(t_s^-,t_s^+\)，不得简单拿最近采样点。

---

## 2.2 至少比较三种边沿估计方法

A. 原 `adjacent-edge assignment`  
B. `timestamped linear extrapolation`  
C. `timestamped robust/local polynomial extrapolation`

其中 C 可以采用：

- 二阶局部多项式，或
- robust linear fit（如 Huber/迭代剔除异常点）。

不能为了复杂而复杂；若 B 已经稳定优于 C，可以保留 B 为最终方案。

### 输出

```text
table_edge_estimator_comparison_v2.csv
fig_v2_04_edge_fit_example.png
fig_v2_05_edge_method_timing_tolerance.png
```

---

# 3. C 参数观测彻底避开开关边沿

电容量估计不应依赖边沿相邻样本。

仅在 OFF/ON 的稳定安全子区间计算：

\[
q_k=\int i_C(t)dt
\]

并构造：

\[
\boxed{
y_C=q_k\alpha+\nu_C
}
\]

其中：

\[
\alpha=\frac{1}{C_1}
\]

对应：

\[
\boxed{
H_C=
\begin{bmatrix}
0&q_k&0
\end{bmatrix}
}
\]

要求：

- 积分区间距离两侧边沿都留 guard time；
- 记录实际积分时长；
- 记录有效电荷 \(q_k\)；
- 当 \(|q_k|<q_{min}\) 时不更新 C 参数；
- 不允许因为某一个边沿样本失配导致 C 通道直接崩溃。

---

# 4. 构造 TR-TS-LTVKF：多速率、多观测线性时变滤波

状态仍保持：

\[
x=
\begin{bmatrix}
v_C\\
\alpha\\
r_C
\end{bmatrix},
\qquad
\alpha=1/C_1
\]

基础状态模型：

\[
x_{k+1}=F_kx_k+w_k
\]

稳定区普通端口观测：

\[
y_V=v_T
\]

\[
H_V=
\begin{bmatrix}
1&0&i_C
\end{bmatrix}
\]

容量伪测量：

\[
y_C=q\alpha+\nu_C
\]

\[
H_C=
\begin{bmatrix}
0&q&0
\end{bmatrix}
\]

ESR 边沿伪测量：

\[
y_R=(i_1+i_2)r_C+\nu_R
\]

\[
H_R=
\begin{bmatrix}
0&0&i_1+i_2
\end{bmatrix}
\]

因此概念上：

\[
\boxed{
\mathcal H=
\begin{bmatrix}
1&0&i_C\\
0&q&0\\
0&0&i_1+i_2
\end{bmatrix}
}
\]

但**不要求三类观测同一时刻出现**。

必须实现为 multi-rate / asynchronous measurement update：

1. stable sample 到来 → \(H_V\) update；
2. 一个安全子区间积分完成 → \(H_C\) update；
3. 一个边沿前后窗口拟合完成 → \(H_R\) update。

暂称：

\[
\boxed{
\text{TR-TS-LTVKF}
}
\]

若最终验证失败，不要强行使用这个名称。

---

# 5. 边沿拟合本身必须输出测量方差

不能把 \(R_R\) 当成手工常数。

对前后窗口拟合，使用拟合残差、时间分布及参数协方差估计：

\[
\sigma_{v^-}^2,\qquad \sigma_{v^+}^2
\]

近似：

\[
\boxed{
R_R
=
\sigma_{v^-}^2+\sigma_{v^+}^2
+
R_{R,\mathrm{floor}}
}
\]

若考虑电流外推误差，可进一步加入：

\[
r_C^2\sigma_{i_\Sigma}^2
\]

同样，对容量伪测量建立：

\[
R_C
=
f(
\sigma_v,
\sigma_i,
q,
\Delta t
)
+
R_{C,\mathrm{floor}}
\]

### 目标

协方差应由测量噪声/拟合质量驱动，而不是对不同工况人工单独调参。

---

# 6. TS-LTVKF 协方差设计必须做成“训练后锁定”，不能逐工况调参

第一次结果显示固定且过小的 \(R\) 在高占空比工况会严重失效，而自适应/下限版本恢复正常。

v2 必须建立统一规则。

## 6.1 建议方法

使用：

- nominal training set；
- high-D training set；
- noisy training set；

仅用于确定：

- \(Q\)；
- \(R_{V,\mathrm{floor}}\)；
- \(R_{C,\mathrm{floor}}\)；
- \(R_{R,\mathrm{floor}}\)；
- NIS gate；
- parameter update gate。

确定后**锁定全部超参数**。

然后在剩余工况 blind test。

禁止：

> 每一个 Vin/D/load 单独重新调 Q/R。

---

## 6.2 NIS 一致性

每类观测分别记录 normalized innovation squared：

\[
NIS_k=
e_k^TS_k^{-1}e_k
\]

报告：

- mean；
- median；
- 95th percentile；
- rejected fraction；
- 每类 measurement 的 gate rate。

输出：

```text
table_covariance_consistency_v2.csv
fig_v2_06_NIS_consistency.png
```

---

# 7. 独立时间误差模型：不要再只用一个统一 PWM offset

真实硬件更可能存在以下不同误差：

\[
\tau_v,\quad\tau_{i1},\quad\tau_{i2}
\]

分别为三通道固定延迟。

同时还要区分：

- common PWM timestamp offset \(\tau_{PWM}\)；
- inter-channel skew；
- random jitter；
- ADC sample-and-hold aperture；
- analog front-end group delay。

因此必须把时间误差拆开。

---

# 8. 固定通道延迟专项

分别测试：

\[
\tau_v,\tau_{i1},\tau_{i2}
\in
[-1000,-500,-200,-100,-50,-20,0,20,50,100,200,500,1000]\text{ ns}
\]

不要做完整 \(13^3\) 全网格。

至少做：

### Single-channel sweep

每次只改变一个通道。

### Pairwise worst-case sweep

例如：

\[
\tau_v=+\tau,\quad \tau_i=-\tau
\]

### 随机/LHS 组合

至少 100 组：

\[
(\tau_v,\tau_{i1},\tau_{i2})
\]

在 ±1 µs 范围均匀或 Latin Hypercube 抽样。

比较：

- v1 adjacent；
- v2 linear extrapolation；
- v2 robust/polynomial；
- TR-TS-LTVKF。

输出：

```text
table_channel_delay_v2.csv
fig_v2_07_delay_single_channel.png
fig_v2_08_delay_pair_heatmap.png
```

---

# 9. 随机 jitter 测试

对每次 ADC 采样加入独立或相关随机 jitter。

RMS：

\[
\sigma_t=
[0,5,10,20,50,100,200,500]\text{ ns}
\]

至少 50 个随机种子。

分别测试：

1. common-clock jitter；
2. voltage/current independent jitter；
3. PWM timestamp jitter。

输出：

- C median / 95th MAPE；
- ESR median / 95th MAPE；
- failure rate；
- edge fit rejection rate。

```text
table_jitter_v2.csv
fig_v2_09_error_vs_jitter.png
```

---

# 10. 边沿窗口设计扫描

不能只给一种窗口。

扫描：

### Guard time

\[
\tau_g=
[0.1,0.2,0.5,1.0,1.5,2.0]\ \mu s
\]

如果振铃持续时间更长，自动扩展范围。

### Window width

\[
W=
[0.5,1.0,1.5,2.0,3.0]\ \mu s
\]

### Points per side

\[
N_w=
[3,4,6,8]
\]

评价：

- ESR MAPE；
- fit residual；
- extrapolation variance；
- latency；
- available samples/cycle。

目标不是找到单个“最优点”，而是找到一个**宽容工作区域**。

输出：

```text
table_edge_window_design_v2.csv
fig_v2_10_edge_window_robust_region.png
```

---

# 11. ESL + timing error 联合测试

第一次已经证明：

- naive peak 在 20 nH 时约 659% ESR MAPE；
- linear extrapolation 在 20 nH 时约 1.16%。

v2 必须进一步联合：

\[
L_{ESL}=
[0,5,10,20,50]\text{ nH}
\]

和固定时间偏移：

\[
|\tau|=
[0,50,100,200,500,1000]\text{ ns}
\]

以及 jitter：

\[
\sigma_t=
[0,20,50,100]\text{ ns}
\]

不要求全部笛卡尔积，可做分层 DOE。

至少包含以下压力点：

### Stress A

\[
L_{ESL}=20nH,\quad
|\tau|=200ns,\quad
\sigma_t=20ns
\]

### Stress B

\[
L_{ESL}=20nH,\quad
|\tau|=500ns,\quad
\sigma_t=50ns
\]

### Stress C

\[
L_{ESL}=50nH,\quad
|\tau|=500ns,\quad
\sigma_t=100ns
\]

Model A 可做全部；Model B 至少做 nominal + A + B。

输出：

```text
table_esl_timing_joint_v2.csv
fig_v2_11_esl_timing_joint.png
```

---

# 12. 模拟前端带宽与群延迟

真实 `vT`、`i1`、`i2` 都会经过模拟前端。

至少为每个通道加入一阶或二阶低通模型。

测试截止频率：

\[
f_c=
[100k,250k,500k,1M,2M]\text{ Hz}
\]

并记录每个通道的：

- magnitude attenuation；
- group delay at \(f_s\)；
- group delay around switching edge frequency content。

测试：

### matched front-end

三通道相同滤波器。

### mismatched front-end

电压与电流通道截止频率不同。

重点回答：

> 只做数字时间戳补偿是否足够，还是必须对模拟前端群延迟做标定/反卷积？

输出：

```text
table_frontend_delay_v2.csv
fig_v2_12_frontend_bandwidth.png
```

---

# 13. ADC 位数、samples/cycle 与 sampling phase 必须彻底解耦

第一次结果具有明显非单调性，所以不能再只比较“8/16/32 points”。

## 13.1 ADC 位数

\[
bits=[12,14,16]
\]

保留原量程：

- voltage 0–100 V；
- current ±5 A；

同时报告 LSB。

---

## 13.2 samples/cycle

\[
N_s=[8,12,16,24,32]
\]

---

## 13.3 sampling phase

对每一个 bits × \(N_s\) 组合，把整个 ADC 采样栅格相对于 PWM 平移：

\[
\phi=
0,\frac{1}{16},\frac{2}{16},\ldots,\frac{15}{16}
\]

个 sampling interval。

即必须测试至少 16 个 phase，而不是只测试一个默认相位。

比较：

- old TS-LTVKF；
- TR-TS-LTVKF。

统计：

- median MAPE；
- worst-case MAPE；
- 95th percentile；
- pass fraction。

定义通过：

\[
C\ MAPE<3\%
\]

\[
ESR\ MAPE<5\%
\]

### 最终不允许只说

“16-bit/16 points 首次通过”。

必须回答：

> 在随机/未知 sampling phase 下，哪一种配置具有 ≥95% 的通过率？

输出：

```text
table_adc_phase_sweep_v2.csv
fig_v2_13_adc_phase_passrate.png
fig_v2_14_error_vs_sampling_phase.png
```

---

# 14. 噪声测试改成绝对噪声单位

SNR 仍可保留用于和 v1 对比，但 v2 的主要结果必须使用：

\[
\sigma_v\text{ [mV RMS]}
\]

\[
\sigma_i\text{ [mA RMS]}
\]

建议：

\[
\sigma_v=
[0.5,1,2,5,10,20,50]\text{ mV}
\]

\[
\sigma_i=
[0.1,0.5,1,2,5,10,20]\text{ mA}
\]

不要全部笛卡尔积，可选匹配等级和几个交叉压力点。

必须把：

- ADC quantization；
- analog noise；
- timing jitter；

分开后再做联合测试。

输出：

```text
table_absolute_noise_v2.csv
fig_v2_15_absolute_noise.png
```

---

# 15. 归一化 LTV 可观测性重新计算

第一次的：

\[
x=
[v_C,\alpha,r_C]^T
\]

数值尺度差别很大，原始 `cond(O)` 不能直接作物理解释。

定义 base values：

\[
V_b=V_{C,\mathrm{nom}}
\]

\[
\alpha_b=1/C_{\mathrm{nom}}
\]

\[
r_b=r_{\mathrm{nom}}
\]

设：

\[
x=S\bar x
\]

其中：

\[
S=
\mathrm{diag}(V_b,\alpha_b,r_b)
\]

则：

\[
\bar F_k=S^{-1}F_kS
\]

\[
\bar H_k=H_kS
\]

重新构造：

\[
\bar{\mathcal O}_{k,N}
\]

计算：

- rank；
- singular values；
- condition number；
- minimum singular value。

至少：

\[
N=3,5,10,20
\]

---

# 16. 噪声加权 Observability Gramian / Fisher Information

除 rank 外，再计算噪声加权信息：

\[
W_o
=
\sum_j
\Phi_{j,k}^T
H_j^T
R_j^{-1}
H_j
\Phi_{j,k}
\]

使用归一化坐标。

报告：

\[
\lambda_{\min}(W_o)
\]

\[
\lambda_{\max}(W_o)
\]

\[
\kappa(W_o)
\]

并分别给：

- stable-only observations；
- + C pseudo measurement；
- + ESR pseudo measurement；
- 完整 TR-TS-LTVKF。

这个实验应直接回答：

> C pseudo 和 ESR pseudo 是否真正改善了两个健康参数方向的信息量？

输出：

```text
table_observability_normalized_v2.csv
fig_v2_16_observability_normalized.png
fig_v2_17_information_gain_by_measurement.png
```

---

# 17. 回归验证：改进不能破坏第一次已经通过的结果

v2 新算法完成后，必须重新跑第一次 **51 个 CCM 工况**。

不需要重新把 24 个 DCM 工况算成成功，但要保留 DCM detection/freeze。

使用**同一套锁定参数**。

统计：

- C median / max MAPE；
- ESR median / max MAPE；
- convergence；
- NIS；
- gate rate。

至少不应明显差于第一次：

第一次 TS-LTVKF 最大值约：

\[
C=0.2021\%
\]

\[
ESR=1.1263\%
\]

v2 不要求必须比这个极低误差更低，重点是：

> 在引入 timing-robust 机制后，多工况精度不能换来明显的基础性能退化。

---

# 18. 重点复测第一次 KF 最差协方差工况

必须单独复测：

\[
V_{in}=28.8V,\quad
D=0.65,\quad
25\%\ load
\]

第一次固定过小协方差曾产生严重错误。

对比：

1. fixed-small R；
2. v1 adaptive/floor；
3. v2 measurement-derived covariance + floor + NIS gate。

必须给完整：

- innovation；
- NIS；
- covariance；
- parameter trace。

输出：

```text
fig_v2_18_worst_covariance_case.png
```

---

# 19. DCM 只做检测/冻结，不在本轮重新推导

本轮不扩展 DCM 参数模型。

进入 DCM 时：

- 标记 mode；
- 停止 C/ESR health update；
- 允许内部必要状态传播；
- 重新进入稳定 CCM 后，等待 observability/charge gate 满足再恢复。

测试至少一个：

\[
CCM\rightarrow DCM\rightarrow CCM
\]

负载过程。

验证：

- 参数不在 DCM 内漂移；
- 恢复 CCM 后能够重新收敛。

输出：

```text
fig_v2_19_ccm_dcm_freeze_resume.png
```

---

# 20. 建议的硬件可实现性目标，不作为强迫通过条件

为了判断是否值得进入实物，设置三个等级：

## Minimum

在 nominal CCM、16-bit、合理前端带宽下：

\[
|\tau_{\mathrm{channel}}|\le100ns
\]

且：

\[
\sigma_t\le20ns
\]

时满足：

\[
C<3\%,\quad ESR<5\%
\]

## Preferred

\[
|\tau_{\mathrm{channel}}|\le200ns
\]

\[
\sigma_t\le50ns
\]

仍满足：

\[
C<3\%,\quad ESR<5\%
\]

## Stretch

\[
|\tau_{\mathrm{channel}}|\le500ns
\]

仍大部分工况通过。

如果只达到 Minimum，也可以进入硬件；如果连 Minimum 都达不到，应重新设计测量结构。

---

# 21. v2 关键判定 Gates

## Gate A — 断崖来源

必须解释 v1 的 20 ns cliff。

PASS 条件：

- 能明确关联到样本状态归属/观测构造；
- 或找到其他确定、可复现实质原因。

不允许继续把“<20 ns”当成未经解释的硬件结论。

---

## Gate B — timing robustness

TR-TS-LTVKF 的误差随时间偏移应表现为**可解释、相对连续**的变化。

若仍然出现：

\[
0\rightarrow20ns
\]

这种无物理解释的瞬时饱和断崖，则 FAIL。

---

## Gate C — parameter projection transparency

所有失败工况都必须同时保存：

- pre-projection estimate；
- post-projection estimate。

不得让 90%、300% 等限幅误差掩盖真实发散程度。

---

## Gate D — normalized observability

必须报告：

\[
\operatorname{rank}(\bar O)
\]

以及：

\[
\kappa(\bar O),\quad
\lambda_{\min}(W_o)
\]

不能再只用未经归一化的 `cond(O)` 判断可观测性。

---

## Gate E — phase-independent ADC conclusion

必须基于 phase sweep 的 pass rate，而不是一个采样相位的单点结果给 ADC 要求。

---

## Gate F — covariance generalization

Q/R/thresholds 在训练集确定后锁定。

blind CCM test 不允许逐工况人工再调。

---

## Gate G — Model B cross-check

改进边沿外推 + timing robustness 至少在 Simscape Model B 上验证：

- nominal；
- 200 ns delay；
- ESL=20 nH + 200 ns；
- ESL=20 nH + 500 ns（如果计算允许）。

---

# 22. 强制输出的新表格

至少：

```text
table_v1_edge_assignment_diagnostics.csv
table_edge_estimator_comparison_v2.csv
table_channel_delay_v2.csv
table_jitter_v2.csv
table_edge_window_design_v2.csv
table_esl_timing_joint_v2.csv
table_frontend_delay_v2.csv
table_adc_phase_sweep_v2.csv
table_absolute_noise_v2.csv
table_observability_normalized_v2.csv
table_covariance_consistency_v2.csv
table_v2_operating_regression.csv
result_metrics_v2.csv
```

---

# 23. result_metrics_v2.csv 必须增加的字段

除 v1 字段外至少增加：

```text
algorithm_version
edge_method
pre_projection_C
pre_projection_ESR
post_projection_C
post_projection_ESR
sample_phase_fraction
common_pwm_offset_ns
voltage_delay_ns
i1_delay_ns
i2_delay_ns
jitter_rms_ns
adc_aperture_ns
voltage_frontend_fc_Hz
i1_frontend_fc_Hz
i2_frontend_fc_Hz
edge_guard_us
edge_window_us
edge_points_per_side
edge_fit_order
edge_fit_rmse_V
edge_fit_variance_V2
R_V
R_C
R_R
NIS_V
NIS_C
NIS_R
gate_V
gate_C
gate_R
rank_Obs_normalized
cond_Obs_normalized
min_sv_Obs_normalized
info_min_eig
info_cond
```

---

# 24. 强制输出的新图

至少：

1. `fig_v2_01_old_method_cliff`
2. `fig_v2_02_sample_index_transition`
3. `fig_v2_03_pre_projection_vs_projection`
4. `fig_v2_04_edge_fit_example`
5. `fig_v2_05_edge_method_timing_tolerance`
6. `fig_v2_06_NIS_consistency`
7. `fig_v2_07_delay_single_channel`
8. `fig_v2_08_delay_pair_heatmap`
9. `fig_v2_09_error_vs_jitter`
10. `fig_v2_10_edge_window_robust_region`
11. `fig_v2_11_esl_timing_joint`
12. `fig_v2_12_frontend_bandwidth`
13. `fig_v2_13_adc_phase_passrate`
14. `fig_v2_14_error_vs_sampling_phase`
15. `fig_v2_15_absolute_noise`
16. `fig_v2_16_observability_normalized`
17. `fig_v2_17_information_gain_by_measurement`
18. `fig_v2_18_worst_covariance_case`
19. `fig_v2_19_ccm_dcm_freeze_resume`
20. `fig_v2_20_v1_vs_v2_summary`

所有图必须：

- 标注单位；
- 标注真实参数；
- 标注算法版本；
- 图注中写清 Model A/Model B；
- 失败值不得裁掉；
- 如有 projection saturation，用不同符号显式标记。

---

# 25. V1_V2_COMPARISON.md 固定结构

必须回答：

## 1. v1 的 20 ns cliff 到底是什么？

只能选择并论证：

- physical timing limit；
- sample association artifact；
- parameter projection artifact；
- combination；
- unresolved。

## 2. v2 是否消除了 cliff？

给定量曲线。

## 3. 真正可支持的 timing tolerance 是多少？

分别给：

- common offset；
- channel skew；
- jitter；
- analog group delay。

## 4. ADC 最低要求是否改变？

不再给单点；给 ≥95% phase pass rate 的配置。

## 5. ESL + timing 联合下是否仍可估计 ESR？

## 6. 归一化后的可观测性最差工况是什么？

## 7. C pseudo / ESR pseudo 各自增加多少信息？

## 8. 协方差机制是否实现跨工况泛化？

## 9. v2 是否值得替代 v1 算法？

## 10. 论文主张应该如何更新？

---

# 26. RESULT_V2_FOR_CHATGPT.md 固定结构

## 1. Executive Result

等级：

- A — hardware-oriented simulation strongly supported
- B — supported with manageable constraints
- C — partially supported
- D — impractical timing/sensing burden
- F — theory/estimator contradicted

## 2. Baseline Cliff Diagnosis

## 3. Timestamped Edge Extrapolation

## 4. TR-TS-LTVKF Formulation Used

列出最终实际实现的：

\[
F_k,\ H_V,\ H_C,\ H_R
\]

## 5. Timing Tolerance

## 6. Channel Delay / Jitter

## 7. ESL + Timing

## 8. ADC / Sampling Phase

## 9. Absolute Noise

## 10. Normalized Observability

## 11. Information Matrix

## 12. Covariance / NIS Consistency

## 13. 51-CCM Regression

## 14. Model B Cross-Validation

## 15. Remaining Failure Cases

## 16. Scientific Assessment

必须明确回答：

1. v1 的 20 ns 是不是物理极限？
2. 新方法是否真正放宽硬件时序要求？
3. edge extrapolation 是否应该成为正式论文方法的一部分？
4. `rank(O)=3` 之外，归一化信息量是否足以支持联合参数估计？
5. 当前 ADC 要求是什么，置信度如何？
6. TS-LTVKF 是否仍应作为主算法？
7. 是否可以进入实物实验？
8. 论文创新主句应该怎样改写？
9. 哪一条主张仍然证据不足？

## 17. Recommended Hardware Experiment

必须给出：

- ADC bits；
- voltage range；
- current range；
- minimum sampling rate；
- recommended PWM-trigger strategy；
- front-end bandwidth；
- timing calibration；
- required measured channels；
- edge window；
- whether simultaneous-sampling ADC is preferred。

## 18. File Index

---

# 27. Codex 停止条件

只有以下全部完成，任务才可结束：

- [ ] v1 20 ns cliff 被复现
- [ ] cliff 的 sample index / projection 机制被诊断
- [ ] timestamped edge extrapolation 已实现
- [ ] C safe-window charge measurement 已实现
- [ ] TR-TS-LTVKF 已实现
- [ ] edge-fit-derived covariance 已实现
- [ ] Q/R 训练后锁定机制完成
- [ ] fixed channel delay sweep 完成
- [ ] jitter Monte Carlo 完成
- [ ] edge window sweep 完成
- [ ] ESL + timing 联合完成
- [ ] analog front-end delay 完成
- [ ] ADC × samples/cycle × phase 完成
- [ ] absolute noise test 完成
- [ ] normalized observability 完成
- [ ] noise-weighted information matrix 完成
- [ ] 51 CCM regression 完成
- [ ] worst covariance case 完成
- [ ] CCM→DCM→CCM freeze/resume 完成
- [ ] Model B 关键压力点交叉验证完成
- [ ] V1_V2_COMPARISON.md 完成
- [ ] RESULT_V2_FOR_CHATGPT.md 完成
- [ ] result_metrics_v2.csv 完成

若某项 BLOCKED：

- 标记 BLOCKED；
- 写明工具/模型/运行时原因；
- 不得假装 PASS；
- 继续完成其余任务。

---

# 28. Codex 最终执行指令

**本任务不是重新证明第一轮已经通过的 Ćuk C–ESR 理论，而是专门攻击第一次暴露出的工程薄弱点。首先复现并解释 20 ns 同步断崖；然后删除对相邻边沿样本的依赖，改为使用真实时间戳的边沿前后窗口拟合/外推，将 ESR 形成独立伪测量，将 C 由远离边沿的电荷积分形成独立伪测量，并以 multi-rate LTV Kalman Filter 融合。所有时序结论必须在独立通道延迟、随机 jitter、模拟前端群延迟、ADC 相位与 ESL 联合测试后给出。不得使用参数投影后的 90%/300% 饱和值掩盖真实发散；必须保存投影前结果。可观测性必须重新做状态尺度归一化并计算噪声加权信息矩阵。Q/R 只能在训练集确定一次，然后锁定用于 blind CCM 验证。**

---

## 版本信息

- Version: **v2.0**
- Date: **2026-08-21**
- Purpose: Complete and strengthen the first Cuk capacitor-health verification by resolving timing-cliff artifacts, introducing timestamped edge extrapolation, normalized observability, measurement-derived covariance, and hardware-oriented timing/noise validation.
