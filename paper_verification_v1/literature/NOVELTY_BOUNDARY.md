# Novelty boundary

## Direct answers

1. **Published simultaneous online C/ESR estimation of the Cuk energy-transfer capacitor:** none found in the 25-paper screened matrix. Several papers perform joint estimation for buck output capacitors, DC links, and supercapacitors.
2. **Use of the Cuk `+iL1 <-> -iL2` commutation for C/ESR decoupling:** none found.
3. **Timestamped edge extrapolation for Cuk ESR estimation:** none found.
4. **Structured multi-rate LTV estimation for Cuk capacitor health:** none found.

## Claims that are supportable with careful wording

Subject to a final IEEE Xplore/Scopus search by the authors before submission, the manuscript may state:

> To the best of our knowledge, this is the first reported online joint C–ESR estimator specifically for the Cuk energy-transfer capacitor that combines topology-synchronous bidirectional excitation, timestamp-reconstructed edge information, and disjoint structured multi-rate updates.

The safest novelty is the **combination and topology-specific observation design**, not any individual estimator primitive.

## Claims that must not be written

- first online capacitor health monitor;
- first simultaneous C/ESR estimator;
- first use of converter-inherent signals;
- first Kalman, RLS, wavelet, edge, or charge-domain capacitor estimator;
- first Cuk parametric fault diagnosis or first Cuk prognostic method.

## Residual novelty risk

Search risk remains moderate because conference proceedings and patents can use different terminology such as “coupling capacitor,” “transfer capacitor,” or “intermediate capacitor.” The paper should avoid an unqualified “first.” No direct high-overlap publication was found, so this audit does not trigger `NOVELTY_RISK` by itself.
