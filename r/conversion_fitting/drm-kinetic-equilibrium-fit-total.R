# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(propagate)
library(ggrepel)
library(ggthemes)

# Clear workspace
rm(list=ls())

# Read in starting data
setwd("N:/FWET/FDCH/AdsCatal/General/personal_work_folders/plasmacatdesign/drm/ugent/sasol-1.8-c450/pwr-const")
filename <- "conversion-values-sasol-1.8.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

####################################################################################################
# Fitting total mole fraction to first-order reaction rate model                                   #
# Obtaining equilibrium total mole fraction of reagents and reaction rate constant with SD and RSD #
####################################################################################################

# A weighing of the datapoints for fitting can be added if desired
# data <- data %>% mutate(weights_value = conv_sd ^ -2 / sum(conv_sd ^ -2))

fit_total <- data %>%
  filter(compound == "Total") %>%
  nls(mole_fraction ~ mole_fraction_total_eq - (mole_fraction_total_eq - 1) * exp(-k * res_time), data = ., #weights = weights_value,
      start = list(mole_fraction_total_eq = 0.50, k = 0.05))

summary(fit_total)$coef

mole_fraction_total_eq     <- summary(fit_total)$coef[1]
mole_fraction_total_eq_sd  <- summary(fit_total)$coef[3]
mole_fraction_total_eq_rsd <- mole_fraction_total_eq_sd / mole_fraction_total_eq

k     <- summary(fit_total)$coef[2]
k_sd  <- summary(fit_total)$coef[4]
k_rsd <- k_sd / k

f_k_form     <- k * mole_fraction_total_eq
f_k_form_rsd <- sqrt(k_rsd ^ 2 + mole_fraction_total_eq_rsd ^ 2)
f_k_form_sd  <- f_k_form_rsd * f_k_form

k_loss     <- (1 - mole_fraction_total_eq) * k
k_loss_rsd <- sqrt(k_rsd ^ 2 + (mole_fraction_total_eq_sd / (1 - mole_fraction_total_eq)) ^ 2)
k_loss_sd  <- k_loss_rsd * k_loss

# Constructing the 95% confidence interval of the fit #
#######################################################

# Create dataframe to store results of the calculated confidence intervals of the nonlinear model
fit_total_conf <- data.frame(res_time = seq(1, 100, 0.5))

# Calculate the 95% Confidence Interval of the nonlinear model using first-/second-order Taylor expansion (Monte Carlo sim is disables (do.sim = FALSE) to shorten calculation time)
conf_values <- predictNLS(fit_total, newdata = fit_total_conf, interval = "confidence", alpha = 0.05, do.sim = FALSE)

# Add results of calculations to dataframe to create plots of results
# Results are calculated using second-order Taylor expansion

# Total mole fraction as fitted to model
fit_total_conf$mole_fraction_total_fit     <- conf_values$summary[, 2]

# SD of total mole fraction as fitted to model
fit_total_conf$mole_fraction_total_fit_sd  <- conf_values$summary[, 4]

# RSD of total mole fraction as fitted to model
fit_total_conf$mole_fraction_total_fit_rsd <- fit_total_conf$mole_fraction_total_fit_sd / fit_total_conf$mole_fraction_total_fit

# Lower 95% Confidence Level of total mole fraction as fitted to model
fit_total_conf$mole_fraction_total_fit_lcl <- conf_values$summary[, 5]

# Upper 95% Confidence Level of total mole fraction as fitted to model
fit_total_conf$mole_fraction_total_fit_ucl <- conf_values$summary[, 6]

# Add modeled equilibrium total mole fraction, its SD, and RSD to the dataframe
fit_total_conf$mole_fraction_eq     <- mole_fraction_total_eq
fit_total_conf$mole_fraction_eq_sd  <- mole_fraction_total_eq_sd
fit_total_conf$mole_fraction_eq_rsd <- mole_fraction_total_eq_rsd

# Add modeled reaction rate, its SD, and RSD to the dataframe
fit_total_conf$k     <- k
fit_total_conf$k_sd  <- k_sd
fit_total_conf$k_rsd <- k_rsd

# Add modeled formation reaction rate, its SD, and RSD to the dataframe
fit_total_conf$f_k_form     <- f_k_form
fit_total_conf$f_k_form_sd  <- f_k_form_sd
fit_total_conf$f_k_form_rsd <- f_k_form_rsd

# Add modeled loss reaction rate, its SD, and RSD to the dataframe
fit_total_conf$k_loss     <- k_loss
fit_total_conf$k_loss_sd  <- k_loss_sd
fit_total_conf$k_loss_rsd <- k_loss_rsd

# Plotting the data #
#####################

# Create plot of fitted and measured total mole fraction with 95% confidence interval for the standard deviation on the mean for the measured total mole fraction
data %>%
  filter(compound == "Total") %>%
  ggplot(aes(x = res_time,
             y = mole_fraction * 100)) +
  geom_line(data  = fit_total_conf,
            aes(x = res_time,
                y = mole_fraction_total_fit * 100),
            color = "grey",
            size  = 1.5) +
  geom_ribbon(data  = fit_total_conf, 
              aes(x    = res_time,
                  y    = mole_fraction_total_fit * 100,
                  ymin = mole_fraction_total_fit_lcl * 100,
                  ymax = mole_fraction_total_fit_ucl * 100), 
              color = "grey",
              alpha = 0.25,
              size  = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = 100 * (mole_fraction - qt(0.975, df = df) * mole_fraction_sd / sqrt(df + 1)),
                    ymax = 100 * (mole_fraction + qt(0.975, df = df) * mole_fraction_sd / sqrt(df + 1))),
                width    = 1,
                position = position_dodge(0.05),
                size     = 1) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(45, 100),
                     expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("Total mole fraction starting products vs. residence time") +
  xlab("Residence time (s)") +
  ylab("Total mole fraction starting products (%)") +
  theme_solarized()

###############################################################
# Fitting total conversion to first-order reaction rate model #
# Obtaining equilibrium total conversion of reagents          #
###############################################################

fit_conv_total <- data %>%
  filter(compound == "Total") %>%
  nls(conv ~ conv_total_eq - conv_total_eq * exp(-k * res_time), data = ., start = list(conv_total_eq = 0.50, k = 0.05))

summary(fit_conv_total)$coef

conv_total_eq     <- summary(fit_conv_total)$coef[1]
conv_total_eq_sd  <- summary(fit_conv_total)$coef[3]
conv_total_eq_rsd <- conv_total_eq_sd / conv_total_eq

# Constructing the 95% confidence interval of the fit #
#######################################################

# Create dataframe to store results of the calculated confidence intervals of the nonlinear model
fit_total_conv_conf <- data.frame(res_time = seq(1, 100, 0.5))

# Calculate the 95% Confidence Interval of the nonlinear model using first-/second-order Taylor expansion (Monte Carlo sim is disables (do.sim = FALSE) to shorten calculation time)
conv_conf_values <- predictNLS(fit_conv_total, newdata = fit_total_conv_conf, interval = "confidence", alpha = 0.05, do.sim = FALSE)

# Add results of calculations to dataframe to create plots of results
# Results are calculated using second-order Taylor expansion

# Total conversion as fitted to model
fit_total_conv_conf$conv_total_fit     <- conv_conf_values$summary[, 2]

# SD of total conversion as fitted to model
fit_total_conv_conf$conv_total_fit_sd  <- conv_conf_values$summary[, 4]

# RSD of total conversion as fitted to model
fit_total_conv_conf$conv_total_fit_rsd <- fit_total_conv_conf$conv_total_fit_sd / fit_total_conv_conf$conv_total_fit

# Lower 95% Confidence Level of total conversion as fitted to model
fit_total_conv_conf$conv_total_fit_lcl <- conv_conf_values$summary[, 5]

# Upper 95% Confidence Level of total conversion as fitted to model
fit_total_conv_conf$conv_total_fit_ucl <- conv_conf_values$summary[, 6]

# Add modeled equilibrium total conversion, its SD, and RSD to the dataframe
fit_total_conv_conf$conv_total_eq     <- conv_total_eq
fit_total_conv_conf$conv_total_eq_sd  <- conv_total_eq_sd
fit_total_conv_conf$conv_total_eq_rsd <- conv_total_eq_rsd

# Plotting the data #
#####################

# Create plot of fitted and measured total conversion with 95% confidence interval for the standard deviation on the mean for the measured total mole fraction
data %>%
  filter(compound == "Total") %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  geom_line(data  = fit_total_conv_conf,
            aes(x = res_time,
                y = conv_total_fit * 100),
            color = "grey",
            size  = 1.5) +
  geom_ribbon(data  = fit_total_conv_conf,
              aes(x    = res_time,
                  y    = conv_total_fit * 100,
                  ymin = conv_total_fit_lcl * 100,
                  ymax = conv_total_fit_ucl * 100),
              color = "grey",
              alpha = 0.25,
              size  = 1.25) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = 100 * (conv - qt(0.975, df = df) * conv_sd / sqrt(df + 1)),
                    ymax = 100 * (conv + qt(0.975, df = df) * conv_sd / sqrt(df + 1))),
                width    = 1,
                position = position_dodge(0.05),
                size     = 1) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(limits = c(0, 60),
                     expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("Total conversion starting products vs. residence time") +
  xlab("Residence time (s)") +
  ylab("Total conversion starting products (%)") +
  theme_solarized()

###############################
# Calculate corresponding SEI #
###############################

# Get averaged plasma power over all residence times
power_avg <- mean(filter(data, compound == "Total")$plasma_power)

# Get reactor volume
reactor_vol_ml <- data$reactor_vol_ml %>% unique()

# Get packed fraction of reactor
packing_factor <- data$packing_factor %>% unique()

fit_total_conv_conf <- fit_total_conv_conf %>%
  mutate(flux_in_fit = (reactor_vol_ml * (1 - packing_factor)) / (res_time / 60),
         sei_fit     = (power_avg / flux_in_fit) * 60 * 24.055)

###################################
# Write fitting data to .csv-file #
###################################

write_csv(fit_total_conf, gsub(".csv", "-total-mole-fraction-fitting.csv", filename))
write_csv(fit_total_conv_conf, gsub(".csv", "-total-conv-fitting.csv", filename))
