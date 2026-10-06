"""
CO2-splitting Snoeckx calculation (Python port of
r/co2_splitting/co2-splitting-snoeckx-calc-parallel.R).

For every raw measurement file matching  dd.ds-dd.csv  (e.g. "17.5s-01.csv") in
FOLDER, this computes the CO2 conversion (Snoeckx method), product selectivities,
yields, carbon/oxygen balances, SEI and energy efficiencies, and writes:
  <stem>-calc.csv        full table
  <stem>-calc-short.csv  plasma-only summary

Differences vs. the R script -- corrected error propagation / value bugs:
  #1 conv_co2_gc SD/RSD: the RSD of the ratio R = c_plasma/c_blank is NOT the RSD of
     the conversion 1 - R. The absolute error carries over, the relative one does not.
  #2 Snoeckx-corrected conversion is a single-variable function of conv_gc, so its
     error is |d/dconv_gc| * sd, not a quadrature sum.
  #3 selec_o_o2_sd used the CO variables; now uses the O2 variables.
  #4 the O2 row's selec_o now reports the O2 oxygen selectivity, not CO's.
  #5 gas_temp_rsd keeps the /2 (mean of in/out).

Retained approximations (same as R, by design, not bugs): delta treated as a constant
(delta_sd = 0) in the selectivity/balance formulas; products/ratios (yield = selec*conv,
yield_ratio) treated as independent in quadrature despite shared concentration terms;
Gibbs-energy temperature uncertainty neglected in ee_gf.
"""

import os
import re
import statistics

import numpy as np
import pandas as pd

# --------------------------------------------------------------------------- #
# Configuration                                                               #
# --------------------------------------------------------------------------- #

FOLDER = r"C:\Users\Sande\OneDrive - Universiteit Antwerpen\plasmacatdesign\co2-splitting\uhasselt\SiO2+TMAH+2-PrOH-220-09H\pwr-const"

NA_VALUES = ["NA", "na", "Na", "nA", "N A", "N/A", "N a", "n A", "n a", ""]

# z-value for which 99.99% of a normal curve falls within +/- z (== R qnorm(.99995)).
Z = statistics.NormalDist().inv_cdf(0.99995)

# Raw input file pattern: digits, ".", digit, "s-", digits, ".csv"  (e.g. 17.5s-01.csv)
INPUT_RE = re.compile(r"\d+\.\ds-\d+\.csv")

# Exact column order of the full <stem>-calc.csv output (matches the R output).
CALC_COLUMNS = [
    "packing", "res_time_sec", "state", "compound", "flow_mlmin", "flow_max_mlmin",
    "flow_mlmin_sd", "flow_rsd", "conc", "conc_avg", "conc_sd", "conc_rsd",
    "conc_avg_corr", "conc_avg_corr_sd", "conc_avg_corr_rsd",
    "conv", "conv_sd", "conv_rsd",
    "selec_c", "selec_c_sd", "selec_c_rsd",
    "yield_c", "yield_c_sd", "yield_c_rsd",
    "selec_o", "selec_o_sd", "selec_o_rsd",
    "yield_o", "yield_o_sd", "yield_o_rsd",
    "yield_ratio", "yield_ratio_sd", "yield_ratio_rsd",
    "balance_c", "balance_c_sd", "balance_c_rsd",
    "balance_o", "balance_o_sd", "balance_o_rsd",
    "delta", "plasma_power_watt", "source_power_watt",
    "plasma_power_watt_avg", "plasma_power_watt_sd", "plasma_power_rsd", "sei_kjmol",
    "gas_temp_in_avg_dgc", "gas_temp_in_sd_dgc", "gas_temp_in_rsd",
    "gas_temp_out_avg_dgc", "gas_temp_out_sd_dgc", "gas_temp_out_rsd",
    "gas_temp_avg_dgc", "gas_temp_sd_dgc", "gas_temp_rsd",
    "ee_gf_perc", "ee_gf_perc_sd", "ee_gf_rsd",
    "ee_lhv_perc", "ee_lhv_perc_sd", "ee_lhv_rsd",
    "ee_hhv_perc", "ee_hhv_perc_sd", "ee_hhv_rsd",
    "sei_kjmol_sd", "sei_rsd",
    "source_power_watt_avg", "source_power_watt_sd", "source_power_rsd",
    "gas_temp_in_dgc", "gas_temp_out_dgc",
]

# Exact column order of the <stem>-calc-short.csv output (matches the R output).
SHORT_COLUMNS = [
    "packing", "res_time_sec", "state", "compound", "flow_mlmin",
    "conv", "conv_sd",
    "selec_c", "selec_c_sd", "yield_c", "yield_c_sd",
    "selec_o", "selec_o_sd", "yield_o", "yield_o_sd",
    "yield_ratio", "yield_ratio_sd",
    "balance_c", "balance_c_sd", "balance_o", "balance_o_sd",
    "ee_gf_perc", "ee_gf_perc_sd", "ee_lhv_perc", "ee_lhv_perc_sd",
    "ee_hhv_perc", "ee_hhv_perc_sd",
    "plasma_power_watt_avg", "plasma_power_watt_sd", "sei_kjmol", "sei_kjmol_sd",
    "source_power_watt_avg", "source_power_watt_sd", "gas_temp_avg_dgc", "gas_temp_sd_dgc",
]


def _scalar(data, state, compound, col):
    """Single value of `col` for the given (state, compound) group (NaN if absent)."""
    sub = data.loc[(data["state"] == state) & (data["compound"] == compound), col]
    return sub.iloc[0] if len(sub) else np.nan


def process_file(path):
    filename = os.path.basename(path)
    data = pd.read_csv(path, na_values=NA_VALUES)

    # ------------------------------------------------------------------ #
    # Per-(state, compound) concentration average, SD and RSD            #
    # ------------------------------------------------------------------ #
    grp = data.groupby(["state", "compound"])["conc"]
    data["conc_avg"] = grp.transform("mean")          # na.rm handled by pandas
    data["conc_sd"] = grp.transform("std")            # ddof=1, matches R sd()
    data["conc_rsd"] = data["conc_sd"] / data["conc_avg"]

    # ------------------------------------------------------------------ #
    # gamma / beta from the flows                                        #
    # ------------------------------------------------------------------ #
    flow_co2 = data.loc[data["compound"] == "CO2", "flow_mlmin"].mean()
    flow_n2 = data.loc[data["compound"] == "N2", "flow_mlmin"].mean()
    if np.isnan(flow_n2):
        flow_n2 = 0.0

    gamma = flow_co2 / (flow_co2 + flow_n2)
    beta = flow_n2 / flow_co2

    not_n2 = data["compound"] != "N2"
    data["conc_avg_corr"] = np.where(not_n2, data["conc_avg"] * (1 + beta), np.nan)
    data["conc_avg_corr_sd"] = np.where(not_n2, data["conc_sd"] * (1 + beta), np.nan)
    data["conc_avg_corr_rsd"] = np.where(not_n2, data["conc_rsd"], np.nan)

    # ------------------------------------------------------------------ #
    # Relevant CO2 / CO / O2 concentration scalars                       #
    # ------------------------------------------------------------------ #
    co2b_avg = _scalar(data, "blank", "CO2", "conc_avg")
    co2b_sd = _scalar(data, "blank", "CO2", "conc_sd")
    co2b_rsd = _scalar(data, "blank", "CO2", "conc_rsd")
    co2p_avg = _scalar(data, "plasma", "CO2", "conc_avg")
    co2p_sd = _scalar(data, "plasma", "CO2", "conc_sd")
    co2p_rsd = _scalar(data, "plasma", "CO2", "conc_rsd")

    cop_avg = _scalar(data, "plasma", "CO", "conc_avg")
    cop_sd = _scalar(data, "plasma", "CO", "conc_sd")
    cop_rsd = _scalar(data, "plasma", "CO", "conc_rsd")

    o2p_avg = _scalar(data, "plasma", "O2", "conc_avg")
    o2p_sd = _scalar(data, "plasma", "O2", "conc_sd")
    o2p_rsd = _scalar(data, "plasma", "O2", "conc_rsd")

    # ------------------------------------------------------------------ #
    # CO2 conversion (Snoeckx) -- corrected error propagation (#1, #2)   #
    # ------------------------------------------------------------------ #
    # GC conversion: conv_gc = 1 - R, with R = c_plasma / c_blank.
    R = co2p_avg / co2b_avg
    conv_gc = 1 - R
    R_rsd = np.sqrt(co2b_rsd ** 2 + co2p_rsd ** 2)
    conv_gc_sd = R * R_rsd                  # abs error of (1 - R) equals abs error of R
    conv_gc_rsd = conv_gc_sd / conv_gc

    # Snoeckx correction is a function of the single variable conv_gc.
    a = gamma / 2
    denom = (1 + a) - a * conv_gc
    conv_co2 = conv_gc / denom
    conv_co2_sd = (1 + a) / denom ** 2 * conv_gc_sd          # |d conv_co2 / d conv_gc| * sd
    conv_co2_rsd = conv_co2_sd / conv_co2                    # == conv_gc_rsd * (1+a)/denom

    delta = 1 + conv_co2 / 2                                 # delta_sd = 0 (kept as in R)

    is_plasma = data["state"] == "plasma"
    is_co2 = data["compound"] == "CO2"
    is_co = data["compound"] == "CO"
    is_o2 = data["compound"] == "O2"

    mask_co2p = is_plasma & is_co2
    data.loc[mask_co2p, "conv"] = conv_co2
    data.loc[mask_co2p, "conv_sd"] = conv_co2_sd
    data.loc[mask_co2p, "conv_rsd"] = conv_co2_rsd
    data["delta"] = delta

    # Shared denominator of the selectivity formulas.
    Dden = co2b_avg - delta * co2p_avg
    sel_den_var = co2b_sd ** 2 + delta ** 2 * co2p_sd ** 2   # variance of Dden

    # ------------------------------------------------------------------ #
    # Carbon: CO selectivity & yield                                     #
    # ------------------------------------------------------------------ #
    selec_c_co = (delta * cop_avg) / Dden
    selec_c_co_rsd = np.sqrt(cop_rsd ** 2 + sel_den_var / Dden ** 2)
    selec_c_co_sd = selec_c_co_rsd * selec_c_co

    mask_cop = is_plasma & is_co
    data.loc[mask_cop, "selec_c"] = selec_c_co
    data.loc[mask_cop, "selec_c_sd"] = selec_c_co_sd
    data.loc[mask_cop, "selec_c_rsd"] = selec_c_co_rsd

    yield_c_co = selec_c_co * conv_co2
    yield_c_co_rsd = np.sqrt(selec_c_co_rsd ** 2 + conv_co2_rsd ** 2)
    yield_c_co_sd = yield_c_co_rsd * yield_c_co

    data.loc[mask_cop, "yield_c"] = yield_c_co
    data.loc[mask_cop, "yield_c_sd"] = yield_c_co_sd
    data.loc[mask_cop, "yield_c_rsd"] = yield_c_co_rsd

    # ------------------------------------------------------------------ #
    # Oxygen selectivity & yield from CO                                 #
    # ------------------------------------------------------------------ #
    selec_o_co = (delta * cop_avg) / (2 * Dden)
    selec_o_co_rsd = np.sqrt(cop_rsd ** 2 + sel_den_var / Dden ** 2)
    selec_o_co_sd = selec_o_co_rsd * selec_o_co

    data.loc[mask_cop, "selec_o"] = selec_o_co
    data.loc[mask_cop, "selec_o_sd"] = selec_o_co_sd
    data.loc[mask_cop, "selec_o_rsd"] = selec_o_co_rsd

    yield_o_co = selec_o_co * conv_co2
    yield_o_co_rsd = np.sqrt(selec_o_co_rsd ** 2 + conv_co2_rsd ** 2)
    yield_o_co_sd = yield_o_co_rsd * yield_o_co

    data.loc[mask_cop, "yield_o"] = yield_o_co
    data.loc[mask_cop, "yield_o_sd"] = yield_o_co_sd
    data.loc[mask_cop, "yield_o_rsd"] = yield_o_co_rsd

    # ------------------------------------------------------------------ #
    # Oxygen selectivity & yield from O2 (#3 sd vars, #4 O2 row values)  #
    # ------------------------------------------------------------------ #
    selec_o_o2 = (delta * o2p_avg) / Dden
    selec_o_o2_rsd = np.sqrt(o2p_rsd ** 2 + sel_den_var / Dden ** 2)
    selec_o_o2_sd = selec_o_o2_rsd * selec_o_o2          # was selec_o_co_rsd * selec_o_co

    mask_o2p = is_plasma & is_o2
    data.loc[mask_o2p, "selec_o"] = selec_o_o2           # was selec_o_co
    data.loc[mask_o2p, "selec_o_sd"] = selec_o_o2_sd
    data.loc[mask_o2p, "selec_o_rsd"] = selec_o_o2_rsd

    yield_o_o2 = selec_o_o2 * conv_co2
    yield_o_o2_rsd = np.sqrt(selec_o_o2_rsd ** 2 + conv_co2_rsd ** 2)
    yield_o_o2_sd = yield_o_o2_rsd * yield_o_o2

    data.loc[mask_o2p, "yield_o"] = yield_o_o2
    data.loc[mask_o2p, "yield_o_sd"] = yield_o_o2_sd
    data.loc[mask_o2p, "yield_o_rsd"] = yield_o_o2_rsd

    # ------------------------------------------------------------------ #
    # Yield ratio CO:O2                                                  #
    # ------------------------------------------------------------------ #
    yield_ratio = yield_c_co / yield_o_o2
    yield_ratio_rsd = np.sqrt(yield_c_co_rsd ** 2 + yield_o_o2_rsd ** 2)
    yield_ratio_sd = yield_ratio_rsd * yield_ratio
    data["yield_ratio"] = yield_ratio
    data["yield_ratio_sd"] = yield_ratio_sd
    data["yield_ratio_rsd"] = yield_ratio_rsd

    # ------------------------------------------------------------------ #
    # Carbon & oxygen balances                                          #
    # ------------------------------------------------------------------ #
    balance_c = (delta * (cop_avg + co2p_avg)) / co2b_avg
    balance_c_rsd = np.sqrt(
        (cop_sd ** 2 + co2p_sd ** 2) / (cop_avg + co2p_avg) ** 2 + co2b_rsd ** 2
    )
    balance_c_sd = balance_c_rsd * balance_c
    data["balance_c"] = balance_c
    data["balance_c_sd"] = balance_c_sd
    data["balance_c_rsd"] = balance_c_rsd

    balance_o = (delta * (o2p_avg + co2p_avg)) / co2b_avg
    balance_o_rsd = np.sqrt(
        (o2p_sd ** 2 + co2p_sd ** 2) / (o2p_avg + co2p_avg) ** 2 + co2b_rsd ** 2
    )
    balance_o_sd = balance_o_rsd * balance_o
    data["balance_o"] = balance_o
    data["balance_o_sd"] = balance_o_sd
    data["balance_o_rsd"] = balance_o_rsd

    # ------------------------------------------------------------------ #
    # Specific Energy Input (SEI)                                        #
    # ------------------------------------------------------------------ #
    pgrp = data.groupby(["state", "compound"])
    data["plasma_power_watt_avg"] = np.where(
        is_plasma, pgrp["plasma_power_watt"].transform("mean"), np.nan)
    data["plasma_power_watt_sd"] = np.where(
        is_plasma, pgrp["plasma_power_watt"].transform("std"), np.nan)
    data["plasma_power_rsd"] = np.where(
        is_plasma, data["plasma_power_watt_sd"] / data["plasma_power_watt_avg"], np.nan)
    data["source_power_watt_avg"] = np.where(
        is_plasma, pgrp["source_power_watt"].transform("mean"), np.nan)
    data["source_power_watt_sd"] = np.where(
        is_plasma, pgrp["source_power_watt"].transform("std"), np.nan)
    data["source_power_rsd"] = np.where(
        is_plasma, data["source_power_watt_sd"] / data["source_power_watt_avg"], np.nan)

    plasma_power_avg = data.loc[is_plasma, "plasma_power_watt"].mean()
    plasma_power_rsd = _scalar(data, "plasma", "CO2", "plasma_power_rsd")

    # Flow uncertainty from the MFC spec: 0.5% of reading + 0.1% of full scale.
    data["flow_mlmin_sd"] = (0.005 * data["flow_mlmin"] + 0.001 * data["flow_max_mlmin"]) / Z
    data["flow_rsd"] = data["flow_mlmin_sd"] / data["flow_mlmin"]
    flow_co2_rsd = _scalar(data, "plasma", "CO2", "flow_rsd")

    sei = (plasma_power_avg / flow_co2) * 60 * 24.055     # J/mmol == kJ/mol
    sei_rsd = np.sqrt(plasma_power_rsd ** 2 + flow_co2_rsd ** 2)
    sei_sd = sei_rsd * sei
    data["sei_kjmol"] = np.where(is_plasma, sei, np.nan)
    data["sei_kjmol_sd"] = np.where(is_plasma, sei_sd, np.nan)
    data["sei_rsd"] = np.where(is_plasma, sei_rsd, np.nan)

    # ------------------------------------------------------------------ #
    # Gas temperature & energy efficiencies                             #
    # ------------------------------------------------------------------ #
    tin = data.loc[mask_co2p, "gas_temp_in_dgc"]
    tout = data.loc[mask_co2p, "gas_temp_out_dgc"]
    tin_avg, tin_sd = tin.mean(), tin.std()
    tout_avg, tout_sd = tout.mean(), tout.std()
    tin_rsd = tin_sd / tin_avg
    tout_rsd = tout_sd / tout_avg

    gas_temp_avg = np.mean([tin_avg, tout_avg])
    gas_temp_rsd = np.sqrt(tin_rsd ** 2 + tout_rsd ** 2) / 2     # mean of in/out -> /2 (#5)
    gas_temp_sd = gas_temp_rsd * gas_temp_avg
    gas_temp_kelv = 273.15 + gas_temp_avg

    # Gibbs free energy of formation (sixth-order polynomial fits to NIST-JANAF data).
    gf_co = (-1.48747e-20 * gas_temp_kelv ** 6 + 2.90543e-16 * gas_temp_kelv ** 5
             - 2.18412e-12 * gas_temp_kelv ** 4 + 7.80039e-09 * gas_temp_kelv ** 3
             - 1.14364e-05 * gas_temp_kelv ** 2 - 8.19286e-02 * gas_temp_kelv - 1.12455e+02)
    gf_co2 = (1.21850e-21 * gas_temp_kelv ** 6 - 2.63973e-17 * gas_temp_kelv ** 5
              + 2.25893e-13 * gas_temp_kelv ** 4 - 9.56091e-10 * gas_temp_kelv ** 3
              + 2.75906e-06 * gas_temp_kelv ** 2 - 4.68102e-03 * gas_temp_kelv - 3.93205e+02)

    data["gas_temp_in_avg_dgc"] = np.where(is_plasma, tin_avg, np.nan)
    data["gas_temp_in_sd_dgc"] = np.where(is_plasma, tin_sd, np.nan)
    data["gas_temp_in_rsd"] = np.where(is_plasma, tin_rsd, np.nan)
    data["gas_temp_out_avg_dgc"] = np.where(is_plasma, tout_avg, np.nan)
    data["gas_temp_out_sd_dgc"] = np.where(is_plasma, tout_sd, np.nan)
    data["gas_temp_out_rsd"] = np.where(is_plasma, tout_rsd, np.nan)
    data["gas_temp_avg_dgc"] = gas_temp_avg
    data["gas_temp_sd_dgc"] = gas_temp_sd
    data["gas_temp_rsd"] = gas_temp_rsd

    ee_gf = (gf_co - gf_co2) * conv_co2 / sei * 100
    ee_gf_rsd = np.sqrt(conv_co2_rsd ** 2 + sei_rsd ** 2)
    ee_gf_sd = ee_gf_rsd * ee_gf
    data["ee_gf_perc"] = np.where(is_plasma, ee_gf, np.nan)
    data["ee_gf_perc_sd"] = np.where(is_plasma, ee_gf_sd, np.nan)
    data["ee_gf_rsd"] = np.where(is_plasma, ee_gf_rsd, np.nan)

    # LHV and HHV energy efficiency (CO LHV == HHV).
    ee_lhv = conv_co2 * 289.5 / sei * 100
    ee_lhv_rsd = np.sqrt(sei_rsd ** 2 + conv_co2_rsd ** 2)
    ee_lhv_sd = ee_lhv_rsd * ee_lhv
    data["ee_lhv_perc"] = np.where(is_plasma, ee_lhv, np.nan)
    data["ee_lhv_perc_sd"] = np.where(is_plasma, ee_lhv_sd, np.nan)
    data["ee_lhv_rsd"] = np.where(is_plasma, ee_lhv_rsd, np.nan)

    data["ee_hhv_perc"] = np.where(is_plasma, ee_lhv, np.nan)
    data["ee_hhv_perc_sd"] = np.where(is_plasma, ee_lhv_sd, np.nan)
    data["ee_hhv_rsd"] = np.where(is_plasma, ee_lhv_rsd, np.nan)

    # ------------------------------------------------------------------ #
    # Write outputs                                                      #
    # ------------------------------------------------------------------ #
    stem = filename[:-4]  # strip ".csv"
    calc = data.reindex(columns=CALC_COLUMNS)
    calc.to_csv(os.path.join(FOLDER, f"{stem}-calc.csv"), index=False, na_rep="NA")

    short = (data.loc[is_plasma, SHORT_COLUMNS].drop_duplicates())
    short.to_csv(os.path.join(FOLDER, f"{stem}-calc-short.csv"), index=False, na_rep="NA")


def main():
    files = sorted(f for f in os.listdir(FOLDER) if INPUT_RE.fullmatch(f))
    for f in files:
        try:
            process_file(os.path.join(FOLDER, f))
            print(f"Processed {f}")
        except Exception as exc:  # mirror the R tryCatch: report and continue
            print(f"Error in file {f}: {exc}")


if __name__ == "__main__":
    main()
