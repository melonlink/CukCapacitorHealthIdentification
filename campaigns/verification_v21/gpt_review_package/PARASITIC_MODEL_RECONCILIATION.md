# Parasitic Model Reconciliation

## What was tested

The read-only Simscape Model B was executed through
`Simulink.SimulationInput` for 45 requested combinations:

- ESL: 1, 5, 10, 20, and 50 nH;
- requested load: 25%, 50%, and 100%;
- duty: 0.30, 0.40, and 0.60.

Where a requested point was not CCM, load was increased to the nearest tested
CCM replacement and both requested/actual fractions were recorded. Each row
stores averaged high-resolution terminal-voltage and capacitor/inductor-current
edge traces in `results/raw/modelB_edge_traces_v21.mat`. Switch-node voltage is
not logged by the existing read-only model and is explicitly marked unavailable.

## Identification result

Model B contains a physical series ESL but ideal switching and no separately
parameterized switching-loop capacitance/damping network. Across the 45 points,
the Model B minus Model A edge residual did not contain enough stable zero
crossings to identify an underdamped second-order ringing mode. The feature
table therefore reports `ring_identifiable=false` rather than a numerical
near-zero frequency. Non-oscillatory residuals were fitted only with a decaying
exponential for the A-P comparison.

## Acceptance

The identified reduced model failed the requested substitution gates:

- waveform NRMSE <10%: 0/45;
- TR ESR MAPE difference <2 percentage points: 12/45 (26.7%);
- joint acceptance: 0/45.

Accordingly, Model A-P **cannot replace Model B for parasitic robustness
sweeps**. This is the required Gate E closure path, not a forced PASS. The v2
arbitrary derivative plus decaying-ringing injection remains historical stress
code only and must not be cited as physical evidence.

The safe claim is narrower: the independent Model B supports the explicitly
simulated ESL/timing points. Hardware ringing frequency, damping, overshoot,
and settling claims require either an enriched Simscape switching-loop model
with physical capacitances/resistances/transition time or bench waveforms.

