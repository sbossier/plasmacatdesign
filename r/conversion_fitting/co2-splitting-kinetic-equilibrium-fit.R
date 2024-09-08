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
setwd("H:/data/co2-splitting/uhasselt/GM11.2")
filename <- "gm11.2-conv-values-no-outliers.csv"
data <- read_csv(filename, na = c("NA", "N A", "na", ""))

######################################################################################
# Fitting CO2 mole fraction to first-order reaction rate model                       #
# obtaining equilibrium CO2 mole fraction and reaction rate constant with SD and RSD #
######################################################################################

# From the CO2 conversion calculated using Snoeckx's method, the mole fraction of CO2 after conversion is measured
data    <- mutate(data, mole_fraction_co2 = (1 - conv) / (1 + 1 / 2 * conv), .after = conv_sd)

nls_fit <- data %>%
                  filter(compound == "CO2") %>%
                  nls(mole_fraction_co2 ~ mole_fraction_co2_eq - (mole_fraction_co2_eq - 1) * exp(-k * res_time), data = .,
                      start = list(mole_fraction_co2_eq = 0.5, k = 0.05),
                      control = nls.control(maxiter= 200, warnOnly=TRUE))

nls_fit_conv <- data %>%
                      filter(compound == "CO2") %>%
                      nls(conv ~ conv_eq - conv_eq * exp(-k * res_time), data = .,
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
# constructing the 95% prediction interval of the fit #
#######################################################

# data_fit_pred <- data.frame(res_time = seq(0, 100, .5))
# pred_values <- predictNLS(nls_fit, newdata = data_fit_pred, interval = "prediction", alpha = .05, do.sim = FALSE)

# data_fit_pred$mean <- pred_values$summary[,2]
# data_fit_pred$lcl <- pred_values$summary[,5]
# data_fit_pred$ucl <- pred_values$summary[,6]

#######################################################
# constructing the 95% confidence interval of the fit #
#######################################################

# Create dataframe to store results of the calculated confidence intervals of the nonlinear model
nls_fit_conf <- data.frame(res_time = seq(1, 100, .5))

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
power_avg <- mean(data$plasma_power[-1], na.rm = T)

# Get reactor volume
reactor_vol_ml <- data$reactor_vol_ml %>% unique()

# Get packed fraction of reactor
packing_factor <- data$packing_factor %>% unique()

# Get idealized blank CO2 concentration (normally 1, unless dilutant is added)
conc_co2_blank <- data %>% filter(compound == "CO2") %>% pull(mole_fraction_i) %>% unique()

# Plasma temperature (K)

gas_temp_avg  <- data %>% filter(compound == "CO2") %>% pull(gas_temp_avg_dgc) %>% mean(na.rm = T)
gas_temp      <- 273.15 + gas_temp_avg

# Gibbs Free Enthalpy of Formation of CO in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

gf_co <- -1.48747E-20*(gas_temp ^ 6) + 2.90543E-16* (gas_temp ^ 5) - 2.18412E-12 * (gas_temp ^ 4) + 7.80039E-09 * (gas_temp ^ 3) - 1.14364E-05 * (gas_temp ^ 2) - 8.19286E-02 * gas_temp - 1.12455E+02

# Gibbs Free Enthalpy of Formation of CO2 in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

gf_co2 <- 1.21850E-21* (gas_temp ^ 6) - 2.63973E-17 * (gas_temp ^ 5) + 2.25893E-13 * (gas_temp ^ 4) - 9.56091E-10 * (gas_temp ^ 3) + 2.75906E-06 * (gas_temp ^ 2) - 4.68102E-03 * gas_temp - 3.93205E+02

nls_fit_conf <- nls_fit_conf %>% mutate(co2_flux_fit    = (reactor_vol_ml * (1 - packing_factor)) / (res_time / 60),
                                        
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

write_csv(nls_fit_conf, gsub(".csv", "-fitting.csv", filename))

#####################
# Plotting the data #
#####################

# Create plot of fitted and measured CO2 conversion with 95% confidence interval for the standard deviation on the mean for the measured CO2 conversion
data %>% filter(compound == "CO2") %>%
  ggplot(aes(x = res_time,
             y = conv*100)) +
  geom_line(data = nls_fit_conf, aes(x = res_time, y = conv_fit*100), color = "grey", linewidth = 1.5) +
  geom_ribbon(data = nls_fit_conf,
              aes(x = res_time, y = conv_fit*100, ymin = conv_fit_lcl*100, ymax = conv_fit_ucl*100), 
              color= "grey", alpha = .25, size = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = 100 *  (conv - qt(.975, df = df)*conv_sd/sqrt(df+1)), ymax = 100 * (conv + qt(.975, df = df)*conv_sd/sqrt(df+1))), width=1, position=position_dodge(0.05), size = 1) +
  scale_x_continuous(limits = c(0, 100),expand = expansion(mult = c(0.01, .01))) + 
  scale_y_continuous(limits = c(0, 40),expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("CO2 conversion vs. residence time") +
  xlab("Residence time (s)") +
  ylab("CO2 conversion (%)") +
  theme_solarized()

# Create plot of fitted and measured energy efficiency with 95% confidence interval for the standard deviation on the mean for the measured energy efficiency
data %>% filter(compound == "CO2") %>%
  ggplot(aes(res_time, ee_gf)) +
  geom_line(data = nls_fit_conf, aes(x = res_time, y = ee_gf_fit), color = "grey", linewidth = 1.5) +
  geom_ribbon(data = nls_fit_conf, 
              aes(x = res_time, y = ee_gf_fit, ymin = ee_gf_fit_lcl, ymax = ee_gf_fit_ucl), 
              color= "grey", alpha = .25, size = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = ee_gf - qt(.975, df = df) * ee_gf_sd/sqrt(df+1), ymax = ee_gf + qt(.975, df = df) * ee_gf_sd/sqrt(df+1)), width=1, position=position_dodge(0.05), size = 1) +
  scale_x_continuous(limits = c(0,100),expand = expansion(mult = c(0.01, .01))) + 
  scale_y_continuous(limits = c(0,7),expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("Energy efficiency vs. residence time") +
  xlab("Residence time (s)") +
  ylab("Energy efficiency (%)") +
  theme_solarized()

# Create plot of fitted and measured CO concentration with 95% confidence interval for the standard deviation on the mean for the measured CO concentration
data %>% filter(compound == "CO") %>%
  ggplot(aes(res_time, 100*yield)) +
  geom_line(data = nls_fit_conf, aes(x = res_time, y = 100 * conc_co_fit), color = "grey", linewidth = 1.5) +
  geom_ribbon(data = nls_fit_conf, 
              aes(x = res_time, y = conc_co_fit, ymin = 100 * conc_co_fit_lcl, ymax = 100 * conc_co_fit_ucl), 
              color= "grey", alpha = .25, size = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = 100 * (yield - qt(.975, df = df) * yield_sd/sqrt(df+1)), ymax = 100 * (yield + qt(.975, df = df) * yield_sd/sqrt(df+1))), width=1, position=position_dodge(0.05), size = 1) +
  scale_x_continuous(limits = c(0,100),expand = expansion(mult = c(0.01, .01))) + 
  scale_y_continuous(limits = c(0,30),expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("CO yield vs. residence time") +
  xlab("Residence time (s)") +
  ylab("CO yield (%)") +
  theme_solarized()

# Create plot of fitted and measured O2 concentration with 95% confidence interval for the standard deviation on the mean for the measured O2 concentration
data %>% filter(compound == "O2") %>%
  ggplot(aes(res_time, yield*100)) +
  geom_line(data = nls_fit_conf, aes(x = res_time, y = 100 * conc_o2_fit), color = "grey", size = 1.5) +
  geom_ribbon(data = nls_fit_conf, 
              aes(x = res_time, y = conc_o2_fit, ymin = 100 * (conc_o2_fit - qt(.975, df = nrow(data)-2) * conc_o2_fit_sd), ymax = 100 * (conc_o2_fit + qt(.975, df = nrow(data)-2) * conc_o2_fit_sd)), 
              color= "grey", alpha = .25, size = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = 100 * (yield - qt(.975, df = df) * yield_sd / sqrt(df + 1)), ymax = 100 * (yield + qt(.975, df = df) * yield_sd/sqrt(df+1))), width=1, position=position_dodge(0.05), size = 1) +
  scale_x_continuous(limits = c(0,100),expand = expansion(mult = c(0.01, .01))) + 
  scale_y_continuous(limits = c(0,17),expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("O2 yield vs. residence time") +
  xlab("Residence time (s)") +
  ylab("O2 yield (%)") +
  theme_solarized()

