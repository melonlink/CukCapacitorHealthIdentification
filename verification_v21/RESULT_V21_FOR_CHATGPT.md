# Result v2.1 for ChatGPT Review

## Executive conclusion

v2.1 closes the internal sampling/AFE/estimator contradictions but does **not**
support an unqualified hardware-readiness claim. The selected simulation
candidate is the conditional, disjoint **TS-SLTVKE**. The minimum fully tested
candidate is 1.6 MS/s/channel, 16-bit, simultaneous sampling, second-order
2 MHz voltage / 1 MHz current AFE, 2 us edge window and at least 3 points/side.
The recommended first bench prototype is 5 MS/s/channel with the same AFE and
16 bits, giving at least 10 points/side and about -40 dB worst alias ratio in
the nominal joint matrix. Residual channel-delay calibration should target
50 ns because that is the worst-case Model B 95% boundary.

## Required answers

### 1. Is the 16-spc versus 1.5–2 us contradiction confirmed?

Yes. At 0.8 MS/s, three uniform points span at least 2.5 us. With a 2 us
window, the 64-phase enumeration has zero feasible phases and only one
worst-phase point/side across every tested duty.

### 2. What ADC rate/window/Nw is internally consistent?

The tested geometric minimum is 1.6 MS/s, 2 us, (N_w=3), guard 0.5 us.
It has 100% enumerated phase feasibility over D=0.25–0.65. The recommended
bench setting is 5 MS/s with the same window/guard and 10 observed points/side;
the fit may still use a controlled subset if desired.

### 3. Do the windows fit at every tested duty?

Yes for the selected 1.6 and 5 MS/s designs. At D=0.25 or 0.65 the shortest
state is 5 us and (g+W=2.5\) us. The analytical state margin and phase point
count both pass.

### 4. Is the 1–2 MHz AFE/ADC aliasing contradiction closed?

Yes for the selected joint regions, not for 0.8 MS/s. The full AFE+S/H+ADC+
quantization+estimator matrix contains 1,360 rows. At 1.6 MS/s with second-order
2 MHz/1 MHz channels, worst tested alias ratio is -25.4 dB and both phases pass.
At 5 MS/s it is about -40.0 dB. ±1% switching-frequency asynchronous checks
pass for the 2 MHz voltage design; the 1 MHz voltage design has C failures at
several rates despite favorable-looking alias numbers.

### 5. Minimum and recommended ADC rates?

- Minimum supported candidate: 1.6 MS/s/channel, simultaneous, 16-bit,
  second-order 2 MHz voltage / 1 MHz current AFE, 40 A current full scale.
- Recommended research prototype: 5 MS/s/channel with the same AFE and bits.

Fourteen bits passed parts of the nominal matrix, but the explicit asynchronous
stress rows were run at 16 bits; therefore 14-bit is not promoted as the final
minimum hardware specification.

### 6. Why did the v2 Model A ringing model disagree with Model B?

It injected an arbitrary derivative plus decaying sinusoid whose frequency,
damping, and amplitude were not identified from Model B. The existing Model B
also lacks an explicit switching-loop capacitance/damping/finite-transition
network, so it does not reproduce that assumed ringing family.

### 7. Can the new Model A-P replace Model B?

No. Across 45 Model B ESL/load/duty rows, no stable underdamped ringing mode was
identifiable. A-P passed 0/45 waveform-NRMSE gates and only 12/45 estimator
agreement gates. Parasitic evidence must remain Model B-specific until the
physical model or bench data is enriched.

### 8. Was the v2 structured Kalman update mathematically imprecise?

Yes. It used (H_V=[1,0,i_C]) but manually zeroed C/ESR gain rows. That is an
engineering gain mask, not the standard Kalman solution and not a complete
Schmidt/consider filter. It also allowed raw-sample reuse without a measurement
cross-covariance model.

### 9. Which final estimator is selected?

The conditional structured estimator:

\[
z_V=v_T-\hat r i_C,\quad H_V=[1,0,0],
\]

with (H_C=[0,q/C_b,0]), (H_R=[0,0,k_RI_\Sigma]), disjoint raw samples,
ordinary scalar Kalman gains, and Joseph covariance updates. The accurate name
is **Topology-Synchronous Structured LTV Kalman Estimator (TS-SLTVKE)**.

### 10. Was measurement double counting present?

It was possible in v2 and is explicitly reproduced by the overlap audit. The
final policy forbids same-sample reuse between V, C, and edge sets. Analog-filter
temporal correlation remains and is handled empirically through locked process
noise; it is not claimed to be an exact correlated likelihood.

### 11. Are C/R covariances still grossly conservative?

Not in the principal nominal/noisy/Model B cases. Nominal C/R NIS means are
0.99/0.84; noisy values are 1.00/0.91; Model B 20 nH values are 0.97/0.91.
High-D ESR NIS remains conservative at 0.28, which is reported rather than
hidden.

### 12. Do NIS/NEES/CI support a confidence claim?

Conditionally. Nominal, high-D, low-CCM, and Model B 20 nH have 100% accuracy
pass over 100 seeds and parameter NEES means 0.35–1.56. The noisy case has
C 95% coverage 93% and 77% accuracy pass. A deliberately opposed +200/-200 ns
channel case has parameter NEES 67.7 and zero coverage. In the 36 health blind
points, all 36 meet C/ESR accuracy, but five ESR=2× points fail the NEES/CI gate.
Confidence is therefore supported only inside the calibrated timing/health
region, not globally.

### 13. Under what conditions is ±200 ns a 95% boundary?

Only the tested high-D CCM rows maintain 200 ns for all ESL=1/10/20 nH and
jitter=0/20/50 ns. Nominal is 100 ns; high load is mostly 100 ns; the weakest
low-CCM rows are 50 ns. A 400 ns relative opposed-channel error fails completely.
The first bench calibration target should therefore be ≤50 ns residual mismatch.

### 14. Which failures are information shortage?

Low load raises C/ESR CRLB: at 25% load the C and ESR variance bounds are much
higher than at 100%. The 0.8 MS/s case is a geometric information failure because
the edge samples do not exist. These are true sampling/information limitations.

### 15. Which failures are model mismatch?

AFE=1.5 MHz gives a C RMSE/CRLB ratio about 25; 100/200 ns timing points give C
ratios about 13/40 and ESR ratios about 18/22. Those large ratios with finite
CRLB show bias/model mismatch, not merely low information. The failed A-P fit
is also model mismatch.

### 16. Can the final algorithm be frozen for hardware?

The mathematical formulation and simulation reference implementation can be
frozen as the v2.1 bench candidate. An unqualified health monitor cannot be
frozen: full 1–2× ESR CI calibration, low-CCM timing, and physical ringing still
require hardware evidence or a richer correlated/parasitic model.

### 17. What can a paper safely claim now?

It can claim the analytical sampling region, the failure of 0.8 MS/s/2 us/3
points, the joint simulated 1.6/5 MS/s design regions, the conditional disjoint
state-parameter formulation, the reported 100-seed NIS/NEES results, and the
Model B timing boundaries under their exact conditions. It can also state that
rank alone is not numerical accuracy and that Model A-P substitution failed.

### 18. What still requires hardware evidence?

Absolute AFE group delay and channel matching, real ADC aperture/jitter/noise,
switching-loop ringing frequency/damping, EMI/common-mode coupling, sensor
saturation/recovery, component-temperature drift, long-term C/ESR aging paths,
and calibrated CI coverage over the full 1–2× ESR health range.

