# 4. Output columns

Every column written by the electrical pipeline, with its unit, its meaning in plain language and how much to trust it.

**Trust levels:**
- **Solid**: measured with few assumptions. Report with confidence (after the probe checks in the [experimental guide](06-experimental-guide.md)).
- **Model**: depends on an equivalent circuit and on input capacitances. Report with the caveats in [Known limitations](05-known-limitations.md). Use for comparing materials rather than as absolute values.
- **Indicative**: depends on detection settings and on the probe bandwidth. Use only for comparisons within one study with identical settings.
- **Check**: diagnostic. Not a result, but tells you whether other results can be trusted.

Naming: `_neg` is the falling half-period (plasma ignites at negative voltage), `_pos` the rising half-period, `_avg` their mean. Step numbers (B1–B16, C1–C4) refer to [Calculation steps](03-calculation-steps.md).

## `lissajous_data.parquet` (input to the calculation)

| Column | Unit | Meaning |
|---|---|---|
| `time_s` | s | Time within the capture |
| `charge_C` | C | Charge from the monitor capacitor |
| `voltage_V` | V | Applied voltage |
| `current_reactor_A` | A | Reactor current (Rogowski coil) |
| `current_source_A` | A | Amplifier output current |
| `project_name`, `reaction_type`, `material_supplier`, `material_name`, `wattage_const` | text | Taken from the folder names ([layout](07-adapting-to-your-reactor.md#folder-layout)) |
| `residence_time_s` | s | Residence (space) time, from the run folder name |
| `measurement_number` | – | Run number, from the run folder name |
| `plasma_state` | text | e.g. `plasma`, from the run folder name |
| `date` | YYYY-MM-DD | From the capture file name |
| `psdata_file_name` | text | Capture file name |

## `lissajous_calculations.parquet`: one row per AC cycle

`lissajous_calculations_no_outliers.parquet` has the same columns, with gross failures removed (C1). `lissajous_calculations_no_outliers_avg.csv` has the per-capture means of the numeric columns (C2).

### Identification
| Column | Unit | Meaning |
|---|---|---|
| `project_name` … `plasma_state` | – | As in the input; `measurement_date` = `date` |
| `psdata_file_name` | – | Capture the cycle comes from |
| `cycle` | – | Cycle number within the capture (1 = first) |

### Power, voltage and currents
| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `power_plasma_W` | W | Solid | Power into the reactor, from the area of the Q–V loop (B12). Forced to match `power_plasma_UIprod_W` per capture by the time shift (B4). |
| `power_plasma_UIprod_W` | W | Solid | Power as the mean of voltage × Rogowski current (B12) |
| `power_source_W` | W | Solid | Power delivered by the amplifier, incl. losses in cables and connections (B12) |
| `U_pp_V` | V | Solid | Peak-to-peak applied voltage |
| `current_rms_reactor_A` | A | Solid | RMS reactor current |
| `current_rms_source_A` | A | Solid | RMS amplifier current |
| `current_rms_plasma_A` | A | Model | RMS of the plasma current (B13) |

### Capacitances (slopes of the Q–V figure)
| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `C_cell_neg_F`, `C_cell_pos_F`, `C_cell_avg_F` | F | Model | Cell capacitance: slope without plasma (B7). Includes stray capacitance; reads ~20% high in our data. |
| `C_cell_neg_intrcpt_C`, `C_cell_pos_intrcpt_C` | C | Model | Charge on the plasma-off line where the voltage crosses zero; their difference is $Q_0$ (B11) |
| `C_diel_eff_neg_F`, `C_diel_eff_pos_F`, `C_diel_eff_avg_F` | F | Model | Effective dielectric capacitance $\zeta_\text{diel}$: straight-line slope while the plasma is on (B7) |
| `C_diel_eff_neg_intrcpt_C`, `C_diel_eff_pos_intrcpt_C` | C | Check | Intercept of that line, only for drawing the figure |
| `C_diel_eff_max_neg_F`, `C_diel_eff_max_pos_F`, `C_diel_eff_max_avg_F` | F | Model | Steepest local slope while the plasma is on, $\zeta_\text{max}$ (B7) |

### Discharge characteristics
| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `U_ignition_neg_V`, `U_ignition_pos_V` | V | Solid | Applied voltage at the first current pulse of the half-period (point B) (B7) |
| `U_breakdown_neg_V`, `U_breakdown_pos_V`, `U_breakdown_avg_V` | V | Model | Gas voltage at breakdown, $U_D$ (B9). Preferred over $U_b$ for packed beds. |
| `U_burning_neg_V`, `U_burning_pos_V`, `U_burning_avg_V` | V | Model | Gas voltage while the plasma conducts, $U_b$ (B8). Not well defined for almond-shaped figures. |
| `alpha_neg`, `alpha_pos`, `alpha_avg` | – | Model | Non-discharging fraction $\alpha$ (B10) |
| `beta_neg`, `beta_pos`, `beta_avg` | – | Model | Discharging fraction $\beta = 1-\alpha$ (B10). In a packed bed also reflects charge trapped on the beads. |
| `Q_delta_dis_neg_C`, `Q_delta_dis_pos_C` | C | Model | Charge carried across the gas per half-period (B11) |
| `Q_delta_dis_per_cycle_C` | C | Model | Sum of both half-periods |
| `Q_delta_dis_per_dis_avg_C` | C | Model | Mean of both half-periods |

### Current pulses
| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `avg_num_udisch_per_cycle` | count | Indicative | Number of current pulses in the cycle (B14). Despite the name, this is a count per cycle; averaging happens later. |
| `avg_num_udisch_per_cycle_corr` | count | Indicative | Pulses whose integrated charge is positive |
| `Q_udisch_per_cycle_total_C` | C | Indicative | Total charge in the pulses |
| `Q_udisch_per_cycle_avg_C` | C | Indicative | Mean charge per pulse |
| `Q_frac_in_udisch` | – | Indicative | Pulse charge / `Q_delta_dis_per_cycle_C` |
| `pulse_band_rms_A` | A | Indicative | RMS plasma current in `pulse_band_Hz` (B15). Grows with both number and height of pulses; needs no detection settings. |
| `pulse_width_median_s` | s | Check | Median width of the accepted pulses |
| `n_pulses_too_wide` | count | Check | Peaks rejected as wider than `max_pulse_width_s`. Many rejects means checking the width limit. |
| `current_noise_sigma_A` | A | Check | Noise level of the high-pass reactor current, mostly the oscilloscope's step size. The pulse threshold should be ≫ this value (≥ 10×). |

### Quality checks
| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `parallelogram_valid` | 1 / 0 / NaN | Check | 1: both half-periods pass the validity check (B7); 0: at least one fails (slope outputs set to NaN); NaN: incomplete half-period at the edge of the capture |
| `flipped_Q`, `flipped_I`, `flipped_Is` | 1 / 0 | Check | Whether the sign of a probe was corrected (B1) |
| `calculated_shift_s` | s | Check | Time shift applied to the charge (B4). Large or day-dependent values point to a badly tuned probe. |
| `delay_eff_off_neg_s`, `delay_eff_off_pos_s` | s | Check | Remaining lag of $Q$ behind $V$ in the plasma-off branch, $-b/C_\text{cell}$ (B7) |
| `C_cell_fit_se_neg_F`, `C_cell_fit_se_pos_F` | F | Check | Standard error of the $C_\text{cell}$ fit |
| `C_cell_window_sens_neg`, `C_cell_window_sens_pos` | – | Check | Relative change of $C_\text{cell}$ when the fit window starts later (≤ 0.10 to pass) |
| `iq_resid_rel_neg`, `iq_resid_rel_pos` | – | Check | Residual of the plasma-off fit relative to the charge amplitude (≤ 0.008 to pass) |
| `pulse_frac_on_neg`, `pulse_frac_on_pos` | – | Check | Fraction of the plasma-on window with pulse activity |
| `n_off_points_neg`, `n_off_points_pos`, `n_on_points_neg`, `n_on_points_pos` | count | Check | Number of points in the fit windows (≥ 50 needed) |
| `power_quadrature_W` | W | Check | Power carried by the lag term of the plasma-off fit (B16). A large share of `power_plasma_W` means part of the power cannot be attributed. |
| `power_ratio_UbQdis` | – | Check | $2U_b\Delta Q_\text{dis}f/P$; 1 for an ideal parallelogram (B16) |
| `power_manley_W` | W | Check | Power predicted by the generalised Manley equation (B16) |

## `profile_data.parquet`: time traces (every 100th sample)

All input columns, plus:

| Column | Unit | Trust | Meaning |
|---|---|---|---|
| `dQ_dV` | F | Check | Local slope of the smoothed Q–V curve; very large near the voltage extremes, where $dV \to 0$ |
| `current_plasma_A` | A | Model | Plasma current (PB19 eq. 3) |
| `current_displacement_A` | A | Model | Measured minus plasma current: the true displacement current |
| `charge_plasma_C` | C | Model | Charge transferred by the plasma (P15 eq. A12) |
| `voltage_gap_V` | V | Model | Voltage across the gas (P15 eq. 3). Assumes a constant burning voltage. |
| `wave_index` | – | – | Period number within the capture, 0–5 (assumes 6 periods per capture) |
| `current_index` | – | – | Half-period number, 0–11 |
| `current_sign` | ±1 | – | Label alternating per half-period. It assumes the capture starts at a half-period boundary, so it is **not** the measured sign of the current. |
