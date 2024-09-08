# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(propagate)
library(ggrepel)
library(ggthemes)
library(broom)
library(plyr)

# Clear workspace
rm(list=ls())

# Read in starting data
setwd("H:/data/drm/ugent")
filename <- "ugent-drm-mole-fractions-overview-no-outliers.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

##################################################################################
# Fitting CO2 mole fraction to first-order reaction rate model                   #
# Obtaining equilibrium concentration and reaction rate constant with SD and RSD #
##################################################################################

# A weighing of the datapoints for fitting can be added if desired
# data <- data %>% mutate(weights_value = conv_sd ^ -2 / sum(conv_sd ^ -2))


reagent <- "Total"

data %>%
  filter(compound == "Total") %>%
  ggplot(aes(x = res_time,
             y = mole_fraction,
             color = material)) +
  geom_point() +
  geom_line()

fitted_models <- data %>%
  filter(compound != "O2") %>%
  group_by(material, compound) %>%
  do(model = lm(mole_fraction ~ res_time, data = .)) %>%
  ungroup()

models <- data %>%
  filter(compound != "O2") %>%
  dlply(., c("material", "compound"), function(df) lm(mole_fraction ~ res_time, data = df))

ldply(models, coef)

l_ply(models, summary, .print = T)

data %>%
  filter(material == "2% Fe(III)Citrate @ SASOL 1.8",
         compound == reagent,
         #!res_time %in% c(20)
  ) %>%
  ggplot(aes(x = res_time,
             y = mole_fraction_sq_inv)) +
  geom_point() +
  geom_line()# +
  #stat_function(fun = function(res_time) (fit$coefficients[1]*exp(fit$coefficients[2]*res_time)))

summary(fit)


data %>%
  filter(compound != "O2") %>%
  nest(data = -c("material", "compound")) %>%
  mutate(model = map(data, ~ lm(mole_fraction_p4_inv ~ res_time, data = .)),
         constants = map(model, tidy),
         stats = map(model, glance),
         order = 5
         ) %>%
  unnest(c(constants, stats), names_repair = "unique") %>%
  dplyr::select(material,
                compound,
                order,
                term,
                estimate,
                std.error,
                adj.r.squared,
                p.value = p.value...9,
                df.residual) %>%
  unique() %>%
  write.table(., "clipboard", sep = "\t", row.names = F, col.names = F)
