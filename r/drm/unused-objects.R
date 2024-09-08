##################
# Unused objects #
##################

# select relative standard deviation of the N2 concentration from the blank experiment
conc_avg_n2_blank_rsd <- data %>%
  filter(state == "blank" & compound == "N2") %>%
  pull(conc_rsd) %>%
  unique()

# select relative standard deviation of the N2 concentration from the plasma
conc_avg_n2_plasma_rsd <- data %>%
  filter(state == "plasma" & compound == "N2") %>%
  pull(conc_rsd) %>%
  unique()