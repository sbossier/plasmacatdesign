rm(list=ls())
gc()

library(parallel)

process_file <- function(filename) {
  tryCatch(
    {
    data <- read_csv(filename, na = c("NA", "na", "Na", "nA", "N A", "N/A", "N a", "n A", "n a", ""))
    
    ##################################################################
    # Calculate average concentration, standard deviation,           #
    # and relative standard deviation for each compound in each test #
    ##################################################################
    
    # na.rm = T is added to ignore NA's
    data <- data %>%
      group_by(state, compound) %>%
      mutate(conc_avg = mean(conc, na.rm = T),
             conc_sd  = sd(conc, na.rm = T),
             conc_rsd = conc_sd / conc_avg,
             .after = conc) %>%
      ungroup()
    
    #################################################
    # Calculate CO2 conversion using Snoeckx method #
    #################################################
    
    # X_CO2 = X_GC / ( ( 1 + gamma / 2 ) - ( gamma / 2 ) * X_GC )
    # with gamma = ( co2flow ) / ( n2flow + co2flow )
    # and X_GC = 1 - c_GC,plasma / c_GC,blank
    
    # Calculate gamma
    
    flow_co2 <- data %>%
      filter(compound == "CO2") %>%
      pull(flow_mlmin) %>%
      unique()
    
    flow_n2 <- data %>%
      filter(compound == "N2") %>%
      pull(flow_mlmin) %>%
      unique() %>%
      ifelse(is.na(.), 0, .)
    
    gamma     <- flow_co2 / (flow_co2 + flow_n2)
    gamma_sd  <- 0
    gamma_rsd <- 0
    
    beta     <- flow_n2 / flow_co2
    beta_sd  <- 0
    beta_rsd <- 0
    
    data <- mutate(data,
                   conc_avg_corr     = ifelse(compound != "N2", conc_avg * (1 + beta), NA),
                   conc_avg_corr_sd  = ifelse(compound != "N2", conc_sd * (1 + beta), NA),
                   conc_avg_corr_rsd = ifelse(compound != "N2", conc_rsd, NA),
                   .after            = conc_rsd)
    
    # Acquire all relevant CO2 concentration values
    
    conc_avg_co2_blank <- data %>%
      filter(state == "blank" & compound == "CO2") %>%
      pull(conc_avg) %>%
      unique()
    
    conc_sd_co2_blank <- data %>%
      filter(state == "blank" & compound == "CO2") %>%
      pull(conc_sd) %>%
      unique()
    
    conc_rsd_co2_blank <- data %>%
      filter(state == "blank" & compound == "CO2") %>%
      pull(conc_rsd) %>%
      unique()
    
    conc_avg_co2_plasma <- data %>%
      filter(state == "plasma" & compound == "CO2") %>%
      pull(conc_avg) %>%
      unique()
    
    conc_sd_co2_plasma <- data %>%
      filter(state == "plasma" & compound == "CO2") %>%
      pull(conc_sd) %>%
      unique()
    
    conc_rsd_co2_plasma <- data %>%
      filter(state == "plasma" & compound == "CO2") %>%
      pull(conc_rsd) %>%
      unique()
    
    # Calculation of incorrect conversion simply based on GC results
    
    conv_co2_gc <- 1 - (conc_avg_co2_plasma / conc_avg_co2_blank)
    
    conv_co2_gc_rsd <- sqrt(conc_rsd_co2_blank ^ 2 + conc_rsd_co2_plasma ^ 2)
    
    conv_co2_gc_sd <- conv_co2_gc_rsd * conv_co2_gc
    
    # Calculation of the CO2 conversion according to the method by Snoeckx
    
    conv_co2 <- conv_co2_gc / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)
    
    conv_co2_rsd <- sqrt(
      conv_co2_gc_rsd ^ 2 +
        ((conv_co2_gc_rsd * (gamma / 2) * conv_co2_gc) / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)) ^ 2
    )
    
    conv_co2_sd <- conv_co2_rsd * conv_co2
    
    # delta can be calculated from this and performs the same role of alpha in the general method
    
    delta <- 1 + conv_co2 / 2
    
    delta_sd <- 0
    
    delta_rsd <- 0
    
    # Add data to framework
    
    data <- mutate(data,
                   conv     = ifelse(state == "plasma" & compound == "CO2", conv_co2, NA),
                   conv_sd  = ifelse(state == "plasma" & compound == "CO2", conv_co2_sd, NA),
                   conv_rsd = ifelse(state == "plasma" & compound == "CO2", conv_co2_rsd, NA),
                   delta    = delta,
                   .after = conc_avg_corr_rsd)
    
    ###################
    # Carbon Monoxide #
    ###################
    
    # Carbon selectivity #
    ######################
    
    conc_avg_co_plasma <- data %>%
      filter(state == "plasma" & compound == "CO") %>%
      pull(conc_avg) %>%
      unique()
    
    conc_sd_co_plasma <- data %>%
      filter(state == "plasma" & compound == "CO") %>%
      pull(conc_sd) %>%
      unique()
    
    conc_rsd_co_plasma <- data %>%
      filter(state == "plasma" & compound == "CO") %>%
      pull(conc_rsd) %>%
      unique()
    
    selec_c_co <- (delta * conc_avg_co_plasma) / (conc_avg_co2_blank - delta * conc_avg_co2_plasma)
    
    selec_c_co_rsd <- sqrt(
      conc_rsd_co_plasma ^ 2
      +
        (conc_sd_co2_blank^2 + delta ^ 2 * conc_sd_co2_plasma ^ 2)/(conc_avg_co2_blank - delta * conc_avg_co2_plasma)^2
    )
    
    selec_c_co_sd <- selec_c_co_rsd * selec_c_co
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "CO" & state == "plasma", selec_c_co, NA),
                   selec_c_sd  = ifelse(compound == "CO" & state == "plasma", selec_c_co_sd, NA),
                   selec_c_rsd = ifelse(compound == "CO" & state == "plasma", selec_c_co_rsd, NA),
                   .after = conv_rsd)
    
    # Carbon yield #
    ################
    
    yield_c_co <- selec_c_co * conv_co2
    
    yield_c_co_rsd <- sqrt(selec_c_co_rsd ^ 2 + conv_co2_rsd ^ 2)
    
    yield_c_co_sd <- yield_c_co_rsd * yield_c_co
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "CO" & state == "plasma", yield_c_co, NA),
                   yield_c_sd  = ifelse(compound == "CO" & state == "plasma", yield_c_co_sd, NA),
                   yield_c_rsd = ifelse(compound == "CO" & state == "plasma", yield_c_co_rsd, NA),
                   .after = selec_c_rsd)
    
    # Oxygen selectivity #
    ######################
    
    selec_o_co <- (delta * conc_avg_co_plasma) / (2 * (conc_avg_co2_blank - delta * conc_avg_co2_plasma))
    
    selec_o_co_rsd <- sqrt(
      conc_rsd_co_plasma ^ 2
      +
        (conc_sd_co2_blank^2 + delta ^ 2 * conc_sd_co2_plasma ^ 2)/(conc_avg_co2_blank - delta * conc_avg_co2_plasma)^2
    )
    
    selec_o_co_sd <- selec_o_co_rsd * selec_o_co
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "CO" & state == "plasma", selec_o_co, NA),
                   selec_o_sd  = ifelse(compound == "CO" & state == "plasma", selec_o_co_sd, NA),
                   selec_o_rsd = ifelse(compound == "CO" & state == "plasma", selec_o_co_rsd, NA),
                   .after = yield_c_rsd)
    
    # Oxygen yield #
    ################
    
    yield_o_co <- selec_o_co * conv_co2
    
    yield_o_co_rsd <- sqrt(selec_o_co_rsd ^ 2 + conv_co2_rsd ^ 2)
    
    yield_o_co_sd <- yield_o_co_rsd * yield_o_co
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "CO" & state == "plasma", yield_o_co, NA),
                   yield_o_sd  = ifelse(compound == "CO" & state == "plasma", yield_o_co_sd, NA),
                   yield_o_rsd = ifelse(compound == "CO" & state == "plasma", yield_o_co_rsd, NA),
                   .after = selec_o_rsd)
    
    ##########
    # Oxygen #
    ##########
    
    # Oxygen selectivity #
    ######################
    
    conc_avg_o2_plasma <- data %>%
      filter(state == "plasma" & compound == "O2") %>%
      pull(conc_avg) %>%
      unique()
    
    conc_sd_o2_plasma <- data %>%
      filter(state == "plasma" & compound == "O2") %>%
      pull(conc_sd) %>%
      unique()
    
    conc_rsd_o2_plasma <- data %>%
      filter(state == "plasma" & compound == "O2") %>%
      pull(conc_rsd) %>%
      unique()
    
    selec_o_o2 <- (delta * conc_avg_o2_plasma) / (conc_avg_co2_blank - delta * conc_avg_co2_plasma)
    
    selec_o_o2_rsd <- sqrt(
      conc_rsd_o2_plasma ^ 2
      +
        (conc_sd_co2_blank^2 + delta ^ 2 * conc_sd_co2_plasma ^ 2)/(conc_avg_co2_blank - delta * conc_avg_co2_plasma)^2
    )
    
    selec_o_o2_sd <- selec_o_co_rsd * selec_o_co
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "O2" & state == "plasma", selec_o_co, selec_o),
                   selec_o_sd  = ifelse(compound == "O2" & state == "plasma", selec_o_co_sd, selec_o_sd),
                   selec_o_rsd = ifelse(compound == "O2" & state == "plasma", selec_o_co_rsd, selec_o_rsd))
    
    # Oxygen yield #
    ################
    
    yield_o_o2 <- selec_o_o2 * conv_co2
    
    yield_o_o2_rsd <- sqrt(selec_o_o2_rsd ^ 2 + conv_co2_rsd ^ 2)
    
    yield_o_o2_sd <- yield_o_o2_rsd * yield_o_o2
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "O2" & state == "plasma", yield_o_o2, yield_o),
                   yield_o_sd  = ifelse(compound == "O2" & state == "plasma", yield_o_o2_sd, yield_o_sd),
                   yield_o_rsd = ifelse(compound == "O2" & state == "plasma", yield_o_o2_rsd, yield_o_rsd))
    
    
    ###############
    # Yield Ratio #
    ###############
    
    yield_ratio <- yield_c_co / yield_o_o2
    
    yield_ratio_rsd <- sqrt(yield_c_co_rsd^2 + yield_o_o2_rsd^2)
    
    yield_ratio_sd <- yield_ratio_rsd * yield_ratio
    
    data <- mutate(data,
                   yield_ratio     = yield_ratio,
                   yield_ratio_sd  = yield_ratio_sd,
                   yield_ratio_rsd = yield_ratio_rsd,
                   .after = yield_o_rsd)
    
    ##################
    # Carbon Balance #
    ##################
    
    balance_c <- (delta * (conc_avg_co_plasma + conc_avg_co2_plasma))/conc_avg_co2_blank
    
    balance_c_rsd <- sqrt(
      (conc_sd_co_plasma ^ 2 + conc_sd_co2_plasma ^ 2) / (conc_avg_co_plasma + conc_avg_co2_plasma) ^ 2
      +
        conc_rsd_co2_blank ^ 2
    )
    
    balance_c_sd <- balance_c_rsd * balance_c
    
    data <- mutate(data,
                   balance_c     = balance_c,
                   balance_c_sd  = balance_c_sd,
                   balance_c_rsd = balance_c_rsd,
                   .after = yield_ratio_rsd)
    
    ##################
    # Oxygen Balance #
    ##################
    
    balance_o <- (delta * (conc_avg_o2_plasma + conc_avg_co2_plasma))/conc_avg_co2_blank
    
    balance_o_rsd <- sqrt(
      (conc_sd_o2_plasma ^ 2 + conc_sd_co2_plasma ^ 2) / (conc_avg_o2_plasma + conc_avg_co2_plasma) ^ 2
      +
        conc_rsd_co2_blank ^ 2
    )
    
    balance_o_sd <- balance_o_rsd * balance_o
    
    data <- mutate(data,
                   balance_o     = balance_o,
                   balance_o_sd  = balance_o_sd,
                   balance_o_rsd = balance_o_rsd,
                   .after = balance_c_rsd)
    
    ###############################
    # Specific Energy Input (SEI) #
    ###############################
    
    # Calculation the average plasma power, its SD and its RSD
    
    data <- data %>%
      group_by(state, compound) %>%
      mutate(plasma_power_watt_avg = ifelse(state == "blank", NA, mean(plasma_power_watt, na.rm = T)),
             plasma_power_watt_sd  = ifelse(state == "blank", NA, sd(plasma_power_watt, na.rm = T)),
             plasma_power_rsd      = ifelse(state == "blank", NA, plasma_power_watt_sd / plasma_power_watt_avg),
             source_power_watt_avg = ifelse(state == "blank", NA, mean(source_power_watt, na.rm = T)),
             source_power_watt_sd  = ifelse(state == "blank", NA, sd(source_power_watt, na.rm = T)),
             source_power_rsd      = ifelse(state == "blank", NA, source_power_watt_sd / source_power_watt_avg),
             .after = source_power_watt) %>%
      ungroup()
    
    # Take average power level, SD and RSD
    
    plasma_power_avg <- data %>%
      filter(state == "plasma") %>%
      pull(plasma_power_watt_avg) %>%
      unique()
    
    plasma_power_sd <- data %>%
      filter(state == "plasma") %>%
      pull(plasma_power_watt_sd) %>%
      unique()
    
    plasma_power_rsd <- data %>%
      filter(state == "plasma") %>%
      pull(plasma_power_rsd) %>%
      unique()
    
    # CO2 flow in to calculate SEI
    
    # Note 1: 0.005 is the reading accuracy of the F-201CV MFCs & 0.001 is the full scale value of the F-201CV MFCs (you can find these values on the product page of the MFCs of your choice),
    #         all flow (so +/- 100% of flow values according to normal distribution) fall between the sumation for these two errors.
    
    # Note 2: 3.890592 is the z-value for which 99.99% of values fall within a normal curve.
    
    data <- mutate(data,
                   flow_mlmin_sd  = (.005 * flow_mlmin + .001 * flow_max_mlmin) / qnorm(.99995),
                   flow_rsd = flow_mlmin_sd / flow_mlmin,
                   .after = flow_max_mlmin)
    
    flow_co2_sd <- data %>%
      filter(compound == "CO2") %>%
      pull(flow_mlmin_sd) %>%
      unique()
    
    flow_co2_rsd <- data %>%
      filter(compound == "CO2") %>%
      pull(flow_rsd) %>%
      unique()
    
    # Calculate SEI (J/mmol same as kJ/mol) (molar gas volume at 1 atm & 20°C)
    
    sei <- (plasma_power_avg / flow_co2) * 60 * 24.055
    
    # Calculate SEI RSD
    
    sei_rsd <- sqrt(plasma_power_rsd ^ 2 + flow_co2_rsd ^ 2)
    
    # Calculate SEI SD
    
    sei_sd <- sei_rsd * sei
    
    # Adding values to the data
    
    data <- mutate(data,
                   sei_kjmol    = ifelse(state == "plasma", sei, NA),
                   sei_kjmol_sd = ifelse(state == "plasma", sei_sd, NA),
                   sei_rsd      = ifelse(state == "plasma", sei_rsd, NA),
                   .after = plasma_power_rsd)
    
    ######################################
    # Energy efficiency Snoeckx's method #
    ######################################
    
    gas_temp_in_avg_dgc  <- data %>% filter(state == "plasma", compound == "CO2") %>%
      pull(gas_temp_in_dgc) %>% mean(na.rm = T)
    gas_temp_in_sd_dgc   <- data %>% filter(state == "plasma", compound == "CO2") %>%
      pull(gas_temp_in_dgc) %>% sd(na.rm = T)
    gas_temp_in_rsd      <- gas_temp_in_sd_dgc / gas_temp_in_avg_dgc
    
    gas_temp_out_avg_dgc <- data %>% filter(state == "plasma", compound == "CO2") %>%
      pull(gas_temp_out_dgc) %>% mean(na.rm = T)
    gas_temp_out_sd_dgc  <- data %>% filter(state == "plasma", compound == "CO2") %>%
      pull(gas_temp_out_dgc) %>% sd(na.rm = T)
    gas_temp_out_rsd     <- gas_temp_out_sd_dgc / gas_temp_out_avg_dgc
    
    gas_temp_avg_dgc     <- mean(c(gas_temp_in_avg_dgc, gas_temp_out_avg_dgc))
    gas_temp_rsd         <- sqrt(gas_temp_in_rsd^2 + gas_temp_out_rsd^2)/2
    gas_temp_sd_dgc      <- gas_temp_rsd * gas_temp_avg_dgc
    
    gas_temp_kelv        <- 273.15 + gas_temp_avg_dgc
    
    # Gibbs Free Enthalpy of Formation of CO in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)
    
    gf_co <- -1.48747E-20*(gas_temp_kelv ^ 6) + 2.90543E-16* (gas_temp_kelv ^ 5) - 2.18412E-12 * (gas_temp_kelv ^ 4) + 7.80039E-09 * (gas_temp_kelv ^ 3) - 1.14364E-05 * (gas_temp_kelv ^ 2) - 8.19286E-02 * gas_temp_kelv - 1.12455E+02
    
    # Gibbs Free Enthalpy of Formation of CO2 in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)
    
    gf_co2 <- 1.21850E-21* (gas_temp_kelv ^ 6) - 2.63973E-17 * (gas_temp_kelv ^ 5) + 2.25893E-13 * (gas_temp_kelv ^ 4) - 9.56091E-10 * (gas_temp_kelv ^ 3) + 2.75906E-06 * (gas_temp_kelv ^ 2) - 4.68102E-03 * gas_temp_kelv - 3.93205E+02
    
    # Energy efficiency calculations
    
    ee_gf_perc <- ((gf_co - gf_co2) * conv_co2) / sei * 100
    
    ee_gf_rsd <- sqrt(conv_co2_rsd ^ 2 + sei_rsd ^ 2)
    
    ee_gf_perc_sd <- ee_gf_rsd * ee_gf_perc
    
    data <- mutate(data,
                   gas_temp_in_avg_dgc  = ifelse(state == "plasma", gas_temp_in_avg_dgc, NA),
                   gas_temp_in_sd_dgc   = ifelse(state == "plasma", gas_temp_in_sd_dgc, NA),
                   gas_temp_in_rsd      = ifelse(state == "plasma", gas_temp_in_rsd, NA),
                   gas_temp_out_avg_dgc = ifelse(state == "plasma", gas_temp_out_avg_dgc, NA),
                   gas_temp_out_sd_dgc  = ifelse(state == "plasma", gas_temp_out_sd_dgc, NA),
                   gas_temp_out_rsd     = ifelse(state == "plasma", gas_temp_out_rsd, NA),
                   gas_temp_avg_dgc     = gas_temp_avg_dgc,
                   gas_temp_sd_dgc      = gas_temp_sd_dgc,
                   gas_temp_rsd         = gas_temp_rsd,
                   ee_gf_perc           = ifelse(state == "plasma", ee_gf_perc, NA),
                   ee_gf_perc_sd        = ifelse(state == "plasma", ee_gf_perc_sd, NA),
                   ee_gf_rsd            = ifelse(state == "plasma", ee_gf_rsd, NA),
                   .after = sei_kjmol)
    # Energy efficiency (%) based on the Lower Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry
    
    ee_lhv_perc <- (conv_co2 * 289.5) / sei * 100
    
    ee_lhv_rsd <- sqrt(sei_rsd ^ 2 + (conv_co2_rsd ^ 2))
    
    ee_lhv_perc_sd <- ee_lhv_rsd * ee_lhv_perc
    
    data <- mutate(data,
                   ee_lhv_perc    = ifelse(state == "plasma", ee_lhv_perc, NA),
                   ee_lhv_perc_sd = ifelse(state == "plasma", ee_lhv_perc_sd, NA),
                   ee_lhv_rsd     = ifelse(state == "plasma", ee_lhv_rsd, NA),
                   .after = ee_gf_rsd)
    
    # Energy efficiency (%) based on the Higher Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry
    # LHV and HHV values for CO are the same
    
    ee_hhv_perc <- (conv_co2 * 289.5) / sei * 100
    
    ee_hhv_rsd <- sqrt(sei_rsd ^ 2 + (conv_co2_rsd ^ 2))
    
    ee_hhv_perc_sd <- ee_hhv_rsd * ee_hhv_perc
    
    data <- mutate(data,
                   ee_hhv_perc    = ifelse(state == "plasma", ee_hhv_perc, NA),
                   ee_hhv_perc_sd = ifelse(state == "plasma", ee_hhv_perc_sd, NA),
                   ee_hhv_rsd     = ifelse(state == "plasma", ee_hhv_rsd, NA),
                   .after = ee_lhv_rsd)
    
    ############################################
    # Write the calculated data to a .csv file #
    ############################################
    
    write_csv(data, gsub(".csv", "-calc.csv", filename))
    data_short <- data %>%
      filter(state == "plasma") %>%
      select(packing,
             res_time_sec,
             state,
             compound,
             flow_mlmin,
             conv,
             conv_sd,
             selec_c,
             selec_c_sd,
             yield_c,
             yield_c_sd,
             selec_o,
             selec_o_sd,
             yield_o,
             yield_o_sd,
             yield_ratio,
             yield_ratio_sd,
             balance_c,
             balance_c_sd,
             balance_o,
             balance_o_sd,
             ee_gf_perc,
             ee_gf_perc_sd,
             ee_lhv_perc,
             ee_lhv_perc_sd,
             ee_hhv_perc,
             ee_hhv_perc_sd,
             plasma_power_watt_avg,
             plasma_power_watt_sd,
             sei_kjmol,
             sei_kjmol_sd,
             source_power_watt_avg,
             source_power_watt_sd,
             gas_temp_avg_dgc,
             gas_temp_sd_dgc) %>%
      unique()
    write_csv(data_short, gsub(".csv", "-calc-short.csv", filename))
  },
  error = function(e) {
    message(sprintf("Error in file %s: %s", filename, e$message))
    return(NULL)
    }
  )
}

# Set working directory and list all files
setwd(file.path("N:", "FWET", "FDCH", "AdsCatal", "General", "personal_work_folders", "plasmacatdesign", "co2-splitting", "uhasselt", "GM11.2", "pwr-const", "test"))
all_files <- list.files(pattern = "\\d+\\.\\ds-\\d+\\.csv")

# Create a cluster (number of cores to use)
no_cores <- detectCores() - 1 # leave one core free for system stability
cl <- makeCluster(no_cores)

# Export required variables and functions to each worker in the cluster
clusterExport(cl, varlist = c("process_file"))
clusterEvalQ(
  cl, {
  library(tidyverse)
    }
)

# Apply the function to all files using parLapply
results <- parLapply(cl, all_files, process_file)

# Stop the cluster
stopCluster(cl)

# Remove the cluster
rm(cl)

# Clean up
gc()