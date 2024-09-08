# DRM selectivity calculation
calculate_selectivity <- function(alpha_value,
                                  atoms_in_compound,
                                  atoms_in_co2,
                                  atoms_in_ch4,
                                  conc_corr_compound,
                                  conc_corr_co2_blank,
                                  conc_corr_co2_plasma,
                                  conc_corr_ch4_blank,
                                  conc_corr_ch4_plasma)
  {
  alpha_value * atoms_in_compound * conc_corr_compound / (
    atoms_in_co2 * (conc_corr_co2_blank - alpha_value * conc_corr_co2_plasma)
    +
    atoms_in_ch4 * (conc_corr_ch4_blank - alpha_value * conc_corr_ch4_plasma)
  )
  }

calculate_selectivity_rsd <- function(alpha_value,
                                      alpha_value_rsd,
                                      atoms_in_co2,
                                      atoms_in_ch4,
                                      conc_corr_compound_rsd,
                                      conc_corr_co2_blank,
                                      conc_corr_co2_blank_sd,
                                      conc_corr_co2_plasma,
                                      conc_corr_co2_plasma_rsd,
                                      conc_corr_ch4_blank,
                                      conc_corr_ch4_blank_sd,
                                      conc_corr_ch4_plasma,
                                      conc_corr_ch4_plasma_rsd) {
  sqrt(
       alpha_value_rsd ^ 2
       +
       conc_corr_compound_rsd ^ 2
       +
       (
        atoms_in_co2 ^ 2 * (conc_corr_co2_blank_sd ^ 2 + (conc_corr_co2_plasma_rsd ^ 2 + alpha_value_rsd ^ 2) * (alpha_value * conc_corr_co2_plasma) ^ 2)
        +
        atoms_in_ch4 ^ 2 * (conc_corr_ch4_blank_sd ^ 2 + (conc_corr_ch4_plasma_rsd ^ 2 + alpha_value_rsd ^ 2) * (alpha_value * conc_corr_ch4_plasma) ^ 2)
       )
       /
       (
        atoms_in_co2 * (conc_corr_co2_blank - alpha_value * conc_corr_co2_plasma)
        +
        atoms_in_ch4 * (conc_corr_ch4_blank - alpha_value * conc_corr_ch4_plasma)
       ) ^ 2
      )
}

# DRM yield calculation
calculate_yield <- function(alpha_value,
                            atoms_in_compound,
                            atoms_in_co2,
                            atoms_in_ch4,
                            conc_corr_compound,
                            conc_corr_co2_blank,
                            conc_corr_ch4_blank) {
  (alpha_value * atoms_in_compound * conc_corr_compound) /
  (atoms_in_co2 * conc_corr_co2_blank + atoms_in_ch4 * conc_corr_ch4_blank)
}

calculate_yield_rsd <- function(alpha_value_rsd,
                                atoms_in_co2,
                                atoms_in_ch4,
                                conc_corr_compound_rsd,
                                conc_corr_co2_blank,
                                conc_corr_co2_blank_sd,
                                conc_corr_ch4_blank,
                                conc_corr_ch4_blank_sd) {
  sqrt(
    alpha_value_rsd ^ 2
    +
    conc_corr_compound_rsd ^ 2
    +
    (atoms_in_co2 ^ 2 * conc_corr_co2_blank_sd ^ 2 + atoms_in_ch4 ^ 2 * conc_corr_ch4_blank_sd ^ 2)
    /
    (atoms_in_co2 * conc_corr_co2_blank + atoms_in_ch4 * conc_corr_ch4_blank) ^ 2
  )
}

# During calculations a lot of times a single concentration of a compound is required (the same piece of basic code below repeats a lot)
# To clean up the code a bit, the function below is created to reduce this 4 line piece of code to one line.
# The same can be achieved with nesting the code but that is a bit messy and less intuitive
pull_value <- function(dataframe, case = "state", molecule = "compound", column = "variable") {
  dataframe %>%
    filter(state == case & compound == molecule) %>%
    pull(column) %>%
    unique()
}