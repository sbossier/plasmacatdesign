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

########
# ag2o #
########

# Read in starting data
ag2o_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0002_01_01.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ag2o_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_01_lissajous.csv")

ag2o_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0012_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ag2o_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_02_lissajous.csv")

ag2o_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/20230125-0023_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ag2o_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_03_lissajous.csv")

bind_rows(ag2o_01_01, ag2o_01_02, ag2o_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ag2o-10%/lissajous/ag2o_01_lissajous_combine.csv")

ag2o_plot_01 <- ag2o_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

ag2o_plot_02 <- ag2o_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ag2o_plot_03 <- ag2o_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
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
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "bi2o3_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_01_lissajous.csv")

bi2o3_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/20230127-0005_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "bi2o3_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_02_lissajous.csv")

bi2o3_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/20230127-0008_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "bi2o3_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_03_lissajous.csv")

bind_rows(bi2o3_01_01, bi2o3_01_02, bi2o3_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-bi2o3-10%/lissajous/bi2o3_01_lissajous_combine.csv")

bi2o3_plot_01 <- bi2o3_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

bi2o3_plot_02 <- bi2o3_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

bi2o3_plot_03 <- bi2o3_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

bi2o3_plot_comb <- grid.arrange(bi2o3_plot_01, bi2o3_plot_02, bi2o3_plot_03, nrow = 1, top = "SASOL 1.8@Bi2O3 10%")

########
# c450 #
########

# Read in starting data
c450_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0005_01_01.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "c450_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_01_lissajous.csv")

c450_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0009_01-02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "c450_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_02_lissajous.csv")

c450_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/20230119-0024_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "c450_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_03_lissajous.csv")

bind_rows(c450_01_01, c450_01_02, c450_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-c450/lissajous/c450_01_lissajous_combine.csv")

c450_plot_01 <- c450_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

c450_plot_02 <- c450_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

c450_plot_03 <- c450_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

c450_plot_comb <- grid.arrange(c450_plot_01, c450_plot_02, c450_plot_03, nrow = 1, top = "SASOL 1.8@C450")

########
# ceo2 #
########

# Read in starting data
ceo2_01_01 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0002_01_01.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ceo2_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_01_lissajous.csv")

ceo2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0004_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ceo2_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_02_lissajous.csv")

ceo2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/20230126-0006_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "ceo2_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_03_lissajous.csv")

bind_rows(ceo2_01_01, ceo2_01_02, ceo2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-ceo2-10%/lissajous/ceo2_01_lissajous_combine.csv")

ceo2_plot_01 <- ceo2_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

ceo2_plot_02 <- ceo2_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

ceo2_plot_03 <- ceo2_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
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
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_01_lissajous.csv")

cuo_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/20230201-0008_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_02_lissajous.csv")

cuo_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/20230201-0004_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_03_lissajous.csv")

bind_rows(cuo_01_01, cuo_01_02, cuo_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-10%/lissajous/cuo_01_lissajous_combine.csv")

cuo_plot_01 <- cuo_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

cuo_plot_02 <- cuo_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_plot_03 <- cuo_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
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
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo-fe2o3_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_01_lissajous.csv")

cuo_fe2o3_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/20230202-0005_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo-fe2o3_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_02_lissajous.csv")

cuo_fe2o3_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/20230202-0008_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "cuo-fe2o3_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_03_lissajous.csv")

bind_rows(cuo_fe2o3_01_01, cuo_fe2o3_01_02, cuo_fe2o3_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-cuo-fe2o3-05-05%/lissajous/cuo-fe2o3_01_lissajous_combine.csv")

cuo_fe2o3_plot_01 <- cuo_fe2o3_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

cuo_fe2o3_plot_02 <- cuo_fe2o3_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

cuo_fe2o3_plot_03 <- cuo_fe2o3_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
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
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "mno2_01_01",
            charge_nC = charge_µC,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_01_lissajous.csv")

mno2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/20230120-0009_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "mno2_01_02",
            charge_nC = charge_µC,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_02_lissajous.csv")

mno2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/20230120-0023_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "mno2_01_03",
            charge_nC = charge_µC,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_03_lissajous.csv")

bind_rows(mno2_01_01, mno2_01_02, mno2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-mno2-10%/lissajous/mno2_01_lissajous_combine.csv")

mno2_plot_01 <- mno2_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

mno2_plot_02 <- mno2_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

mno2_plot_03 <- mno2_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
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
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "sno2_01_01",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_01_lissajous.csv")

sno2_01_02 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/20230124-0004_01_02.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "sno2_01_02",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_02_lissajous.csv")

sno2_01_03 <-
  read_table("N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/20230124-0010_01_03.txt") %>%
  select(time_ms, charge_µC, voltage_kV) %>%
  slice_sample(n = nrow(.) * 0.004) %>%
  arrange(time_ms) %>%
  transmute(material = "sno2_01_03",
            charge_nC = charge_µC * 1000,
            voltage_kV = voltage_kV) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_03_lissajous.csv")

bind_rows(sno2_01_01, sno2_01_02, sno2_01_03) %>%
  write_csv(., "N:/FWET/FDCH/AdsCatal/General/Personal work folders/vermile-valeria/t-rex/sasol-1.8-sno2-10%/lissajous/sno2_01_lissajous_combine.csv")

sno2_plot_01 <- sno2_01_01 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = "Displaced charge (µC)") +
  theme_hc()

sno2_plot_02 <- sno2_01_02 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

sno2_plot_03 <- sno2_01_03 %>%
  ggplot(aes(x = voltage_kV,
             y = charge_nC)) +
  geom_path(size = .75) +
  scale_x_continuous(limits = c(-10, 10),
                     expand = expansion(mult = c(0.01, 0.01)),
                     name   = "Applied voltage (kV)") + 
  scale_y_continuous(limits = c(-500, 500),
                     expand = expansion(mult = c(0.0, 0.01)),
                     name   = NULL) +
  theme_hc()

sno2_plot_comb <- grid.arrange(sno2_plot_01, sno2_plot_02, sno2_plot_03, nrow = 1, top = "SASOL 1.8@sno2 10%")