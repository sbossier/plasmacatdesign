# Never remove raw data, only expand on the .csv-file

# Clear workspace
rm(list=ls())
gc()

# Load necessary packages
library(tidyverse)
library(propagate)
library(ggrepel)
library(ggthemes)

# Read in starting data
setwd("C:/Users/Sande/Documents/uantwerpen/plasmacatdesign/co2-splitting/uhasselt")
filename <- "SiO2+TMAH-220-12H-conversion-values.csv"
data_orgininal <- read_csv(filename, na = c("NA", "N A", "na", ""))

######################################################################################
# Fitting CO2 mole fraction to first-order reaction rate model                       #
# obtaining equilibrium CO2 mole fraction and reaction rate constant with SD and RSD #
######################################################################################

# filter data for CO2
data <- data_orgininal %>% filter(compound == "CO2")

# From the CO2 conversion calculated using Snoeckx's method, the mole fraction of CO2 after conversion is measured
data    <- mutate(data, mole_fraction_co2 = (1 - conv) / (1 + 1 / 2 * conv), .after = conv_sd)

nls_fit <- data %>%
                  filter(compound == "CO2") %>%
                  nls(mole_fraction_co2 ~ mole_fraction_co2_eq - (mole_fraction_co2_eq - 1) * exp(-k * res_time_sec), data = .,
                      start = list(mole_fraction_co2_eq = 0.5, k = 0.05),
                      control = nls.control(maxiter= 200, warnOnly=TRUE))

nls_fit_conv <- data %>%
                      filter(compound == "CO2") %>%
                      nls(conv ~ conv_eq - conv_eq * exp(-k * res_time_sec), data = .,
                          start = list(conv_eq = 0.50, k = 0.05),
                          control = nls.control(maxiter= 200, warnOnly=TRUE))

summary(nls_fit)$coef
summary(nls_fit_conv)$coef

mole_fraction_co2_eq     <- summary(nls_fit)$coef[1]
mole_fraction_co2_eq_sd  <- summary(nls_fit)$coef[3]
mole_fraction_co2_eq_rsd <- mole_fraction_co2_eq_sd / mole_fraction_co2_eq

k                        <- summary(nls_fit)$coef[2]
k_sd                     <- summary(nls_fit)$coef[4]
k_rsd                    <- k_sd/k

f_k_form     <- k * mole_fraction_co2_eq
f_k_form_rsd <- sqrt(k_rsd ^ 2 + mole_fraction_co2_eq_rsd ^ 2)
f_k_form_sd  <- f_k_form_rsd * f_k_form

k_loss     <- (1 - mole_fraction_co2_eq) * k
k_loss_rsd <- sqrt(k_rsd ^ 2 + (mole_fraction_co2_eq_sd / (1 - mole_fraction_co2_eq)) ^ 2)
k_loss_sd  <- k_loss_rsd * k_loss

#######################################################
# constructing the 95% confidence interval of the fit #
#######################################################

# Create dataframe to store results of the calculated confidence intervals of the nonlinear model
nls_fit_conf <- data.frame(res_time_sec = seq(1, 100, .5))

# Calculate the 95% Confidence Interval of the nonlinear model using first-/second-order Taylor expansion (Monte Carlo sim is disables (do.sim = FALSE) to shorten calculation time)
conf_values <- predictNLS(nls_fit, newdata = nls_fit_conf, interval = "confidence", alpha = .05, do.sim = FALSE)

# Add results of calculations to dataframe to create plots of results
# Results are calculated using second-order Taylor expansion

# CO2 equilibrium mole fraction as fitted to model
nls_fit_conf$mole_fraction_co2_fit     <- conf_values$summary[,2]

# SD of CO2 equilibrium mole fraction as fitted to model
nls_fit_conf$mole_fraction_co2_fit_sd  <- conf_values$summary[,4]

# RSD of CO2 equilibrium mole fraction as fitted to model
nls_fit_conf$mole_fraction_co2_fit_rsd <- nls_fit_conf$mole_fraction_co2_fit_sd / nls_fit_conf$mole_fraction_co2_fit

# Lower 95% Confidence Level of CO2 equilibrium mole fraction as fitted to model
nls_fit_conf$mole_fraction_co2_fit_lcl <- conf_values$summary[,5]

# Upper 95% Confidence Level of CO2 equilibrium mole fraction as fitted to model
nls_fit_conf$mole_fraction_co2_fit_ucl <- conf_values$summary[,6]

# Add modeled CO2 equilibrium mole fraction, its SD, and RSD to the dataframe
nls_fit_conf$mole_fraction_co2_eq     <- mole_fraction_co2_eq
nls_fit_conf$mole_fraction_co2_eq_sd  <- mole_fraction_co2_eq_sd
nls_fit_conf$mole_fraction_co2_eq_rsd <- mole_fraction_co2_eq_rsd

# Add modeled reaction rate, its SD, and RSD to the dataframe
nls_fit_conf$k     <- k
nls_fit_conf$k_sd  <- k_sd
nls_fit_conf$k_rsd <- k_rsd

# Add modeled formation reaction rate, its SD, and RSD to the dataframe
nls_fit_conf$f_k_form     <- f_k_form
nls_fit_conf$f_k_form_sd  <- f_k_form_sd
nls_fit_conf$f_k_form_rsd <- f_k_form_rsd

# Add modeled loss reaction rate, its SD, and RSD to the dataframe
nls_fit_conf$k_loss     <- k_loss
nls_fit_conf$k_loss_sd  <- k_loss_sd
nls_fit_conf$k_loss_rsd <- k_loss_rsd

######################################################
# Converting CO2 mole fraction fit to CO2 conversion #
######################################################

conv_eq     <- (1 - mole_fraction_co2_eq) / (1 + 1 / 2 * mole_fraction_co2_eq)
conv_eq_rsd <- sqrt(
                    (mole_fraction_co2_eq_sd / (1 - mole_fraction_co2_eq)) ^ 2 +
                    ((0.5 * mole_fraction_co2_eq_sd) / (1 + 0.5 * mole_fraction_co2_eq)) ^ 2
                   )
conv_eq_sd  <- conv_eq * conv_eq_rsd

nls_fit_conf$conv_eq     <- conv_eq
nls_fit_conf$conv_eq_sd  <- conv_eq_sd
nls_fit_conf$conv_eq_rsd <- conv_eq_rsd

nls_fit_conf <- mutate(nls_fit_conf,
                       conv_fit     = (1 - mole_fraction_co2_fit) / (1 + 1 / 2 * mole_fraction_co2_fit),
                       conv_fit_sd  = sqrt((mole_fraction_co2_fit_sd / (1 - mole_fraction_co2_fit)) ^ 2 + (1 / 2 * mole_fraction_co2_fit_sd / (1 + 1 / 2 * mole_fraction_co2_fit)) ^ 2) * conv_fit,
                       conv_fit_rsd = conv_fit_sd / conv_fit,
                       conv_fit_lcl = (1 - mole_fraction_co2_fit_ucl) / (1 + 1 / 2 * mole_fraction_co2_fit_ucl),
                       conv_fit_ucl = (1 - mole_fraction_co2_fit_lcl) / (1 + 1 / 2 * mole_fraction_co2_fit_lcl)
                       )

##################################
# Energy efficiency for this fit #
##################################

# Get averaged plasma power over all residence times
power_avg <- mean(data$plasma_power_watt_avg[-1], na.rm = T)

# Get reactor volume
reactor_vol_ml <- 17.31

# Get packed fraction of reactor
packing_factor <- 0.4774

# Get idealized blank CO2 concentration (normally 1, unless dilutant is added)
conc_co2_blank <- 1

# Plasma temperature (K)

gas_temp_avg  <- data %>% filter(compound == "CO2") %>% pull(gas_temp_avg_dgc) %>% mean(na.rm = T)
gas_temp      <- 273.15 + gas_temp_avg

# Gibbs Free Enthalpy of Formation of CO in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

gf_co <- -1.48747E-20*(gas_temp ^ 6) + 2.90543E-16* (gas_temp ^ 5) - 2.18412E-12 * (gas_temp ^ 4) + 7.80039E-09 * (gas_temp ^ 3) - 1.14364E-05 * (gas_temp ^ 2) - 8.19286E-02 * gas_temp - 1.12455E+02

# Gibbs Free Enthalpy of Formation of CO2 in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

gf_co2 <- 1.21850E-21* (gas_temp ^ 6) - 2.63973E-17 * (gas_temp ^ 5) + 2.25893E-13 * (gas_temp ^ 4) - 9.56091E-10 * (gas_temp ^ 3) + 2.75906E-06 * (gas_temp ^ 2) - 4.68102E-03 * gas_temp - 3.93205E+02

nls_fit_conf <- nls_fit_conf %>% mutate(co2_flux_fit    = (reactor_vol_ml * (1 - packing_factor)) / (res_time_sec / 60),
                                        
                                        alpha_fit       = 1 + (1 / 2) * conv_fit,
                                         
                                        alpha_fit_sd    = (1 / 2) * conv_fit * conv_fit_rsd,
                                        
                                        conc_co_fit     = conv_fit / (1 + (1 / 2) * conv_fit),
                                        conc_co_fit_sd  = conc_co_fit * sqrt( conv_fit_rsd ^ 2
                                                                            +
                                                                            (((1 / 2) * conv_fit * conv_fit_rsd) / (1 + (1 / 2) * conv_fit)) ^ 2
                                                                            ),
                                        conc_co_fit_lcl = conc_co_fit - qt(.975, df = nrow(data)-2) * conc_co_fit_sd,
                                        conc_co_fit_ucl = conc_co_fit + qt(.975, df = nrow(data)-2) * conc_co_fit_sd,
                                        
                                        conc_o2_fit     = conv_fit / (2 + conv_fit),
                                        conc_o2_fit_sd  = conc_o2_fit * sqrt(conv_fit_rsd ^ 2
                                                                            +
                                                                            (conv_fit_sd / (2 + conv_fit)) ^ 2
                                                                            ),
                                        conc_o2_fit_lcl = conc_o2_fit - qt(.975, df = nrow(data)-2) * conc_o2_fit_sd,
                                        conc_o2_fit_ucl = conc_o2_fit + qt(.975, df = nrow(data)-2) * conc_o2_fit_sd,
                                        
                                        sei_fit         = (power_avg / co2_flux_fit) * 60 * 24.055,
                                        
                                        ee_gf_fit       = (alpha_fit * conc_co_fit * gf_co - conv_fit * conc_co2_blank * gf_co2) / (sei_fit) * 100,
                                        ee_gf_fit_sd    = 100 * sqrt(
                                                                    (sqrt((alpha_fit_sd / alpha_fit) ^ 2 + (conc_co_fit_sd / conc_co_fit) ^ 2) * alpha_fit * conc_co_fit * gf_co) ^ 2
                                                                    +
                                                                    (conv_fit_sd * conc_co2_blank * gf_co2) ^ 2
                                                                    )
                                                               /
                                                               sei_fit,
                                        ee_gf_fit_lcl   = ee_gf_fit - qt(.975, df = nrow(data)-2) * ee_gf_fit_sd,
                                        ee_gf_fit_ucl   = ee_gf_fit + qt(.975, df = nrow(data)-2) * ee_gf_fit_sd
                                       )

###################################
# Write fitting data to .csv-file #
###################################

nls_fit_conf$packing <- data$packing %>% unique()

co2_data <- nls_fit_conf %>% 
  mutate(
    packing,
    compound = "CO2",
    res_time_sec,
    conc_fit = mole_fraction_co2_fit,
    conc_fit_sd = mole_fraction_co2_fit_sd,
    conc_fit_rsd = mole_fraction_co2_fit_rsd,
    conc_fit_lcl = mole_fraction_co2_fit_lcl,
    conc_fit_ucl = mole_fraction_co2_fit_ucl,
    k, k_sd, k_rsd, f_k_form, f_k_form_sd, f_k_form_rsd, k_loss, k_loss_sd, k_loss_rsd,
    conv_eq, conv_eq_sd, conv_eq_rsd, conv_fit, conv_fit_sd, conv_fit_rsd, conv_fit_lcl, conv_fit_ucl,
    sei_fit, ee_gf_fit, ee_gf_fit_sd, ee_gf_fit_lcl, ee_gf_fit_ucl,
    .keep = "none"
  )


# 2. CO: use the CO-specific concentration columns
co_data <- nls_fit_conf %>% 
  mutate(
    packing,
    compound = "CO",
    res_time_sec,
    conc_fit     = conc_co_fit,
    conc_fit_sd  = conc_co_fit_sd,
    conc_fit_rsd = conc_co_fit_sd / conc_co_fit,
    conc_fit_lcl = conc_co_fit_lcl,
    conc_fit_ucl = conc_co_fit_ucl,
    k, k_sd, k_rsd, f_k_form, f_k_form_sd, f_k_form_rsd, k_loss, k_loss_sd, k_loss_rsd,
    sei_fit, ee_gf_fit, ee_gf_fit_sd, ee_gf_fit_lcl, ee_gf_fit_ucl,
    conv_eq = NA, conv_eq_sd = NA, conv_eq_rsd = NA,
    conv_fit = NA, conv_fit_sd = NA, conv_fit_rsd = NA, conv_fit_lcl = NA, conv_fit_ucl = NA,
    .keep = "none"
  )

# 3. O2: use the O2-specific concentration columns
o2_data <- nls_fit_conf %>% 
  mutate(
    packing,
    compound = "O2",
    res_time_sec,
    conc_fit     = conc_o2_fit,
    conc_fit_sd  = conc_o2_fit_sd,
    conc_fit_rsd = conc_o2_fit_sd / conc_o2_fit,
    conc_fit_lcl = conc_o2_fit_lcl,
    conc_fit_ucl = conc_o2_fit_ucl,
    k, k_sd, k_rsd, f_k_form, f_k_form_sd, f_k_form_rsd, k_loss, k_loss_sd, k_loss_rsd,
    sei_fit, ee_gf_fit, ee_gf_fit_sd, ee_gf_fit_lcl, ee_gf_fit_ucl,
    conv_eq = NA, conv_eq_sd = NA, conv_eq_rsd = NA,
    conv_fit = NA, conv_fit_sd = NA, conv_fit_rsd = NA, conv_fit_lcl = NA, conv_fit_ucl = NA,
    .keep = "none"
  )

# Combine the three data frames into one
combined_data <- bind_rows(co2_data, co_data, o2_data)

write_csv(combined_data, gsub(".csv", "-fitting.csv", filename))