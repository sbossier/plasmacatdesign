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
filename <- "overview-selec-yield-balance-h.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

#################
# Hydrogen (H2) #
#################

# H2 Selectivity #
##################

data %>% filter(compound == "H2") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(20, 50),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# H2 Yield #
############

data %>% filter(compound == "H2") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 1) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.75,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(-1, 25),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#################
# Ethane (C2H6) #
#################

# C2H6 Selectivity #
####################

data %>% filter(compound == "C2H6") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 35),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity C2H6 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# C2H6 Yield #
##############

data %>% filter(compound == "C2H6") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 6),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield C2H6 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#################
# Ethene (C2H4) #
#################

# C2H4 Selectivity #
####################

data %>% filter(compound == "C2H4") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(-0.25, 1.75),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity C2H4 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# C2H4 Yield #
##############

data %>% filter(compound == "C2H4") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(-0.01, 0.1),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield C2H4 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#################
# Ethyne (C2H2) #
#################

# C2H2 Selectivity #
####################

data %>% filter(compound == "C2H2") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(-0.25, 2),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity C2H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# C2H2 Yield #
##############

data %>% filter(compound == "C2H2") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 0.4),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield C2H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##################
# Propane (C3H8) #
##################

# C3H8 Selectivity #
####################

data %>% filter(compound == "C3H8") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 70),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity C3H8 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# C3H8 Yield #
##############

data %>% filter(compound == "C3H8") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 10),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield C3H8 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

###########################
# Dimethylether (CH3OCH3) #
###########################

# CH3OCH3 Selectivity #
#######################

data %>% filter(compound == "CH3OCH3") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 10),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity CH3OCH3 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# CH3OCH3 Yield #
#################

data %>% filter(compound == "CH3OCH3") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 4),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield CH3OCH3 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

####################
# Methanol (CH3OH) #
####################

# CH3OH Selectivity #
#####################

data %>% filter(compound == "CH3OH") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 0.60),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity CH3OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# CH3OH Yield #
###############

data %>% filter(compound == "CH3OH") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 4),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield CH3OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

####################
# Ethanol (C2H5OH) #
####################

# C2H5OH Selectivity #
######################

data %>% filter(compound == "C2H5OH") %>%
  ggplot(aes(x = res_time,
             y = 100 * selec_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (selec_h + qt(.975, df) * selec_h_sd),
                    ymax  = 100 * (selec_h - qt(.975, df) * selec_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.45,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(0, 10),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-selectivity C2H5OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

# C2H5OH Yield #
################

data %>% filter(compound == "C2H5OH") %>%
  ggplot(aes(x = res_time,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.75,
            alpha = 0.65) +
  geom_errorbar(aes(ymin  = 100 * (yield_h + qt(.975, df) * yield_h_sd),
                    ymax  = 100 * (yield_h - qt(.975, df) * yield_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.40,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 2),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-yield C2H5OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

####################
# Hydrogen Balance #
####################

data %>% filter(compound == "H2") %>%
  ggplot(aes(x = res_time,
             y = 100 * balance_h,
             color = material)) +
  geom_point(size = 1.85) +
  geom_line(size  = 0.85,
            alpha = 1) +
  geom_errorbar(aes(ymin  = 100 * (balance_h + qt(.975, df) * balance_h_sd),
                    ymax  = 100 * (balance_h - qt(.975, df) * balance_h_sd)),
                width = 1.50,
                size  = 0.85,
                alpha = 0.5,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.01))) + 
  scale_y_continuous(limits = c(60, 105),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence Time (s)",
       y     = "H-balance (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

