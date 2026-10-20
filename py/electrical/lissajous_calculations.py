# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "marimo",
#     "numpy>=2",
#     "pandas>=2.2",
#     "pyarrow>=19",
#     "scipy>=1.15",
#     "matplotlib>=3.10",
# ]
# [tool.uv]
# exclude-newer = "2026-10-20T00:00:00Z"
# ///

import marimo

__generated_with = "0.25.2"
app = marimo.App()


@app.cell
def _():
    import marimo as mo

    return (mo,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    # Lissajous (charge–voltage) calculations

    This notebook turns the oscilloscope data of a DBD plasma reactor into numbers you can report: plasma power, the capacitances of the reactor, how much of the packed bed discharges, the voltage across the gas, the charge carried by the plasma, and indicators of current pulses.

    **Input:** `lissajous_data.parquet` files made by `psdata_conversion_and_consolidation.py`. One per reactor-run folder.
    **Output, written next to each input file:**
    - `lissajous_calculations.parquet`: one row per AC cycle;
    - the same with gross failures removed, plus an average per capture (`.csv`);
    - `lissajous_figure.png`;
    - `profile_data.parquet`.

    **How to use:** set `top_folder` in the configuration cell below (default: `example-data/` in the repository root) and press **Run calculations**.

    **Documentation** (written for chemists, no physics background assumed):
    [what we measure](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/01-what-we-measure.md) ·
    [equivalent circuits](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/02-equivalent-circuits.md) ·
    [calculation steps](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/03-calculation-steps.md) ·
    [output columns](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/04-output-columns.md) ·
    [known limitations](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/05-known-limitations.md) ·
    [experimental guide](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/06-experimental-guide.md) ·
    [adapting to your reactor](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/07-adapting-to-your-reactor.md) ·
    [references](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/08-references.md)
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.callout(mo.md(r"""
    **Before you report numbers, read the [known limitations](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/05-known-limitations.md).**

    1. **Plasma power** (`power_plasma_W`) is the most robust result.
    2. **Capacitances, `beta`, `U_breakdown` and `Q_delta_dis`** depend on an equivalent-circuit model that was not made for packed beds. Use them to compare materials measured the same way; their absolute values are uncertain. Prefer `U_breakdown` over `U_burning`.
    3. A **lag term** in the plasma-off fit carries about a third of the power and of the transferred charge in our data, and its origin is unresolved. Check `power_quadrature_W`.
    4. **Current-pulse metrics** are indicative only: with a 10 ns Rogowski coil they depend on the detection settings.
    5. Runs with **elliptical** Q–V figures (few cycles with `parallelogram_valid == 1`) give power only.
    """), kind="warn")
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 0 · Libraries and settings

    `top_folder` is the folder to process: every subfolder that contains a `lissajous_data.parquet` is calculated. The other settings (frequency, dielectric capacitance, detection limits) are arguments of `calculate_results` and are explained in [adapting to your reactor](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/07-adapting-to-your-reactor.md).
    """)
    return


@app.cell
def _():
    import os
    import gc
    import numpy as np
    import pandas as pd
    import matplotlib.pyplot as plt
    from scipy.signal import savgol_filter
    from scipy.signal import find_peaks, peak_widths
    from scipy.signal import butter, sosfiltfilt
    from scipy.ndimage import uniform_filter1d
    from scipy.optimize import differential_evolution

    return (
        butter,
        differential_evolution,
        find_peaks,
        gc,
        np,
        os,
        pd,
        peak_widths,
        plt,
        savgol_filter,
        sosfiltfilt,
        uniform_filter1d,
    )


@app.cell
def _(mo, os):
    # Folder to process; default: example-data/ in the repository root.
    # Replace with your own path, e.g. r'D:\data\my_project'
    top_folder = os.path.normpath(
        os.path.join(str(mo.notebook_dir()), '..', '..', 'example-data')
    )

    # Column names for the result .csv file
    column_names_new = [
        'project_name',
        'psdata_file_name',
        'measurement_date',
        'measurement_number',
        'material_supplier',
        'material_name',
        'reaction_type',
        'wattage_const',
        'residence_time_s',
        'plasma_state',
        'cycle',
        'power_plasma_W',
        'power_plasma_UIprod_W',
        'power_source_W',
        'U_pp_V',
        'current_rms_reactor_A',
        'current_rms_plasma_A',
        'current_rms_source_A',
        'U_burning_neg_V',
        'U_burning_pos_V',
        'U_burning_avg_V',
        'U_breakdown_neg_V',
        'U_breakdown_pos_V',
        'U_breakdown_avg_V',
        'Q_delta_dis_pos_C',
        'Q_delta_dis_neg_C',
        'Q_delta_dis_per_cycle_C',
        'Q_delta_dis_per_dis_avg_C',
        'avg_num_udisch_per_cycle',
        'avg_num_udisch_per_cycle_corr',
        'Q_udisch_per_cycle_total_C',
        'Q_udisch_per_cycle_avg_C',
        'Q_frac_in_udisch',
        'C_cell_neg_F',
        'C_cell_neg_intrcpt_C',
        'C_cell_pos_F',
        'C_cell_pos_intrcpt_C',
        'C_cell_avg_F',
        'C_diel_eff_neg_F',
        'C_diel_eff_neg_intrcpt_C',
        'C_diel_eff_pos_F',
        'C_diel_eff_pos_intrcpt_C',
        'C_diel_eff_avg_F',
        'C_diel_eff_max_neg_F',
        'C_diel_eff_max_pos_F',
        'C_diel_eff_max_avg_F',
        'U_ignition_neg_V',
        'U_ignition_pos_V',
        'alpha_neg',
        'alpha_pos',
        'alpha_avg',
        'beta_neg',
        'beta_pos',
        'beta_avg',
        'parallelogram_valid',
        'flipped_Q',
        'flipped_I',
        'flipped_Is',
        'delay_eff_off_neg_s',
        'delay_eff_off_pos_s',
        'C_cell_fit_se_neg_F',
        'C_cell_fit_se_pos_F',
        'C_cell_window_sens_neg',
        'C_cell_window_sens_pos',
        'iq_resid_rel_neg',
        'iq_resid_rel_pos',
        'pulse_frac_on_neg',
        'pulse_frac_on_pos',
        'n_off_points_neg',
        'n_off_points_pos',
        'n_on_points_neg',
        'n_on_points_pos',
        'calculated_shift_s',
        'power_quadrature_W',
        'power_ratio_UbQdis',
        'power_manley_W',
        'current_noise_sigma_A',
        'pulse_band_rms_A',
        'pulse_width_median_s',
        'n_pulses_too_wide'
    ]
    return column_names_new, top_folder


@app.cell
def _(mo):
    # Nothing is deleted or recalculated until the button is pressed,
    # so editing a cell above does not trigger a full recalculation
    run = mo.ui.run_button(label="Run calculations")
    run
    return (run,)


@app.cell
def _(np):
    def lissajous_area(x, y):
        # Perform numerical integration of the Lissaous curve to calculate the plasma power
        return 0.5 * np.abs(np.dot(x, np.roll(y, 1)) - np.dot(y, np.roll(x, 1)))

    return (lissajous_area,)


@app.cell
def _(lissajous_area, np):
    def objective_function(
            shift, data, U, Q, ac_freq_Hz, num_cycles, power_plasma_UIprod_W
    ):
        # Round the shift to the nearest integer
        shift = int(np.round(shift).item())

        # Apply the shift to the charge column
        shifted_charge = np.roll(data[Q], -shift)

        # Calculate plasma power using the Lissajous area
        power_plasma_W = lissajous_area(data[U], shifted_charge) * ac_freq_Hz / num_cycles

        # Return the absolute difference between the two power values
        return np.abs(power_plasma_W - power_plasma_UIprod_W)

    return (objective_function,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    The calculation is split into functions, each responsible for one task:
    - `calculate_results` (step 1): all per-cycle results
    - `remove_outliers` (step 2): removes cycles with gross failures
    - `lissajous_figure_generation` (step 3): the average Q–V figure
    - `profile_calculation` (step 4): down-sampled time traces with plasma current and gap voltage
    """)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 1 · `calculate_results`: everything per AC cycle

    Per oscilloscope capture this step:
    1. checks the probe signs and keeps whole periods only;
    2. removes offsets and corrects the time delay of the charge probe;
    3. finds where the plasma is active from the current pulses;
    4. fits the slopes of the Q–V figure;
    5. derives power, capacitances, partial discharging, the gas voltages, the transferred charge, the plasma current and current-pulse metrics.

    Each sub-step, its formula and its reference: [calculation steps, part B](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/03-calculation-steps.md#part-b-from-the-data-table-to-results).
    """)
    return


@app.cell
def _(np, peak_widths):
    def integrate_microdischarge_charge(
        t,
        I,
        peaks,
        rel_height=0.9
    ):
        """
        Integrate baseline-subtracted plasma current peaks
        to obtain total microdischarge charge.

        Parameters
        ----------
        t : np.ndarray
            Time array (s)
        I : np.ndarray
            Plasma current array (A)
        peaks : np.ndarray
            Indices of detected peaks
        rel_height : float
            Relative height for peak width determination (0 < rel_height < 1)

        Returns
        -------
        Q_micro : float
            Total microdischarge charge (C)
        Q_peaks : np.ndarray
            Charge per microdischarge (C)
        """

        _, _, left_ips, right_ips = peak_widths(
            I, peaks, rel_height=rel_height
        )

        Q_peaks = []

        for l, r in zip(left_ips, right_ips):
            li = int(np.floor(l))
            ri = int(np.ceil(r))

            if ri <= li + 1:
                continue

            seg_t = t[li:ri + 1]
            seg_I = I[li:ri + 1]

            # Linear baseline between endpoints
            baseline = np.interp(
                seg_t,
                [seg_t[0], seg_t[-1]],
                [seg_I[0], seg_I[-1]]
            )

            Q = np.trapezoid(seg_I - baseline, seg_t)

            # Safety: reject negative or unphysical integrals
            if Q > 0:
                Q_peaks.append(Q)

        Q_peaks = np.asarray(Q_peaks)

        return Q_peaks.sum(), Q_peaks

    return (integrate_microdischarge_charge,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    **Slope fits per half-period** (`slope_method='iq'`):
    - *Plasma off* runs from the end of pulse activity at a voltage extremum to the first new pulse (point B, ignition). Activity is found in the high-pass filtered reactor current, independent of the charge, the capacitances and the time shift.
    - *Plasma-off fit*: `Q = C_cell·V + b·dV/dt + c`. The `b` term absorbs a lag of Q behind V. It is a model element the later steps do not use: see [known limitations](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/05-known-limitations.md#the-lag-term-in-the-plasma-off-fit).
    - *Plasma on* runs from B to the next extremum. `C_diel_eff` is the straight-line slope; `C_diel_eff_max` is the steepest local slope (Peeters & Butterworth 2019 §3.2).
    - *Validity check*: when the fit residual or the window sensitivity of `C_cell` is too large, all slope-based outputs of the cycle are left empty (NaN).
    `slope_method='legacy'` reproduces the old windows for comparison.
    """)
    return


@app.cell
def _(butter, np, sosfiltfilt, uniform_filter1d):
    # Per half-cycle outputs of half_cycle_slopes
    HALF_CYCLE_KEYS = [
        'C_cell_F',
        'C_cell_intrcpt_C',
        'C_cell_fit_se_F',
        'C_cell_window_sens',
        'delay_eff_off_s',
        'C_diel_eff_F',
        'C_diel_eff_intrcpt_C',
        'C_diel_eff_max_F',
        'U_ignition_V',
        'V_ext_V',
        'iq_resid_rel',
        'pulse_frac_on',
        'n_off_points',
        'n_on_points'
    ]

    # Outputs that only exist if the parallelogram model applies
    SLOPE_KEYS = [
        'C_cell_F',
        'C_cell_intrcpt_C',
        'C_diel_eff_F',
        'C_diel_eff_intrcpt_C',
        'C_diel_eff_max_F'
    ]


    def align_polarity(V, Q, I, I_source, decimate=50):
        """
        Detect inverted probe channels, with the applied voltage as reference.

        Physical checks, independent of the trigger phase:
        - charge follows voltage (Q ~ C_cell * V): corr(V, Q) > 0
        - the reactor current is the derivative of the charge: corr(I, dQ/dt) > 0
        - the source delivers power: mean(V * I_source) > 0
        An inverted V cannot be told apart from Q, I and I_source all inverted;
        in that case all three are flipped (pos and neg labels swap).

        Returns
        -------
        flip_Q, flip_I, flip_I_source : bool
        """
        v, q, i, i_s = (np.asarray(x)[::decimate] for x in (V, Q, I, I_source))
        flip_Q = np.corrcoef(v, q)[0, 1] < 0
        if flip_Q:
            q = -q
        flip_I = np.corrcoef(i, np.gradient(q))[0, 1] < 0
        flip_I_source = np.mean(v * i_s) < 0

        # Cross-check: after correction the reactor must absorb power
        if np.mean(v * (-i if flip_I else i)) < 0:
            print('Warning: reactor power negative after polarity correction')

        return flip_Q, flip_I, flip_I_source


    def discharge_activity(
        I,
        dt,
        decimate,
        hp_cutoff_Hz=1e6,
        k_med=5,
        smooth_s=10e-6
    ):
        """
        Microdischarge activity from the high-pass filtered reactor current.

        Independent of Q, C_cell and the charge time shift. The envelope is the
        maximum |I_hp| per block of `decimate` samples; a block is active if
        it exceeds k_med times the median envelope (the noise floor).

        Returns
        -------
        density : np.ndarray
            Fraction of active blocks in a moving window of smooth_s,
            one value per block
        noise_sigma : float
            Robust standard deviation (1.4826 MAD) of I_hp in the inactive
            blocks, the noise floor for pulse detection
        """
        sos = butter(4, hp_cutoff_Hz, 'hp', fs=1 / dt, output='sos')
        I_hp = sosfiltfilt(sos, I)
        n = len(I_hp) // decimate * decimate
        envelope = np.abs(I_hp[:n]).reshape(-1, decimate).max(axis=1)
        active = envelope > k_med * np.median(envelope)
        quiet = I_hp[:n].reshape(-1, decimate)[~active].ravel()
        noise_sigma = 1.4826 * np.median(np.abs(quiet - np.median(quiet)))
        window = max(1, int(round(smooth_s / (dt * decimate))))
        return uniform_filter1d(active.astype(float), window), noise_sigma


    def fit_iq(V, dVdt, Q):
        """
        Least squares Q = C * V + b * dV/dt + c.

        C is the capacitance in phase with V. The quadrature term b * dV/dt
        absorbs a lag of Q behind V (time misalignment or lossy capacitive
        elements), which otherwise curves the plasma-off branch and makes a
        plain linear fit depend on the fit window. For a pure delay,
        b / C = -delay.

        Returns
        -------
        coef : np.ndarray
            [C, b, c]
        resid_std : float
            Standard deviation of the residuals (C)
        coef_se : np.ndarray
            Standard errors of coef
        """
        A = np.column_stack([V, dVdt, np.ones(len(V))])
        coef, *_ = np.linalg.lstsq(A, Q, rcond=None)
        resid = Q - A @ coef
        dof = max(1, len(Q) - A.shape[1])
        cov = np.linalg.pinv(A.T @ A) * (resid @ resid) / dof
        return coef, resid.std(), np.sqrt(np.diag(cov))


    def max_local_slope(V, Q, frac=0.2, step=0.05):
        # Steepest local dQ/dV (zeta_max) from sliding linear fits
        n = len(V)
        w = max(10, int(frac * n))
        s = max(1, int(step * n))
        return max(
            np.polyfit(V[i:i + w], Q[i:i + w], 1)[0]
            for i in range(0, n - w + 1, s)
        )


    def half_cycle_slopes(
        t,
        V,
        V_smooth,
        dVdt,
        Q,
        density,
        samples_per_period,
        on_threshold=0.05,
        min_points=50,
        sens_start=0.5,
        max_resid_rel=0.008,
        max_window_sens=0.10
    ):
        """
        Segment every half-cycle (V extremum to next V extremum) into
        - plasma-off: the longest run without discharge activity, from the
          end of activity at the extremum until the first microdischarge
          (point B)
        - plasma-on: B until the next extremum
        and fit the slopes.

        Validity gate: the plasma-off fit residual relative to the charge
        amplitude must be <= max_resid_rel and C_cell may change by at most
        max_window_sens when the window starts at sens_start * |V_ext|
        instead of at the end of discharge activity.

        Returns
        -------
        halves : list of dict
            One per complete half-cycle, with HALF_CYCLE_KEYS plus
            t_ext (time of the starting extremum), sign (+1 falling A-B-C,
            -1 rising C-D-A) and valid (NaN if no fit was possible)
        """
        Q_amp = np.ptp(Q) / 2

        # V extrema, one index per extremum
        ext = np.flatnonzero(np.diff(np.sign(dVdt)) != 0)
        ext = ext[np.abs(V_smooth[ext]) > 0.9 * np.abs(V_smooth).max()]
        ext = [
            e for i, e in enumerate(ext)
            if i == 0 or e - ext[i - 1] > samples_per_period // 10
        ]

        halves = []
        for ia, ib in zip(ext[:-1], ext[1:]):
            res = dict.fromkeys(HALF_CYCLE_KEYS, np.nan)
            res.update(
                t_ext=t[ia], sign=np.sign(V_smooth[ia]), valid=np.nan,
                V_ext_V=V_smooth[ia]
            )
            halves.append(res)

            # Longest quiet run, robust to flicker at the extremum and to
            # isolated pulses; it must end in activity (point B)
            active = np.r_[True, density[ia:ib] > on_threshold, True]
            edges = np.flatnonzero(np.diff(active.astype(int)))
            starts, ends = edges[0::2], edges[1::2]
            if len(starts) == 0:
                continue
            longest = np.argmax(ends - starts)
            if ia + ends[longest] >= ib:
                continue
            i_off = ia + starts[longest]
            i_B = ia + ends[longest]
            active = active[1:-1]
            off = np.arange(i_off, i_B)
            on = np.arange(i_B, ib)
            res.update(
                U_ignition_V=V_smooth[i_B],
                pulse_frac_on=active[i_B - ia:].mean(),
                n_off_points=len(off),
                n_on_points=len(on)
            )
            if len(off) < min_points or len(on) < min_points:
                continue

            # Plasma-off: C_cell
            (C_cell, b, c), resid_std, coef_se = fit_iq(V[off], dVdt[off], Q[off])

            # Window sensitivity: refit starting at sens_start * |V_ext|
            late = off[res['sign'] * V_smooth[off] <= sens_start * abs(V_smooth[ia])]
            if len(late) >= min_points:
                C_late = fit_iq(V[late], dVdt[late], Q[late])[0][0]
                res['C_cell_window_sens'] = abs(C_late - C_cell) / C_cell

            # Intercept: model charge at the zero crossing of V
            zero = off[:-1][np.diff(np.sign(V_smooth[off])) != 0]
            intercept = c + b * dVdt[zero[0]] if len(zero) else np.nan

            # Plasma-on: remove the same quadrature term, then linear fits
            Q_on = Q[on] - b * dVdt[on]
            C_diel_eff = np.polyfit(V[on], Q_on, 1)[0]
            # Intercept (for plotting only) through the measured on-branch
            C_diel_eff_intrcpt = np.mean(Q[on] - C_diel_eff * V[on])

            res.update(
                C_cell_F=C_cell,
                C_cell_intrcpt_C=intercept,
                C_cell_fit_se_F=coef_se[0],
                delay_eff_off_s=-b / C_cell,
                C_diel_eff_F=C_diel_eff,
                C_diel_eff_intrcpt_C=C_diel_eff_intrcpt,
                C_diel_eff_max_F=max_local_slope(V[on], Q_on),
                iq_resid_rel=resid_std / Q_amp
            )
            res['valid'] = bool(
                res['iq_resid_rel'] <= max_resid_rel
                and res['C_cell_window_sens'] <= max_window_sens
            )

        return halves


    def select_half_cycle(halves, sign, t_start, t_end):
        # Half-cycle of the given sign whose starting extremum lies in the cycle
        for h in halves:
            if h['sign'] == sign and t_start <= h['t_ext'] < t_end:
                return h
        return {**dict.fromkeys(HALF_CYCLE_KEYS, np.nan), 'valid': np.nan}

    return (
        HALF_CYCLE_KEYS,
        SLOPE_KEYS,
        align_polarity,
        discharge_activity,
        half_cycle_slopes,
        select_half_cycle,
    )


@app.cell
def _(
    HALF_CYCLE_KEYS,
    SLOPE_KEYS,
    align_polarity,
    differential_evolution,
    discharge_activity,
    find_peaks,
    half_cycle_slopes,
    integrate_microdischarge_charge,
    lissajous_area,
    np,
    objective_function,
    pd,
    savgol_filter,
    select_half_cycle,
):
    def calculate_results(
            data_df,
            result_column_names,
            ac_freq_Hz=3000,
            C_diel_F=204e-12,
            discharge_threshold_A=7.5e-3,
            max_pulse_width_s=1e-6,
            pulse_band_Hz=(0.2e6, 10e6),
            t='time_s',
            Q='charge_C',
            U='voltage_V',
            Ir='current_reactor_A',
            Is='current_source_A',
            smoothing_fraction=0.025,
            slope_method='iq',
            slope_dt_s=0.32e-6,
            slope_smoothing_s=32e-6,
            max_resid_rel=0.008,
            max_window_sens=0.10,
            de_seed=0
    ):
        # Extract some variables from the data
        project_name = data_df['project_name'].iloc[0]
        reaction_type = data_df['reaction_type'].iloc[0]
        material_supplier = data_df['material_supplier'].iloc[0]
        material_name = data_df['material_name'].iloc[0]
        wattage_const = data_df['wattage_const'].iloc[0]
        residence_time_s = data_df['residence_time_s'].iloc[0]
        measurement_number = data_df['measurement_number'].iloc[0]
        plasma_state = data_df['plasma_state'].iloc[0]
        date = data_df['date'].iloc[0]

        # Other variables
        ac_period_s = 1 / ac_freq_Hz

        # Initialize the result DataFrame
        results_psdata_files = []

        # Initialize columns for smoothed data in the original dataframe
        data_df['dV_dt'] = np.nan
        data_df['dQ_dV'] = np.nan

        # Loop over the grouped data by the column 'psdata_file_name'
        for psdata_file_name, group_data in data_df.groupby('psdata_file_name'):
            print(f'Processing {psdata_file_name}...')

            data = group_data.copy()

            # Sort data by 't'
            data.sort_values(by=t, inplace=True)

            # Make t start at 0
            data[t] = data[t] - data[t].iloc[0]

            # Align probe polarities with the applied voltage as reference
            # (the sign of the first sample depends on the trigger phase)
            flipped_Q, flipped_I, flipped_Is = align_polarity(
                data[U], data[Q], data[Ir], data[Is]
            )
            for col, flip in [(Q, flipped_Q), (Ir, flipped_I), (Is, flipped_Is)]:
                if flip:
                    data[col] = -data[col]
                    print(f'Polarity of {col} flipped')

            # Calculate the number of full cycles
            num_cycles = int(np.floor(
                (data[t].iloc[-1] - data[t].iloc[0]) / ac_period_s
            ))

            # Calculate the total time of the full cycles
            full_cycle_time = num_cycles * ac_period_s

            # Select the full cycles
            data = data[data[t] < data[t].iloc[0] + full_cycle_time].copy()

            # Remove the offsets of charge and voltage over the full cycles
            # (P15 section 4.1: Q and V average to zero over a period)
            data[Q] = data[Q] - data[Q].mean()
            data[U] = data[U] - data[U].mean()

            # Calculate plasma power using the product of U and I
            power_plasma_UIprod_W = np.mean(data[U] * data[Ir])

            # Calculate time per row
            t_per_row = data[t].iloc[1] - data[t].iloc[0]

            # Define the bounds for the shift
            shift_bounds = [(0, int((ac_period_s / 10) / t_per_row))]

            # Run the differential evolution algorithm
            result = differential_evolution(
                objective_function,
                bounds=shift_bounds,
                args=(data, U, Q, ac_freq_Hz, num_cycles, power_plasma_UIprod_W),
                strategy='best1bin',
                maxiter=1000,
                popsize=15,
                tol=1e-6,
                mutation=(0.5, 1.0),
                recombination=0.7,
                rng=de_seed
            )

            # Extract the optimized shift value
            optimized_shift = int(np.round(result.x[0]))
            calculated_shift_s = optimized_shift * t_per_row

            print(f"Optimized shift: {calculated_shift_s * 1e6} µs")

            # Apply the optimized shift to the charge column
            data.loc[:, Q] = np.roll(data[Q], -optimized_shift)

            # Smooth voltage_V and charge_C using a Savitzky-Golay filter
            smoothing_window_size = int(np.floor(smoothing_fraction * len(data[t])))
            print(f"Calculated smoothing window size: {smoothing_window_size} (typically 15625)")

            data.loc[:, 'voltage_smooth_V'] = savgol_filter(
                data[U],
                window_length=smoothing_window_size,
                polyorder=2
            )

            data.loc[:, 'charge_smooth_C'] = savgol_filter(
                data[Q],
                window_length=smoothing_window_size,
                polyorder=2
            )

            # Calculate necessary derivatives
            data.loc[:, 'dV_dt'] = np.gradient(
                        data['voltage_smooth_V'],
                        data[t]
                    )

            data.loc[:, 'dQ_dV'] = np.gradient(
                data['charge_smooth_C'],
                data['voltage_smooth_V']
            )

            # Update the original dataframe with
            # corrected time, shifted charge, and smoothed values
            data_df.loc[data.index, t] = data[t]
            data_df.loc[data.index, Q] = data[Q]
            data_df.loc[data.index, U] = data[U]
            data_df.loc[data.index, Ir] = data[Ir]
            data_df.loc[data.index, Is] = data[Is]
            data_df.loc[data.index, 'dV_dt'] = data['dV_dt']
            data_df.loc[data.index, 'dQ_dV'] = data['dQ_dV']

            # Microdischarge activity and noise floor of the reactor current
            # (decimated: the fits need ~1000 points per half-cycle, not 10^5)
            decimate = max(1, int(round(slope_dt_s / t_per_row)))
            density, noise_sigma_A = discharge_activity(
                data[Ir].to_numpy(), t_per_row, decimate
            )

            # Segment half-cycles on microdischarge activity and fit the slopes
            if slope_method == 'iq':
                dt_dec = t_per_row * decimate
                n_dec = len(density) * decimate
                t_dec = data[t].to_numpy()[:n_dec:decimate]
                V_dec = data[U].to_numpy()[:n_dec:decimate]
                Q_dec = data[Q].to_numpy()[:n_dec:decimate]
                sg_window = int(slope_smoothing_s / dt_dec) | 1
                V_dec_smooth = savgol_filter(V_dec, sg_window, 2)
                dVdt_dec = savgol_filter(
                    V_dec, sg_window, 2, deriv=1, delta=dt_dec
                )
                halves = half_cycle_slopes(
                    t_dec, V_dec, V_dec_smooth, dVdt_dec, Q_dec, density,
                    samples_per_period=int(ac_period_s / dt_dec),
                    max_resid_rel=max_resid_rel,
                    max_window_sens=max_window_sens
                )

            # Initialize the result dictionary
            results_cycles = []

            # Loop over the cycles
            for cycle_num in range(num_cycles):
                try:
                    cycle_start_time = cycle_num * ac_period_s
                    cycle_end_time = (cycle_num + 1) * ac_period_s
                    subset = data[
                        (data[t] >= cycle_start_time) &
                        (data[t] < cycle_end_time)
                    ].copy().reset_index()

                    # Identify zero crossings in smoothed charge
                    zero_crossings = np.where(
                        np.diff(np.sign(subset['charge_smooth_C'])) != 0
                    )[0]

                    # Calculate U_delta_pos_V and U_delta_neg_V
                    if len(zero_crossings) > 0:
                        voltage_just_before = subset.iloc[zero_crossings][U]
                        voltage_just_after = subset.iloc[zero_crossings + 1][U]

                        voltages_around_crossing = pd.concat(
                            [voltage_just_before, voltage_just_after],
                            axis=1
                        )
                        mean_voltages = voltages_around_crossing.mean(axis=1)

                        U_delta_pos_V = mean_voltages[mean_voltages > 0].mean()
                        U_delta_neg_V = mean_voltages[mean_voltages < 0].mean()
                    else:
                        U_delta_pos_V = np.nan
                        U_delta_neg_V = np.nan

                    # Calculate the peak-to-peak voltage
                    U_max_pos_V = subset[U].max()
                    U_max_neg_V = subset[U].min()
                    U_pp_V = np.abs(U_max_pos_V) + np.abs(U_max_neg_V)

                    if slope_method == 'iq':
                        # Falling half-cycle A-B-C gives the 'neg' slopes,
                        # rising half-cycle C-D-A the 'pos' slopes
                        neg = select_half_cycle(
                            halves, 1, cycle_start_time, cycle_end_time
                        )
                        pos = select_half_cycle(
                            halves, -1, cycle_start_time, cycle_end_time
                        )
                        # 1: both half-cycles pass the validity gate, 0: at least one
                        # fails, NaN: a half-cycle is incomplete (record edge)
                        parallelogram_valid = float(neg['valid']) * float(pos['valid'])

                        # No slope-derived output unless both half-cycles are valid
                        if parallelogram_valid != 1:
                            neg = {**neg, **dict.fromkeys(SLOPE_KEYS, np.nan)}
                            pos = {**pos, **dict.fromkeys(SLOPE_KEYS, np.nan)}

                        C_cell_neg_F = neg['C_cell_F']
                        C_cell_neg_intrcpt_C = neg['C_cell_intrcpt_C']
                        C_cell_pos_F = pos['C_cell_F']
                        C_cell_pos_intrcpt_C = pos['C_cell_intrcpt_C']
                        C_diel_eff_neg_F = neg['C_diel_eff_F']
                        C_diel_eff_neg_intrcpt_C = neg['C_diel_eff_intrcpt_C']
                        C_diel_eff_pos_F = pos['C_diel_eff_F']
                        C_diel_eff_pos_intrcpt_C = pos['C_diel_eff_intrcpt_C']
                    else:
                        # Legacy windows: U >= U_max/5 (plasma-off) and Q sign (plasma-on)
                        #    B---------------A
                        #   /               /
                        #  /               /
                        # C---------------D
                        # Calculate indices for A and C and subset data
                        # By determining most extreme values of U and Q
                        U_max_index = subset[U].idxmax()
                        U_min_index = subset[U].idxmin()
                        Q_max_index = subset[Q].idxmax()
                        Q_min_index = subset[Q].idxmin()

                        if Q_max_index < U_min_index:
                            subset_A_C = subset.iloc[Q_max_index:U_min_index]
                        else:
                            subset_A_C = pd.concat(
                                [subset.iloc[Q_max_index:], subset.iloc[:U_min_index]]
                            )

                        if Q_min_index < U_max_index:
                            subset_C_A = subset.iloc[Q_min_index:U_max_index]
                        else:
                            subset_C_A = pd.concat(
                                [subset.iloc[Q_min_index:], subset.iloc[:U_max_index]]
                            )

                        # Calculate the slopes
                        subset_A_B = subset_A_C[
                            subset_A_C[U] >= (U_max_pos_V / 5)
                        ]
                        C_cell_neg_F, C_cell_neg_intrcpt_C = np.polyfit(
                            subset_A_B[U],
                            subset_A_B[Q],
                            1
                        )

                        subset_B_C = subset_A_C[
                            subset_A_C[Q] < 0
                        ]
                        C_diel_eff_neg_F, C_diel_eff_neg_intrcpt_C = np.polyfit(
                            subset_B_C[U],
                            subset_B_C[Q],
                            1
                        )

                        subset_C_D = subset_C_A[
                            subset_C_A[U] <= (U_max_neg_V / 5)
                        ]
                        C_cell_pos_F, C_cell_pos_intrcpt_C = np.polyfit(
                            subset_C_D[U],
                            subset_C_D[Q],
                            1
                        )

                        subset_D_A = subset_C_A[
                            subset_C_A[Q] > 0
                        ]
                        C_diel_eff_pos_F, C_diel_eff_pos_intrcpt_C = np.polyfit(
                            subset_D_A[U],
                            subset_D_A[Q],
                            1
                        )
                        parallelogram_valid = np.nan
                        neg = pos = dict.fromkeys(HALF_CYCLE_KEYS, np.nan)

                    # Calculate slope averages
                    C_cell_avg_F = (C_cell_pos_F + C_cell_neg_F) / 2
                    C_diel_eff_avg_F = (C_diel_eff_pos_F + C_diel_eff_neg_F) / 2
                    C_diel_eff_max_avg_F = (
                        pos['C_diel_eff_max_F'] + neg['C_diel_eff_max_F']
                    ) / 2

                    # Calculate the alpha and beta parameters
                    alpha_pos = (
                        (C_diel_F - C_diel_eff_pos_F) /
                        (C_diel_F - C_cell_pos_F)
                    )
                    alpha_neg = (
                        (C_diel_F - C_diel_eff_neg_F) /
                        (C_diel_F - C_cell_neg_F)
                    )
                    alpha_avg = (alpha_pos + alpha_neg) / 2

                    beta_pos = (
                        (C_diel_eff_pos_F - C_cell_pos_F) /
                        (C_diel_F - C_cell_pos_F)
                    )
                    beta_neg = (
                        (C_diel_eff_neg_F - C_cell_neg_F) /
                        (C_diel_F - C_cell_neg_F)
                    )
                    beta_avg = (beta_pos + beta_neg) / 2

                    # Calculate burning voltages
                    U_burning_pos_V = (
                        (1 - C_cell_pos_F / C_diel_F) /
                        (1 - C_cell_pos_F / C_diel_eff_pos_F) *
                        U_delta_pos_V
                    )
                    U_burning_neg_V = (
                        (1 - C_cell_neg_F / C_diel_F) /
                        (1 - C_cell_neg_F / C_diel_eff_neg_F) *
                        U_delta_neg_V
                    )
                    U_burning_avg_V = (U_burning_pos_V + np.abs(U_burning_neg_V)) / 2

                    # Calculate breakdown voltages
                    # U_D = V_min (1 - C_cell / C_diel) with V_min half the voltage
                    # span from the V extremum to ignition (Brandenburg et al. 2023
                    # eq. 9; De Meyer et al. 2025); uses the measured C_cell, so the
                    # packing is included, and is independent of C_diel_eff
                    V_min_pos_V = np.abs(pos['V_ext_V'] - pos['U_ignition_V']) / 2
                    V_min_neg_V = np.abs(neg['V_ext_V'] - neg['U_ignition_V']) / 2
                    U_breakdown_pos_V = V_min_pos_V * (1 - C_cell_pos_F / C_diel_F)
                    U_breakdown_neg_V = -V_min_neg_V * (1 - C_cell_neg_F / C_diel_F)
                    U_breakdown_avg_V = (
                        U_breakdown_pos_V + np.abs(U_breakdown_neg_V)
                    ) / 2

                    # Calculate Q_null_C
                    Q_null_C = C_cell_neg_intrcpt_C - C_cell_pos_intrcpt_C

                    # Calculate conductively transferred charge
                    Q_delta_dis_pos_C = Q_null_C / (1 - C_cell_pos_F / C_diel_F)
                    Q_delta_dis_neg_C = Q_null_C / (1 - C_cell_neg_F / C_diel_F)
                    Q_delta_dis_total_C = (Q_delta_dis_pos_C + Q_delta_dis_neg_C)
                    Q_delta_dis_avg_C = Q_delta_dis_total_C / 2

                    # Calculate plasma power (W)
                    power_plasma_W = lissajous_area(
                        subset[U], subset[Q]
                    ) * ac_freq_Hz

                    # Calculate plasma power using the product of U and I
                    power_plasma_UIprod_W = np.mean(subset[U] * subset[Ir])

                    # Calculate source power (W)
                    power_source_W = np.mean(subset[U] * subset[Is])

                    # Calculate the RMS current in the reactor
                    current_rms_reactor_A = np.sqrt(np.mean(np.square(subset[Ir])))

                    # Calculate the RMS current in the source
                    current_rms_source_A = np.sqrt(np.mean(np.square(subset[Is])))

                    # Self-consistency diagnostics
                    # Power in the quadrature term b dV/dt of the plasma-off fit
                    # (b = -C_cell delay_eff_off), i.e. a parallel loss element
                    V_amp_V = U_pp_V / 2
                    omega = 2 * np.pi * ac_freq_Hz
                    power_quadrature_W = np.mean([
                        h['C_cell_F'] * h['delay_eff_off_s'] for h in (neg, pos)
                    ]) * omega**2 * V_amp_V**2 / 2

                    # P15 eq. 14: W = 2 U_b Q_dis, ratio 1 for a parallelogram
                    power_ratio_UbQdis = (
                        2 * U_burning_avg_V * Q_delta_dis_avg_C * ac_freq_Hz
                        / power_plasma_W
                    )

                    # Generalised Manley equation (Brandenburg et al. 2023 eq. 13)
                    V_min_avg_V = (V_min_pos_V + V_min_neg_V) / 2
                    power_manley_W = (
                        4 * ac_freq_Hz * beta_avg * (C_diel_F - C_cell_avg_F)
                        * V_min_avg_V * (V_amp_V - V_min_avg_V)
                    )

                    if np.isfinite(C_cell_avg_F):
                        # Calculate plasma current
                        subset['current_plasma_A'] = (
                            1 / (1 - C_cell_avg_F / C_diel_F)
                            ) * (
                            subset[Ir] - C_cell_avg_F * subset['dV_dt']
                        )

                        # Calculate the RMS current of the plasma
                        current_rms_plasma_A = np.sqrt(
                            np.mean(np.square(subset['current_plasma_A']))
                        )

                        # Find peaks in the plasma current
                        # (with the Pearson 4100 the pulses are 170-700 ns wide
                        # and >= 270 ns apart, so these two limits do not bind)
                        peak_distance = int(50e-9 / t_per_row)
                        peak_width = int(15e-9 / t_per_row)
                        I = subset['current_plasma_A'].to_numpy()
                        tt = subset[t].to_numpy()

                        # Band-limited RMS of the plasma current: a spectral
                        # pulse metric after De Meyer et al. 2024, computed on
                        # the PB19 plasma current (Parseval, one-sided rfft)
                        spectrum = np.fft.rfft(I)
                        freqs = np.fft.rfftfreq(len(I), t_per_row)
                        in_band = (
                            (freqs >= pulse_band_Hz[0]) &
                            (freqs <= pulse_band_Hz[1])
                        )
                        pulse_band_rms_A = np.sqrt(
                            2 * np.sum(np.abs(spectrum[in_band])**2)
                        ) / len(I)

                        # Find positive peaks
                        p_pos, props_pos = find_peaks(
                            I,
                            height=discharge_threshold_A,
                            width=peak_width,
                            distance=peak_distance,
                            prominence=discharge_threshold_A
                        )

                        # Reject slow current humps (10-280 us in the test data,
                        # on the scale of the half-period) wider than
                        # max_pulse_width_s; real pulses are 0.1-1 us wide
                        max_width = max_pulse_width_s / t_per_row
                        too_wide_pos = props_pos['widths'] > max_width
                        width_pos = props_pos['widths'][~too_wide_pos]
                        p_pos = p_pos[~too_wide_pos]

                        # Integrate positive peaks
                        Qpos, Qpos_each = integrate_microdischarge_charge(
                            tt,
                            I,
                            p_pos
                        )

                        # Find negative peaks (detect on inverted signal, integrate magnitude)
                        p_neg, props_neg = find_peaks(
                            -I,
                            height=discharge_threshold_A,
                            width=peak_width,
                            distance=peak_distance,
                            prominence=discharge_threshold_A
                        )

                        too_wide_neg = props_neg['widths'] > max_width
                        width_neg = props_neg['widths'][~too_wide_neg]
                        p_neg = p_neg[~too_wide_neg]

                        # Pulse width check: median width of the accepted
                        # pulses and number rejected as too wide
                        widths_all = np.concatenate([width_pos, width_neg])
                        pulse_width_median_s = (
                            np.median(widths_all) * t_per_row
                            if len(widths_all) else np.nan
                        )
                        n_pulses_too_wide = int(
                            too_wide_pos.sum() + too_wide_neg.sum()
                        )

                        # Integrate negative peaks (detect on inverted signal, integrate magnitude)
                        Qneg, Qneg_each = integrate_microdischarge_charge(
                            tt,
                            -I,
                            p_neg
                        )

                        # Total number of microdischarges
                        # without correction
                        num_udisch = len(p_pos) + len(p_neg)

                        # with correction
                        Qall_each = np.concatenate([Qpos_each, Qneg_each])
                        num_udisch_corr = len(Qall_each)

                        # total displaced charge in microdischarges
                        Q_total = Qpos + Qneg

                        # average displaced charge per microdischarge
                        Q_micro_avg_C = np.mean(Qall_each) if num_udisch_corr > 0 else 0

                        # Fraction of Q discharges in microdischarges
                        Q_frac_in_udisch = Q_total / Q_delta_dis_total_C
                    else:
                        current_rms_plasma_A = np.nan
                        pulse_band_rms_A = np.nan
                        pulse_width_median_s = np.nan
                        n_pulses_too_wide = np.nan
                        num_udisch = num_udisch_corr = np.nan
                        Q_total = Q_micro_avg_C = Q_frac_in_udisch = np.nan

                    # Write cycle results to results_cycles
                    results_cycles.append(
                        {
                            'project_name': project_name,
                            'psdata_file_name': psdata_file_name,
                            'cycle': cycle_num + 1,
                            'measurement_date': date,
                            'measurement_number': measurement_number,
                            'material_supplier': material_supplier,
                            'material_name': material_name,
                            'reaction_type': reaction_type,
                            'wattage_const': wattage_const,
                            'residence_time_s': residence_time_s,
                            'plasma_state': plasma_state,
                            'power_plasma_W': power_plasma_W,
                            'power_plasma_UIprod_W': power_plasma_UIprod_W,
                            'power_source_W': power_source_W,
                            'U_pp_V': U_pp_V,
                            'current_rms_reactor_A': current_rms_reactor_A,
                            'current_rms_plasma_A': current_rms_plasma_A,
                            'current_rms_source_A': current_rms_source_A,
                            'U_burning_neg_V': U_burning_neg_V,
                            'U_burning_pos_V': U_burning_pos_V,
                            'U_burning_avg_V': U_burning_avg_V,
                            'U_breakdown_neg_V': U_breakdown_neg_V,
                            'U_breakdown_pos_V': U_breakdown_pos_V,
                            'U_breakdown_avg_V': U_breakdown_avg_V,
                            'Q_delta_dis_pos_C': Q_delta_dis_pos_C,
                            'Q_delta_dis_neg_C': Q_delta_dis_neg_C,
                            'Q_delta_dis_per_cycle_C': Q_delta_dis_total_C,
                            'Q_delta_dis_per_dis_avg_C': Q_delta_dis_avg_C,
                            'avg_num_udisch_per_cycle': num_udisch,
                            'avg_num_udisch_per_cycle_corr': num_udisch_corr,
                            'Q_udisch_per_cycle_total_C': Q_total,
                            'Q_udisch_per_cycle_avg_C': Q_micro_avg_C,
                            'Q_frac_in_udisch': Q_frac_in_udisch,
                            'C_cell_neg_F': C_cell_neg_F,
                            'C_cell_neg_intrcpt_C': C_cell_neg_intrcpt_C,
                            'C_cell_pos_F': C_cell_pos_F,
                            'C_cell_pos_intrcpt_C': C_cell_pos_intrcpt_C,
                            'C_cell_avg_F': C_cell_avg_F,
                            'C_diel_eff_neg_F': C_diel_eff_neg_F,
                            'C_diel_eff_neg_intrcpt_C': C_diel_eff_neg_intrcpt_C,
                            'C_diel_eff_pos_F': C_diel_eff_pos_F,
                            'C_diel_eff_pos_intrcpt_C': C_diel_eff_pos_intrcpt_C,
                            'C_diel_eff_avg_F': C_diel_eff_avg_F,
                            'C_diel_eff_max_neg_F': neg['C_diel_eff_max_F'],
                            'C_diel_eff_max_pos_F': pos['C_diel_eff_max_F'],
                            'C_diel_eff_max_avg_F': C_diel_eff_max_avg_F,
                            'U_ignition_neg_V': neg['U_ignition_V'],
                            'U_ignition_pos_V': pos['U_ignition_V'],
                            'alpha_neg': alpha_neg,
                            'alpha_pos': alpha_pos,
                            'alpha_avg': alpha_avg,
                            'beta_neg': beta_neg,
                            'beta_pos': beta_pos,
                            'beta_avg': beta_avg,
                            'parallelogram_valid': parallelogram_valid,
                            'flipped_Q': float(flipped_Q),
                            'flipped_I': float(flipped_I),
                            'flipped_Is': float(flipped_Is),
                            'delay_eff_off_neg_s': neg['delay_eff_off_s'],
                            'delay_eff_off_pos_s': pos['delay_eff_off_s'],
                            'C_cell_fit_se_neg_F': neg['C_cell_fit_se_F'],
                            'C_cell_fit_se_pos_F': pos['C_cell_fit_se_F'],
                            'C_cell_window_sens_neg': neg['C_cell_window_sens'],
                            'C_cell_window_sens_pos': pos['C_cell_window_sens'],
                            'iq_resid_rel_neg': neg['iq_resid_rel'],
                            'iq_resid_rel_pos': pos['iq_resid_rel'],
                            'pulse_frac_on_neg': neg['pulse_frac_on'],
                            'pulse_frac_on_pos': pos['pulse_frac_on'],
                            'n_off_points_neg': neg['n_off_points'],
                            'n_off_points_pos': pos['n_off_points'],
                            'n_on_points_neg': neg['n_on_points'],
                            'n_on_points_pos': pos['n_on_points'],
                            'calculated_shift_s': calculated_shift_s,
                            'power_quadrature_W': power_quadrature_W,
                            'power_ratio_UbQdis': power_ratio_UbQdis,
                            'power_manley_W': power_manley_W,
                            'current_noise_sigma_A': noise_sigma_A,
                            'pulse_band_rms_A': pulse_band_rms_A,
                            'pulse_width_median_s': pulse_width_median_s,
                            'n_pulses_too_wide': n_pulses_too_wide
                        }
                    )
                except Exception as e:
                    print(f'Error processing cycle {cycle_num + 1} of {num_cycles}...')
                    print(e)
                    continue

            # Write cycle results to results_psdata_files
            results_psdata_files.extend(results_cycles)

        # Create a DataFrame from the results
        results_df = pd.DataFrame(
            results_psdata_files,
            columns=result_column_names
        )

        return data_df, results_df

    return (calculate_results,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 2 · `remove_outliers`: remove gross failures

    Removes cycles where a core quantity deviates more than 20% from its capture's median (calculation glitch), or where the power deviates more than 10% from the run's median (off the power setpoint). It is not a statistical test: cycles differ by only ~1%, so a statistical test would remove good data. [Details](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/03-calculation-steps.md#c1-remove-gross-failures).
    """)
    return


@app.cell
def _(np):
    def remove_outliers(
        results_df,
        max_cycle_deviation=0.20,
        max_power_deviation=0.10
    ):
        """
        Remove cycles with gross failures, not statistical outliers.

        Cycles within one psdata file scatter by only ~1% (core quantities,
        99th percentile 0.4-8%), so statistical tests flag trivial deviations
        and file-to-file drift. Instead, a cycle is removed if
        - a core quantity deviates more than max_cycle_deviation from the
          median of its own psdata file (calculation glitch), or
        - its plasma power deviates more than max_power_deviation from the
          median of the folder (measurement off the power setpoint).
        Microdischarge counts and charges are excluded: they are heavy-tailed
        by nature and should be summarised with medians instead.
        NaN values (cycles where the parallelogram model does not apply)
        never trigger removal.
        """
        try:
            core_columns = [
                'power_plasma_W',
                'U_pp_V',
                'current_rms_plasma_A',
                'U_burning_avg_V',
                'U_breakdown_avg_V',
                'Q_delta_dis_per_dis_avg_C',
                'C_cell_avg_F',
                'C_diel_eff_avg_F'
            ]

            # Relative deviation of each cycle from its own file median
            file_median = results_df.groupby('psdata_file_name')[
                core_columns
            ].transform('median')
            cycle_deviation = (
                (results_df[core_columns] - file_median) / file_median
            ).abs()
            glitch = (cycle_deviation > max_cycle_deviation).any(axis=1)

            # Plasma power relative to the folder median (power setpoint)
            power = results_df['power_plasma_W']
            off_power = (power / power.median() - 1).abs() > max_power_deviation

            # Add a new column 'outlier' to the data
            # with the outlier predictions
            results_df['outlier'] = np.where(glitch | off_power, -1, 1)

            # Filter the outliers
            no_outliers = results_df[
                results_df['outlier'] == 1
            ].drop(columns=['outlier'])

            print(
                f'Found {results_df.shape[0] - no_outliers.shape[0]} outliers '
                f'({glitch.sum()} glitches, {off_power.sum()} off power).'
            )

            # Return the no_outliers DataFrame
            return no_outliers

        except Exception as e:
            print('An error occurred while processing for outlier detection in:'
            f'{results_df['psdata_file_name'].iloc[0]}. Error message: {str(e)}')

    return (remove_outliers,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 3 · `lissajous_figure_generation`: the check figure

    `lissajous_figure.png` has three panels:
    1. the average Q–V loop with the fitted lines;
    2. |dQ/dV| over time;
    3. dQ/dV against voltage, with the mean capacitances as horizontal lines and the ignition voltages as vertical lines.

    Look at it for every run: do the lines follow the branches, and do the ignition lines sit at the corners?
    """)
    return


@app.cell
def _(np, plt, savgol_filter):
    def lissajous_figure_generation(
        data_df,
        results_no_outliers_df,
        folder_name,
        row_skip=100,
        time_column='time_s',
        voltage_column='voltage_V',
        charge_column='charge_C',
        voltage_charge_deriv_column='dQ_dV'
    ):
        try:
            columns_to_keep = [
                time_column,
                voltage_column,
                charge_column,
                voltage_charge_deriv_column
            ]
            # Keep the columns that are needed for the lissajous generation
            data_df = data_df[columns_to_keep]

            # Group by 'time_s' and aggregate
            data_mean = data_df.groupby('time_s').mean().reset_index()

            # Select every row_skip row
            data_subset = data_mean.iloc[::row_skip].reset_index()

            # Extract and average slopes and intercepts
            C_cell_pos_F = results_no_outliers_df['C_cell_pos_F'].mean()
            C_cell_neg_F = results_no_outliers_df['C_cell_neg_F'].mean()
            C_cell_pos_intrcpt_C = results_no_outliers_df[
                'C_cell_pos_intrcpt_C'
            ].mean()
            C_cell_neg_intrcpt_C = results_no_outliers_df[
                'C_cell_neg_intrcpt_C'
            ].mean()

            C_diel_eff_pos_F = results_no_outliers_df['C_diel_eff_pos_F'].mean()
            C_diel_eff_neg_F = results_no_outliers_df['C_diel_eff_neg_F'].mean()
            C_diel_eff_pos_intrcpt_C = results_no_outliers_df[
                'C_diel_eff_pos_intrcpt_C'
            ].mean()
            C_diel_eff_neg_intrcpt_C = results_no_outliers_df[
                'C_diel_eff_neg_intrcpt_C'
            ].mean()

            # calculate lines
            x = np.arange(-1.2e4, 1.2e4, 1e3)
            y_cell_pos = C_cell_pos_F * x + C_cell_pos_intrcpt_C
            y_cell_neg = C_cell_neg_F * x + C_cell_neg_intrcpt_C
            y_diel_eff_pos = C_diel_eff_pos_F * x + C_diel_eff_pos_intrcpt_C
            y_diel_eff_neg = C_diel_eff_neg_F * x + C_diel_eff_neg_intrcpt_C

            # Plot and save the lissajous figure and dQ_dV vs time_s figure side by side
            plt.figure(figsize=(21, 6))
            plt.subplot(1, 3, 1)
            plt.plot(
                data_subset['voltage_V'],
                data_subset['charge_C'],
                label='Lissajous figure'
            )
            plt.plot(x, y_cell_pos, label='CD, C_cell_pos')
            plt.plot(x, y_cell_neg, label='AB, C_cell_neg')
            plt.plot(x, y_diel_eff_pos, label='DA, C_diel_eff_pos')
            plt.plot(x, y_diel_eff_neg, label='BC, C_diel_eff_neg')
            plt.axis([-15e3, 15e3, -1e-6, 1e-6])
            plt.xlabel('Voltage (V)')
            plt.ylabel('Charge (C)')
            plt.legend()

            plt.subplot(1, 3, 2)
            plt.plot(
                data_subset['time_s'],
                abs(data_subset['dQ_dV']),
                label='dQ_dV vs time_s'
            )
            plt.xlabel('Time (s)')
            plt.ylabel('dQ_dV (F)')
            plt.axis([0, 1e-3, 0, 200e-12])
            plt.legend()

            # dQ/dV vs V from smoothed time derivatives (masked near turning
            # points), with the fitted capacitances and mean ignition voltages
            dt_subset = data_subset[time_column].iloc[1] - data_subset[time_column].iloc[0]
            sg_window = int(32e-6 / dt_subset) | 1
            dVdt = savgol_filter(data_subset[voltage_column], sg_window, 2, deriv=1)
            dQdt = savgol_filter(data_subset[charge_column], sg_window, 2, deriv=1)
            moving = np.abs(dVdt) > 0.2 * np.abs(dVdt).max()
            plt.subplot(1, 3, 3)
            plt.plot(
                data_subset[voltage_column][moving],
                (dQdt / dVdt)[moving] * 1e12,
                '.', markersize=2, label='dQ/dV'
            )
            for col, style in [
                ('C_cell_avg_F', 'C1'),
                ('C_diel_eff_avg_F', 'C3'),
                ('C_diel_eff_max_avg_F', 'C4')
            ]:
                if col in results_no_outliers_df:
                    plt.axhline(
                        results_no_outliers_df[col].mean() * 1e12,
                        color=style, label=col
                    )
            for col in ['U_ignition_neg_V', 'U_ignition_pos_V']:
                if col in results_no_outliers_df:
                    plt.axvline(
                        results_no_outliers_df[col].mean(),
                        color='grey', linestyle='--'
                    )
            plt.xlabel('Voltage (V)')
            plt.ylabel('dQ/dV (pF)')
            plt.ylim(0, 250)
            plt.legend()

            plot_filename = (
                folder_name +
                '/' +
                'lissajous_figure.png'
            )

            plt.savefig(plot_filename, dpi=150)
            plt.clf()
            plt.close()
            print(f'Lissajous figure saved as {plot_filename}')

        except Exception as e:
                print('An error occurred while averaging the lissajous figures.'
                      f'Error message: {str(e)}')

    return (lissajous_figure_generation,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 4 · `profile_calculation`: time traces

    Keeps every 100th sample and adds:
    - the plasma current (Peeters & Butterworth 2019 eq. 3);
    - the true displacement current;
    - the charge carried by the plasma (Peeters & van de Sanden 2015 eq. A12);
    - the gap voltage (P15 eq. 3), using the median `alpha`, `beta` and `C_cell` of the capture's valid cycles.

    `current_sign` is a label per half-period, not the measured sign. [Column list](https://github.com/sbossier/plasmacatdesign/blob/main/docs/electrical/04-output-columns.md#profile_dataparquet-time-traces-every-100th-sample).
    """)
    return


@app.cell
def _(pd):
    def profile_calculation(
        data_df,
        results_no_outliers_df,
        C_diel,
        row_skip=100,
        ac_freq_Hz=3000
    ):
        try:
            # Initialize an empty DataFrame to store the subset
            data_subset = pd.DataFrame()

            # Group data by 'psdata_file_name' and iterate over each group
            for group_name, group_data in data_df.groupby('psdata_file_name'):
                # Select every 'row_skip'th row from the group
                subset = group_data.iloc[::row_skip, :].reset_index(drop=True)

                # Extract variables from the results_df where
                # the 'psdata_file_name' is equal to the group_name
                res_row = results_no_outliers_df.loc[
                    results_no_outliers_df['psdata_file_name'] == group_name
                ]

                if res_row.empty:
                    print(f"⚠️ Skipping file without results: {group_name}")
                    continue

                # Per-file values: median over the cycles that pass the
                # validity gate (all cycles if none pass)
                valid = res_row[res_row['parallelogram_valid'] == 1]
                if valid.empty:
                    valid = res_row
                alpha = valid['alpha_avg'].median()
                beta = valid['beta_avg'].median()
                C_cell = valid['C_cell_avg_F'].median()

                # Calculate plasma current
                subset['current_plasma_A'] = (1 / (1 - C_cell / C_diel)) * (
                    subset['current_reactor_A'] - C_cell * subset['dV_dt']
                )

                # Calculate displacement current
                subset['current_displacement_A'] = (
                    subset['current_reactor_A'] - subset['current_plasma_A']
                )

                # Calculate plasma charge
                subset['charge_plasma_C'] = (
                    subset['charge_C'] - C_cell * subset['voltage_V']
                ) / (1 - C_cell / C_diel)

                # Calculate gap voltage
                subset['voltage_gap_V'] = (
                    1 + (alpha * C_cell) / (beta * C_diel)
                ) * subset['voltage_V'] - (1 / (beta * C_diel)) * subset['charge_C']

                # Drop the unnecessary column
                subset = subset.drop(
                    columns=['dV_dt', 'voltage_smooth_V', 'charge_smooth_C'],
                    errors='ignore'
                )

                # Append the subset to the data_subset DataFrame
                data_subset = pd.concat([data_subset, subset], ignore_index=True)

            # Create a column 'wave_index' that contains the index of the
            # current wavelength, a full wavelength is 1/3000 seconds.
            # time_s from 0 to <1/3000 is wave_index 0,
            # from 1/3000 to <2/3000 is wave_index 1, etc.,
            # until 5/3000 to <6/3000 is wave_index 5.
            data_subset['wave_index'] = (
                (data_subset['time_s'] * ac_freq_Hz).astype(int) % 6
            )

            # Create 'current_index'
            # Create 'current_sign' indicating for 0 to <1/6000 that
            # the current is positive (1) and for 1/6000 to <2/6000 that
            # the current is negative (-1) and so on until <12/6000 (-1)
            data_subset['current_index'] = (
                (data_subset['time_s'] * (ac_freq_Hz * 2)).astype(int) % 12
            )

            data_subset['current_sign'] = (-1) ** data_subset['current_index']

            print('Profile calculation completed.')

            return data_subset

        except Exception as e:
            print(f'An error occurred: {e}')
            return None

    return (profile_calculation,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Step 5 · Run

    For every folder under `top_folder` that contains `lissajous_data.parquet`:
    - old result files in that folder are deleted;
    - steps 1–4 run;
    - the outputs are written next to the input.

    In the browser this starts with the **Run calculations** button. With `uv run` it starts directly.
    """)
    return


@app.cell
def _(
    calculate_results,
    gc,
    lissajous_figure_generation,
    os,
    pd,
    profile_calculation,
    remove_outliers,
):
    # Run all calculations for one folder containing lissajous_data.parquet
    def process_folder(folder_name, result_column_names):
        print(f'Processing folder: {folder_name}')

        # Delete the .png, .csv, and .parquet result files
        for file in os.listdir(folder_name):
            if (
                (file.endswith('.csv') or file.endswith('.png') or file.endswith('.parquet')) and
                file != 'lissajous_data.parquet'
            ):
                os.remove(os.path.join(folder_name, file))

        # Read the lissajous_data.parquet file
        data_df = pd.read_parquet(
            os.path.join(folder_name, 'lissajous_data.parquet')
        )

        data_df, results_df = calculate_results(
            data_df,
            result_column_names=result_column_names,
            ac_freq_Hz=3000,
            C_diel_F=204e-12,
            discharge_threshold_A=7.5e-3,
            t='time_s',
            Q='charge_C',
            U='voltage_V',
            Ir='current_reactor_A',
            Is='current_source_A',
            smoothing_fraction=0.025,
            slope_method='iq'
        )

        results_df.to_parquet(
            os.path.join(
                folder_name,
                'lissajous_calculations.parquet'
            ),
            index=False,
            compression='gzip'
        )

        # Remove outliers from the results
        results_no_outliers_df = remove_outliers(
            results_df=results_df
        )

        # Write the results without outliers to a .parquet file
        results_no_outliers_df.to_parquet(
            os.path.join(
                folder_name,
                'lissajous_calculations_no_outliers.parquet'
            ),
            index=False,
            compression='gzip'
        )

        # Select only numeric columns for averaging
        numeric_columns = results_no_outliers_df.select_dtypes(
            include=[float, int]
        ).columns

        # Group by 'psdata_file_name' and calculate the mean for numeric columns
        results_no_outliers_avg_df = results_no_outliers_df.groupby(
            'psdata_file_name'
        )[numeric_columns].mean().reset_index()

        # Write the averaged results to a .csv file
        results_no_outliers_avg_df.to_csv(
            os.path.join(
                folder_name,
                'lissajous_calculations_no_outliers_avg.csv'
            ),
            index=False
        )

        # Generate mean lissajous figure
        lissajous_figure_generation(
            data_df=data_df,
            results_no_outliers_df=results_no_outliers_df,
            folder_name=folder_name,
            time_column='time_s',
            voltage_column='voltage_V',
            charge_column='charge_C',
            row_skip=100
        )

        # Generate current/voltage profile
        profile_df = profile_calculation(
            data_df=data_df,
            results_no_outliers_df=results_no_outliers_df,
            C_diel=204e-12,
            row_skip=100,
            ac_freq_Hz=3000
        )

        # Write the current/voltage profile to a .parquet file
        profile_df.to_parquet(
            os.path.join(
                folder_name,
                'profile_data.parquet'
            ),
            index=False,
            compression='gzip'
        )

        # Free up memory
        gc.collect()

    return (process_folder,)


@app.cell
def _(column_names_new, mo, os, process_folder, run, top_folder):
    # Runs on button press, or unconditionally as a script (uv run)
    mo.stop(
        not (run.value or mo.app_meta().mode == "script"),
        mo.md("Press **Run calculations** to start.")
    )

    # Walk through each directory in the folder tree and do the calculations
    for _folder_name, _, _filenames in os.walk(top_folder):
        try:
            # Check if 'lissajous_data.parquet' is not in the directory
            if 'lissajous_data.parquet' not in _filenames:
                continue

            process_folder(_folder_name, column_names_new)
        except Exception as e:
            print(f'An error occurred: {e}')
            continue
    return


if __name__ == "__main__":
    app.run()
