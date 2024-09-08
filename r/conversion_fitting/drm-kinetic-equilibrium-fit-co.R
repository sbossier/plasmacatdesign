# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(propagate)
library(ggrepel)
library(ggthemes)

# Clear workspace
rm(list=ls())

# Read in starting data
setwd("H:/data/dry-reforming-methane/ugent/sasol-1.8-cu(ii)(no3)2-2%")
filename <- "conversion-values-sasol-1.8-cu(ii)(no3)2-2%-no-outliers.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

##################################################################################
# Fitting CO mole fraction to first-order reaction rate model                    #
# Obtaining equilibrium concentration and reaction rate constant with SD and RSD #
##################################################################################

# A weighing of the datapoints for fitting can be added if desired
# data <- data %>% mutate(weights_value = conv_sd ^ -2 / sum(conv_sd ^ -2))

fit_co <- data %>%
  filter(compound == "CO") %>%
  nls(mole_fraction ~ mole_fraction_eq - mole_fraction_eq * exp(-k * res_time), data = ., #weights = weights_value,
      start = list(mole_fraction_eq = 0.20, k = 0.05))

summary(fit_co)$coef

mole_fraction_eq     <- summary(fit_co)$coef[1]
mole_fraction_eq_sd  <- summary(fit_co)$coef[3]
mole_fraction_eq_rsd <- mole_fraction_eq_sd / mole_fraction_eq

k                    <- summary(fit_co)$coef[2]
k_sd                 <- summary(fit_co)$coef[4]
k_rsd                <- k_sd / k

f_k_form     <- k * mole_fraction_eq
f_k_form_rsd <- sqrt(k_rsd ^ 2 + mole_fraction_eq_rsd ^ 2)
f_k_form_sd  <- f_k_form_rsd * f_k_form

k_loss     <- (1 - mole_fraction_eq) * k
k_loss_rsd <- sqrt(k_rsd ^ 2 + (mole_fraction_eq_sd / (1 - mole_fraction_eq)) ^ 2)
k_loss_sd  <- k_loss_rsd * k_loss

# Constructing the 95% prediction interval of the fit #
#######################################################

# fit_co_pred <- data.frame(res_time = seq(0, 100, 0.5))
# pred_values <- predictNLS(fit_co, newdata = fit_ch4_pred, interval = "prediction", alpha = 0.05, do.sim = FALSE)

# fit_co_pred$mean <- pred_values$summary[, 2]
# fit_co_pred$lcl <- pred_values$summary[, 5]
# fit_co_pred$ucl <- pred_values$summary[, 6]

# Constructing the 95% confidence interval of the fit #
#######################################################

# Create dataframe to store results of the calculated confidence intervals of the nonlinear model
fit_co_conf <- data.frame(res_time = seq(1, 100, 0.5))

# Calculate the 95% Confidence Interval of the nonlinear model using first-/second-order Taylor expansion (Monte Carlo sim is disables (do.sim = FALSE) to shorten calculation time)
conf_values <- predictNLS(fit_co, newdata = fit_co_conf, interval = "confidence", alpha = 0.05, do.sim = FALSE)

# Add results of calculations to dataframe to create plots of results
# Results are calculated using second-order Taylor expansion

# CO mole fraction as fitted to model
fit_co_conf$mole_fraction_fit    <- conf_values$summary[, 2]

# SD of CO mole fraction as fitted to model
fit_co_conf$mole_fraction_fit_sd <- conf_values$summary[, 4]

# RSD of CO mole fraction as fitted to model
fit_co_conf$mole_fraction_fit_rsd <- fit_co_conf$mole_fraction_fit_sd / fit_co_conf$mole_fraction_fit

# Lower 95% Confidence Level of CO mole fraction as fitted to model
fit_co_conf$mole_fraction_fit_lcl <- conf_values$summary[, 5]

# Upper 95% Confidence Level of CO mole fraction as fitted to model
fit_co_conf$mole_fraction_fit_ucl <- conf_values$summary[, 6]

# Add modeled equilibrium mole fraction, its SD, and RSD to the dataframe
fit_co_conf$mole_fraction_eq     <- mole_fraction_eq
fit_co_conf$mole_fraction_eq_sd  <- mole_fraction_eq_sd
fit_co_conf$mole_fraction_eq_rsd <- mole_fraction_eq_rsd

# Add modeled reaction rate, its SD, and RSD to the dataframe
fit_co_conf$k     <- k
fit_co_conf$k_sd  <- k_sd
fit_co_conf$k_rsd <- k_rsd

# Add modeled formation reaction rate, its SD, and RSD to the dataframe
fit_co_conf$f_k_form     <- f_k_form
fit_co_conf$f_k_form_sd  <- f_k_form_sd
fit_co_conf$f_k_form_rsd <- f_k_form_rsd

# Add modeled loss reaction rate, its SD, and RSD to the dataframe
fit_co_conf$k_loss     <- k_loss
fit_co_conf$k_loss_sd  <- k_loss_sd
fit_co_conf$k_loss_rsd <- k_loss_rsd

# Plotting the data #
#####################

# Create plot of fitted and measured CO mole fraction with 95% confidence interval for the standard deviation on the mean for the measured ch4 conversion
data %>% filter(compound == "CO") %>%
  ggplot(aes(x = res_time,
             y = mole_fraction * 100)) +
  geom_line(data  = fit_co_conf,
            aes(x = res_time,
                y = mole_fraction_fit * 100),
            color = "grey",
            size  = 1.5) +
  geom_ribbon(data  = fit_co_conf, 
              aes(x    = res_time,
                  y    = mole_fraction_fit * 100,
                  ymin = mole_fraction_fit_lcl * 100,
                  ymax = mole_fraction_fit_ucl * 100), 
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
  scale_y_continuous(limits = c(0, 20),
                     expand = expansion(mult = c(0.01, 0.01))) +
  ggtitle("Mole fraction CO vs. residence time") +
  xlab("Residence time (s)") +
  ylab("Mole fraction CO (%)") +
  theme_solarized()

###################################
# Write fitting data to .csv-file #
###################################

write_csv(fit_co_conf, gsub(".csv", "-co-mole-fraction-fitting.csv", filename))
