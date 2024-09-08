# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(readxl)
library(ggrepel)
library(ggthemes)
library(Rttf2pt1)
library(extrafontdb)
library(extrafont)
library(directlabels)

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())
gc()

# Read in starting data from an excel file
setwd("H:/data/co2-splitting")
filename <- "overview-conv-co2.xlsx"
data <- read_excel(filename, na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"))

data_conv <- data %>%
  group_by(material, pwr_sei) %>%
  select(supplier, material, res_time, conv, conv_sd, df_conv) %>%
  filter(conv != "NA") %>%
  mutate(co2_mole_fraction = (1-conv)/(1+conv/2)) %>%
  ungroup() %>%
  filter(supplier == "VITO", pwr_sei == "Power Const.") %>%
  write_csv(., "C:/Users/sbossier/Desktop/data_mole_fraction.txt")

data_conv %>% filter(supplier == "VITO", pwr_sei == "Power Const.") %>%
  ggplot(aes(x = res_time,
             y = co2_mole_fraction)) +
  geom_line(aes(color = material),
             size = 2) +
  scale_x_continuous(limits = c(0, 40),
                     expand = expansion(mult = c(0.0, 0.02))) + 
  scale_y_continuous(limits = c(0.4, 1),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = expression(CO[2]~conversion~("%")),
       color = "Materials:") +
  theme_bw(base_size = 13) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 12)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

data_conv %>% filter(supplier == "VITO", pwr_sei == "Power Const.") %>%
  ggplot(aes(x = res_time,
             y = log(co2_mole_fraction))) +
  geom_line(aes(color = material),
            size = 2) +
  scale_x_continuous(limits = c(0, 40),
                     expand = expansion(mult = c(0.0, 0.02))) + 
  scale_y_continuous(limits = c(-.75, 0),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = expression(CO[2]~conversion~("%")),
       color = "Materials:") +
  theme_bw(base_size = 13) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 12)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

data_conv %>% filter(supplier == "VITO", pwr_sei == "Power Const.") %>%
  ggplot(aes(x = res_time,
             y = 1/co2_mole_fraction)) +
  geom_line(aes(color = material),
            size = 2) +
  scale_x_continuous(limits = c(0, 40),
                     expand = expansion(mult = c(0.0, 0.02))) + 
  scale_y_continuous(limits = c(1, 2.5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = expression(CO[2]~conversion~("%")),
       color = "Materials:") +
  theme_bw(base_size = 13) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 12)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


########################################
# CO2 conversion vs SEI w/ data points #
########################################
# & pwr_sei == "Power Const." & supplier == c("UHasselt")
# data %>% filter(material == c("SiO2", "GM10.3", "GM10.4", "Glass Beads HT"))
material == "SiO2" |
  material == "GM10.3" |
  material == "GM10.4" |
  material == "Glass Beads HT"
data %>% filter((material_ab == "α-Al2O3, Ca-cont, CaCl3" |
                 material_ab == "α-Al2O3, Ca-free, AlCl3" |
                 material_ab == "TiO2 Anatase" |
                 material_ab == "TiO2 Rutile") &
                 pwr_sei == "Power Const.") %>%
  ggplot(aes(x = sei,
             group = material_ab,
             color = material_ab)) +
  geom_point(aes(y = conv * 100),
             size = 2.5) +
  geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
                    ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd)),
                width = 60,
                position = position_dodge(0.05),
                size = 1.15) +
  geom_line(aes(y = conv_fit * 100,
                #shape = pwr_sei
                ),
            size = 1.5) +
  geom_ribbon(aes(ymin  = conv_fit_lcl * 100,
                  ymax  = conv_fit_ucl * 100#,
                  #shape = pwr_sei
                  ),
              alpha       = 0.05,
              size        = 0.4,
              show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.01, 0.03))) + 
  scale_y_continuous(limits = c(0, 56),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x     = "SEI (kJ/mol)",
       y     = expression(CO[2]~Conversion~("%")),
       color = "Materials:",
       #linetype = "Versus Empty Reactor:"
  ) +
  theme_bw(base_size = 17) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13.5),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 16)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))

#########################################
# CO2 conversion vs SEI w/o data points #
#########################################

# filter(compound == "CO2" & supplier == c("UHasselt") & grepl("Al", material) | grepl("Empty", material))

data %>% filter(pwr_sei == "Power Const." & grepl("alpha", support_type) & supplier == c("VITO")) %>%
  ggplot(aes(x = sei,
             y = conv * 100)) +
  geom_line(aes(x     = sei,
                y     = conv_fit * 100,
                color = material_ab,
                #linetype = pwr_sei
                ),
                size = 1.75) +
  #geom_ribbon(aes(x     = sei,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material,
  #                shape = pwr_sei),
  #            alpha = 0.05,
  #            size  = 0.5,
  #            show.legend = F) +
  scale_x_continuous(limits = c(0, 8000),
                     expand = expansion(mult = c(0.0, 0.005))) + 
  scale_y_continuous(limits = c(0, 50),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "SEI (kJ/mol)",
       y     = expression(CO[2]~Conversion~("%")),
       color = "Materials:",
       #linetype = "Versus Empty Reactor:"
       ) +
  theme_bw(base_size = 18) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 17),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 16.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

###################################################
# CO2 conversion vs residence time w/ data points #
###################################################

data %>% filter(pwr_sei == "Power Const." & supplier == c("VITO") & grepl("alpha", support_type)) %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  geom_point(aes(color = material_ab),
             size = 2) +
  geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
                    ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd),
                    color = material_ab),
                width = 1.5,
                position = position_dodge(0.05),
                size = 1.50) +
  geom_line(aes(x     = res_time,
                y     = conv_fit * 100,
                color = material_ab),
                size = 1.75) +
  #geom_ribbon(aes(x     = res_time,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material,
  #                lineshape = pwr_sei),
  #            alpha = 0.05,
  #            size  = 0.5,
  #            show.legend = FALSE) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.02))) + 
  scale_y_continuous(limits = c(0, 50),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = expression(CO[2]~conversion~("%")),
       color = "Materials:") +
  theme_bw(base_size = 13) +
  scale_colour_colorblind() +
  theme(legend.position = "none",
        legend.text     = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 12)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

####################################################
# CO2 conversion vs residence time w/o data points #
####################################################

data %>% filter(compound == "CO2" & supplier == c("UHasselt", "LADCA")) %>%
  ggplot(aes(x = res_time,
             y = conv * 100)) +
  #geom_point(aes(color = material),
  #           size = 1.85) +
  #geom_errorbar(aes(ymin  = 100 * (conv - qt(0.975, df = df_conv) * conv_sd),
  #                  ymax  = 100 * (conv + qt(0.975, df = df_conv) * conv_sd),
  #                  color = material),
  #              width = 1.5,
  #              position = position_dodge(0.05),
  #              size = .75) +
  geom_line(aes(x     = res_time,
                y     = conv_fit * 100,
                color = material),
            size = 1) +
  #geom_ribbon(aes(x     = res_time,
  #                ymin  = conv_fit_lcl * 100,
  #                ymax  = conv_fit_ucl * 100,
  #                color = material,
  #                lineshape = pwr_sei),
  #            alpha = 0.05,
  #            size  = 0.5,
  #            show.legend = FALSE) +
  scale_x_continuous(limits = c(0, 100),
                     expand = expansion(mult = c(0.0, 0.005))) + 
  scale_y_continuous(limits = c(0, 45),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = "CO2 conversion (%)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))
