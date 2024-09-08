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
filename <- "lissajous-data-raw.csv"
data     <- read_csv(filename,
                     na = c("NA", "N/A", "N A", "Na", "na", "n a", "N a"),
                     locale=locale(encoding="latin1")
                     )

# Calculations based on measured data 
data <- data %>%
  mutate(
         red_el_field_Td = ((U_pp_kV * 1000 / 2) / (4.44e-3)) / (101325 / ((273.15 + gas_temp_avg_dgc) * 1.380649e-23)) * 1e21,
         disch_gap_mm    = (diam_elec_out_mm - diam_elec_in_mm) / 2 - thickn_db_mm,
         disch_vol_mL    = (((diam_elec_out_mm - 2 * thickn_db_mm)/2) ^ 2 - (diam_elec_in_mm / 2) ^ 2) * pi * 0.1,
         diam_db_in_mm   = diam_elec_out_mm - 2 * thickn_db_mm,
         gap_gas_mm      = (2 * (1 - packing_factor) * disch_vol_mL * 10 ^ 3) / (pi * disch_l_mm * (diam_elec_in_mm + diam_db_in_mm)),
         gap_p_mm        = disch_gap_mm - gap_gas_mm,
         A_elec_out_mm2  = diam_elec_out_mm * pi * disch_l_mm,
         C_db            = (2 * pi * 8.8541878128e-12 * rel_perm_db * disch_l_mm * 1e-3) / log(diam_elec_out_mm / diam_db_in_mm) * 1e9, #capacitance in nF
         C_eff_DA        = slope_DA_nCperV,
         C_p_DA          = 1 / (1 / C_eff_DA - 1 / C_db),
         rel_perm_p_DA   = (C_p_DA * gap_p_mm) / (8.8541878128e-6 * A_elec_out_mm2),
         C_eff_BC        = slope_BC_nCperV,
         C_p_BC          = 1 / (1 / C_eff_BC - 1 / C_db),
         rel_perm_p_BC   = (C_p_BC * gap_p_mm) / (8.8541878128e-6 * A_elec_out_mm2),
         rel_perm_p_avg  = (rel_perm_p_DA + rel_perm_p_BC) / 2,
         rel_perm_p_diff = abs(rel_perm_p_DA - rel_perm_p_BC),
         alpha           = (C_db - slope_DA_nCperV) / (C_db - slope_CD_nCperV),
         avg_displ_Q_per_half_cycle_nC = avg_num_µdisch_per_half_cycle * avg_displ_Q_per_peak_nCperpeak
        )

c_eff <- data %>%
  group_by(material) %>%
  dplyr::filter(supplier == "UGent", pwr_sei == "Power Const.") %>%
  mutate(C_eff_DA_avg = mean(C_eff_DA, na.rm = T),
         C_eff_DA_sd  = sd(C_eff_DA, na.rm = T)) %>%
  select(material,
         C_eff_DA_avg,
         C_eff_DA_sd) %>%
  ungroup() %>%
  unique()

U_pp_kV <- data %>%
  group_by(material) %>%
  dplyr::filter(supplier == "UGent",
         pwr_sei == "Power Const.") %>%
  mutate(U_pp_kV_avg = mean(U_pp_kV, na.rm = T),
         U_pp_kV_sd  = sd(U_pp_kV, na.rm = T)) %>%
  select(material,
         U_pp_kV_avg,
         U_pp_kV_sd) %>%
  ungroup() %>%
  unique()

# calculate average & sd of the data to plot
data_avg_res_time <- data %>%
  group_by(supplier, material, pwr_sei, res_time) %>%
  transmute(
    supplier                          = supplier,
    material                          = material,
    res_time                          = res_time,
    U_min_pos_kV_avg                  = mean(U_min_pos_kV, na.rm = T),
    U_min_pos_kV_sd                   = sd(U_min_pos_kV, na.rm = T),
    U_min_neg_kV_avg                  = mean(U_min_neg_kV, na.rm = T),
    U_min_neg_kV_sd                   = sd(U_min_neg_kV, na.rm = T),
    U_pp_kV_avg                       = mean(U_pp_kV, na.rm = T),
    U_pp_kV_sd                        = sd(U_pp_kV, na.rm = T),
    plasma_power_W_avg                = mean(plasma_power_W, na.rm = T),
    plasma_power_W_sd                 = sd(plasma_power_W, na.rm = T),
    source_power_W_avg                = mean(source_power_W, na.rm = T),
    source_power_W_sd                 = sd(source_power_W, na.rm = T),
    plasma_rms_current_mA_avg         = mean(plasma_rms_current_mA, na.rm = T),
    plasma_rms_current_mA_sd          = sd(plasma_rms_current_mA, na.rm = T),
    source_rms_current_mA_avg         = mean(source_rms_current_mA, na.rm = T),
    source_rms_current_mA_sd          = sd(plasma_rms_current_mA, na.rm = T),
    avg_num_µdisch_per_half_cycle_avg = round(mean(avg_num_µdisch_per_half_cycle, na.rm = T)),
    avg_num_µdisch_per_half_cycle_sd  = round(sd(avg_num_µdisch_per_half_cycle, na.rm = T)),
    avg_displ_Q_per_half_cycle_nC_avg = mean(avg_displ_Q_per_half_cycle_nC, na.rm = T),
    avg_displ_Q_per_half_cycle_nC_sd  = sd(avg_displ_Q_per_half_cycle_nC, na.rm = T),
    red_el_field_Td_avg               = mean(red_el_field_Td, na.rm = T),
    red_el_field_Td_sd                = sd(red_el_field_Td, na.rm = T),
    alpha_avg                         = mean(alpha, na.rm = T),
    alpha_sd                          = sd(alpha, na.rm = T),
    df_calc                           = df_calc) %>%
  unique() %>%
  ungroup()

data_avg <- data %>%
  group_by(supplier, material, pwr_sei) %>%
  transmute(
    supplier                          = supplier,
    material                          = material,
    pwr_sei                           = pwr_sei,
    U_min_pos_kV_avg                  = mean(U_min_pos_kV, na.rm = T),
    U_min_pos_kV_sd                   = sd(U_min_pos_kV, na.rm = T),
    U_min_neg_kV_avg                  = mean(U_min_neg_kV, na.rm = T),
    U_min_neg_kV_sd                   = sd(U_min_neg_kV, na.rm = T),
    U_pp_kV_avg                       = mean(U_pp_kV, na.rm = T),
    U_pp_kV_sd                        = sd(U_pp_kV, na.rm = T),
    plasma_power_W_avg                = mean(plasma_power_W, na.rm = T),
    plasma_power_W_sd                 = sd(plasma_power_W, na.rm = T),
    source_power_W_avg                = mean(source_power_W, na.rm = T),
    source_power_W_sd                 = sd(source_power_W, na.rm = T),
    plasma_rms_current_mA_avg         = mean(plasma_rms_current_mA, na.rm = T),
    plasma_rms_current_mA_sd          = sd(plasma_rms_current_mA, na.rm = T),
    source_rms_current_mA_avg         = mean(source_rms_current_mA, na.rm = T),
    source_rms_current_mA_sd          = sd(plasma_rms_current_mA, na.rm = T),
    avg_num_µdisch_per_half_cycle_avg = round(mean(avg_num_µdisch_per_half_cycle, na.rm = T)),
    avg_num_µdisch_per_half_cycle_sd  = round(sd(avg_num_µdisch_per_half_cycle, na.rm = T)),
    avg_displ_Q_per_half_cycle_nC_avg = mean(avg_displ_Q_per_half_cycle_nC, na.rm = T),
    avg_displ_Q_per_half_cycle_nC_sd  = sd(avg_displ_Q_per_half_cycle_nC, na.rm = T),
    red_el_field_Td_avg               = mean(red_el_field_Td, na.rm = T),
    red_el_field_Td_sd                = sd(red_el_field_Td, na.rm = T),
    alpha_avg                         = mean(alpha, na.rm = T),
    alpha_sd                          = sd(alpha, na.rm = T),
    df_calc                           = n()) %>%
  unique() %>%
  ungroup()
  

# Write the calculated data back to the file
write_csv(data, "lissajous-data-processed.csv")
write_csv(data_avg_res_time, "lissajous-data-average-res-time.csv")
write_csv(data_avg, "lissajous-data-average.csv")


rel_perm <- data %>%
  dplyr::filter(res_time >= 30) %>%
  group_by(material, pwr_sei) %>%
  mutate(rel_perm = mean(rel_perm_p_DA, na.rm = T),
         rel_perm_sd = sd(rel_perm_p_DA, na.rm = T)) %>%
  ungroup() %>%
  select(material, rel_perm, rel_perm_sd) %>%
  unique()


#####################
# U_min_pos vs. SEI #
#####################
data %>% dplyr::filter(pwr_sei == "Power Const." & grepl("Al", support_type)) %>%
  ggplot(aes(x = sei,
             y = U_min_pos_kV_avg,
             color = material)) +
  geom_point(size = 2) +
  geom_line(alpha = 1) +
  geom_errorbar(aes(ymin  = U_min_pos_kV_avg + qt(.975, df_calc) * U_min_pos_kV_sd / sqrt(df_calc + 1),
                    ymax  = U_min_pos_kV_avg - qt(.975, df_calc) * U_min_pos_kV_sd / sqrt(df_calc + 1)),
                width = 15,
                size  = 0.85,
                alpha = 0.25,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 7000),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(4, 9),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Minimum Positive Voltage (kV)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


#####################
# U_min_neg vs. SEI #
#####################
data %>% ggplot(aes(x = sei,
                    y = U_min_neg_kV_avg,
                    color = material)) +
  geom_point(size = 1.85) +
  geom_line(alpha = .6) +
  geom_errorbar(aes(ymin = U_min_neg_kV_avg + qt(.975, df_calc) * U_min_neg_kV_sd / sqrt(df_calc + 1),
                    ymax = U_min_neg_kV_avg - qt(.975, df_calc) * U_min_neg_kV_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.85,
                alpha = 0.1,
                show.legend = F) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Minimum Negative Voltage (kV)",
       color = "Materials:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))


################
# U_pp vs. SEI #
################
#& grepl("Alpha", material_ab)
#& !grepl("Porous", material_ab) 
data %>% dplyr::filter(pwr_sei == "Power Const." &
                grepl("SiO2", material_ab) &
                supplier == c("UHasselt") &
                !grepl("M Ti", material_ab)) %>%
  ggplot(aes(x = sei,
             y = U_pp_kV_avg,
             color = material_ab)) +
  geom_point(size = 2) +
  geom_line(size = 1.3) +
  geom_errorbar(aes(ymin = U_pp_kV_avg + qt(.975, df_calc) * U_pp_kV_sd / sqrt(df_calc + 1),
                    ymax = U_pp_kV_avg - qt(.975, df_calc) * U_pp_kV_sd / sqrt(df_calc + 1)),
                width = 2,
                size  = 1,
                alpha = 0.1,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 6000),
                     expand = expansion(mult = c(0.0, 0.022))) + 
  scale_y_continuous(limits = c(17.5, 22.5),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Applied Peak-to-Peak Voltage (kV)",
       color = "Materials:",
       #linetype = "Versus Empty Reactor:"
  ) +
  theme_bw(base_size = 18) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 17),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 16.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = F))


###############################
# I_plasma & I_source vs. SEI #
###############################
data %>% dplyr::filter(supplier == "VITO", pwr_sei == "Power Const." & grepl("Al", support_type)) %>%
  select(material,
         sei,
         plasma_rms_current_mA_avg,
         plasma_rms_current_mA_sd,
         source_rms_current_mA_avg,
         source_rms_current_mA_sd,
         df_calc) %>%
  pivot_longer(data     = .,
               cols     = c(plasma_rms_current_mA_avg, source_rms_current_mA_avg),
               names_to = "state",
               values_to = "current_mA_avg") %>%
  pivot_longer(data     = .,
               cols     = c(plasma_rms_current_mA_sd, source_rms_current_mA_sd),
               values_to = "current_mA_sd") %>%
  select(!name) %>%
  mutate(state = str_to_title(str_remove(state, "_rms_current_mA_avg"))) %>%
  unique() %>%
  ggplot(aes(x  = sei,
             y  = current_mA_avg,
             color = material,
             shape = state)) +
  geom_point(size  = 2) +
  geom_line(alpha = .75) +
  geom_errorbar(aes(ymin = current_mA_avg + qt(.975, df_calc) * current_mA_sd / sqrt(df_calc + 1),
                    ymax = current_mA_avg - qt(.975, df_calc) * current_mA_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.75,
                alpha = 0.35) +
  labs(x = "SEI (kJ/mol)",
       y = "Current (mA)",
       color = "Materials:",
       shape = "Current:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        legend.title    = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T),
         shape = guide_legend(reverse = F, ncol = 1, bycol = T))


###############################
# P_plasma & P_source vs. SEI #
###############################
data %>% dplyr::filter(pwr_sei == "Power Const." & grepl("Al", support_type)) %>%
  select(material,
         sei,
         plasma_power_W_avg,
         plasma_power_W_sd,
         source_power_W_avg,
         source_power_W_sd,
         df_calc) %>%
  pivot_longer(data     = .,
               cols     = c(plasma_power_W_avg, source_power_W_avg),
               names_to = "state",
               values_to = "power_W_avg") %>%
  pivot_longer(data     = .,
               cols     = c(plasma_power_W_sd, source_power_W_sd),
               values_to = "power_W_sd") %>%
  select(!name) %>%
  mutate(state = str_to_title(str_remove(state, "_power_W_avg"))) %>%
  unique() %>%
  ggplot(aes(x     = sei,
             y     = power_W_avg,
             color = material,
             shape = state)) +
  geom_point(size  = 2) +
  geom_line(size  = 0.75,
            alpha = 1) +
  geom_errorbar(aes(ymin = power_W_avg + qt(.975, df_calc) * power_W_sd / sqrt(df_calc + 1),
                    ymax = power_W_avg - qt(.975, df_calc) * power_W_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.75,
                alpha = 0.5) +
  labs(x = "SEI (kJ/mol)",
       y = "Power (W)",
       color = "Materials:",
       shape = "Power:") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 13),
        legend.title    = element_text(size = 13),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T),
         shape = guide_legend(reverse = F, ncol = 1, bycol = T))


##################################
# Avg. # of µ-discharges vs. SEI #
##################################
data_avg %>%
  ggplot(aes(x = res_time,
             y = avg_num_µdisch_per_half_cycle_avg,
             color = material)) +
  geom_point(size = 2) +
  geom_line(#aes(linetype = pwr_sei),
            size  = 1.5,
            alpha = 1) +
  geom_errorbar(aes(ymin = avg_num_µdisch_per_half_cycle_avg + qt(.975, df_calc) * avg_num_µdisch_per_half_cycle_sd / sqrt(df_calc + 1),
                    ymax = avg_num_µdisch_per_half_cycle_avg - qt(.975, df_calc) * avg_num_µdisch_per_half_cycle_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.75,
                alpha = 0.15) +
  geom_smooth(method='lm',
              se = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(0, 75),
                     expand = expansion(mult = c(0.05, 0.01))) +
  labs(x = "Residence time (s)",
       y = "Average Number of \n µ-Discharges per Half Lissajous Cycle",
       color = "Materials:",
       linetype = "Versus Empty Reactor") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 15),
        legend.title    = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T),
         shape = guide_legend(reverse = F, ncol = 1, bycol = T))


############################
# Avg. Displaced Q vs. SEI #
############################
data %>% dplyr::filter(pwr_sei == "Power Const." & grepl("Alpha", material_ab) & supplier == c("VITO")) %>%
  ggplot(aes(x = sei,
             y = avg_displ_Q_per_peak_nCperpeak_avg,
             color = material_ab)) +
  geom_point(size = 2) +
  geom_line(#aes(linetype = pwr_sei),
            size = 1.5) +
  geom_errorbar(aes(ymin = avg_displ_Q_per_peak_nCperpeak_avg + qt(.975, df_calc) * avg_displ_Q_per_peak_nCperpeak_sd / sqrt(df_calc + 1),
                    ymax = avg_displ_Q_per_peak_nCperpeak_avg - qt(.975, df_calc) * avg_displ_Q_per_peak_nCperpeak_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.75,
                alpha = 0.085) +
  scale_x_continuous(limits = c(0, 6000),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(6, 11),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x = "SEI (kJ/mol)",
       y = "Average Displaced Charge \n per µ-discharge (nC)",
       color = "Materials:",
       linetype = "Versus Empty Reactor") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        legend.title    = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T),
         shape = guide_legend(reverse = T, ncol = 1, bycol = T))


##################################
# Total Avg. Displaced Q vs. SEI #
##################################
data_avg_res_time %>% dplyr::filter(supplier == c("VITO")) %>%
  ggplot(aes(x = sei,
             y = avg_displ_Q_per_half_cycle_nC_avg,
             color = material)) +
  geom_point(size = 2) +
  geom_line(#aes(linetype = pwr_sei),
            linewidth  = 1.5,
            alpha = 0.85) +
  geom_errorbar(aes(ymin = avg_displ_Q_per_half_cycle_nC_avg + qt(.975, df_calc) * avg_displ_Q_per_half_cycle_nC_sd / sqrt(df_calc + 1),
                    ymax = avg_displ_Q_per_half_cycle_nC_avg - qt(.975, df_calc) * avg_displ_Q_per_half_cycle_nC_sd / sqrt(df_calc + 1)),
                width = 1.5,
                size  = 0.85,
                alpha = 0.15) +
  geom_smooth(method='lm',
              se = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.0))) + 
  scale_y_continuous(limits = c(600, 1000),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x = "Residence time (s)",
       y = "Total Displaced Charge \n per half Lissajous Cycle (nC)",
       color = "Materials:"#,
       #linetype = "Versus Empty Reactor"
       ) +
  theme_bw(base_size = 12) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 12),
        legend.title    = element_text(size = 12),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 11)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T),
         shape = guide_legend(reverse = F, ncol = 1, bycol = T))


########################################
# Reduced Electric Field - E/n vs. SEI #
########################################

# dplyr::filter(supplier == c("VITO") & grepl("Al", material) | grepl("Empty", material)) %>%
# dplyr::filter(supplier == c("UGent") & grepl("SASOL", material) | grepl("Empty", material)) %>%

data_avg %>%
  ggplot(aes(x = res_time,
             y = red_el_field_Td_avg,
             color = material,
            )) +
  geom_point(size = 1.85) +
  geom_line(#aes(linetype = pwr_sei),
            linewidth  = 1.75,
            alpha = 1) +
  geom_errorbar(aes(ymin  = red_el_field_Td_avg + qt(.975, df_calc) * red_el_field_Td_sd / sqrt(df_calc + 1),
                    ymax  = red_el_field_Td_avg - qt(.975, df_calc) * red_el_field_Td_sd / sqrt(df_calc + 1)),
                width = 1.6,
                size  = 0.90,
                alpha = 0.15,
                show.legend = F) +
  geom_smooth(method='lm',
              se = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.01, 0.0))) +
  scale_y_continuous(limits = c(75, 110),
                     expand = expansion(mult = c(0.01, 0.01))) +
  labs(x        = "Residence time (s)",
       y        = "Reduced Electric Field (Td)",
       color    = "Materials:",
       #linetype = "Versus Empty Reactor"
       ) +
  theme_bw(base_size = 12) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 12),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 11)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

###################################
# Relative Permittivity DA vs SEI #
###################################

# Q (C)
# ^
# |     B----------A
# |    /          /
# |   /          /
# |  /          /
# | C----------D
# |-------------> U (V)

data %>%
  dplyr::filter(pwr_sei == "Power Const." & grepl("Al2O3", material_ab) & supplier == c("VITO")) %>%
  group_by(material_ab) %>%
  select(material_ab, res_time, rel_perm_p_DA_avg) %>%
  unique() %>%
  mutate(rel_perm_avg = mean(rel_perm_p_DA_avg),
         rel_perm_sd  = sd(rel_perm_p_DA_avg)) %>%
  add_count(material_ab) %>%
  select(material_ab, rel_perm_avg, rel_perm_sd, n) %>%
  unique() %>%
  ungroup() %>%
  ggplot(aes(x = reorder(material_ab, rel_perm_avg),
             y = rel_perm_avg,
             fill = reorder(material_ab, rel_perm_avg))) +
  geom_col(position = "dodge") +
  geom_errorbar(aes(ymin = rel_perm_avg - (qt(0.975, n) * rel_perm_sd) / sqrt(n + 1),
                    ymax = rel_perm_avg + (qt(0.975, n) * rel_perm_sd) / sqrt(n + 1)),
                position = "dodge") +
  scale_y_continuous(limits = c(0, 10),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x = "Materials",
       y = "Calculated Relative Permittivity") +
  theme_bw(base_size = 16) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  scale_fill_colorblind() +
  theme(legend.position = "none",
        legend.text     = element_text(size = 16),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 15),
        #axis.text.x     = element_text(angle = 0, hjust = 1)
  ) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = T))

data %>%
  dplyr::filter(pwr_sei == "Power Const." & grepl("Al2O3", material_ab) & supplier == c("VITO")) %>%
  ggplot(aes(x = res_time,
             y = rel_perm_p_DA_avg,
             color = material_ab)) +
  geom_point(size = 2) +
  geom_line(#aes(linetype = pwr_sei),
            size  = 1,
            alpha = 1) +
  geom_errorbar(aes(ymin  = rel_perm_p_DA_avg + qt(.975, df_calc) * rel_perm_p_DA_sd / sqrt(df_calc + 1),
                    ymax  = rel_perm_p_DA_avg - qt(.975, df_calc) * rel_perm_p_DA_sd / sqrt(df_calc + 1)),
                width = 2,
                size  = 0.85,
                alpha = 0.5,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 75),
                     expand = expansion(mult = c(0.0, 0.0))) +
  scale_y_continuous(limits = c(0, 12.5),
                     expand = expansion(mult = c(0, 0.0))) +
  labs(x        = "Residence Time (s)",
       y        = "Relative Permitivity of the Packing",
       color    = "Materials:",
       #linetype = "Versus Empty Reactor"
       ) +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 16),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 15)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = F))

###################################
# Relative Permittivity BC vs SEI #
###################################

# Q (C)
# ^
# |     B----------A
# |    /          /
# |   /          /
# |  /          /
# | C----------D
# |-------------> U (V)

data %>% dplyr::filter(supplier == c("UGent")) %>% 
  ggplot(aes(x = sei,
             y = rel_perm_p_BC_avg,
             color = material)) +
  #geom_point(size = 1.85) +
  geom_line(aes(linetype = pwr_sei),
            size  = 1.5,
            alpha = 1) +
  #geom_errorbar(aes(ymin  = rel_perm_p_BC_avg + qt(.975, df_calc) * rel_perm_p_BC_sd / sqrt(df_calc + 1),
  #                  ymax  = rel_perm_p_BC_avg - qt(.975, df_calc) * rel_perm_p_BC_sd / sqrt(df_calc + 1)),
  #              width = 1.5,
  #              size  = 0.85,
  #              alpha = 0.1,
  #              show.legend = F) +
  scale_x_continuous(limits = c(0, 75),
                     expand = expansion(mult = c(0.0, 0.0))) +
  scale_y_continuous(limits = c(5, 30),
                     expand = expansion(mult = c(0.0, 0.0))) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Relative Permitivity of the Packing \n (Based on the BC Slope)",
       color = "Materials:",
       linetype = "Versus Empty Reactor") +
  theme_bw(base_size = 16) +
  scale_colour_colorblind() +
  theme(legend.position = "right",
        legend.text     = element_text(size = 15),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 14.5)) +
  guides(color = guide_legend(reverse = T, ncol = 1, bycol = T))



########################################
# Effective reactor capacitance (nC/V) #
########################################
data %>% dplyr::filter(pwr_sei == "Power Const." & grepl("SiO2", material_ab) & supplier == c("UHasselt") & !grepl("M Ti", material_ab)) %>%
  group_by(material_ab, res_time) %>%
  mutate(slope_DA_nCperV_mean = mean(slope_DA_nCperV, na.rm = T),
         slope_DA_nCperV_sd   = sd(slope_DA_nCperV, na.rm = T)) %>%
  ungroup() %>%
  ggplot(aes(x = sei,
             y = slope_DA_nCperV_mean,
             color = material_ab)) +
  geom_point(size = 2) +
  geom_line(size = 1.3) +
  geom_errorbar(aes(ymin = slope_DA_nCperV_mean + qt(.975, df_calc) * slope_DA_nCperV_sd / sqrt(df_calc + 1),
                    ymax = slope_DA_nCperV_mean - qt(.975, df_calc) * slope_DA_nCperV_sd / sqrt(df_calc + 1)),
                width = 2,
                size  = 1,
                alpha = 0.1,
                show.legend = F) +
  scale_x_continuous(limits = c(0, 6000),
                     expand = expansion(mult = c(0.0, 0.022))) + 
  scale_y_continuous(limits = c(0.10, .2),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "SEI (kJ/mol)",
       y     = "Effective reactor capacitance (nC/V)",
       color = "Materials:",
       #linetype = "Versus Empty Reactor:"
  ) +
  theme_bw(base_size = 18) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 17),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 16.5)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = F))


#########
# Alpha #
#########
dplyr::filter(pwr_sei == "Power Const." & grepl("SiO2", material_ab) & supplier == c("UHasselt") & !grepl("M Ti", material_ab))

data_avg %>% group_by(material, res_time) %>%
  ggplot(aes(x = res_time,
             y = alpha_avg,
             color = material)) +
  geom_point(size = 2) +
  geom_line(linewidth = 1.3) +
  geom_errorbar(aes(ymin = alpha_avg + qt(.975, df_calc) * alpha_sd / sqrt(df_calc + 1),
                    ymax = alpha_avg - qt(.975, df_calc) * alpha_sd / sqrt(df_calc + 1)),
                width = 2,
                size  = 1,
                alpha = 0.15,
                show.legend = F) +
  geom_smooth(method='lm',
              se = F) +
  scale_x_continuous(limits = c(0, 85),
                     expand = expansion(mult = c(0.0, 0.022))) + 
  scale_y_continuous(limits = c(.25, .6),
                     expand = expansion(mult = c(0.0, 0.01))) +
  labs(x     = "Residence time (s)",
       y     = "Alpha",
       color = "Materials:",
       #linetype = "Versus Empty Reactor:"
  ) +
  theme_bw(base_size = 12) +
  scale_colour_colorblind() +
  theme(legend.position = "bottom",
        legend.text     = element_text(size = 12),
        text            = element_text(family = "Calibri"),
        axis.text       = element_text(size = 11)) +
  guides(color = guide_legend(reverse = F, ncol = 1, bycol = F))
