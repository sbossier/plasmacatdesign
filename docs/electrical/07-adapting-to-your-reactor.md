# 7. Adapting the code to your reactor

The defaults are set for our reactor, frequency and oscilloscope. This page lists what to check or change when you use the code for your own setup. All settings are parameters of `calculate_results` in `py/electrical/lissajous_calculations.py`, or are set in the configuration cells of the notebooks.

## Our setup as worked example

Coaxial DBD reactor after the design of Uytdenhouwen et al.:

| Part | Value |
|---|---|
| Inner (grounded) electrode | stainless-steel rod, Ø 7.98 mm |
| Dielectric | α-alumina tube, inner Ø 16.85 mm, wall 2.68 mm (outer Ø 22.21 mm) |
| Gap | 4.44 mm, packed with 1.6–1.8 mm spheres (packing efficiency 47.7%) |
| High-voltage electrode | stainless-steel mesh, length 100 mm (plasma volume of the empty reactor 17.3 mL) |
| Power supply | function generator (Tektronix AFG2021) + amplifier (Trek 20/20C-HS), sine 3 kHz, 30 W |
| Voltage probe | Tektronix P6015A (1000:1) on the mesh electrode |
| Current probe | Rogowski coil, Pearson 4100 (10 ns rise time), around the ground lead of the inner electrode |
| Charge | 10 nF, 100 V C0G ceramic capacitor (Kemet C330C103F1G5TA) in the ground line, read with a 10:1 probe (Pico TA150) |
| Source current | built-in current monitor of the Trek amplifier |
| Oscilloscope | PicoScope 6402D, 3.2 ns sample interval, 6 periods per capture |
| Shielding | reactor in a Faraday cage |

## Dielectric capacitance

`C_diel_F` (default 204 pF) is the capacitance of the dielectric alone. For a coaxial tube (De Meyer et al. 2024, eq. 2):

$$
C_\text{diel} = \frac{2\pi\varepsilon_0\varepsilon_r L}{\ln(b/a)}
$$

where:
- $L$ is the length of the outer electrode;
- $a$ and $b$ are the inner and outer *radius* of the dielectric tube;
- $\varepsilon_0 = 8.854\times10^{-12}$ F/m;
- $\varepsilon_r$ is the relative permittivity of the tube material.

**Our reactor:**
- $L$ = 0.100 m, $a$ = 8.425 mm, $b$ = 11.105 mm, $\ln(b/a)$ = 0.276, so $C_\text{diel} = 20.1\ \text{pF} \times \varepsilon_r$.
- With $\varepsilon_r$ = 10.1 (alumina), 204 pF. With 9.3–10.1, 187–204 pF.

The same formula for the empty gas gap ($\varepsilon_r$ = 1, $a$ = rod radius 3.99 mm, $b$ = 8.425 mm) gives $C_\text{gap}$ = 7.4 pF, and so an empty-reactor $C_\text{cell}$ of 7.2 pF. Compare that with an empty-reactor no-plasma measurement to find the stray capacitance $C_s$.

For a flat (planar) reactor, use $C = \varepsilon_0\varepsilon_r A/d$ (PB19 §2.1, footnote).

## Frequency and time scales

| Parameter | Default | Scales with | What to do |
|---|---|---|---|
| `ac_freq_Hz` | 3000 | – | Set to your drive frequency. Used for whole periods, power and spectra. |
| `smoothing_fraction` | 0.025 | capture length | Smoothing window for $V$ and $Q$ (B5). Here 2.5% of 2 ms = 50 µs = 15% of a period. Keep the window at ~10–15% of a period. |
| Time-shift bound | $T/10$ | period | Fixed in the code. The search for the charge delay covers 0 to a tenth of a period (33 µs here). |
| `slope_dt_s` | 0.32 µs | sample interval | Block length for the activity detection (B6); ~100 samples. Keep ≥ 50 samples and ≪ a period. |
| `slope_smoothing_s` | 32 µs | period | Smoothing for the fit windows (B7); ~10% of a period. |
| Activity smoothing | 10 µs | period | `smooth_s` in `discharge_activity`; a few % of a period. |
| Activity high-pass | 1 MHz | pulse width | `hp_cutoff_Hz` in `discharge_activity`. It must be well above the drive frequency and below the pulse content. |

At higher frequencies, for example 23.5 kHz (De Meyer et al. 2024) with a 42.6 µs period, the absolute time settings (`slope_smoothing_s`, `smooth_s`) must be scaled down.

## Validity check

| Parameter | Default | Meaning |
|---|---|---|
| `max_resid_rel` | 0.008 | Allowed residual of the plasma-off fit, relative to the charge amplitude |
| `max_window_sens` | 0.10 | Allowed change of $C_\text{cell}$ when the fit window starts later |

These values are **empirical**. Our parallelogram-like runs had a median residual of 0.0026–0.0068, the elliptical runs 0.0094–0.024.
- Run your data and inspect `iq_resid_rel_*` and `C_cell_window_sens_*` before you trust or change these limits.
- Judge a run by the *fraction* of valid cycles, not by single cycles.

## Pulse detection

| Parameter | Default | How to set it |
|---|---|---|
| `discharge_threshold_A` | 7.5 mA | Must be ≫ the noise: check `current_noise_sigma_A` (≥ 10× is safe). Keep it **fixed** across all runs you want to compare, because counts change strongly with it ([limitations](05-known-limitations.md#current-pulses-are-indicative)). |
| `max_pulse_width_s` | 1 µs | Look at `pulse_width_median_s` and `n_pulses_too_wide`. The limit should sit between your real pulses and slow current humps (on the scale of the half-period). It must stay well below half a period. |
| Minimum width 15 ns, minimum spacing 50 ns | fixed | They do not bind with a 10 ns current probe. With a faster probe they matter: set them from the response time of your probe. |

## Spectral pulse band

`pulse_band_Hz` (default 0.2–10 MHz) is the frequency band for `pulse_band_rms_A` (B15). To choose it for your setup:
1. Compute the spectrum of the plasma current in windows that contain pulses, and in quiet windows.
2. Take the band where the pulse spectrum is clearly (≥ 100×) above the quiet spectrum.
3. Keep the lower edge above the drive harmonics and slow humps, and the upper edge below the bandwidth of your current probe.

Our result:

| Band | Plasma-on / plasma-off power ratio | Share of pulse power |
|---|---|---|
| 0.2–0.5 MHz | ~1400 | 16–17% |
| 0.5–1 MHz | 1400–2000 | 24–25% |
| 1–2 MHz | 1000–1500 | 23–25% |
| 2–3 MHz | 700–1000 | 8–9% |
| 3–10 MHz | 150–550 | 2–3% |
| 10–20 MHz | 30–45 | 0.1% |
| 50–150 MHz | 1–1.6 | 0% (noise) |

## Probe signs, units and channel order

- **Channel order:** the conversion notebook expects the CSV export in this order: time, charge, voltage, reactor current, source current. Other channels after these are ignored.
- **Units:** taken from the CSV header and converted to SI (`convert_to_si`). Supported: ms, s, nC, knC (= µC), A, mA, W, kW, V, kV. In PicoScope, set up *custom probes* so channel A shows charge ($Q = C_m \times$ probe voltage) and the other channels show kV and mA.
- **Signs:** wrong probe signs are corrected automatically (B1), with the applied voltage as the reference.

## PicoScope conversion

- `picoscope_exe`: path to `PicoScope.exe` (PicoScope 6).
- `picoscope_view`: the name of the scope view to export. **It depends on the language of PicoScope**: "Scope 1" in English, "Scoop 1" in Dutch. If the conversion produces no CSV files, check this first.

## Folder layout

The conversion notebook reads the experiment description from the folder names (`parse_file_path`). Everything below `parent_dir_project` must follow this order:

```
<parent_dir_project>/<project>/<reaction>/<supplier>/<material>/<power mode>/lissajous/<run folder>/<capture>.psdata
```

| Level | Example | Becomes |
|---|---|---|
| project | `plasmacatdesign` | `project_name` |
| reaction | `co2-splitting` | `reaction_type` |
| supplier | `uhasselt` | `material_supplier` |
| material | `SiO2+TMAH-220-03H` | `material_name` |
| power mode | `pwr-const` | `wattage_const` |
| fixed word | `lissajous` | – (required) |
| run folder | `10.0s-01-plasma-01` | `residence_time_s` = 10.0, `measurement_number` = 1, `plasma_state` = plasma |
| capture | `20240220-0017.psdata` | `date` = 2024-02-20 |

- Folders whose path contains `ignore` are skipped.
- A folder that already contains `lissajous_data.parquet` is skipped unless you tick "delete existing" in the notebook.
- A configurable layout is on the [to-do list](../../to-do.md).

## Checklist for a new setup

1. Compute `C_diel_F` from your geometry, and measure an empty-reactor no-plasma reference.
2. Set `ac_freq_Hz` and scale the time settings.
3. Run one folder and look at `lissajous_figure.png`:
   - Is the loop parallelogram-like?
   - Do the fitted lines follow the branches?
   - Are the ignition voltages (vertical lines) at the corners?
4. Check the fraction of valid cycles (`parallelogram_valid`), `current_noise_sigma_A`, `pulse_width_median_s` and `n_pulses_too_wide`.
5. Check `calculated_shift_s`. Values of several µs mean the charge probe needs tuning.
6. Check `power_quadrature_W` relative to `power_plasma_W` ([limitations](05-known-limitations.md#the-lag-term-in-the-plasma-off-fit)).
