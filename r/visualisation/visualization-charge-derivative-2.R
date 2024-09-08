# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(ggrepel)
library(ggthemes)
library(Rttf2pt1)
library(extrafontdb)
library(extrafont)
library(signal)
library(zoo)
library(data.table)

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())

# read in datafiles from picoscope as a .txt
dataFiles <- lapply(Sys.glob("C:/Users/sbossier/Desktop/lissajous/2023*.csv"), function(file) {
  read_csv(file, col_names = c(
    "time_ms",
    "charge_µC",
    "voltage_kV",
    "current_plasma_A",
    "current_source_mA",
    "power_plasma_kW",
    "power_source_kW"
  ), skip = 2)
})

# take the average of all the measurements
data <- rbindlist(dataFiles)[, lapply(.SD, mean), list(time_ms)]

# select at random 0.32% (gives 2000 rows starting from 625001) of the rows of the average dataframe as a simple smoothing technique and arrange them on ascending time
data_new <- data %>%
  slice_sample(n = nrow(data) * 0.0032) %>%
  arrange(time_ms) %>%
  transmute(time_ms           = time_ms,
            voltage_V         = voltage_kV * 1000,
            charge_pC         = charge_µC * 1000000,
            current_plasma_mA = current_plasma_A * 1000
            )



ggplot(data = data_new,
       aes(x = voltage_V,
           y = charge_pC),) +
  geom_point(size = .05) +
  scale_x_continuous(name = "Voltage (V)",
                     limits = c(-10000, 10000)) +
  scale_y_continuous(name = "Charge (pC)",
                     limits = c(-600000, 600000))

# smooth charge data with simple spline function
data_smooth <- data.frame(smooth.spline(x = data_new$time_ms,
                                        y = data_new$charge_pC)[c(1:2)]) %>%
  transmute(time_ms = x,
            charge_pC_smooth = y)

ggplot(data = data_smooth,
       aes(x = time_ms,
           y = charge_pC_smooth)) +
  geom_point(size = .05) +
  scale_x_continuous(name = "Time (ms)",
                     limits = c(0, 1)) +
  scale_y_continuous(name = "Charge (pC)",
                     limits = c(-600000, 600000))

# merge smoothed and raw data (that is smoothed by taking 0.0032% random rows)
# calculate capacitance as charge derivative to voltage for random row charge and random row + smoothed charge
cap_diel_pF <- 203
data_cap <- merge(data_new, data_smooth) %>%
  mutate(
    cap_pF = c(NA,
               ifelse(abs(diff(charge_pC) / diff(voltage_V)) == Inf,
                      NA,
                      diff(charge_pC) / diff(voltage_V)
                      )
               ),
    cap_pF_smooth = c(NA,
                    ifelse(abs(diff(charge_pC_smooth) / diff(voltage_V)) == Inf,
                           NA,
                           diff(charge_pC_smooth) / diff(voltage_V)
                           )
                    )
         ) %>%
  dplyr::filter((is.na(cap_pF) == F | is.na(cap_pF_smooth) == F) & cap_pF < cap_diel_pF & cap_pF_smooth < cap_diel_pF)

ggplot(data = data_cap,
       aes(x = time_ms,
           y = cap_pF)) +
  geom_point(size = .05) +
  geom_hline(yintercept = 13) +
  scale_x_continuous(name = "Time (ms)",
                     limits = c(0, 1)) +
  scale_y_continuous(name = "Capacitance (pF)",
                     limits = c(-50, 500)) +
  geom_ribbon(aes(ymin = 100,
                  ymax = 150),
              alpha = 0.2)

ggplot(data = data_cap,
       aes(x = time_ms,
           y = cap_pF_smooth)) +
  geom_point(size = .05) +
  geom_hline(yintercept = 11.3) +
  scale_x_continuous(name = "Time (ms)",
                     limits = c(0, 1)) +
  scale_y_continuous(name = "Capacitance (pF)",
                     limits = c(-50, 500))

# calculate alpha
cap_cell_pF <- c()
for (i in 0:10) {
  cap_cell_pF[i+1] <- data_cap %>%
    filter(between(time_ms, 0.105 + i * (1/6), 0.175 + i * (1/6))) %>%
    pull(cap_pF_smooth) %>%
    median()
}

cap_cell_pF_avg <- mean(cap_cell_pF)
cap_cell_pF_sd  <-   sd(cap_cell_pF)

alpha <- list()
alpha2 <- c()
for (i in 0:10) {
  alpha[[i+1]] <- data_cap %>%
    filter(between(time_ms, 0.175 + i * (1/6), 0.245 + i * (1/6))) %>%
    mutate(alpha = (cap_diel_pF - cap_pF_smooth) / (cap_diel_pF - cap_cell_pF_avg)) %>%
    select(time_ms, alpha) %>%
    filter(between(alpha, 0, 1))
  alpha2[i+1] <- data_cap %>%
    filter(between(time_ms, 0.175 + i * (1/6), 0.245 + i * (1/6))) %>%
    mean(cap_pF_smooth)
}

alpha <- dplyr::bind_rows(alpha) %>%
  mutate(material = "sasol-1.8-cuo-10%",
         res_time = 40,
         .before = time_ms)

ggplot(alpha,
       aes(x = time_ms,
           y = alpha))+
  geom_point(size = 0.1) +
  scale_y_continuous(
    name = "Alpha",
    limits = c(-.1, 1.1)
    )

write_csv(alpha, "H:/data/drm/ugent/sasol-1.8-cuo-10%/sasol-1.8-cuo-10%-40.0s-alpha.csv")