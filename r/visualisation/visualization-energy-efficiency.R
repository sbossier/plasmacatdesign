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
setwd("H:/data/co2-splitting")
filename <- "overview-energy-efficiency.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

########################################################
# Energy Efficiency Based On Gibbs Free Energy vs. SEI #
########################################################

# filter(compound == "CO2" & supplier == c("VITO") & grepl("TiO2", material))

data %>% filter(supplier == c("VITO") & grepl("TiO2", material) | grepl("Empty", material)) %>%
  ggplot(aes(x     = sei,
             y     = ee_gf,
             color = material_ab)) +
  #geom_point(size = 1.95) +
  geom_line(aes(x     = sei,
                y     = ee_gf_fit,
                color = material_ab,
                linetype = pwr_sei
                ),
            size = 1.75) +
  #geom_errorbar(aes(ymin = ee_gf - qt(0.975, df) * ee_gf_sd,
  #                  ymax = ee_gf + qt(0.975, df) * ee_gf_sd),
  #              width = 1.6,
  #              size  = 0.9,
  #              alpha = 0.4,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "SEI (kJ/mole)",
       y     = "Energy Efficiency based on \n Gibbs Free Energy of Formation (%)",
       color = "Materials:",
       linetype = "Versus Empty Reactor") +
  theme_bw(base_size = 18) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 17),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 15.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


####################################################################
# Energy efficiency based on Gibbs Free Energy of Formation vs SEI #
####################################################################
data %>% filter(supplier == c("VITO") & grepl("Al", material) | grepl("Empty", material)) %>%
  ggplot(aes(x     = sei,
             y     = ee_gf,
             color = material)) +
  #geom_point(size = 1.95) +
  geom_line(aes(x     = sei,
                y     = ee_gf_fit,
                color = material,
                linetype = pwr_sei
               ),
            size = 1.5) +
  #geom_errorbar(aes(ymin = ee_gf - qt(0.975, df) * ee_gf_sd,
  #                  ymax = ee_gf + qt(0.975, df) * ee_gf_sd),
  #              width = 1.6,
  #              size  = 0.9,
  #              alpha = 0.4,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 6.5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "SEI (kJ/mole)",
       y     = "Energy Efficiency based on \n Gibbs Free Energy of Formation (%)",
       color = "Materials:",
       linetype = "Versus Empty Reactor") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


data %>% ggplot(aes(x     = res_time,
                    y     = ee_lhv,
                    color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 1) +
  geom_errorbar(aes(ymin = ee_lhv - qt(0.975, df) * ee_lhv_sd,
                    ymax = ee_lhv + qt(0.975, df) * ee_lhv_sd),
                width = 1.6,
                size  = 0.9,
                alpha = 0.75,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(1, 5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "Energy Efficiency based on \n Lower Heating Values (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))


data %>% ggplot(aes(x     = res_time,
                    y     = ee_hhv,
                    color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin = ee_hhv - qt(0.975, df) * ee_hhv_sd,
                    ymax = ee_hhv + qt(0.975, df) * ee_hhv_sd),
                width = 1.6,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "Energy Efficiency based on \n Higher Heating Values (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
