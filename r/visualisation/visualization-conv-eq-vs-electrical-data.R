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
gc()

# Read in starting data
setwd("H:/data/co2-splitting")
filename <- "overview-conv-co2-u-pp.csv"
data     <- read_csv(filename,
                     na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"),
                     locale = locale(encoding = "latin1"))

#qt(.975, df_calc) * 
data %>% dplyr::filter(pwr_sei == "Power Const.") %>%
  ggplot(aes(x = rel_perm_overall,
             y = conv * 100,
             color = support_type)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = conv_lcl * 100,
                    ymax = conv_ucl * 100),
                width = .1,
                size  = 1,
                alpha = 1,
                show.legend = F) +
  geom_errorbarh(aes(xmin  = rel_perm_overall - rel_perm_overall_error,
                     xmax  = rel_perm_overall + rel_perm_overall_error),
                 height = 1,
                 size  = 1,
                 alpha = 1,
                 show.legend = F) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Alpha",
       y     = "85 sec Fitted Conversion (%)",
       color = "Support:") +
  #geom_smooth(aes(group = 1),
  #            method = lm,
  #            se = F) +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 2, bycol = T))
