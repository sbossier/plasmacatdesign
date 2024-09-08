# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)
library(ggrepel)
library(ggthemes)
library(gridExtra)
library(Rttf2pt1)
library(extrafontdb)
library(extrafont)

# Load in fonts
loadfonts(device = "win")

# Clear workspace
rm(list=ls())
gc()

############
# variable #
############

# Read in starting data
var <-
  read_csv("C:/Users/sbossier/Desktop/lissajous/20230419-0007.csv",
             col_names = c(
               "time_ms",
               "charge_µC",
               "voltage_kV",
               "current_plasma_A",
               "current_source_mA",
               "power_plasma_kW",
               "power_source_kW"
             ),
             skip = 2) %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0, 2)) %>%
  transmute(material = "var",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000)

# Assuming 'var' is your data frame
n <- 30  # Choose the value of n, e.g., 10 for every 10th row
var_selected <- var[seq(1, nrow(var), by = n), ]
i <- 4
var_plot <- ggplot(data = var_selected, aes(x = time_ms, y = current_plasma_mA)) +
  geom_line(linewidth = 0.5) +
  scale_x_continuous(limits = c(0.280 + i * (1/3), 0.280 + (i+0.5) * (1/3)),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (ms)") + 
  scale_y_continuous(limits = c(-5, 50),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()
var_plot

########
# ag2o #
########

# Read in starting data
ag2o_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0002_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ag2o_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_01_reduced.csv")

ag2o_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0012_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ag2o_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_02_reduced.csv")

ag2o_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0023_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ag2o_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_03_reduced.csv")

bind_rows(ag2o_01_01, ag2o_01_02, ag2o_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_reduced_combine.csv")

ag2o_plot_01 <- ag2o_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

ag2o_plot_02 <- ag2o_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ag2o_plot_03 <- ag2o_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ag2o_plot_comb <- grid.arrange(ag2o_plot_01, ag2o_plot_02, ag2o_plot_03, nrow = 1, top = "SASOL 1.8@Ag2O 10%")

#########
# bi2o3 #
#########

# Read in starting data
bi2o3_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/20230127-0003-01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "bi2o3_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_01_reduced.csv")

bi2o3_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/20230127-0005_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "bi2o3_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_02_reduced.csv")

bi2o3_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/20230127-0008_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "bi2o3_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_03_reduced.csv")

bind_rows(bi2o3_01_01, bi2o3_01_02, bi2o3_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_reduced_combine.csv")

bi2o3_plot_01 <- bi2o3_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

bi2o3_plot_02 <- bi2o3_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

bi2o3_plot_03 <- bi2o3_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

bi2o3_plot_comb <- grid.arrange(bi2o3_plot_01, bi2o3_plot_02, bi2o3_plot_03, nrow = 1, top = "SASOL 1.8@Bi2O3 10%")

########
# ceo2 #
########

# Read in starting data
ceo2_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0002_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ceo2_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_01_reduced.csv")

ceo2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0004_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ceo2_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_02_reduced.csv")

ceo2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0006_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "ceo2_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_03_reduced.csv")

bind_rows(ceo2_01_01, ceo2_01_02, ceo2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_reduced_combine.csv")

ceo2_plot_01 <- ceo2_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

ceo2_plot_02 <- ceo2_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ceo2_plot_03 <- ceo2_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ceo2_plot_comb <- grid.arrange(ceo2_plot_01, ceo2_plot_02, ceo2_plot_03, nrow = 1, top = "SASOL 1.8@CeO2 10%")

#######
# cuo #
#######

# Read in starting data
cuo_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/20230201-0003_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_01_reduced.csv")

cuo_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/20230201-0008_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_02_reduced.csv")

cuo_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/20230201-0004_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_03_reduced.csv")

bind_rows(cuo_01_01, cuo_01_02, cuo_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_reduced_combine.csv")

cuo_plot_01 <- cuo_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

cuo_plot_02 <- cuo_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_plot_03 <- cuo_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_plot_comb <- grid.arrange(cuo_plot_01, cuo_plot_02, cuo_plot_03, nrow = 1, top = "SASOL 1.8@CuO 10%")

#############
# cuo-fe2o3 #
#############

# Read in starting data
cuo_fe2o3_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/20230202-0001_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo-fe2o3_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_01_reduced.csv")

cuo_fe2o3_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/20230202-0005_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo-fe2o3_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_02_reduced.csv")

cuo_fe2o3_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/20230202-0008_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "cuo-fe2o3_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A * 1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_03_reduced.csv")

bind_rows(cuo_fe2o3_01_01, cuo_fe2o3_01_02, cuo_fe2o3_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_reduced_combine.csv")

cuo_fe2o3_plot_01 <- cuo_fe2o3_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

cuo_fe2o3_plot_02 <- cuo_fe2o3_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_fe2o3_plot_03 <- cuo_fe2o3_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_fe2o3_plot_comb <- grid.arrange(cuo_fe2o3_plot_01, cuo_fe2o3_plot_02, cuo_fe2o3_plot_03, nrow = 1, top = "SASOL 1.8@CuO-Fe2O3 05-05%")

########
# mno2 #
########

# Read in starting data
mno2_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/20230120-0004_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "mno2_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_01_reduced.csv")

mno2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/20230120-0009_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "mno2_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_02_reduced.csv")

mno2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/20230120-0023_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "mno2_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_03_reduced.csv")

bind_rows(mno2_01_01, mno2_01_02, mno2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_reduced_combine.csv")

mno2_plot_01 <- mno2_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

mno2_plot_02 <- mno2_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

mno2_plot_03 <- mno2_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

mno2_plot_comb <- grid.arrange(mno2_plot_01, mno2_plot_02, mno2_plot_03, nrow = 1, top = "SASOL 1.8@MnO2 10%")

########
# sno2 #
########

# Read in starting data
sno2_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/20230124-0010_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "sno2_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_01_reduced.csv")

sno2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/20230124-0004_01_02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "sno2_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_02_reduced.csv")

sno2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/20230124-0010_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "sno2_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_03_reduced.csv")

bind_rows(sno2_01_01, sno2_01_02, sno2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_reduced_combine.csv")

sno2_plot_01 <- sno2_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

sno2_plot_02 <- sno2_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

sno2_plot_03 <- sno2_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

sno2_plot_comb <- grid.arrange(sno2_plot_01, sno2_plot_02, sno2_plot_03, nrow = 1, top = "SASOL 1.8@SnO2 10%")

########
# c450 #
########

# Read in starting data
c450_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0005_01_01.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "c450_01_01",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_01_reduced.csv")

c450_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0009_01-02.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "c450_01_02",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_02_reduced.csv")

c450_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0024_01_03.txt") %>%
  select(time_ms, current_plasma_A) %>%
  dplyr::filter(between(time_ms, 0.3, 0.466)) %>%
  transmute(material = "c450_01_03",
            time_ms  =  time_ms,
            current_plasma_mA = current_plasma_A*1000) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_03_reduced.csv")

bind_rows(c450_01_01, c450_01_02, c450_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_reduced_combine.csv")

c450_plot_01 <- c450_01_01 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Plasma current (mA)") +
  theme_hc()

c450_plot_02 <- c450_01_02 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

c450_plot_03 <- c450_01_03 %>%
  ggplot(aes(x = time_ms*1000,
             y = current_plasma_mA)) +
  geom_line(linewidth = .5) +
  scale_x_continuous(limits = c(300, 466),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Time (µs)") + 
  scale_y_continuous(limits = c(-10, 200),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

c450_plot_comb <- grid.arrange(c450_plot_01, c450_plot_02, c450_plot_03, nrow = 1, top = "SASOL 1.8 C450")