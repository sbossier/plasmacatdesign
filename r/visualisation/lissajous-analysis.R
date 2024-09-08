# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(ggrepel)
library(ggthemes)
library(Rttf2pt1)
library(extrafontdb)
library(extrafont)

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())

# Read in starting data
data <-
  read_tsv("C:/Users/sbossier/Desktop/70.0s-01/20210312-0009.txt",
           col_names = c("time_ms", "charge_µC", "voltage_kV", "current_plasma_A", "current_source_mA", "power_applied_kW", "power_plasma_kW"),
           skip = 2)

data <- data %>%
  mutate(current_plasma_mA = current_plasma_A * 1000,
         power_applied_W = power_applied_kW * 1000,
         power_plasma_W = power_plasma_kW * 1000)

data %>%
  select(time_ms, current_plasma_mA) %>%
  dplyr::filter(between(time_ms, 0.1666, 0.4666)) %>%
  ggplot(aes(x = time_ms,
             y = current_plasma_mA)) +
  geom_line()

loess_smooth <- data %>%
  select(time_ms, current_plasma_mA) %>%
  dplyr::filter(between(time_ms, 0.1666, 0.4666)) %>%
  loess(formula = .$current_plasma_mA ~ .$time_ms)

data %>%
  dplyr::filter(between(time_ms, 0.1666, 0.4666)) %>%
  mutate(loess_smoothing = loess_smooth$fitted) %>%
  ggplot(aes(x = time_ms,
             y = loess_smoothing)) +
  geom_line()

smooth_spline <- smooth.spline(x = data$time_ms, y = data$current_plasma_mA)

smooth_spline %>%
  filter(between(x, 0.3, 0.466)) %>%
  ggplot(aes(x = x,
             y = y)) +
  geom_line()



ind <- findPeaks(data$current_plasma_mA,
          thresh = 0.45)

peaks <- data[ind,]

sgolayfilt(data$current_plasma_mA)

