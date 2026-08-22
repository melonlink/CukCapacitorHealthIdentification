# Codex 执行任务 v2.2
# Ćuk 能量传递电容 C–ESR 健康辨识：DSP 片内 ADC 优先验证与外置 ADC 决策

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **版本**：v2.2 — Native DSP ADC Feasibility and ADC Architecture Decision  
> **前置结果**：verification_v1 / v2 / v2.1  
> **最终算法候选**：TS-SLTVKE  
> **核心原则**：**不预设必须使用 16-bit 外置 ADC。优先验证目标 DSP 片内 ADC。只有在经过量程优化、模拟前端优化、PWM 同步、多周期统计和通道校准后仍不能满足 C/ESR 精度与置信度要求，才判定需要外接高分辨率 ADC。**

---

# 0. 为什么修改硬件采样假设

v2.1 已经关闭以下问题：

1. 0.8 MS/s + 2 µs edge window + 3 points/side 在几何上不可行；
2. 1.6 MS/s 是当前 2 µs window、3 points/side 的测试几何下限候选；
3. 5 MS/s 是此前基于 16-bit 外置/理想高性能 ADC 假设给出的科研台架推荐；
4. TS-SLTVKE 已不再依赖边沿相邻样本，而采用 timestamped window extrapolation；
5. 真实参数变化很慢，C 和 ESR 不需要每一个 PWM 周期都独立得到最终健康结论。

因此：

\[
\boxed{
\text{ADC nominal resolution}
}
\]

不能单独作为“必须 16-bit”的依据。

真正决定能否使用 DSP 片内 ADC 的因素是：

\[
\boxed{
\text{effective resolution}
+
\text{analog scaling}
+
\text{sample rate}
+
\text{synchronization}
+
\text{multi-cycle information}
}
\]

本轮必须重新验证。

---

# 1. 不再默认 ADC=16 bit

本轮禁止写死：

```text
ADC = 16 bit external
```

改成三条候选路径：

## Path A — DSP Native High-Speed ADC

优先使用 DSP 片内高速 ADC 模式。

典型可能是：

\[
12\text{-bit}
\]

但必须以**实际目标 DSP datasheet**为准。

---

## Path B — DSP Native High-Resolution ADC

如果目标 DSP 支持：

\[
14/16\text{-bit}
\]

片内 ADC，测试其最高有效采样率是否满足采样几何和算法要求。

---

## Path C — External ADC

只有 A/B 在优化后仍失败，才进入外置 ADC。

外置 ADC 不默认一定是 16-bit；根据最终误差预算决定：

- 14-bit；
- 16-bit；
- simultaneous SAR；
- 采样率。

最终必须从验证结果反推规格。

---

# 2. 第一步：确认目标 DSP 的真实 ADC 能力

Codex 首先检查项目源代码、硬件配置、README、器件型号定义。

输出：

```text
TARGET_DSP_ADC_PROFILE.md
```

至少记录：

```text
DSP part number
number of ADC modules
resolution modes
max sample rate per mode
single-ended/differential capability
number of SOCs
PWM trigger capability
simultaneous/concurrent conversion capability
acquisition window
conversion latency
input reference
ADC input range
INL
DNL
SNR/SINAD
ENOB if specified
offset error
gain error
reference requirements
channel-to-channel skew
```

如果项目中**没有明确目标 DSP 型号**：

1. 不允许自行假装已有型号；
2. 建立参数化 ADC profile；
3. 至少建立以下参考模式用于算法决策，不宣称是最终芯片规格：

```text
native_12bit_highspeed:
    bits = 12
    fs_adc = 3.5 or 4 MS/s

native_16bit_slow:
    bits = 16
    fs_adc = 1.0–1.1 MS/s
```

并在最终报告标记：

```text
TARGET_DSP_NOT_FIXED
```

---

# 3. 必须区分 resolution 与 ENOB

禁止直接认为：

\[
12\text{-bit ADC}\Rightarrow12\text{-bit effective}
\]

实际仿真至少采用：

\[
ENOB=
[9.5,10,10.5,11,11.5,12]
\]

作为 native 12-bit sensitivity sweep。

若 datasheet 已提供 SINAD：

\[
ENOB=\frac{SINAD-1.76}{6.02}
\]

按 datasheet 转换。

对于片内 16-bit ADC，也必须根据实际 ENOB/SINAD 建模，而不是按理想 16 bit。

---

# 4. 重新建立实际健康特征幅值预算

使用全部代表性 CCM 工况计算：

\[
\Delta V_{ESR}
=
r_C(i_1+i_2)
\]

以及 C safe-window：

\[
\Delta V_C
=
\frac{Q}{C}
\]

覆盖：

\[
C/C_0=[0.8,0.9,1.0]
\]

\[
ESR/ESR_0=[1,1.5,2]
\]

以及：

- low CCM margin；
- nominal；
- high load；
- high D。

输出：

```text
table_health_signal_budget_v22.csv
```

字段至少：

```text
Vin
D
load
C
ESR
i1
i2
I_sum
edge_ESR_signal_mV
charge_C_signal_mV
```

必须给：

- min；
- median；
- max；

的 ESR 和 C 有效健康信号幅值。

---

# 5. 不再固定 current full scale = 40 A

v2.1 报告中出现了 40 A current full scale，但当前项目代表性电流明显远低于该值。

本轮必须重新推导实际 current ADC range。

从所有正常 + 动态 CCM 仿真提取：

\[
I_{1,\max}
\]

\[
I_{2,\max}
\]

再加入：

\[
M_I=
[1.25,1.5,2.0]
\]

的 transient margin。

候选满量程：

\[
I_{FS}
=
M_I\cdot\max(I_{1,\max},I_{2,\max})
\]

取工程可实现标准档。

不得为了避免饱和直接把量程放大到导致 ADC 利用率极低。

输出：

```text
table_current_range_design_v22.csv
```

---

# 6. 电压测量必须比较三种模拟前端架构

这是判断片内 12-bit ADC 是否可用的核心。

---

## Architecture V1 — 单通道宽量程 vT

例如：

\[
v_T:0\sim100V
\]

线性压缩到 DSP ADC full scale。

优点：

- 最简单。

缺点：

- ESR edge 可能只占很少 ADC code。

必须作为 baseline。

---

## Architecture V2 — 双量程电压测量

使用两个 DSP ADC 通道：

### Vabs

测量：

- 绝对 \(v_T\)；
- 较宽量程；
- 用于内部状态和 C safe-window。

### Vedge / Vripple

采用：

- level shift；
- AC coupling；
- high-pass / band-limited ripple extraction；
- instrumentation/differential gain；

把：

\[
\Delta V_{ESR}
\]

放大后映射到大部分 ADC 动态范围。

该通道只服务：

\[
z_R
\]

不要求承受完整 0–100 V DC 动态范围。

必须保证：

- DC blocking / level shift 的模型明确；
- 不破坏 edge extrapolation；
- transfer function 可标定；
- 不产生不可恢复饱和。

---

## Architecture V3 — level-shifted single precision window

如果实际：

\[
v_T
\]

在目标应用的工作范围窄于 0–100 V，测试通过偏置/level-shift 把真实工作区映射到 ADC 全量程。

若超出工作区则进入保护/降级，不要求单一通道覆盖理论无限范围。

---

# 7. 定义 ADC code utilization

对于每种前端计算：

\[
LSB_{plant}
=
\frac{V_{plant,FS}}{2^{N}}
\]

有效 ESR code 数：

\[
\boxed{
N_{code,R}
=
\frac{\Delta V_{ESR}}{LSB_{plant}}
}
\]

C-window code：

\[
\boxed{
N_{code,C}
=
\frac{\Delta V_C}{LSB_{plant}}
}
\]

报告最差工况：

- ESR edge codes；
- C charge-window codes；
- RMS noise codes。

不要先规定必须多少 code。

让 Monte Carlo 结果决定最低 code utilization，但将：

\[
N_{code}<4
\]

标记为明显高风险；

\[
4\le N_{code}<16
\]

标记为 quantization-sensitive；

\[
N_{code}\ge16
\]

标记为 candidate。

最终通过实际 MAPE/NEES 判定，而不是只靠该经验标签。

---

# 8. 片内 ADC 采样速度优先按真实 DSP 模式验证

至少测试：

```text
1.0 MS/s
1.1 MS/s
1.6 MS/s
2.0 MS/s
3.0 MS/s
3.5 MS/s
4.0 MS/s
5.0 MS/s
```

其中：

- 1.0/1.1：代表某些片内高分辨率模式；
- 3.5/4：代表常见片内高速 12-bit 模式；
- 5：保留外置高性能方案对照。

必须先执行 sampling geometry gate。

如果某模式：

\[
f_{ADC}
\]

无法提供所需窗口点数，不允许因为“位数高”就判定为更优。

---

# 9. edge window 允许随 native ADC 重新设计

不强迫所有 ADC 使用：

\[
W=2\mu s
\]

但必须满足：

1. 足够点数；
2. 不进入邻接开关状态；
3. linear extrapolation bias 可接受；
4. AFE 动态允许；
5. Model B edge waveform 支持。

对每个 native ADC rate 自动优化：

\[
g,\ W,\ N_w
\]

但优化范围必须预先固定，不允许逐测试工况秘密调参。

候选：

\[
g=[0.2,0.5,0.8,1.0]\mu s
\]

\[
W=[1.5,2,2.5,3,4,5]\mu s
\]

\[
N_w=[3,4,5,6,8]
\]

最终为每个 ADC mode 锁定一套参数。

---

# 10. 使用 PWM 硬件触发，不按随机 sampling phase 作为主模式

如果目标 DSP ADC 支持 ePWM/SOC 硬件触发：

\[
\boxed{
\text{designed synchronous phase}
}
\]

应作为**主实现方式**。

同时保留 phase perturbation 测试：

\[
\Delta\phi
\]

模拟：

- trigger delay；
- clock mismatch；
- jitter；
- calibration residual。

不要把“随机未知相位”作为片内 ADC 的默认场景，因为片内 ADC 与 PWM 通常可以由同一时钟/事件触发。

但必须验证触发后的残余误差。

---

# 11. 多 ADC 模块并行采样能力必须利用

如果 DSP 具有多个独立 ADC module：

优先将：

- \(v_T\) / Vabs；
- Vedge；
- \(i_1\)；
- \(i_2\)；

分配到不同 ADC module，以减少：

- MUX settling；
- sequential skew；
- input charge kickback；
- conversion latency mismatch。

Codex 必须根据目标 DSP profile 建立：

```text
ADC channel/module assignment proposal
```

并仿真实际 channel skew。

---

# 12. 多周期健康估计必须正式进入验证

C 与 ESR 的真实老化时间尺度远慢于：

\[
T_s
\]

因此不要求单周期达到最终健康精度。

测试 coherent / timestamp-aware multi-cycle fusion：

\[
N_{cycle}
=
[1,4,16,64,256,1024]
\]

对于每个 PWM 周期生成：

\[
\hat z_R
\]

和：

\[
\hat z_C
\]

然后通过：

- Kalman sequential accumulation；
- weighted batch average；
- robust median/trimmed mean 对照；

进行慢健康更新。

---

# 13. 不允许假设量化误差可以理想 sqrt(N) 消失

真实同步采样中 quantization error 可能与 PWM 周期相关。

因此 Monte Carlo 必须分别包含：

## Case Q1 — deterministic quantization

无额外 analog noise。

## Case Q2 — natural analog noise

例如：

\[
0.25,\ 0.5,\ 1,\ 2,\ 5,\ 10mV RMS
\]

形成自然 dither。

## Case Q3 — ADC offset/gain/INL/DNL

按照目标 DSP datasheet，若未知则使用参数化 sweep。

必须判断：

> multi-cycle accumulation 是真正增加有效信息，还是只重复同一个量化 code。

---

# 14. 片内 ADC 非理想性模型

至少包括：

- quantization；
- ENOB/noise；
- ADC offset；
- gain error；
- INL；
- DNL；
- reference noise；
- channel skew；
- aperture jitter；
- acquisition settling；
- finite source impedance；
- AFE group delay。

如果 datasheet 没有具体某项：

标记：

```text
DATASHEET_NOT_SPECIFIED
```

做合理 sensitivity sweep，但不得冒充器件实测值。

---

# 15. 片内 ADC 校准策略

测试以下校准层级：

## Cal 0

无校准。

## Cal 1

offset + gain calibration。

## Cal 2

offset + gain + channel timing calibration。

## Cal 3

Cal 2 + AFE transfer/gain correction \(k_R\)。

必须判断最低需要哪个等级。

---

# 16. kR 必须在 DSP native ADC 场景重新核对

对 edge measurement：

\[
z_R
=
k_RI_\Sigma r_C+\nu_R
\]

测试：

\[
k_R(D,P,ESR,C,AFE,\text{ADC mode})
\]

覆盖：

\[
D=[0.3,0.4,0.55,0.65]
\]

load：

low CCM / nominal / high

ESR：

\[
1,\ 1.5,\ 2\times
\]

AFE 元件容差：

\[
\pm1\%,\ \pm5\%
\]

目标：

- 判断 \(k_R\) 是否可一次标定；
- 或需要温度/工况补偿；
- 或双量程 Vedge 架构能否让 \(k_R\) 更稳定。

---

# 17. 核心比较矩阵

最终至少比较：

| ADC architecture | bits/mode | fs_ADC | voltage architecture | current range | multi-cycle | result |
|---|---:|---:|---|---|---:|---|
| Native wide-range | native | native | V1 | optimized | 1…1024 | |
| Native dual-range | native | native | V2 | optimized | 1…1024 | |
| Native level-shift | native | native | V3 | optimized | 1…1024 | |
| Native high-resolution | native HR | native HR | best | optimized | | |
| External reference | 16-bit | 5 MS/s | best | optimized | | |

外置 16-bit 只作为 reference/control，不能默认获胜。

---

# 18. 必须重新验证 C/ESR accuracy

每个 ADC architecture 至少测试：

\[
C/C_0=[0.8,0.9,1.0]
\]

\[
ESR/ESR_0=[1,1.5,2]
\]

代表性 CCM：

- low margin；
- nominal；
- high load；
- high D。

输出：

- C MAPE；
- ESR MAPE；
- bias；
- variance；
- NIS；
- NEES；
- CI coverage；
- convergence cycles；
- number of accepted edge updates。

---

# 19. DSP native ADC 的 PASS 标准

## Accuracy

\[
MAPE_C<3\%
\]

\[
MAPE_{ESR}<5\%
\]

---

## Robustness

至少：

\[
95\%
\]

代表性 blind cases 通过。

---

## Timing

使用 PWM hardware trigger 后：

\[
|\Delta t_{residual}|
\]

达到 v2.1 最差工况要求。

优先目标：

\[
\le50ns
\]

如果目标 DSP 硬件结构能天然更好，记录实际能力。

---

## Statistical confidence

不得在 nominal 通过、ESR=2× 全部失真。

如果 CI 仍不完全校准，可以：

- point estimate PASS；
- confidence PARTIAL；

但必须明确。

---

# 20. 何时才判定“必须外接 16-bit ADC”

只有以下流程全部完成后：

### Step 1

native ADC + wide-range AFE FAIL。

### Step 2

native ADC + optimized range FAIL。

### Step 3

native ADC + dual-range/high-gain edge channel FAIL。

### Step 4

native ADC + PWM synchronous trigger FAIL。

### Step 5

native ADC + multi-cycle accumulation FAIL。

### Step 6

native ADC + offset/gain/timing calibration FAIL。

并且失败是：

\[
\boxed{
\text{ADC information/resolution limitation}
}
\]

而不是：

- 模型失配；
- AFE 不合理；
- 边沿窗口错误；
- 时序未校准。

此时才能输出：

\[
\boxed{
\text{EXTERNAL ADC REQUIRED}
}
\]

---

# 21. 外置 ADC 决策不能只写 16-bit

如果 native FAIL，进一步通过仿真反推：

\[
N_{bit,min}
\]

\[
f_{ADC,min}
\]

\[
ENOB_{min}
\]

\[
simultaneous\ channels
\]

\[
aperture/jitter
\]

例如最终可能是：

```text
14-bit / 5 MS/s sufficient
```

也可能是：

```text
16-bit / 2 MS/s sufficient
```

或者：

```text
16-bit / 5 MS/s required
```

必须由数据决定。

---

# 22. 强制输出结论类型

`DSP_ADC_DECISION.md` 最终只能选择：

## A

```text
NATIVE_ADC_SUFFICIENT
```

并给推荐配置。

## B

```text
NATIVE_ADC_SUFFICIENT_WITH_DUAL_RANGE_AFE
```

## C

```text
NATIVE_HIGH_RESOLUTION_MODE_REQUIRED
```

## D

```text
EXTERNAL_ADC_REQUIRED
```

## E

```text
UNRESOLVED
```

不能只写“建议用 16 bit 更保险”。

---

# 23. 强制表格

至少输出：

```text
table_target_dsp_adc_profile_v22.csv
table_health_signal_budget_v22.csv
table_current_range_design_v22.csv
table_adc_code_utilization_v22.csv
table_native_adc_geometry_v22.csv
table_native_adc_nonideal_v22.csv
table_multicycle_gain_v22.csv
table_voltage_architecture_v22.csv
table_kR_robustness_v22.csv
table_native_vs_external_v22.csv
table_health_blind_adc_v22.csv
result_metrics_v22.csv
```

---

# 24. 强制图

至少：

```text
fig_v22_01_health_signal_amplitude.png
fig_v22_02_adc_code_utilization.png
fig_v22_03_native_adc_sampling_geometry.png
fig_v22_04_voltage_architecture_comparison.png
fig_v22_05_esr_error_vs_bits_enob.png
fig_v22_06_esr_error_vs_multicycle.png
fig_v22_07_C_error_vs_multicycle.png
fig_v22_08_deterministic_quantization_floor.png
fig_v22_09_calibration_benefit.png
fig_v22_10_kR_variation.png
fig_v22_11_native_vs_external.png
fig_v22_12_final_adc_decision_region.png
```

---

# 25. DSP_ADC_DECISION.md 必须回答

1. 目标 DSP 型号是什么？
2. 片内 ADC 有哪些 resolution/rate 模式？
3. 片内最快 ADC 是否满足 edge-window sampling geometry？
4. 片内高分辨率模式是否反而因采样率过低而不满足？
5. native ADC 的实际 ENOB 假设/规格是什么？
6. 当前 ESR 最小 edge signal 是多少 mV？
7. 宽量程 vT 下该信号只有多少 ADC codes？
8. 优化量程后多少 codes？
9. dual-range Vedge 是否显著改善？
10. current full scale 最终应为多少，而不是沿用 40 A？
11. multi-cycle 更新能提高多少实际精度？
12. deterministic quantization 是否形成不可平均的 floor？
13. PWM 同步触发是否满足 timing requirement？
14. native ADC + calibration 是否通过 C<3%、ESR<5%？
15. ESR=2× 是否仍通过？
16. 最低可用片内 ADC 配置是什么？
17. 推荐片内 ADC 配置是什么？
18. 是否必须外接 ADC？
19. 若必须，最低 external ADC bit/rate/ENOB 是什么？
20. 最终硬件架构是什么？

---

# 26. RESULT_V22_FOR_CHATGPT.md 必须包含

## 1. Executive Decision

明确：

```text
Native ADC sufficient / not sufficient
```

## 2. DSP ADC Datasheet Profile

## 3. Signal Amplitude Budget

## 4. Current/Voltage Range Optimization

## 5. Wide-Range vs Dual-Range Voltage Channel

## 6. Native ADC Quantization / ENOB

## 7. Sampling Geometry

## 8. Multi-Cycle Information Accumulation

## 9. Calibration

## 10. kR Robustness

## 11. Blind Health Accuracy

## 12. Native vs External ADC

## 13. Final ADC Decision

## 14. Hardware Recommendation

---

# 27. 任务停止条件

只有以下完成才结束：

- [ ] 目标 DSP ADC profile 已确认或参数化
- [ ] resolution 与 ENOB 已分开
- [ ] C/ESR signal budget 完成
- [ ] current range 重新确定
- [ ] wide-range vT 测试完成
- [ ] dual-range/high-gain edge channel 完成
- [ ] level-shift architecture 完成或说明不适用
- [ ] native sampling geometry 完成
- [ ] PWM synchronous sampling 完成
- [ ] deterministic quantization floor 完成
- [ ] multi-cycle fusion 完成
- [ ] native ADC nonideal 完成
- [ ] calibration levels 完成
- [ ] kR robustness 完成
- [ ] health blind matrix 完成
- [ ] external ADC reference 对照完成
- [ ] DSP_ADC_DECISION.md 完成
- [ ] RESULT_V22_FOR_CHATGPT.md 完成

---

# 28. Codex 最终执行指令

**不要默认必须使用 16-bit 外置 ADC。首先从项目中识别实际目标 DSP，并按其 datasheet 建立片内 ADC 的分辨率、ENOB、最高采样率、触发、ADC module 和通道时序模型。如果目标 DSP 未确定，则用参数化的 native 12-bit high-speed 与 native high-resolution 模式做架构判断。必须先优化电流/电压量程，再比较宽量程、双量程 edge 通道和 level-shift 前端；必须利用 PWM 硬件同步采样和健康参数慢变化允许的多周期信息积累。只有在 native ADC 经过量程优化、同步触发、多周期融合、offset/gain/timing 校准后仍因信息分辨率不足而不能达到 C<3%、ESR<5%，才允许判定 external ADC required。外接 ADC 的 bit/rate 也必须由仿真反推，不能直接写死 16-bit/5 MS/s。**

---

## Version

- v2.2
- Phase: Native DSP ADC feasibility before external ADC commitment
- Final decision variable: **native ADC sufficient?**
