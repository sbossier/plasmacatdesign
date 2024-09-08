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
filename <- "overview-conv-eq-k-values.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))


data %>% filter(constant_type != "conv_eq" & pwr_sei == "Power Const." & supplier == c("VITO") & grepl("alpha", support_type)) %>%
  ggplot(aes(x = reorder(material_ab, value),
             y = value,
             fill = reorder(constant_type, value))) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = value - (qt(0.975, df) * value_sd) / sqrt(df + 1),
                    ymax = value + (qt(0.975, df) * value_sd) / sqrt(df + 1)),
                position = "dodge") +
  scale_y_continuous(limits = c(0, 0.075),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Materials",
       y     = expression(Reaction~rate~(s^-1)),
       fill = "Reaction rate constant type:") +
  theme_bw(base_size = 16) +
  scale_fill_colorblind(labels = c(expression(k[loss]),
                                   expression(f*k[form]),
                                   "k")) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 16),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 15),
        #axis.text.x     = element_text(angle = 0, hjust = 1)
        ) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))


