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
ca_free_alcl <-
  read_table("H:/data/co2-splitting/vito/AlCl-1600-S1700-F94/pwr-cte/70.0s-01/20210531-0034.txt") %>%
  mutate(compound = "α-Al2O3, Ca-free, AlCl3")
centre_value <- ca_free_alcl %>% filter(voltage_kV == 0) %>% select(charge_knC) %>% {mean(.$charge_knC)}
ca_free_alcl <- ca_free_alcl %>% mutate(charge_knC = charge_knC - centre_value)

ca_free_alno3 <-
  read_table("H:/data/co2-splitting/vito/AlNO3-1600-S1700-F90/pwr-cte/lissajous-data/70.0s-01-plasma/20220316-0001.txt") %>%
  mutate(compound = "α-Al2O3, Ca-free, Al(NO3)3")
centre_value <- ca_free_alno3 %>% filter(voltage_kV == 0) %>% select(charge_knC) %>% {mean(.$charge_knC)}
ca_free_alno3 <- ca_free_alno3 %>% mutate(charge_knC = charge_knC - centre_value)

ca_cont_caal <-
  read_table("H:/data/co2-splitting/vito/CaAl-1600-S1700-F94/pwr-cte/70.0s-02/20210506-0049.txt") %>%
  mutate(compound = "α-Al2O3, Ca-cont, CaCl3")
centre_value <- ca_cont_caal %>% filter(voltage_kV == 0) %>% select(charge_knC) %>% {mean(.$charge_knC)}
ca_cont_caal <- ca_cont_caal %>% mutate(charge_knC = charge_knC - centre_value)

porous_0surf <-
  read_table("H:/data/co2-splitting/vito/PlAl-21001-1450/pwr-ct/70.0s-01/lissajous/20211011-0012.txt") %>%
  mutate(compound = "α-Al2O3, Ca-free, Porous")
centre_value <- porous_0surf %>% filter(voltage_kV == 0) %>% select(charge_knC) %>% {mean(.$charge_knC)}
porous_0surf <- porous_0surf %>% mutate(charge_knC = charge_knC - centre_value)

porous_5surf <-
  read_table("H:/data/co2-splitting/vito/PlAl-21003-1450/pwr-ct/70.0s-01/lissajous/20210923-0036.txt") %>%
  mutate(compound = "α-Al2O3, Ca-free, Porous, 5% Surfactant")
centre_value <- porous_5surf %>% filter(voltage_kV == 0) %>% select(charge_knC) %>% {mean(.$charge_knC)}
porous_5surf <- porous_5surf %>% mutate(charge_knC = charge_knC - centre_value)

data <- bind_rows(ca_free_alcl, ca_free_alno3, ca_cont_caal, porous_0surf, porous_5surf)

data %>% filter(between(time_ms, 0.3, 0.466)
                #& !grepl("Porous", compound)
                ) %>%
  ggplot(aes(x     = time_ms - 0.3,
             y     = current_reactor_A*1000,
             color = compound)) +
  geom_line(size  = 0.75,
            alpha = 1) +
  #scale_x_continuous(expand = expansion(mult = c(0, 0.01))) +
  #scale_y_continuous(limits = c(-10, 105),
                     #expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Time (ms)",
       y     = "Measured reactor current (mA)",
       color = "Material:") +
  facet_wrap(. ~ compound, labeller = label_wrap_gen(width = 11, multi_line = TRUE)) +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "none",
        legend.text     = element_text(size = 16),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 15)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

data2 <-
  data %>%
  group_by(compound) %>%
  slice_sample(prop = 0.1) %>%
  arrange(time_ms) %>%
  ungroup

data2 %>% #filter(!grepl("Porous", compound)) %>%
  ggplot(aes(x = voltage_kV,
             y = charge_knC*1000,
             color = compound)) +
  geom_path(size = 0.75,
            alpha = 0.75) +
  labs(x = "Applied voltage (kV)",
       y = "Measured charge (nC)",
       color = "Material") +
  facet_wrap(compound ~ ., labeller = label_wrap_gen(width = 11, multi_line = TRUE)) +
  theme_bw(base_size = 16) +
  scale_color_colorblind() +
  theme(legend.position = "none",
        legend.text = element_text(size = 16),
        text = element_text(family = "Calibri"),
        axis.text = element_text(size = 15)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

