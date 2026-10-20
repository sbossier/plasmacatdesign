# 5. Known limitations

This page lists what is uncertain in the results and by how much.

The numbers come from 30 test runs of our reactor:
- SiO2+TMAH-220-03H: 14 runs
- GM10.4 / GM11.2 / GM13.3: 4 runs
- Glass_Beads_HT: 12 runs

Each run is 3 kHz, 30 W, CO₂. Other reactors will give other numbers, but the same checks apply.

**Summary:**
1. Plasma power is the most robust result.
2. Capacitances, $\beta$, $U_D$ and $\Delta Q_\text{dis}$ are useful for **comparing materials** measured the same way. Their **absolute** values carry the uncertainties below.
3. Current-pulse metrics are **indicative** only.

---

## The lag term in the plasma-off fit
**Critical, unresolved.**

**What:**
- The plasma-off part of the Q–V loop is curved: the charge lags behind the voltage.
- To get a cell capacitance that does not depend on where the fit window starts, the code fits $Q = C_\text{cell}V + b\,dV/dt + c$ ([step B7](03-calculation-steps.md#b7-fit-the-slopes-per-half-period)).
- The extra term $b\,dV/dt$ is what a resistor in parallel with the reactor would produce: a lossy element.
- The later formulas (plasma current, $Q_0$, $\Delta Q_\text{dis}$, $U_b$, gap voltage) use equivalent circuits that **have no such element** ([Equivalent circuits](02-equivalent-circuits.md#where-the-models-are-mixed)).

**How large** (column `power_quadrature_W`):

| Material | Share of the 30 W carried by the lag term | Contribution to $Q_0$ |
|---|---|---|
| GM13.3 | 34% | 213 of 662 nC (~⅓) |
| SiO2+TMAH | 37% | 228 of 643 nC (~⅓) |
| Glass_Beads_HT | 71% | 464 of 665 nC |

**What it could be.** Each option has a different consequence:
1. *Charge keeps flowing after the voltage peak* (slow conduction in the bed). This is real plasma, so power and transferred charge are correct.
2. *Heating losses in the dielectric or the packing*, a "parasitic resistance" (Brandenburg 2017). This is not plasma, so the plasma power and $\Delta Q_\text{dis}$ are overestimated.
3. *A remaining timing error between the probes.* This is a measurement artefact.

**How to tell them apart:**
- Record a Q–V figure **without plasma right after switching off a hot run** (voltage below ignition).
- If the lag remains, it is option 2 or 3. If it is gone, it is option 1.
- This measurement is not available for most of our materials and cannot be repeated.

**Current choice:** $Q_0$ includes the lag term. Excluding it would lower $Q_0$ and $\Delta Q_\text{dis}$ by about one third.

**Advice:** compare materials only when `power_quadrature_W` / `power_plasma_W` is similar between them. For new measurements, follow the [experimental guide](06-experimental-guide.md#4-reference-measurements).

## Cell capacitance reads too high during plasma
- Only the GM materials have no-plasma recordings to compare against:

  | Material | $C_\text{cell}$ without plasma | $C_\text{cell}$ from the plasma-off branch |
  |---|---|---|
  | GM13.3 | 22.0–23.6 pF | 27.6 pF (+20%) |
  | GM10.4 | 29.8 pF | 35.1 pF (+18%) |

- A higher plasma-off slope during operation is expected. A weak residual plasma or surface charge adds capacitance (Peeters & Butterworth 2019, §3.3). This is why that reference recommends measuring $C_\text{cell}$ *without* plasma.
- **Effect:** everything that uses $C_\text{cell}$ shifts: $\alpha$, $\beta$, $U_b$, $U_D$ (only weakly, about −3% for +20% in $C_\text{cell}$), $\Delta Q_\text{dis}$ and the plasma current.
- The bias is systematic, so comparisons between materials are more robust than absolute values.
- The previous fit method gave values 15–21% too low.

## Day-to-day differences in probe tuning
- Runs with a small fitted time shift (0.5–1.8 µs) give $C_\text{cell}$ = 33–34 pF. Runs with a large shift (8–9.5 µs) give 29–31.5 pF.
- The shift mostly reflects how well the charge probe was tuned that day, so **comparisons across measurement days carry about 12% uncertainty** in $C_\text{cell}$.
- Remedy: tune the probe and record a no-plasma reference every day ([guide](06-experimental-guide.md)).

## Time-shift correction
- The charge signal is shifted so that the area power equals the $V\cdot I$ power ([step B4](03-calculation-steps.md#b4-correct-the-time-delay-between-voltage-and-charge)).
- This is justified because the charge probe was detuned for a long period. Without plasma, the GM reactor is nearly lossless (≤ 0.06 W), yet $Q$ lagged $V$ by 12.8–13.1 µs, constant over 4–12 kVpp: a probe artefact.
- **Open point:** on the same day, the power-matching shift was 8.3–9.0 µs while the no-plasma zero-area shift was 12.8 µs. The difference is unexplained.
- Every slope-based result depends on this shift.
- Because the shift forces the two powers to agree, `power_plasma_W` and `power_plasma_UIprod_W` can no longer be used to check each other.

## Stray capacitance is not separated
- The measured slopes include the capacitance of cables and holder ($C_s$), while $C_\text{diel}$ is a geometric value (Brandenburg et al. 2023; De Meyer et al. 2025).
- Leaving $C_s$ out lowers $U_D$ by about $C_s/C_\text{diel}$ and $U_b$ by about $C_s/(\beta C_\text{diel})$: a few percent.
- **Remedy:** measure the empty reactor without plasma. $C_s$ = measured − geometric $C_\text{cell}$ (7.2 pF for our empty reactor, see [Adapting](07-adapting-to-your-reactor.md#dielectric-capacitance)).

## Geometric dielectric capacitance
- $C_\text{diel}$ = 204 pF is calculated from the tube dimensions with a relative permittivity $\varepsilon_r$ = 10.1 for alumina.
- Literature values of 9.3–10.1 give **187–204 pF**.
- This 5–10% uncertainty passes into $\alpha$, $\beta$, $U_b$, $U_D$ and $\Delta Q_\text{dis}$ (P15 eqs. 7, 8, 13, 16).
- A voltage-amplitude series can show where $\zeta_\text{diel}$ saturates, which gives a measured estimate ([guide](06-experimental-guide.md#4-reference-measurements)).

## A plane-parallel model applied to a packed bed
The partial-discharging model was derived for a uniform gas gap (Peeters & van de Sanden 2015). In a packed bed:
- the plasma starts where the beads touch and spreads as the voltage rises, giving almond-shaped figures;
- the burning voltage is then not constant (Butterworth & Allen 2017, §3.6);
- $\alpha$ mixes "area not discharging" with "charge trapped on the beads".

Our data show the strain:
- **$U_b$ vs $U_D$:** the ideal model says they are equal (Brandenburg et al. 2023, eq. 9). We find $U_b$ = 7.8–8.0 kV against $U_D$ = 5.4–5.9 kV.
- **Energy check:** $2U_b\Delta Q_\text{dis}f$ exceeds the measured power by about 20% (`power_ratio_UbQdis` ≈ 1.2, P15 eq. 14).

**Advice:** prefer $U_D$ (`U_breakdown_*`) over $U_b$. Do not convert $U_b$ or the gap voltage profile into a reduced electric field $E/N$.

## Elliptical figures (Glass_Beads_HT)
- These Q–V figures have no straight segments; the slope rises steadily. The parallelogram model does not apply (Peeters & Butterworth 2019, §3.3): only 5 of 258 cycles passed the validity check.
- Possible causes (PB19 §3.3):
  - an unstable discharge averaged over many periods;
  - a measurement error (stray capacitance or inductance, probe delay).
- The data are from 2022, when the probe was probably detuned, and the remaining lag (~28 µs) is larger than for SiO2+TMAH (~19 µs). Both point to a measurement error.
- However, the Rogowski current independently shows 30 W, so real dissipation without clear pulses is possible too.
- **For such runs only the power is reported.**

## Current pulses are indicative
- The Rogowski coil (Pearson 4100) has a 10 ns rise time. With it we see current pulses of 0.1–1 µs (median ~0.25 µs, rise 0.14–0.47 µs).
- These are probably groups of microdischarges, not single filaments of a few ns.
- De Meyer et al. (2024) did not count pulses with the same coil for this reason.
- **Counts depend strongly on the settings.** Pulses per cycle at fixed settings (GM13.3 / SiO2+TMAH):

  | Threshold | width ≤ 300 ns | width ≤ 1 µs (default) | no width limit |
  |---|---|---|---|
  | 5 mA | 103 / 126 | – | 144 / 151 |
  | 7.5 mA (default) | 73 / 97 | 110 / 120 | 109 / 121 |
  | 10 mA | 54 / 76 | – | 84 / 98 |
  | 15 mA | 31 / 49 | – | 54 / 65 |

- The **ranking** of materials is stable, but the **ratio** between them varies (0.64–0.90). Use pulse metrics only for comparisons within one study with identical settings. `pulse_band_rms_A` needs no detection settings and is a useful cross-check.
- **Fixed threshold:** the threshold is a fixed 7.5 mA, not a multiple of the noise.
  - The noise floor of the current is set by the oscilloscope's step size (quantisation).
  - That step size changes 40× with the chosen vertical range (0.006–0.246 mA in our data).
  - A noise-based threshold would make the counts depend on scope settings.
  - 7.5 mA is at least 11× the noise in all 30 test runs (`current_noise_sigma_A` = 0.06–0.67 mA).

## Resolved in this version (for users of the earlier notebook)

The earlier calculation is kept in `ipynb/electrical/lissajous_calculations.ipynb`.

| Topic | Before | Now |
|---|---|---|
| Fit windows | $V > V_\text{max}/5$ and the sign of $Q$: arbitrary windows; $C_\text{cell}$ 19–29 pF with up to 17% scatter between cycles | Windows from the current pulses; scatter 0.4–3.6% |
| Probe sign | Taken from the first sample; failed in three runs (power read 3–5 W instead of 30 W) | Physical checks (B1) |
| Outliers | A fixed 25% of cycles removed by construction | Only gross failures (C1) |
| $U_D$ | Used the empty-reactor gas capacitance (wrong for a packed bed) and the wrong voltage | Brandenburg et al. 2023 eq. 9 (B9) |
| Offsets | Not removed | Removed (B3) |
| Time shift | Random, could differ between runs | Seeded |
| Gap voltage profile | Used $\alpha$, $\beta$ of the first cycle only | Median of the valid cycles |
| Pulse width limit | 300 ns, cut through the real pulses | 1 µs, between pulses and slow humps |
