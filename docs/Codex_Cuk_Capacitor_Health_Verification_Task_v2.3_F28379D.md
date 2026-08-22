# Codex 执行任务 v2.3
# Ćuk 能量传递电容 C–ESR 健康辨识：TMS320F28379D 器件级 ADC / AFE / ePWM-SOC 最终闭环验证

> **项目**：`Cuk_Capacitor_Health_Identification`  
> **任务版本**：v2.3 — TMS320F28379D Device-Specific Closure  
> **目标 DSP**：**Texas Instruments TMS320F28379D**  
> **前置结果**：verification_v1 / v2 / v2.1 / v2.2  
> **当前算法候选**：**TS-SLTVKE — Topology-Synchronous Structured LTV Kalman Estimator**  
> **任务目标**：用 TMS320F28379D 官方 datasheet / TRM / silicon errata 的真实 ADC、电气、采样、同步和时序参数，替换 v2.2 的参数化 ADC profile，建立一个能够真实落到 F28379D 寄存器、ePWM SOC、ADC S/H、DMA/CPU 数据路径和差分模拟前端上的最终仿真规格。
>
> **核心原则**：
>
> 1. 不再修改 C–ESR 核心辨识理论，除非器件级验证发现新的结构问题；
> 2. 不再用理想“采样时间点”代替真实 ADC acquisition aperture；
> 3. 不再用“1.1 MSPS”一个数字代替实际 ADC 采集窗口 + 转换时间 + SOC 排程；
> 4. 不再假设四个 ADC 可以随意异步工作；16-bit 模式必须按照 TI 的同步运行条件设计；
> 5. 不再把 Vedge/Vabs 看成理想低压信号；必须验证浮置 Ćuk 能量传递电容端口的高共模、dv/dt 和差分 AFE 可实现性；
> 6. 不再把 ENOB=14.65 当作所有工况的保证值；它是 datasheet 特定测试条件下的典型值，必须做降额 sensitivity；
> 7. 本轮完成后，如果通过，**冻结仿真算法与 ADC 架构，进入真实台架设计**。

---

# 0. 官方资料必须作为 Source of Truth

Codex 在开始前建立：

```text
verification_v23/
└─ sources/
   ├─ SOURCE_INDEX.md
   └─ datasheet_extract.md
```

至少使用以下 TI 官方资料：

## 0.1 Datasheet

**TMS320F2837xD Dual-Core Real-Time Microcontrollers datasheet, Rev. P**  
Literature: `SPRS880P`

官方入口：

```text
https://www.ti.com/product/TMS320F28379D
https://www.ti.com/lit/ds/symlink/tms320f28379d.pdf
```

若 URL 重定向，使用 TI 当前正式 Rev. P 文档。

---

## 0.2 Technical Reference Manual

**TMS320F2837xD Dual-Core Microcontrollers Technical Reference Manual, Rev. K**  
Literature: `SPRUHM8K`

重点章节：

- ADC configurability；
- SOC principle of operation；
- trigger operation；
- ADC acquisition window；
- ADC input models；
- oversampled conversion from ePWM trigger；
- ADC timings；
- ensuring synchronous operation；
- choosing acquisition window duration；
- achieving simultaneous sampling；
- calibration；
- ePWM；
- DMA。

---

## 0.3 Silicon Errata

**TMS320F2837xD Dual-Core Real-Time MCUs Silicon Errata, Rev. N**  
Literature: `SPRZ412N`

重点检查：

- ADC random conversion errors / sparkle codes；
- ADC offset trim in different modes；
- ADC DMA read of stale result；
- ADC input multiplexer advisories；
- 与目标 silicon revision 相关的所有 ADC/ePWM/DMA advisory。

---

## 0.4 DriverLib

使用 F2837xD C2000 DriverLib API 作为寄存器配置映射参考：

- `ADC_setMode`
- `ADC_setupSOC`
- `ADC_setInterruptPulseMode`
- `ADC_setSOCPriority`
- ePWM ADC SOC functions；
- DMA functions；
- device/silicon revision API。

不得只依据本任务书中的参数；必须在 `SOURCE_INDEX.md` 中给出：

```text
claim
document
section/table
actual value
used in model?
notes
```

---

# 1. 首先建立真实 F28379D ADC Truth Table

生成：

```text
F28379D_ADC_DATASHEET_CLOSURE.md
table_f28379d_adc_truth.csv
```

必须从 datasheet/TRM 核实以下内容。

---

## 1.1 ADC 架构

确认：

- ADC 模块数量；
- 每个模块单独的 S/H 资源数量；
- 16-bit mode；
- 12-bit mode；
- differential / single-ended 限制；
- 每模块 SOC 数量；
- result register 数量；
- ePWM trigger availability；
- burst mode；
- PPB；
- trigger-to-sample delay capture；
- simultaneous sampling 条件。

---

## 1.2 16-bit differential 官方电气参数

至少记录：

```text
ADCCLK min/max
minimum acquisition window
conversion cycles typ/max
throughput
VREFHI
VREFLO
differential input range
input pin voltage range
required common-mode
gain error typ/max
offset error typ/max
ADC-to-ADC gain error
ADC-to-ADC offset error
DNL typ/max
INL typ/max
SNR typ
SINAD typ
ENOB typ
CMRR
PSRR
ADC-to-ADC isolation
```

当前预期但必须由 Codex 核实：

- 16-bit differential；
- 1.1 MSPS / ADC；
- minimum S/H ≈ 320 ns；
- ENOB typ ≈ 14.65 bits under datasheet test conditions；
- INL max ≈ ±3 LSB；
- DNL max ≈ ±1 LSB；
- VREFCM requirement approximately ±50 mV around reference midpoint。

**禁止把典型值当作 guaranteed minimum。**

---

# 2. ENOB 14.65 的适用边界必须明确

datasheet 的 ENOB/SINAD 测试条件与我们的边沿波形不同。

Codex 必须记录：

- test frequency；
- VREF；
- clock source；
- single ADC / synchronous ADC；
- I/O activity condition；
- whether asynchronous ADC is supported。

然后建立 sensitivity：

\[
ENOB=
[12.5,13.0,13.5,14.0,14.65]
\]

以及 datasheet static worst-case：

- INL max；
- DNL max；
- gain max；
- offset max。

最终报告必须区分：

```text
TI_TYPICAL
TI_MAX_STATIC
ENGINEERING_DERATED
```

不允许说：

> “F28379D 硬件 ENOB 保证 14.65 bit”。

---

# 3. 16-bit 模式必须采用同步四 ADC 架构

根据 datasheet，16-bit AC 性能的 synchronous ADC 条件必须被实际满足。

本任务默认目标架构：

| ADC module | Signal | Purpose |
|---|---|---|
| ADCA | Vedge | ESR edge observation |
| ADCB | Vabs | absolute capacitor terminal voltage / C observation |
| ADCC | i1 | input-inductor current |
| ADCD | i2 | output-inductor current |

但这只是候选。

Codex 必须检查：

1. 选定 package 是否真正引出 ADCA/B/C/D；
2. 每个模块是否存在可用的 16-bit differential pair；
3. differential pair 与 PCB pin mapping；
4. 是否有 pin 与其他必须外设冲突；
5. 特殊 ADC pin pulldown / parasitic 是否应避开；
6. 四模块是否可以使用：
   - identical ADCCLK；
   - identical resolution；
   - identical S/H duration；
   - identical trigger schedule；
7. 如果某个 package 无法实现，比较：
   - 176-pin PTP；
   - 337-ball ZWT；
   并给最小可行 package。

输出：

```text
F28379D_ADC_PINMAP.md
table_f28379d_adc_pinmap.csv
```

不能只写 ADC-A/B/C/D，不写实际 differential pair。

---

# 4. 关键修正：采样几何必须包含完整 S/H aperture

v2.2 把采样当成理想时间点。

真实 16-bit ADC acquisition window：

\[
T_{acq}\ge320ns
\]

因此一个样本不是：

\[
t_k
\]

上的数学点，而是：

\[
[t_k,\ t_k+T_{acq}]
\]

或由 TRM 实际定义的等价 acquisition interval。

---

## 4.1 重新定义 edge safe-window feasibility

若边沿前安全窗口为：

\[
[t_e-g-W,\ t_e-g]
\]

则每个 acquisition aperture 必须**完整落在该窗口内**。

不是仅要求 sample timestamp 位于窗口。

因此对 \(N_w\) 个样本：

\[
\boxed{
t_{S/H,start}^{(1)}
\ge t_e-g-W
}
\]

\[
\boxed{
t_{S/H,end}^{(N)}
\le t_e-g
}
\]

并且相邻 SOC 必须满足真实 ADC pipeline/priority timing。

---

# 5. 用真实 ADC timing 重做 1.1 MSPS 几何

必须从 datasheet/TRM 建立：

```text
SOC trigger
→ acquisition start
→ acquisition duration
→ conversion
→ result latch
→ next SOC availability
```

不能直接使用：

\[
T=1/1.1MSPS
\]

作为所有内部事件的间隔。

至少使用：

- ADCCLK = 50 MHz candidate；
- SYSCLK = 实际 F28379D configuration；
- datasheet typ/max conversion cycles；
- minimum 320 ns S/H；
- realistic register ACQPS；
- priority/arbitration。

---

## 5.1 重新验证 v2.2 的候选

v2.2：

\[
g=0.2\mu s
\]

\[
W=2.0\mu s
\]

\[
N_w=3
\]

必须重新判断：

```text
POINT_TIMESTAMP_FEASIBLE
FULL_APERTURE_FEASIBLE
PIPELINE_FEASIBLE
```

三个结论。

如果 full-aperture 不可行：

自动测试：

\[
W=
[2.0,2.2,2.4,2.5,2.8,3.0,3.5]\mu s
\]

\[
g=
[0.2,0.3,0.5,0.8]\mu s
\]

\[
N_w=[3,4]
\]

找到真实 F28379D 的最小可用窗口。

---

# 6. Duty-cycle 最短状态约束重新核对

对：

\[
D=[0.25,0.30,0.35,0.40,0.45,0.55,0.60,0.65]
\]

验证：

\[
g+W+T_{aperture\ margin}
<
\min(D,1-D)T_s
\]

其中：

\[
f_s=50kHz
\]

必须给：

- pre-edge feasibility；
- post-edge feasibility；
- 0→1 edge；
- 1→0 edge；
- worst duty。

如果只有一个 edge 在全 duty 范围可靠，则允许最终算法只使用一个 edge。

---

# 7. 一边 3 个点是否足够必须重新验证

v2.2 在理想 observation-layer 认为 3 点足够。

本轮使用真实：

- acquisition aperture；
- F28379D ENOB；
- INL/DNL；
- AFE；
- Model B waveform；

比较：

\[
N_w=3,4,5
\]

如果 1.1 MSPS 只能真实取得 3 点，则必须证明：

\[
N_w=3
\]

的 edge-fit：

- bias；
- variance；
- outlier sensitivity；
- timing sensitivity；

仍达到 ESR<5%。

若不能：

\[
\boxed{
\text{native 1.1 MSPS architecture must be reconsidered}
}
\]

不得因为 v2.2 已经通过而强行维持。

---

# 8. ePWM-SOC 触发必须做到寄存器级可实现

F28379D 有丰富 ePWM ADC trigger 资源，但一个 ePWM 的 SOCA/SOCB 并不自动等价于任意多个采样时间。

Codex 必须建立**真实可配置的 SOC schedule**。

输出：

```text
F28379D_EPWM_ADC_SCHEDULE.md
table_epwm_soc_schedule.csv
```

每个采样事件至少记录：

```text
event_id
PWM_cycle_phase
master_epwm
trigger_epwm
SOCA_or_SOCB
TBCTR_event
compare_register
ADCA_SOC
ADCB_SOC
ADCC_SOC
ADCD_SOC
acquisition_start
acquisition_end
conversion_end
result_latch
used_by_V
used_by_C
used_by_R
```

---

# 9. 多采样点如何产生：必须用硬件触发方案

优先方案：

- 主 Cuk PWM ePWM 负责功率开关；
- 其余同步 ePWM modules 作为 ADC trigger generators；
- ePWM outputs 可不引脚输出；
- 所有 trigger ePWM 与主 PWM time-base 同步；
- 每个 sampling phase 用 ePWM compare event 产生 SOC。

不得用：

- CPU 软件延时；
- ISR 中软件 force SOC；

作为主采样方法。

---

# 10. 四个 ADC 必须同一时刻采样

为保证 16-bit synchronous ADC 条件：

每一个采样 event 应同时触发：

\[
ADCA,\ ADCB,\ ADCC,\ ADCD
\]

使用：

- identical ADCCLK；
- identical resolution；
- identical S/H duration；
- identical trigger event。

即使某些时刻只有 Vedge 有用，四个 ADC 仍可一起采样，其余结果可以丢弃。

比较：

### Architecture S1

所有模块全程完全相同 sampling schedule。

### Architecture S2

不同模块不同 schedule。

若 S2 会破坏 TI 的 synchronous ADC 性能条件，则正式禁止 S2。

---

# 11. Exact throughput / utilization audit

50 kHz PWM：

\[
T_s=20\mu s
\]

1.1 MSPS 理论每 ADC 每周期最多约：

\[
22
\]

次转换，但必须用真实 pipeline 计算。

设计以下最小 sampling schedule：

### ESR edge

前：

\[
N_w
\]

点；

后：

\[
N_w
\]

点。

### C safe interval

需要：

- endpoints；
- current integration samples。

允许复用“同一个 acquisition event 的四个同步信号”，但不得违反 v2.1 的 raw-data double-counting policy。

必须计算：

```text
conversions_per_ADC_per_PWM
ADC utilization
conversion idle margin
SOC queue depth
deadline miss
```

要求：

\[
\boxed{\text{zero SOC overrun / zero missed acquisition}}
\]

---

# 12. 研究一个 edge / 两个 edge 两种架构

比较：

## E1 — one-edge ESR update

每 PWM 周期只使用一个最干净的 topology edge。

优势：

- 减少 ADC 采样压力；
- 增大采样窗口；
- 简化寄生影响。

## E2 — both-edge ESR update

使用两个边沿。

优势：

- 信息量增加；
- 可以做 consistency check。

比较：

- C/ESR MAPE；
- edge consistency；
- ADC utilization；
- schedule feasibility；
- robustness。

如果 E1 已足够，第一版硬件优先 E1。

---

# 13. 16-bit differential AFE 必须按照真实 common-mode 设计

TI 16-bit differential ADC 不是普通单端 0–3.3 V 输入。

本轮以 external：

\[
VREFHI=2.5V,\quad VREFLO=0V
\]

作为首选 baseline，因为主要 ADC AC characterization 以 2.5 V reference 给出。

Codex 必须从 datasheet 确认：

\[
VREFCM=(VREFHI+VREFLO)/2
\]

并满足 datasheet 规定的 differential input common-mode tolerance。

AFE 输出必须生成：

\[
V_P,\quad V_N
\]

并确保：

- 两个 ADC pins 始终在允许电压范围；
- common mode 满足要求；
- differential range 不越界；
- 正负瞬态不会触发 clamp。

---

# 14. 使用真实 ADC input RC model

16-bit differential input model至少包含 datasheet：

- sampling switch \(R_{on}\)；
- sampling capacitor \(C_h\)；
- per-channel parasitic \(C_p\)；
- source impedance \(R_s\)。

当前 datasheet 参考参数应由 Codex核实，例如：

\[
R_{on}\approx700\Omega
\]

\[
C_h\approx16.5pF
\]

而“nominal source impedance 50 Ω”不能被错误解释成绝对最大源阻抗。

Codex 必须用 TRM acquisition-window方法计算：

\[
R_{source,AFE}
\rightarrow
T_{settle,16bit}
\]

并验证 320 ns 是否足够。

---

# 15. AFE 驱动器必须做 settling，而不仅是 bandwidth

当前 TS-SLTVKE 的主要采样不是普通低频正弦，而是快速变化波形。

对 Vedge、Vabs、i1、i2 前端建立：

- closed-loop bandwidth；
- output impedance；
- RC isolation；
- differential settling；
- slew rate；
- ADC kickback；
- source capacitance；
- input common-mode。

测试 acquisition window：

\[
[320,360,400,500,640]ns
\]

比较：

- settling error in LSB；
- effective ENOB；
- sample timing；
- achievable MSPS。

目标是在“精度”和“吞吐率”之间找到真实工作点。

---

# 16. 320 ns minimum 不一定是最终最佳值

如果为了 16-bit settling 需要：

\[
T_{acq}>320ns
\]

则转换吞吐率可能下降。

必须重新计算：

\[
f_{sample,actual}
\]

及：

- edge points；
- window；
- duty feasibility。

不能为了满足模拟 settling 把 ADC speed 降低，却仍使用原 1.1 MSPS 结论。

---

# 17. Vedge 测量必须加入 Ćuk 浮置端口 common-mode 模型

这是本轮重要新增项。

能量传递电容 \(C_1\) 两个端点都可能相对 DSP ground 快速变化。

不能把：

\[
v_T
\]

直接当成一个 ground-referenced 40 V 信号。

Codex 在 Model B 中导出：

\[
v_{C+}(t)
\]

\[
v_{C-}(t)
\]

定义：

\[
v_T=v_{C+}-v_{C-}
\]

\[
v_{CM,C}=\frac{v_{C+}+v_{C-}}{2}
\]

至少统计：

- differential DC range；
- common-mode min/max；
- common-mode dv/dt；
- edge common-mode step；
- differential edge step。

输出：

```text
table_c1_measurement_commonmode.csv
fig_v23_c1_diff_commonmode.png
```

---

# 18. Vabs / Vedge AFE 必须加入有限 CMRR

双量程 V2 架构仍保留：

### Vabs

宽量程差分测量。

### Vedge

高增益 AC/dynamic differential measurement。

但必须测试前端 finite CMRR：

\[
CMRR=
[60,70,80,90,100,110]dB
\]

及高频 CMRR degradation。

将共模误差注入：

\[
v_{err,CM}(t)
\]

判断：

- edge fit bias；
- C endpoint bias；
- ESR MAPE。

最终反推：

\[
\boxed{
CMRR_{required}
}
\]

不能假定一个普通运放分压器足以完成 Vedge。

---

# 19. Vedge AFE 的 5 kHz HP / 1.2 MHz LP 假设重新核对

v2.2 使用的 Vedge 参数化前端：

\[
HP\approx5kHz
\]

\[
LP\approx1.2MHz
\]

本轮必须与真实 1.1 MSPS + acquisition timing 联合仿真。

注意：

\[
1.1MSPS
\]

Nyquist 仅：

\[
550kHz
\]

但 PWM 同步采样可能并非传统随机带限采样场景。

因此必须做三类测试：

### A

exact synchronous schedule；

### B

switching frequency：

\[
f_s(1\pm1\%)
\]

扰动；

### C

sampling timestamp：

\[
\pm20,\pm50ns
\]

扰动。

比较 LP：

\[
[300,500,700k,1.0M,1.2M,1.5M]Hz
\]

最终找真实可接受的 AFE bandwidth，而不是保留 v2.2 假设。

---

# 20. 外部 2.5 V reference 必须建模

F28379D ADC 使用外部 reference。

模型至少加入：

- reference noise；
- drift；
- output impedance；
- decoupling；
- four-ADC simultaneous transient loading；
- ADC-to-ADC shared reference sensitivity。

至少 sensitivity：

\[
VREF\ noise=
[1,5,10,20,50]\ \mu V_{RMS}
\]

以及：

\[
gain\ drift=
[5,10,25,50]ppm/^\circ C
\]

用于判断 reference 是否进入 C/ESR 误差预算。

不要求本轮选择具体 reference 芯片。

---

# 21. 时钟源必须按照 datasheet AC test条件核对

datasheet ENOB/SINAD 注明时钟精度和 jitter 会影响 AC 性能。

测试：

### Clock A

高精度外部 crystal / oscillator + PLL。

### Clock B

内部 oscillator sensitivity case。

不能直接把 datasheet 14.65 ENOB 用于 Clock B。

若最终论文/硬件需要高精度 ADC：

\[
\boxed{
\text{external crystal/clock should be the baseline}
}
\]

由仿真给出依据。

---

# 22. Silicon revision / errata audit

生成：

```text
F28379D_SILICON_ERRATA_ADC.md
```

必须检查实际/目标 silicon revision。

---

## 22.1 Random conversion error / sparkle code

对受影响 revision，按照 errata 建模并核对 workaround：

- S/H ≥ specified value；
- ADCCLK limit；
- integer prescale；
- required memory writes。

如果目标 production revision 不受影响，明确写：

```text
NOT_APPLICABLE_TO_SELECTED_REVISION
```

但保留生产来料 revision check。

---

## 22.2 ADC offset trim by mode

每次设置：

- 16-bit；
- differential；

必须使用 TI/C2000Ware 推荐的 mode-setting/calibration flow，确保正确 trim 被加载。

不得只直接改 resolution register。

---

## 22.3 DMA stale ADC result advisory

如果最终使用 ADCINT → DMA：

必须判断是否触发 errata。

比较：

### DMA strategy 1

直接 late ADCINT → DMA。

### DMA strategy 2

按 errata workaround。

### DMA strategy 3

使用 CPU/CLA read 或不同 EOC/interrupt timing。

最终不得采用存在 stale-result 风险的方案。

---

# 23. ADC 数据通路必须做吞吐量审计

比较：

## D1 — DMA continuous

四 ADC 每个采样事件搬运 4 × 16-bit。

## D2 — DMA burst/window

只保存算法所需窗口。

## D3 — CLA/CPU immediate preprocessing

边沿窗口先做局部处理，再存储 sufficient statistics。

评估：

- samples/s；
- bytes/s；
- DMA load；
- RAM buffer；
- CPU1；
- CPU2；
- CLA；
- 20.48 ms health-window memory；
- worst ISR latency。

---

# 24. 1024-cycle 融合在 F28379D 上必须可实时

当前：

\[
1024/50kHz=20.48ms
\]

测试：

- edge OLS；
- C charge calculation；
- three scalar Kalman updates；
- NIS；
- parameter projection/gating；
- 1024-cycle accumulations；

在 C28x / CLA 上的预计运算量。

如果 C2000Ware / compiler 可用：

建立 benchmark C implementation。

输出：

```text
F28379D_COMPUTE_BUDGET.md
table_compute_budget.csv
```

---

# 25. DriverLib 配置骨架必须生成

创建：

```text
firmware_reference/
├─ f28379d_adc_init.c
├─ f28379d_adc_soc_schedule.c
├─ f28379d_epwm_trigger.c
├─ f28379d_dma_adc.c
├─ ts_sltvke_step.c
└─ README.md
```

要求：

- 使用 TI DriverLib；
- 不是伪代码；
- 如果本机有 C2000Ware，至少做语法/工程编译；
- 如果没有，做静态 API 核对并标记 `NOT_COMPILED`.

---

# 26. 必须给出 exact ACQPS / ADC clock register proposal

基于：

- SYSCLK；
- ADC prescale；
- ADCCLK；
- S/H target；

输出：

```text
SYSCLK
EPWMCLK
ADC prescale
ADCCLK
ACQPS
actual acquisition ns
conversion ns
sample-to-result latency
sustainable per-module rate
```

注意 ACQPS 的：

\[
(ACQPS+1)
\]

等实际定义必须从 TRM 核实。

不能手算后不和寄存器定义对应。

---

# 27. 四 ADC 同步 operation proof

必须用 TRM 的 synchronous-operation规则逐项打勾：

```text
same ADCCLK?
same S/H?
same resolution?
same signal mode?
same trigger?
same power-up?
same timing?
```

如果 Vedge/Vabs/current 前端因为 settling 需要不同 S/H，则不能直接让各 ADC 使用不同 ACQPS 而仍声称 datasheet synchronous ENOB。

此时比较：

### Option 1

全部采用四通道中最大的 S/H。

### Option 2

异步模式。

若 16-bit asynchronous AC performance 不受官方支持，则 Option 2 不得作为主方案。

---

# 28. Package 与 PCB 约束

至少输出候选：

- 176-pin PTP；
- 337-ball ZWT。

评价：

- 四 ADC differential pair；
- ePWM trigger resources；
- VREF pins；
- analog ground；
- crystal；
- DMA/communication；
- debugging；
- PCB 可实现性。

如果 PTP 已满足项目，优先降低原型 PCB 难度。

---

# 29. v2.3 器件级 Monte Carlo

基于真实 F28379D 参数至少做：

\[
N=200
\]

seeds / representative condition。

随机：

- ENOB/noise；
- INL/DNL；
- gain/offset；
- ADC-to-ADC mismatch；
- reference noise；
- AFE gain；
- AFE group delay；
- channel timing；
- clock jitter；
- CMRR；
- temperature surrogate。

工况：

1. low CCM；
2. nominal；
3. high load；
4. high D；
5. \(C=0.8C_0\)；
6. \(ESR=2ESR_0\)；
7. \(C=0.8C_0, ESR=2ESR_0\)。

输出：

- C MAPE；
- ESR MAPE；
- p50/p95/p99；
- CI coverage；
- failure cause。

---

# 30. 最终 Gate

## Gate A — Datasheet Closure

所有关键 ADC 参数都有官方来源。

---

## Gate B — Full Aperture Sampling

不是只有 sample timestamp 可行。

必须：

\[
\boxed{
\text{full S/H aperture + conversion schedule feasible}
}
\]

---

## Gate C — Synchronous Four-ADC Operation

满足 TI synchronous ADC 运行条件。

---

## Gate D — AFE Settling

在最终 ACQPS 内达到目标 16-bit settling。

---

## Gate E — Common-Mode Measurement

Vabs/Vedge 的差分高共模测量在有限 CMRR 下仍满足：

\[
C<3\%
\]

\[
ESR<5\%
\]

---

## Gate F — Errata Safe

最终 SOC/DMA/ADC mode 配置不违反 silicon errata。

---

## Gate G — Real-Time Feasible

ADC/ePWM/DMA/CPU/CLA schedule 无 overrun。

---

## Gate H — Device-Level Accuracy

200-seed representative Monte Carlo：

\[
\ge95\%
\]

cases 满足：

\[
C<3\%,\quad ESR<5\%
\]

---

# 31. 失败时的决策树

如果 v2.3 失败，不立即推翻算法。

按顺序定位：

### Failure 1 — 1.1 MSPS acquisition geometry

如果 3 点完整 S/H aperture 放不下：

- widen edge window；
- use one-edge only；
- reduce Nw；
- verify bias；
- 若仍失败 → 外接 faster ADC candidate。

### Failure 2 — AFE settling

- increase ACQPS；
- improve driver；
- reduce source R；
- 若 rate 下降导致 geometry fail → 外接 ADC candidate。

### Failure 3 — common-mode / CMRR

- improve differential AFE；
- consider isolated/dedicated high-CMRR front end；
- 不应直接归因于 ADC 位数。

### Failure 4 — ADC resolution/nonlinearity

若真实 F28379D worst-case 仍导致 C>3%：

- multi-cycle；
- range optimization；
- calibration；
- 若仍失败 → external ADC required。

---

# 32. 强制输出文件

```text
F28379D_ADC_DATASHEET_CLOSURE.md
F28379D_ADC_PINMAP.md
F28379D_EPWM_ADC_SCHEDULE.md
F28379D_ADC_AFE_INTERFACE.md
F28379D_SILICON_ERRATA_ADC.md
F28379D_COMPUTE_BUDGET.md
F28379D_V23_DECISION.md
RESULT_V23_FOR_CHATGPT.md
result_metrics_v23.csv
```

---

# 33. 强制表格

```text
table_f28379d_adc_truth.csv
table_f28379d_adc_pinmap.csv
table_f28379d_exact_timing.csv
table_epwm_soc_schedule.csv
table_full_aperture_geometry.csv
table_acqps_settling.csv
table_c1_commonmode.csv
table_afe_cmrr.csv
table_afe_bandwidth_v23.csv
table_reference_clock.csv
table_errata_compliance.csv
table_dma_throughput.csv
table_compute_budget.csv
table_v23_monte_carlo.csv
result_metrics_v23.csv
```

---

# 34. 强制图

至少：

```text
fig_v23_01_adc_real_timing.png
fig_v23_02_full_aperture_edge_window.png
fig_v23_03_soc_schedule.png
fig_v23_04_acqps_vs_settling.png
fig_v23_05_edge_points_vs_duty.png
fig_v23_06_c1_diff_commonmode.png
fig_v23_07_cmrr_esr_error.png
fig_v23_08_afe_bw_native_adc.png
fig_v23_09_reference_noise.png
fig_v23_10_adc_error_budget.png
fig_v23_11_compute_timeline.png
fig_v23_12_monte_carlo_accuracy.png
fig_v23_13_ci_coverage.png
fig_v23_14_final_hardware_window.png
```

---

# 35. F28379D_V23_DECISION.md 最终只能给以下结论之一

## A

```text
F28379D_INTERNAL_ADC_CONFIRMED
```

表示：

- 器件级 timing；
- aperture；
- AFE；
- common mode；
- errata；
- real-time；

全部闭环。

---

## B

```text
F28379D_INTERNAL_ADC_CONFIRMED_WITH_AFE_CONSTRAINTS
```

表示 ADC 本身可用，但必须满足明确的高性能 AFE/CMRR/driver 条件。

---

## C

```text
F28379D_INTERNAL_ADC_MARGINAL
```

表示 nominal 可用但 p95 / timing / settling 裕量不足。

---

## D

```text
EXTERNAL_ADC_REQUIRED
```

必须明确具体原因：

- speed；
- aperture；
- resolution；
- AFE；
- simultaneous sampling；
- timing。

---

## E

```text
UNRESOLVED
```

不得强行 PASS。

---

# 36. RESULT_V23_FOR_CHATGPT.md 必须回答

1. TMS320F28379D 的实际 ADC 参数与 v2.2 参数化假设有何差异？
2. 14.65 ENOB 在什么测试条件下成立？
3. 工程降额后应采用多少 ENOB？
4. 1.1 MSPS 下 2 µs / 3-point 方案的**完整 S/H aperture**是否真的可行？
5. 最终 edge guard / window / points 是多少？
6. 最终 ACQPS 是多少？
7. 实际 sustainable samples/s 是多少？
8. 四 ADC 是否能真正同步？
9. 四个 differential pair 映射到哪些 pins？
10. 推荐 package 是什么？
11. ePWM 如何生成所有 ADC sampling events？
12. 是否存在 SOC queue/overrun？
13. 一个 edge 还是两个 edge 更合理？
14. Vabs/Vedge 的 Cuk 浮置共模范围是多少？
15. 所需 AFE CMRR 是多少？
16. 1.2 MHz Vedge LP 是否仍合理？
17. 外部 VREF 和 clock 对精度有何影响？
18. F28379D errata 对 ADC/DMA 设计有什么实际约束？
19. 1024-cycle algorithm 是否实时可实现？
20. p95 C/ESR accuracy 是多少？
21. F28379D 内置 ADC 是否最终确认可用？
22. 如果不能，根本原因是什么？
23. 是否需要外置 ADC？
24. 仿真版本是否可以冻结并进入 PCB/台架？

---

# 37. Codex 执行指令

**锁定目标器件为 TMS320F28379D。读取 verification_v1、v2、v2.1、v2.2，但不得覆盖。建立 verification_v23。使用 TI 官方 SPRS880P datasheet、SPRUHM8K TRM 和 SPRZ412N silicon errata 作为器件事实来源，禁止继续使用参数化 ADC profile 代替真实规格。重点重新验证 v2.2 最大未决点：在 16-bit differential 模式、真实 ≥320 ns acquisition aperture、真实 conversion pipeline 和 1.1 MSPS/module 的条件下，原 2 µs edge window / 3 points-per-side 是否在完整 S/H aperture 意义上真实可实现。若不可行，自动重设计 window/guard/one-edge schedule，然后重新验证 TS-SLTVKE。所有四个 ADC 必须按照 TI synchronous-operation 条件使用相同 ADCCLK、resolution、S/H 和 trigger schedule，并建立真实 ePWM-SOC 配置表。Vabs/Vedge 不能继续视为理想 ground-referenced 信号，必须从 Simscape Model B 提取 C1 两端的 differential/common-mode 波形，加入有限 CMRR、AFE settling、ADC input RC、reference、clock jitter 和 silicon errata。最终生成可直接映射到 DriverLib 的 ADC/ePWM/DMA 配置骨架。如果器件级验证通过，则冻结算法和采样架构进入硬件；如果失败，必须明确是 sampling speed、aperture、AFE settling、common-mode、resolution 还是 errata 导致，再决定是否外接 ADC。**

---

## Version

- **v2.3**
- Target device: **TMS320F28379D**
- Phase: **final device-specific simulation closure before PCB**
- Success criterion: **datasheet-accurate, register-realizable, full-aperture-feasible, AFE-feasible and statistically supported internal-ADC implementation**
