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
filename <- "overview-yield-ratio-alpha.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

#############################################
# H2:CO Yield Ratio (Syn Gas Ratio) vs. SEI #
#############################################

data %>% ggplot(aes(x = sei,
                    y = yield_ratio,
                    color = material_ab)) +
  #geom_point(size = 1.85) +
  geom_line(size  = 1.5,
            alpha = 1) +
  #geom_errorbar(aes(ymin  = yield_ratio + qt(.975, 7) * yield_ratio_sd / yield_ratio ^ 2,
  #                  ymax  = yield_ratio - qt(.975, 7) * yield_ratio_sd / yield_ratio ^ 2),
  #              width = 1.6,
  #              size  = 0.9,
  #              alpha = 0.75,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 6500),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0.5, 1.75),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "SEI (kJ/mole)",
       y     = expression(Yield~Ratio~H[2]:CO),
       color = "Materials:") +
  theme_bw(base_size = 18) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 17),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 16.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


data %>% ggplot(aes(x = res_time,
                    y = alpha,
                    color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  #geom_errorbar(aes(ymin  = alpha + qt(.975, 7) * alpha_sd,
  #                  ymax  = alpha - qt(.975, 7) * alpha_sd),
  #              width = 1.6,
  #              size  = 0.9,
  #              alpha = 0.4,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0.95, 1.05),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Residence Time (s)",
       y     = "Alpha",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
