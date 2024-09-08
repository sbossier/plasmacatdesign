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
filename <- "overview-conversion-co2-ch4-total.csv"
data     <- read_csv(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

######################################
# Total conversion vs residence time #
######################################

data %>% filter(compound == "Total") %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  geom_point(aes(color = material),
             size = 2) +
  geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
                    ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd),
                    color = material),
                width = 1.5,
                position = position_dodge(0.05),
                size = 0.90) +
  geom_line(aes(x     = res_time,
                y     = conv_fit * 100,
                color = material),
            size = 1) +
  geom_ribbon(aes(x     = res_time,
                  ymin  = conv_fit_lcl * 100,
                  ymax  = conv_fit_ucl * 100,
                  color = material),
              alpha = 0.05,
              size  = 0.6,
              show.legend = FALSE) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.005))) + 
  scale_y_continuous(limits = c(0, 60),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = "Total conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 15) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 13)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

###########################
# Total conversion vs SEI #
###########################

data %>% filter(compound == "Total") %>%
  ggplot(aes(x = sei,
             y = conv * 100)) +
  #geom_point(aes(color = material),
  #           size = 2) +
  #geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  color = material),
  #              width = 60,
  #              position = position_dodge(0.05),
  #              size = 1) +
  geom_line(aes(x     = sei,
                y     = conv_fit * 100,
                color = material_ab
                ),
            size = 1.5) +
  #geom_ribbon(aes(x     = sei,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material),
  #            alpha = 0.1,
  #            size  = 0.4,
  #            show.legend = F) +
  scale_x_continuous(limits = c(100, 200),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 5),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "SEI (kJ/mole)",
       y     = "Total conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

####################################
# CO2 conversion vs residence time #
####################################

data %>% filter(compound == "CO2") %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  geom_point(aes(color = material),
             size = 1.85) +
  geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
                    ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd),
                    color = material),
                width = 1.5,
                position = position_dodge(0.05),
                size = .75) +
  geom_line(aes(x     = res_time,
                y     = conv_fit * 100,
                color = material),
            size = .85) +
  geom_ribbon(aes(x     = res_time,
                  ymin  = conv_fit_lcl * 100,
                  ymax  = conv_fit_ucl * 100,
                  color = material),
              alpha = 0.05,
              size  = 0.5,
              show.legend = FALSE) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.005))) + 
  scale_y_continuous(limits = c(0, 30),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = "CO2 conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#########################
# CO2 conversion vs SEI #
#########################

data %>% filter(compound == "CO2") %>%
  ggplot(aes(x = sei,
             y = conv * 100)) +
  #geom_point(aes(color = material),
  #           size = 2) +
  #geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  color = material),
  #              width = 60,
  #              position = position_dodge(0.05),
  #              size = 1) +
  geom_line(aes(x     = sei,
                y     = conv_fit * 100,
                color = material),
            size = 1.5) +
  #geom_ribbon(aes(x     = sei,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material),
  #            alpha = 0.1,
  #            size  = 0.4,
  #            show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 70),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "SEI (kJ/mole)",
       y     = "CO2 conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

####################################
# CH4 conversion vs residence time #
####################################

data %>% filter(compound == "CH4") %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  geom_point(aes(color = material),
             size = 1.85) +
  geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
                    ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd),
                    color = material),
                width = 1.5,
                position = position_dodge(0.05),
                size = .75) +
  geom_line(aes(x     = res_time,
                y     = conv_fit * 100,
                color = material),
            size = .85) +
  geom_ribbon(aes(x     = res_time,
                  ymin  = conv_fit_lcl * 100,
                  ymax  = conv_fit_ucl * 100,
                  color = material),
              alpha = 0.05,
              size  = 0.5,
              show.legend = FALSE) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.005))) + 
  scale_y_continuous(limits = c(0, 70),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = "CH4 conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#########################
# CH4 conversion vs SEI #
#########################

data %>% filter(compound == "CH4") %>%
  ggplot(aes(x = sei,
             y = conv * 100)) +
  #geom_point(aes(color = material),
  #           size = 2) +
  #geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  color = material),
  #              width = 60,
  #              position = position_dodge(0.05),
  #              size = 1) +
  geom_line(aes(x     = sei,
                y     = conv_fit * 100,
                color = material),
            size = 1.5) +
  #geom_ribbon(aes(x     = sei,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material),
  #            alpha = 0.1,
  #            size  = 0.4,
  #            show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.01, 0.01))) + 
  scale_y_continuous(limits = c(0, 70),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "SEI (kJ/mole)",
       y     = "CH4 conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
