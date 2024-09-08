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
filename_yield  <- "overview-selec-yield-balance-h.csv"
data_yield      <- read_csv(filename_yield, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

data_yield <- data_yield[order(data_yield$compound, data_yield$material),]

filename_conv   <- "overview-conversion-co2-ch4-total.csv"
data_conv       <- read_csv(filename_conv, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

data_conv_ch4 <- data_conv[order(data_conv$material),] %>% select(c(compound, material, conv, conv_sd, df_conv)) %>%
  filter(compound == "CH4" & conv != "NA") %>%
  rename(name = compound, material_check = material)

data <- na.omit(cbind(data_yield, data_conv_ch4))

########################################
# CH4 Conversion vs. H2 Hydrogen Yield #
########################################

data %>% filter(compound == "H2") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  #geom_point(size = 2) +
  geom_line(size  = 1.5, 
            alpha = 1) +
  #geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
  #                  xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
  #              width = 0.75,
  #              size  = 0.9,
  #              alpha = 0.5,
  #              show.legend = F) +
  #geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
  #                  ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
  #              width = 1,
  #              size  = 0.9,
  #              alpha = 0.5,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 30),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##########################################
# CH4 Conversion vs. C2H6 Hydrogen Yield #
##########################################

data %>% filter(compound == "C2H6") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.75,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 6),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield C2H6 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##########################################
# CH4 Conversion vs. C2H4 Hydrogen Yield #
##########################################

data %>% filter(compound == "C2H4") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.01,
                size  = 0.8,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.8,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.025, 0.15),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield C2H4 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##########################################
# CH4 Conversion vs. C2H2 Hydrogen Yield #
##########################################

data %>% filter(compound == "C2H2") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.01,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.1, 0.5),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield C2H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##########################################
# CH4 Conversion vs. C3H8 Hydrogen Yield #
##########################################

data %>% filter(compound == "C3H8") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 10),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield C3H8 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#############################################
# CH4 Conversion vs. CH3OCH3 Hydrogen Yield #
#############################################

data %>% filter(compound == "CH3OCH3") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 5),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield CH3OCH3 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

###########################################
# CH4 Conversion vs. CH3OH Hydrogen Yield #
###########################################

data %>% filter(compound == "CH3OH") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.01,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.01, 0.25),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield CH3OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

############################################
# CH4 Conversion vs. C2H5OH Hydrogen Yield #
############################################

data %>% filter(compound == "C2H5OH") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * yield_h,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 0.75) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.01,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (yield_h - qt(.975, df) * yield_h_sd / sqrt(df + 1)),
                    ymax = 100 * (yield_h + qt(.975, df) * yield_h_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 65),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.5, 5),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "CH4 Conversion (%)",
       y     = "Hydrogen Yield C2H5OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
