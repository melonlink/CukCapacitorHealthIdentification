# SOTA review for Paper Verification v1

## Search and screening

The matrix records 25 traceable publications selected from publisher pages, DOI records, institutional repositories, and two recent review articles. The search prioritized 2020–2026 and retained classic topology-specific, RLS, and closed-form methods. `NR` means that no single aggregate value was visible in the accessible metadata; it does not mean zero error. `NA` means the field is not applicable. No numerical value was inferred from an unread figure.

Coverage audit:

- direct joint C/ESR estimation: 13 records;
- Kalman-class estimation or diagnosis: 4 records;
- RLS/least-squares class: 6 records;
- inherent-signal or no-extra-injection: 10 records, of which at least 5 directly estimate a capacitor parameter online;
- wavelet or signal reconstruction: 4 records;
- Cuk diagnosis/prognostics: 3 records.

## What the literature already establishes

Joint C/ESR monitoring is mature outside the Cuk energy-transfer-capacitor setting. Buck closed-form methods, buck-boost RLS, supercapacitor RLS/RELS, parameter observers, DC-link frequency methods, and wavelet/Kalman methods all estimate the same two health indicators. Therefore neither “online C/ESR estimation” nor “converter-inherent excitation” can be claimed as a first.

The strongest transferable comparators are:

1. Yao et al. for topology-derived current-sensorless closed-form estimation;
2. Ribeiro et al. for inherent-signal plus RLS estimation;
3. the augmented-state and self-tuned Kalman literature for generic state/parameter filtering;
4. the 2024/2025 wavelet–Kalman papers for current/signal reconstruction.

The public descriptions of the wavelet papers do not define a Cuk-specific implementation with identical sampling, timestamp, and edge conventions. Paper Verification v1 therefore labels B4 **Cuk-adapted wavelet-KF baseline**, not an exact reproduction.

## Gaps relevant to this project

The screened literature does not disclose a method that simultaneously has all of these features:

- targets the Cuk energy-transfer capacitor rather than an output or DC-link capacitor;
- exploits the within-cycle current reversal `+iL1 <-> -iL2`;
- separates ESR edge information from charge-domain capacitance information;
- reconstructs a common switching edge using timestamps before forming the ESR observation;
- performs structured, disjoint, multi-rate scalar Kalman/Joseph updates for `[vC, Cb/C, rC]`.

This is a scoped evidence statement, not proof that no unpublished or non-indexed work exists.

## Fair-baseline decision

B0–B4 are retained. B3 is locked as Dual EKF before blind testing. B4 is explicitly an adapted method. B5 is **not executed** because the NPC inherent-signal method estimates spectral intermodulation components that do not have a unique, publication-supported one-to-one Cuk mapping. Its core RLS idea is already represented by B1, while inventing a new spectral mapping would compare two new methods rather than reproduce a baseline.

## Interpretation rule

No baseline is described as failed merely because its original topology differs. Each baseline receives the same Cuk-derived observation dataset, random initialization distribution, training/test separation, and projection bounds. Sensor-fair results are the primary table. Method-native sensor/injection requirements remain in the literature matrix and protocol discussion.
