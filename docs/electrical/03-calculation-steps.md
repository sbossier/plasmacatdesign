# 3. Calculation steps

This page follows the notebooks step by step. For each step it gives:
- **what** happens;
- **why** it is needed;
- the **formula**;
- the **reference**;
- the **function** in the code.

Settings in `code font` are parameters you can change (see [Adapting to your reactor](07-adapting-to-your-reactor.md)).

Abbreviations for the main references:
- **P15**: Peeters & van de Sanden 2015
- **PB19**: Peeters & Butterworth 2019
- **B&A17**: Butterworth & Allen 2017
- **B23**: Brandenburg et al. 2023
- **DM24 / DM25**: De Meyer et al. 2024 / 2025

All are listed in the [references](08-references.md).

---

## Part A: from oscilloscope files to one data table

Notebook: `py/electrical/psdata_conversion_and_consolidation.py`.

### A1. Convert PicoScope files to CSV
- **What:** each `.psdata` capture is exported to CSV with the PicoScope 6 command line (`/c … /f csv /b all /v "<view name>"`).
- **Why:** `.psdata` is a proprietary format. The CSV holds time plus the four channels in the units set in PicoScope (here ms, µC as "knC", kV, mA, mA).
- **Function:** `convert_folder`.

### A2. Convert to SI units
- **What:** every column is converted to seconds, coulombs, volts and amperes using the unit in the CSV header.
- **Function:** `convert_to_si`.

### A3. Add the experiment description
- **What:** project, reaction, supplier, material, power mode, residence time, run number, plasma state and date are read from the folder and file names. See [folder layout](07-adapting-to-your-reactor.md#folder-layout).
- **Function:** `parse_file_path`.

### A4. Save one table per run
- **What:** all captures of one run folder are stacked into `lissajous_data.parquet`.
- **Why:** one compressed file is much faster to read than hundreds of CSVs.

---

## Part B: from the data table to results

Notebook: `py/electrical/lissajous_calculations.py`, function `calculate_results`. Steps B1–B13 run per oscilloscope capture (one `.psdata` file, here 6 periods of 3 kHz).

### B1. Check the sign of each probe
- **What:** the applied voltage is the reference. Charge, reactor current and source current are flipped if they have the wrong sign.
- **Why:** a probe connected the other way round inverts its signal. In our test data this happened to the Rogowski coil in some runs, which made the power negative.
- **How:** three physical checks that do not depend on when the scope triggered:
  - charge follows voltage, $\text{corr}(V, Q) > 0$;
  - the current is the derivative of the charge, $\text{corr}(I, dQ/dt) > 0$;
  - the source delivers power, $\overline{V I_s} > 0$.
- **Output:** `flipped_Q`, `flipped_I`, `flipped_Is`.
- **Function:** `align_polarity`.

### B2. Keep whole periods only
- **What:** the capture is cut to an integer number of periods $T = 1/f$.
- **Why:** power and averages are only correct over whole periods (PB19 §2.3).

### B3. Remove offsets
- **What:** the mean of $Q$ and of $V$ over the whole periods is subtracted.
- **Why:** over a period, charge and voltage must average to zero (P15 §4.1; DM24 SI §S4). A small offset on the charge probe (1.5–3.2% of the amplitude in our data) would otherwise shift the zero crossings used in B8 and the gap voltage in B13.

### B4. Correct the time delay between voltage and charge
- **What:** the charge signal is shifted in time by a whole number of samples, between 0 and $T/10$. The shift is chosen so that the power from the loop area matches the power from the Rogowski current:

$$
\min_{\text{shift}} \left| f\oint V\,dQ_\text{shifted} - \overline{V I} \right|
$$

- **Why:**
  - A delay between the voltage probe and the charge probe opens or closes the Q–V loop and changes the power and every slope (PB19 §3.3).
  - The Rogowski current gives an independent power, so it is used as the reference.
  - Our charge probe was not well tuned for a long period, which caused delays of several µs.
- **How:** a global optimiser (`differential_evolution`), seeded (`de_seed`) so results are reproducible.
- **Output:** `calculated_shift_s`.
- **Caveat:** this forces the area power to equal the $V\cdot I$ power, so the two are no longer independent checks of each other. See [limitations](05-known-limitations.md#time-shift-correction).

### B5. Smooth and differentiate
- **What:** $V$ and $Q$ are smoothed with a Savitzky–Golay filter (window = `smoothing_fraction` × capture length ≈ 50 µs, order 2). The derivatives $dV/dt$ and $dQ/dV$ are computed from the smoothed signals.
- **Why:** the raw signals contain quantisation steps and pulse noise, and differentiating raw data amplifies noise (PB19 §3.4; DM24 SI §S6).

### B6. Find where the plasma is active
- **What:**
  - The reactor current is high-pass filtered above 1 MHz. This keeps only fast changes, i.e. the discharge pulses.
  - The signal is cut into blocks of `slope_dt_s` (0.32 µs). A block is *active* if its peak exceeds 5 × the median block peak.
  - A 10 µs moving average gives the fraction of active blocks over time.
- **Why:**
  - This marks plasma-on and plasma-off from the current pulses themselves, independent of $Q$, of the capacitances and of the time shift in B4.
  - The old method used arbitrary windows ($V > V_\text{max}/5$ and the sign of $Q$), which biased $C_\text{cell}$.
- **Also gives:** the noise level of the current in the inactive blocks, `current_noise_sigma_A`.
- **Function:** `discharge_activity`.

### B7. Fit the slopes per half-period
Each half-period runs from one voltage extremum to the next. It is split into two windows:
- **plasma-off:** the longest stretch without activity, from the end of activity at the extremum to the first new pulse (point B, ignition);
- **plasma-on:** from B to the next extremum.

The fits:

1. **Cell capacitance** (plasma-off): least-squares fit of

$$
Q = C_\text{cell}\,V + b\,\frac{dV}{dt} + c
$$

   - The extra term $b\,dV/dt$ absorbs a lag of $Q$ behind $V$, which otherwise curves this branch.
   - With it, $C_\text{cell}$ changes by only 2–4% when the window start moves. A straight line changes by ~20%.
   - The lag is reported as `delay_eff_off_*_s` $= -b/C_\text{cell}$.
   - **Caveat:** this term is a model element the later steps do not use. See [limitations](05-known-limitations.md#the-lag-term-in-the-plasma-off-fit).

2. **Effective dielectric capacitance** (plasma-on):
   - after removing the same $b\,dV/dt$, the straight-line slope is `C_diel_eff_*` ($\zeta_\text{diel}$);
   - the steepest slope over a sliding window of 20% of the branch is `C_diel_eff_max_*` ($\zeta_\text{max}$, recommended for almond-shaped figures by PB19 §3.2 and B&A17 §2.6.2).

3. **Ignition voltage:** the applied voltage at point B, `U_ignition_*`.

4. **Validity check** (`parallelogram_valid`). A half-period passes when:
   - the residual of the plasma-off fit is ≤ `max_resid_rel` (0.8% of the charge amplitude), and
   - $C_\text{cell}$ changes by ≤ `max_window_sens` (10%) when the window starts at half the peak voltage instead.

   If either half-period of a cycle fails, all slope-based outputs of that cycle are set to empty (NaN). Power and RMS currents are always computed.

Functions: `half_cycle_slopes`, `fit_iq`, `max_local_slope`, `select_half_cycle`.

**Naming:**
- `_neg` is the falling half-period (from +max to −max), where the plasma ignites at negative voltage.
- `_pos` is the rising half-period.
- `_avg` is their mean, using magnitudes for voltages.

### B8. Burning voltage $U_b$ (P15 eq. 13)
- **What:** $\Delta U$ is the voltage at which the smoothed charge crosses zero, averaged per polarity. Then

$$
U_b = \frac{1 - C_\text{cell}/C_\text{diel}}{1 - C_\text{cell}/\zeta_\text{diel}}\,\Delta U
$$

- **Meaning:** the voltage across the gas while the plasma conducts, corrected for partial discharging.
- **Output:** `U_burning_neg_V`, `U_burning_pos_V`, `U_burning_avg_V`.
- **Caveat:** only meaningful for a parallelogram-like figure (§2.5 of [Equivalent circuits](02-equivalent-circuits.md)).

### B9. Breakdown voltage $U_D$ (B23 eq. 9; DM25)
- **What:** $V_\text{min}$ is half the voltage span from the extremum to the ignition point B. Then

$$
U_D = V_\text{min}\left(1 - \frac{C_\text{cell}}{C_\text{diel}}\right)
$$

- **Meaning:**
  - the voltage across the gas at the moment it breaks down;
  - it uses only $C_\text{cell}$ and the ignition point, not $\zeta_\text{diel}$, so it does not depend on partial discharging;
  - in the ideal model $U_D = U_b$. Their difference shows how far the figure departs from the ideal.
- **Output:** `U_breakdown_*_V`.

### B10. Partial discharging $\alpha$, $\beta$ (P15 eqs. 7–8)

$$
\alpha = \frac{C_\text{diel} - \zeta_\text{diel}}{C_\text{diel} - C_\text{cell}},\qquad
\beta = \frac{\zeta_\text{diel} - C_\text{cell}}{C_\text{diel} - C_\text{cell}}
$$

- **Meaning:**
  - $\beta$ is the fraction of the electrode that discharges ($\beta = 1$: everything; $\beta = 0$: nothing).
  - In a packed bed it also reflects how much charge crosses the gap rather than staying on the beads (B&A17).
- **Output:** `alpha_*`, `beta_*`.

### B11. Transferred charge (P15 eqs. 15–16)
- **What:**
  - $Q_0$ is the vertical distance between the two plasma-off lines, each evaluated where the applied voltage crosses zero.
  - The model value at that point includes $b\,dV/dt$.

$$
\Delta Q_\text{dis} = \frac{Q_0}{1 - C_\text{cell}/C_\text{diel}}
$$

- **Meaning:** the charge the plasma carries across the gas in one half-period.
- **Output:**
  - `Q_delta_dis_neg_C` and `Q_delta_dis_pos_C` (using each half-period's $C_\text{cell}$);
  - their sum `Q_delta_dis_per_cycle_C`;
  - their mean `Q_delta_dis_per_dis_avg_C`.

### B12. Power, voltage and currents per cycle
- `power_plasma_W` = loop area × $f$ (PB19 eq. 9).
- `power_plasma_UIprod_W` = $\overline{V I}$ with the Rogowski current.
- `power_source_W` = $\overline{V I_s}$ with the amplifier's current monitor. It includes losses outside the reactor.
- `U_pp_V` = peak-to-peak applied voltage.
- `current_rms_reactor_A`, `current_rms_source_A` = root-mean-square currents.

### B13. Plasma current (PB19 eq. 3)

$$
i_\text{plasma}(t) = \frac{1}{1 - C_\text{cell}/C_\text{diel}}\left(I(t) - C_\text{cell}\frac{dV}{dt}\right)
$$

- **Meaning:** the current carried by the plasma alone.
- **Output:** `current_rms_plasma_A` (its RMS value).
- **Note on the factor $1/(1 - C_\text{cell}/C_\text{diel})$:**
  - PB19 §2.2 explains why it is needed.
  - DM24 (eq. 7) subtracts only $C_\text{cell}\,dV/dt$.
  - Because $C_\text{cell}$ differs between packings, leaving the factor out changes comparisons between materials by a few percent (about 1.15–1.20 here).

### B14. Current pulses
- **What:** peaks in $i_\text{plasma}$, positive and negative, are found with these criteria:
  - height and prominence ≥ `discharge_threshold_A` (7.5 mA);
  - width ≥ 15 ns;
  - spacing ≥ 50 ns;
  - width ≤ `max_pulse_width_s` (1 µs).
- **Charge per pulse:** each pulse is integrated between the points where it has fallen to 10% of its height, above a straight baseline.
- **Outputs:**
  - `avg_num_udisch_per_cycle`: number of pulses per cycle;
  - `avg_num_udisch_per_cycle_corr`: pulses with a positive integrated charge;
  - `Q_udisch_per_cycle_total_C`, `Q_udisch_per_cycle_avg_C`: total and mean charge in pulses;
  - `Q_frac_in_udisch`: total pulse charge / $\Delta Q_\text{dis}$ per cycle;
  - `pulse_width_median_s`, `n_pulses_too_wide`: checks of the width limit.
- **Why the 1 µs limit:**
  - In our data, real pulses are 0.1–1 µs wide (median ~0.25 µs).
  - Slow current "humps" of 10–280 µs also appear, on the time scale of the half-period.
  - The limit sits in the empty gap between the two groups.
- **Caveat:** the pulses are indicative only ([limitations](05-known-limitations.md#current-pulses-are-indicative)).
- **Function:** `integrate_microdischarge_charge`.

### B15. Spectral pulse metric (after DM24)
- **What:** the root-mean-square of $i_\text{plasma}$ restricted to the frequency band `pulse_band_Hz` (0.2–10 MHz), from the Fourier transform of each cycle (Parseval's theorem):

$$
I_\text{band,RMS} = \frac{\sqrt{2\sum_{k\in\text{band}} |X_k|^2}}{N}
$$

  where $X_k$ is the discrete Fourier transform of the $N$ samples of one cycle.
- **Why:**
  - It needs no peak detection, so it has no threshold or width settings.
  - It grows with both the number and the height of the pulses (DM24 SI §S7).
  - Its unit is amperes.
- **Why this band:**
  - In our data, 73% of the pulse power lies at 0.2–3 MHz.
  - Plasma-on exceeds plasma-off by more than 100× up to 10 MHz. Above 50 MHz there is only noise.
  - DM24 used 10–100 MHz with a faster setup; for our pulses that band would contain mainly noise.
  - Choose the band from your own spectra ([Adapting](07-adapting-to-your-reactor.md#spectral-pulse-band)).
- **Output:** `pulse_band_rms_A`.

### B16. Consistency checks (not corrections)
- `power_quadrature_W` $= \overline{C_\text{cell}\,\tau}\;\omega^2 V_0^2/2$, with $\tau$ = `delay_eff_off_*_s` and $\omega = 2\pi f$. This is the power carried by the lag term of B7.
- `power_ratio_UbQdis` $= 2 U_b\,\Delta Q_\text{dis}\,f / P$. It equals 1 for an ideal parallelogram (P15 eq. 14).
- `power_manley_W` $= 4f\beta(C_\text{diel} - C_\text{cell})V_\text{min}(V_0 - V_\text{min})$, the generalised Manley power (B23 eq. 13). It is close to the measured power when the parallelogram model holds.

---

## Part C: cleaning, averaging and figures

### C1. Remove gross failures
**Function:** `remove_outliers`. A cycle is removed when:
- one of its core quantities deviates more than `max_cycle_deviation` (20%) from the median of its own capture (a calculation glitch), or
- its power deviates more than `max_power_deviation` (10%) from the median of the run (a capture off the power setpoint).

Pulse metrics are not used for this, because they scatter by nature. Empty (NaN) values never cause removal.

**Why not a statistical outlier test:** cycles within one capture differ by only ~1%. Statistical tests would then flag 20–30% of perfectly good cycles.

### C2. Average per capture
`lissajous_calculations_no_outliers_avg.csv` holds the mean of every numeric column per capture.

**Statistics:** cycles and captures of the same run are not independent repeats.
- Use the **reactor run** as the unit of replication.
- Use the scatter between captures only as a measurement uncertainty.

### C3. Figure
**Function:** `lissajous_figure_generation`. `lissajous_figure.png` has three panels:
1. the average Q–V loop with the fitted lines;
2. $|dQ/dV|$ against time;
3. $dQ/dV$ against $V$, with the mean $C_\text{cell}$, $\zeta_\text{diel}$ and $\zeta_\text{max}$ as horizontal lines and the ignition voltages as vertical lines.

### C4. Time profiles
**Function:** `profile_calculation`. `profile_data.parquet` keeps every 100th sample and adds:
- `current_plasma_A`: PB19 eq. 3;
- `current_displacement_A` $= I - i_\text{plasma}$: the true displacement current (PB19 §2.2);
- `charge_plasma_C` $= (Q - C_\text{cell}V)/(1 - C_\text{cell}/C_\text{diel})$: P15 eq. A12;
- `voltage_gap_V`: P15 eq. 3 with the median $\alpha$, $\beta$ and $C_\text{cell}$ of the valid cycles of that capture.
