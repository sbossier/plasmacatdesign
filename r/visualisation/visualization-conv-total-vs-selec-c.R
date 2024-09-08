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
filename_selec <- "overview-selec-yield-balance-c.csv"
data_selec     <- read_csv(filename_selec, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

data_selec <- data_selec[order(data_selec$compound, decreasing = T),]

filename_conv  <- "overview-conversion-co2-ch4-total.csv"
data_conv     <- read_csv(filename_conv, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

data_conv_total <- data_conv[order(data_conv$material, decreasing = T),] %>% select(c(compound, material, conv, conv_sd, df_conv)) %>%
  filter(compound == "Total" & conv != "NA") %>%
  rename(name = compound, material_check = material)

data <- cbind(data_selec, data_conv_total)

##############################################
# Total Conversion vs. CO Carbon Selectivity #
##############################################

data %>% filter(compound == "CO") %>%
  ggplot(aes(x = 100 * conv,
                    y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(25, 75),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity CO (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

################################################
# Total Conversion vs. C2H6 Carbon Selectivity #
################################################

data %>% filter(compound == "C2H6") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 1) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.75,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 25),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity C2H6 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

################################################
# Total Conversion vs. C2H4 Carbon Selectivity #
################################################

data %>% filter(compound == "C2H4") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.1, 1.75),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity C2H4 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

################################################
# Total Conversion vs. C2H2 Carbon Selectivity #
################################################

data %>% filter(compound == "C2H2") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.1, 4),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity C2H2 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

################################################
# Total Conversion vs. C3H8 Carbon Selectivity #
################################################

data %>% filter(compound == "C3H8") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
             color = material)) +
  geom_point(size = 2) +
  geom_line(size  = 1, 
            alpha = 1) +
  geom_errorbar(aes(xmin = 100 * (conv - qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1)),
                    xmax = 100 * (conv + qt(.975, df_conv) * conv_sd / sqrt(df_conv + 1))),
                width = 0.1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 50),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity C3H8 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

###################################################
# Total Conversion vs. CH3OCH3 Carbon Selectivity #
###################################################

data %>% filter(compound == "CH3OCH3") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 12),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity CH3OCH3 (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#################################################
# Total Conversion vs. CH3OH Carbon Selectivity #
#################################################

data %>% filter(compound == "CH3OH") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.01, 0.3),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity CH3OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

##################################################
# Total Conversion vs. C2H5OH Carbon Selectivity #
##################################################

data %>% filter(compound == "C2H5OH") %>%
  ggplot(aes(x = 100 * conv,
             y = 100 * selec_c,
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
  geom_errorbar(aes(ymin = 100 * (selec_c - qt(.975, df) * selec_c_sd / sqrt(df + 1)),
                    ymax = 100 * (selec_c + qt(.975, df) * selec_c_sd / sqrt(df + 1))),
                width = 1,
                size  = 0.9,
                alpha = 0.4,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 55),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(-0.01, 1),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "Total Conversion (%)",
       y     = "Carbon Selectivity C2H5OH (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
