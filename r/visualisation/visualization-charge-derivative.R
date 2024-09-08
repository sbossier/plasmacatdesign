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

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())

# C450 #
########

sasol_18_c450 <-
  read_table("C:/Users/sbossier/Desktop/sasol-1.8-c450.txt") %>%
  slice(which(row_number() %% 50 == 1)) %>%
  mutate(compound   = "sasol-1.8",
         time_ms    = time_ms,
         voltage_V  = voltage_kV*1000,
         charge_pC  = charge_knC*1000*1000,
         current_reactor_mA = current_reactor_A * 1000,
         cap_pC = c(NA,
                    ifelse(abs(diff(charge_pC)/diff(voltage_V)) == Inf,
                    NA,
                    diff(charge_pC)/diff(voltage_V)))) %>%
  select(compound,
         time_ms,
         voltage_V,
         charge_pC,
         cap_pC) %>%
  dplyr::filter(is.na(cap_pC) == F) %>%
  mutate(filter = zoo::rollmean(x = cap_pC,
                                k = 50,
                                fill = NA))

plot(sasol_18_c450$time_ms,
     sasol_18_c450$filter,
     type = "l",
     ylab = "Cap pC",
     xlim = c(0, 1),
     ylim = c(-50, 125)
     )

# CuO 10% #
###########

sasol_18_cu10 <-
  read_table("C:/Users/sbossier/Desktop/sasol-1.8-cuo-10%.txt") %>%
  slice(which(row_number() %% 500 == 1)) %>%
  mutate(compound           = "alumina-cuo-10%",
         time_ms            = time_ms,
         voltage_V          = voltage_kV * 1000,
         charge_pC          = charge_knC * 1000 * 1000,
         charge_pC_rollmean = rollmean(charge_pC,
                               k = 9,
                               fill = NA),
         current_reactor_mA = current_reactor_A * 1000,
         cap_pC = c(NA,
                    ifelse(abs(diff(charge_pC)/diff(voltage_V)) == Inf,
                           NA,
                           diff(charge_pC)/diff(voltage_V)
                           )
                    )
         ) %>%
  select(compound,
         time_ms,
         voltage_V,
         charge_pC_rollmean,
         charge_pC,
         cap_pC) %>%
  dplyr::filter(is.na(cap_pC) == F) %>%
  mutate(cap_pC = rollmean(x = cap_pC,
                                k = 3,
                                fill = NA))

ggplot(sasol_18_cu10, aes(x = time_ms))+
  geom_line(aes(y = cap_pC))+
  geom_line(aes(y = voltage_V/10)) +
  scale_y_continuous(
    name = "Capacitance (nF)",
    sec.axis = sec_axis(trans = ~.*10, name = "Voltage (V)")
  )



plot(sasol_18_cu10$voltage_V,
     sasol_18_cu10$charge_pC,
     type = "l")
plot(sasol_18_cu10$voltage_V,
     sasol_18_cu10$charge_pC_rollmean,
     type = "l")

plot(sasol_18_cu10$time_ms,
     sasol_18_cu10$cap_pC,
     type = "l",
     ylab = "Cap pC",
     xlim = c(0, 0.5),
     ylim = c(-500, 500)
)


# Fe2O3 10% #
#############

sasol_18_fe10 <-
  read_table("C:/Users/sbossier/Desktop/sasol-1.8-fe2o3-10%.txt") %>%
  slice(which(row_number() %% 1000 == 1)) %>%
  mutate(compound           = "sasol-1.8-fe10",
         time_ms            = time_ms,
         voltage_V          = voltage_kV*1000,
         charge_pC_rollmean = rollmean(charge_knC * 1000 * 1000,
                                       k = 5,
                                       fill = NA),
         charge_pC          = charge_knC * 1000 * 1000,
         current_reactor_mA = current_reactor_A * 1000,
         cap_pC = c(NA,
                    ifelse(abs(diff(charge_pC)/diff(voltage_V)) == Inf,
                           NA,
                           abs(diff(charge_pC)/diff(voltage_V))))) %>%
  select(compound,
         time_ms,
         voltage_V,
         charge_pC_rollmean,
         charge_pC,
         cap_pC) %>%
  dplyr::filter(is.na(cap_pC) == F) %>%
  mutate(filter = zoo::rollmean(x = cap_pC,
                                k = 2,
                                fill = NA))

plot(sasol_18_fe10$voltage_V,
     sasol_18_fe10$charge_pC,
     type = "l")

plot(sasol_18_fe10$time_ms,
     sasol_18_fe10$filter,
     type = "l",
     ylab = "Cap pC",
     xlim = c(0, 1),
     ylim = c(-10, 500)
)

data <- bind_rows(sasol_18_c450, sasol_18_cu10, sasol_18_fe10)