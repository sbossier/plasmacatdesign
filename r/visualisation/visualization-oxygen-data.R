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
setwd("H:/data/dry-reforming-methane")
filename <- "overview-selec-yield-balance-o.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))


data %>% filter(compound == "CO") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_o,
             color = material)) +
  geom_point(size = 1.95) +
  geom_line(size  = 0.85,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_o + qt(.975, df) * selec_o_sd),
                    ymax  = 100 * (selec_o - qt(.975, df) * selec_o_sd)),
                width = 1.5,
                size  = 0.85,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(50, 115),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "O-selectivity CO (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))


data %>% filter(compound == "CO") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_o,
             color = material)) +
  geom_point(size = 1.95) +
  geom_line(size  = 0.85,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_o + qt(.975, df) * yield_o_sd),
                    ymax  = 100 * (yield_o - qt(.975, df) * yield_o_sd)),
                width = 1.5,
                size  = 0.95,
                alpha = 0.5,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 30),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "O-yield CO (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))


data %>% filter(compound == "CO") %>%
  ggplot(aes(x = res_time,
             y = 100 * balance_o,
             color = material)) +
  geom_point(size = 1.95) +
  geom_line(size  = 0.85,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (balance_o + qt(.975, df) * balance_o_sd),
                    ymax  = 100 * (balance_o - qt(.975, df) * balance_o_sd)),
                width = 1.5,
                size  = 0.95,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(80, 105),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "O-balance (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

