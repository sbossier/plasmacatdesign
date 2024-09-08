# Load necessary packages
library(parallel)

# Clear workspace
rm(list=ls())

# Define the function to process each file
process_file <- function(filename) {
  tryCatch({
    data     <- read_csv(filename, na = c("", "NA", "N/A", "N A", "Na", "na", "n a", "N a"))
    
    ###############################################################################
    # Calculate average concentration, SD, and RSD for each compound in each test #
    ###############################################################################
    
    # na.rm = T is added to ignore logical NA's
    data <- data %>%
      group_by(state, compound) %>%
      mutate(conc_avg = mean(conc, na.rm = T),
             conc_sd  = sd(conc, na.rm = T),
             conc_rsd = conc_sd / conc_avg,
             .after   = conc) %>%
      ungroup()
    
    ###################################
    # Calculate beta and its SD & RSD #
    ###################################
    
    # Note 1: 0.005 is the reading accuracy of the F-201CV MFCs & 0.001 is the full scale value of the F-201CV MFCs
    #         (you can find these values on the product page of the MFCs of your choice),
    #         all flow (so +/- 100% of flow values according to normal distribution) fall between the summation for these two errors.
    
    # Note 2: 3.890592 is the z-value for which 99.99% of values fall within a normal curve.
    
    # Note 3: there is no error on beta, as any error from the error on gas flow is indirectly present in the measured concentrations by the GC.
    
    # Calculate the SD and RSD on the flow
    data <- mutate(data,
                   flow_mlmin_sd  = (.005 * flow_mlmin + .001 * flow_max_mlmin) / qnorm(.99995),
                   flow_rsd       = flow_mlmin_sd / flow_mlmin,
                   .after         = flow_max_mlmin)
    
    # Select average N2 concentration from blank experiment
    conc_avg_n2_blank  <- pull_value(dataframe = data, case = "blank", molecule = "N2", column = "conc_avg")
    
    # Select average CO2 concentration from blank experiment
    conc_avg_co2_blank <- pull_value(data, "blank", "CO2", "conc_avg")
    
    # Select average CH4 concentration from blank experiment
    conc_avg_ch4_blank <- pull_value(data, "blank", "CH4", "conc_avg")
    
    # Calculate beta as the ratio between the concentrations of N2 and CO2 + CH4 as measured by the GC,
    # this corrects for the pressure drop across the (packed) reactor (I assume)
    beta     <- conc_avg_n2_blank / (conc_avg_co2_blank + conc_avg_ch4_blank)
    beta_sd  <- 0
    beta_rsd <- 0
    
    # Add this data to the dataframe
    data <- mutate(data,
                   beta     = beta,
                   beta_sd  = beta_sd,
                   beta_rsd = beta_rsd,
                   .after   = conc_rsd)
    
    ####################################
    # Calculate alpha and its SD & RSD #
    ####################################
    
    # Select average N2 concentrations from plasma experiment
    conc_avg_n2_plasma <- pull_value(data, "plasma", "N2", "conc_avg")
    
    # We calculate alpha and set its SD and RSD to 0
    # (The error on alpha is indirectly present in the error on the concentrations determined by the GC)
    # For the blank experiments alpha is equal to 1 (there is no gas expansion)conc_avg_n2_blank / conc_avg_n2_plasma * (1 + beta) - beta
    data <- mutate(data,
                   alpha     = ifelse(state == "blank", 1, conc_avg_n2_blank / conc_avg_n2_plasma * (1 + beta) - beta ),
                   alpha_sd  = 0,
                   alpha_rsd = 0,
                   .after    = conc_rsd)
    
    # From the data, obtain alpha and its RSD
    # This is not done in the report so one sees it
    alpha     <- pull_value(data, "plasma", "N2", "alpha")
    alpha_sd  <- 0
    alpha_rsd <- 0
    
    ########################################################
    # Calculate corrected concentrations for the compounds #
    ########################################################
    
    # Calculation of the corrected average concentrations of all compounds entering and leaving the reactor
    # This correction however, has no physical meaning for N2, so to avoid confusion, we'll delete is for N2
    data <- mutate(data,
                   conc_avg_corr     = ifelse(compound == "N2", NA, conc_avg * (1 + beta / alpha)),
                   conc_avg_corr_sd  = ifelse(compound == "N2", NA, sqrt((beta_rsd ^ 2 + alpha_rsd ^ 2)
                                                                         *
                                                                           (beta / alpha) ^ 2 / (1 + beta / alpha) ^ 2
                                                                         +
                                                                           conc_rsd ^ 2)
                                              *
                                                conc_avg_corr),
                   conc_avg_corr_rsd = ifelse(compound == "N2", NA, conc_avg_corr_sd / conc_avg_corr),
                   .after            = beta_rsd)
    
    ##########################
    # Calculating conversion #
    ##########################
    
    # Carbon dioxide (CO2) #
    ########################
    
    # Obtain the corrected concentration of CO2 in the blank measurement and its SD & RSD
    conc_avg_corr_co2_blank     <- pull_value(data, "blank", "CO2", "conc_avg_corr")
    conc_avg_corr_co2_blank_sd  <- pull_value(data, "blank", "CO2", "conc_avg_corr_sd")
    conc_avg_corr_co2_blank_rsd <- pull_value(data, "blank", "CO2", "conc_avg_corr_rsd")
    
    # Obtain the corrected concentration of CO2 in the plasma measurement and its SD & RSD
    conc_avg_corr_co2_plasma     <- pull_value(data, "plasma", "CO2", "conc_avg_corr")
    conc_avg_corr_co2_plasma_sd  <- pull_value(data, "plasma", "CO2", "conc_avg_corr_sd")
    conc_avg_corr_co2_plasma_rsd <- pull_value(data, "plasma", "CO2", "conc_avg_corr_rsd")
    
    # Calculate the CO2 conversion from these numbers
    conv_co2     <- 1 - alpha * (conc_avg_corr_co2_plasma / conc_avg_corr_co2_blank)
    
    # Calculate the standard deviation on the CO2 conversion
    conv_co2_sd  <- sqrt(conc_avg_corr_co2_blank_rsd ^ 2 + conc_avg_corr_co2_plasma_rsd ^ 2 + alpha_rsd ^ 2) *
      alpha *
      (conc_avg_corr_co2_plasma / conc_avg_corr_co2_blank)
    
    # Calculate the relative standard deviation on the CO2 conversion
    conv_co2_rsd <- conv_co2_sd / conv_co2
    
    # Add these numbers for CO2 to the data
    data         <- mutate(data,
                           conv     = ifelse(compound == "CO2" & state == "plasma", conv_co2, NA),
                           conv_sd  = ifelse(compound == "CO2" & state == "plasma", conv_co2_sd, NA),
                           conv_rsd = ifelse(compound == "CO2" & state == "plasma", conv_co2_rsd, NA),
                           .after   = conc_avg_corr_rsd)
    
    # Methane (CH4) #
    #################
    
    # Obtain also the corrected concentration of CH4 in the blank measurement and its SD & RSD
    conc_avg_corr_ch4_blank     <- pull_value(data, "blank", "CH4", "conc_avg_corr")
    conc_avg_corr_ch4_blank_sd  <- pull_value(data, "blank", "CH4", "conc_avg_corr_sd")
    conc_avg_corr_ch4_blank_rsd <- pull_value(data, "blank", "CH4", "conc_avg_corr_rsd")
    
    # Obtain also the corrected concentration of CH4 in the plasma measurement and its SD & RSD
    conc_avg_corr_ch4_plasma     <- pull_value(data, "plasma", "CH4", "conc_avg_corr")
    conc_avg_corr_ch4_plasma_sd  <- pull_value(data, "plasma", "CH4", "conc_avg_corr_sd")
    conc_avg_corr_ch4_plasma_rsd <- pull_value(data, "plasma", "CH4", "conc_avg_corr_rsd")
    
    # Calculate the CH4 conversion from these numbers
    conv_ch4     <- 1 - alpha * (conc_avg_corr_ch4_plasma / conc_avg_corr_ch4_blank)
    
    # Calculate the standard deviation on the CH4 conversion
    conv_ch4_sd  <- sqrt(conc_avg_corr_ch4_blank_rsd ^ 2 + conc_avg_corr_ch4_plasma_rsd ^ 2 + alpha_rsd ^ 2) *
      alpha *
      (conc_avg_corr_ch4_plasma / conc_avg_corr_ch4_blank)
    
    # Calculate the relative standard deviation on the CO2 conversion
    conv_ch4_rsd <- conv_ch4_sd / conv_ch4
    
    # Add these numbers for CH4 to the data
    data         <- mutate(data,
                           conv     = ifelse(compound == "CH4" & state == "plasma", conv_ch4, conv),
                           conv_sd  = ifelse(compound == "CH4" & state == "plasma", conv_ch4_sd, conv_sd),
                           conv_rsd = ifelse(compound == "CH4" & state == "plasma", conv_ch4_rsd, conv_rsd))
    
    # Total conversion #
    ####################
    
    flow_co2       <- pull_value(data, "blank", "CO2", "flow_mlmin")
    flow_co2_sd    <- pull_value(data, "blank", "CO2", "flow_mlmin_sd")
    flow_co2_rsd   <- pull_value(data, "blank", "CO2", "flow_rsd")
    
    flow_ch4       <- pull_value(data, "blank", "CH4", "flow_mlmin")
    flow_ch4_sd    <- pull_value(data, "blank", "CH4", "flow_mlmin_sd")
    flow_ch4_rsd   <- pull_value(data, "blank", "CH4", "flow_rsd")
    
    conv_total     <- conv_co2 * flow_co2 / (flow_co2 + flow_ch4) + conv_ch4 * flow_ch4 / (flow_co2 + flow_ch4)
    
    conv_total_sd  <- sqrt(
      (conv_co2 * flow_co2 / (flow_co2 + flow_ch4))^2 * (conv_co2_rsd^2 + flow_co2_rsd^2 + ((flow_co2_sd^2 + flow_ch4_sd^2) / (flow_co2 + flow_ch4)^2))
      +
        (conv_ch4 * flow_ch4 / (flow_co2 + flow_ch4))^2 * (conv_ch4_rsd^2 + flow_ch4_rsd^2 + ((flow_co2_sd^2 + flow_ch4_sd^2) / (flow_co2 + flow_ch4)^2))
    )
    
    conv_total_rsd <- conv_total_sd / conv_total
    
    # Create new row for the total conversion
    data <- data %>%
      add_row(
        material = first(data$material), # or data$material[1]
        res_time_sec = first(data$res_time_sec), # or data$res_time_sec[1]
        state = "plasma",
        compound = "Total",
        atoms_c = NA_real_,
        atoms_h = NA_real_,
        atoms_o = NA_real_,
        flow_mlmin = flow_co2 + flow_ch4,
        flow_max_mlmin = NA_real_,
        flow_mlmin_sd = sqrt(flow_co2_sd^2 + flow_ch4_sd^2),
        flow_rsd = flow_mlmin_sd / flow_mlmin,
        conc = NA_real_,
        conc_avg = NA_real_,
        conc_sd = NA_real_,
        conc_rsd = NA_real_,
        alpha = alpha,
        alpha_sd = alpha_sd,
        alpha_rsd = alpha_rsd,
        beta = beta,
        beta_sd = beta_sd,
        beta_rsd = beta_rsd,
        conc_avg_corr = conc_avg_corr_co2_plasma + conc_avg_corr_ch4_plasma,
        conc_avg_corr_sd = sqrt(conc_avg_corr_co2_plasma_sd^2 + conc_avg_corr_ch4_plasma_sd^2),
        conc_avg_corr_rsd = conc_avg_corr_sd/conc_avg_corr,
        conv = conv_total,
        conv_sd = conv_total_sd,
        conv_rsd = conv_total_rsd,
        plasma_power_watt = NA_real_,
        source_power_watt = NA_real_,
        plasma_temp_celc = first(data$plasma_temp_celc),
      )
    
    ########################
    # Carbon monoxide (CO) #
    ########################
    
    # CO carbon selectivity #
    #########################
    
    # From the data, the concentration of CO in plasma experiments must be obtained and its SD & RSD
    conc_avg_corr_co     <- pull_value(data, "plasma", "CO", "conc_avg_corr")
    conc_avg_corr_co_sd  <- pull_value(data, "plasma", "CO", "conc_avg_corr_sd")
    conc_avg_corr_co_rsd <- pull_value(data, "plasma", "CO", "conc_avg_corr_rsd")
    
    # The carbon selectivity of CO can be calculated as follows
    selec_c_co <- calculate_selectivity(alpha_value          = alpha,
                                        atoms_in_compound    = 1,
                                        atoms_in_co2         = 1,
                                        atoms_in_ch4         = 1,
                                        conc_corr_compound   = conc_avg_corr_co,
                                        conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                        conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                        conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                        conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    # The RSD of the carbon selectivity of CO can be calculated as follows
    selec_c_co_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                alpha_value_rsd          = alpha_rsd,
                                                atoms_in_co2             = 1,
                                                atoms_in_ch4             = 1,
                                                conc_corr_compound_rsd   = conc_avg_corr_co_rsd,
                                                conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    # The SD of the carbon selectivity of CO can be calculated as follows
    selec_c_co_sd <- selec_c_co_rsd * selec_c_co
    
    # Add these numbers to the data
    data <- mutate(data,
                   selec_c     = ifelse(compound == "CO" & state == "plasma", selec_c_co, NA),
                   selec_c_sd  = ifelse(compound == "CO" & state == "plasma", selec_c_co_sd, NA),
                   selec_c_rsd = ifelse(compound == "CO" & state == "plasma", selec_c_co_rsd, NA),
                   .after = conv_rsd)
    
    # CO carbon yield #
    ###################
    
    # The carbon yield of CO can be calculated as follows
    yield_c_co     <- calculate_yield(alpha_value         = alpha,
                                      atoms_in_compound   = 1,
                                      atoms_in_co2        = 1,
                                      atoms_in_ch4        = 1,
                                      conc_corr_compound  = conc_avg_corr_co,
                                      conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                      conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    # The RSD of the carbon yield of CO can be calculated as follows
    yield_c_co_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                          atoms_in_co2           = 1,
                                          atoms_in_ch4           = 1,
                                          conc_corr_compound_rsd = conc_avg_corr_co_rsd,
                                          conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                          conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                          conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                          conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    # The SD of the carbon yield of CO can be calculated as follows
    yield_c_co_sd  <- yield_c_co_rsd * yield_c_co
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "CO" & state == "plasma", yield_c_co, NA),
                   yield_c_sd  = ifelse(compound == "CO" & state == "plasma", yield_c_co_sd, NA),
                   yield_c_rsd = ifelse(compound == "CO" & state == "plasma", yield_c_co_rsd, NA),
                   .after = selec_c_rsd)
    
    # CO oxygen selectivity #
    #########################
    
    selec_o_co     <- calculate_selectivity(alpha_value          = alpha,
                                            atoms_in_compound    = 1,
                                            atoms_in_co2         = 2,
                                            atoms_in_ch4         = 0,
                                            conc_corr_compound   = conc_avg_corr_co,
                                            conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                            conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                            conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_o_co_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                alpha_value_rsd          = alpha_rsd,
                                                atoms_in_co2             = 2,
                                                atoms_in_ch4             = 0,
                                                conc_corr_compound_rsd   = conc_avg_corr_co_rsd,
                                                conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_o_co_sd  <- selec_o_co_rsd * selec_o_co
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "CO" & state == "plasma", selec_o_co, NA),
                   selec_o_sd  = ifelse(compound == "CO" & state == "plasma", selec_o_co_sd, NA),
                   selec_o_rsd = ifelse(compound == "CO" & state == "plasma", selec_o_co_rsd, NA),
                   .after = yield_c_rsd)
    
    # CO oxygen yield #
    ###################
    
    yield_o_co     <- calculate_yield(alpha_value         = alpha,
                                      atoms_in_compound   = 1,
                                      atoms_in_co2        = 2,
                                      atoms_in_ch4        = 0,
                                      conc_corr_compound  = conc_avg_corr_co,
                                      conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                      conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_o_co_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                          atoms_in_co2           = 2,
                                          atoms_in_ch4           = 0,
                                          conc_corr_compound_rsd = conc_avg_corr_co_rsd,
                                          conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                          conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                          conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                          conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_o_co_sd  <- yield_o_co_rsd * yield_o_co
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "CO" & state == "plasma", yield_o_co, NA),
                   yield_o_sd  = ifelse(compound == "CO" & state == "plasma", yield_o_co_sd, NA),
                   yield_o_rsd = ifelse(compound == "CO" & state == "plasma", yield_o_co_rsd, NA),
                   .after = selec_o_rsd)
    
    ###############
    # Oxygen (O2) #
    ###############
    
    # O2 oxygen selectivity #
    #########################
    
    conc_avg_corr_o2     <- pull_value(data, "plasma", "O2", "conc_avg_corr")
    conc_avg_corr_o2_sd  <- pull_value(data, "plasma", "O2", "conc_avg_corr_sd")
    conc_avg_corr_o2_rsd <- pull_value(data, "plasma", "O2", "conc_avg_corr_rsd")
    
    selec_o_o2     <- calculate_selectivity(alpha_value          = alpha,
                                            atoms_in_compound    = 2,
                                            atoms_in_co2         = 2,
                                            atoms_in_ch4         = 0,
                                            conc_corr_compound   = conc_avg_corr_o2,
                                            conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                            conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                            conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_o_o2_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                alpha_value_rsd          = alpha_rsd,
                                                atoms_in_co2             = 2,
                                                atoms_in_ch4             = 0,
                                                conc_corr_compound_rsd   = conc_avg_corr_o2_rsd,
                                                conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_o_o2_sd  <- selec_o_o2_rsd * selec_o_o2
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "O2" & state == "plasma", selec_o_o2, selec_o),
                   selec_o_sd  = ifelse(compound == "O2" & state == "plasma", selec_o_o2_sd, selec_o_sd),
                   selec_o_rsd = ifelse(compound == "O2" & state == "plasma", selec_o_o2_rsd, selec_o_rsd))
    
    # O2 oxygen yield #
    ###################
    
    yield_o_o2     <- calculate_yield(alpha_value         = alpha,
                                      atoms_in_compound   = 2,
                                      atoms_in_co2        = 2,
                                      atoms_in_ch4        = 0,
                                      conc_corr_compound  = conc_avg_corr_o2,
                                      conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                      conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_o_o2_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                          atoms_in_co2           = 2,
                                          atoms_in_ch4           = 0,
                                          conc_corr_compound_rsd = conc_avg_corr_o2_rsd,
                                          conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                          conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                          conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                          conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_o_o2_sd  <- yield_o_o2_rsd * yield_o_o2
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "O2" & state == "plasma", yield_o_o2, yield_o),
                   yield_o_sd  = ifelse(compound == "O2" & state == "plasma", yield_o_o2_sd, yield_o_sd),
                   yield_o_rsd = ifelse(compound == "O2" & state == "plasma", yield_o_o2_rsd, yield_o_rsd))
    
    #################
    # Hydrogen (H2) #
    #################
    
    # H2 hydrogen selectivity #
    ###########################
    
    conc_avg_corr_h2     <- pull_value(data, "plasma", "H2", "conc_avg_corr")
    conc_avg_corr_h2_sd  <- pull_value(data, "plasma", "H2", "conc_avg_corr_sd")
    conc_avg_corr_h2_rsd <- pull_value(data, "plasma", "H2", "conc_avg_corr_rsd")
    
    selec_h_h2     <- calculate_selectivity(alpha_value          = alpha,
                                            atoms_in_compound    = 2,
                                            atoms_in_co2         = 0,
                                            atoms_in_ch4         = 4,
                                            conc_corr_compound   = conc_avg_corr_h2,
                                            conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                            conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                            conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_h2_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                alpha_value_rsd          = alpha_rsd,
                                                atoms_in_co2             = 0,
                                                atoms_in_ch4             = 4,
                                                conc_corr_compound_rsd   = conc_avg_corr_h2_rsd,
                                                conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_h2_sd  <- selec_h_h2_rsd * selec_h_h2
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "H2" & state == "plasma", selec_h_h2, NA),
                   selec_h_sd  = ifelse(compound == "H2" & state == "plasma", selec_h_h2_sd, NA),
                   selec_h_rsd = ifelse(compound == "H2" & state == "plasma", selec_h_h2_rsd, NA),
                   .after      = yield_o_rsd)
    
    # H2 hydrogen yield #
    #####################
    
    yield_h_h2     <- calculate_yield(alpha_value         = alpha,
                                      atoms_in_compound   = 2,
                                      atoms_in_co2        = 0,
                                      atoms_in_ch4        = 4,
                                      conc_corr_compound  = conc_avg_corr_h2,
                                      conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                      conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_h2_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                          atoms_in_co2           = 0,
                                          atoms_in_ch4           = 4,
                                          conc_corr_compound_rsd = conc_avg_corr_h2_rsd,
                                          conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                          conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                          conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                          conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_h2_sd  <- yield_h_h2_rsd * yield_h_h2
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "H2" & state == "plasma", yield_h_h2, NA),
                   yield_h_sd  = ifelse(compound == "H2" & state == "plasma", yield_h_h2_sd, NA),
                   yield_h_rsd = ifelse(compound == "H2" & state == "plasma", yield_h_h2_rsd, NA),
                   .after      = selec_h_rsd)
    
    #################
    # Ethane (C2H6) #
    #################
    
    # C2H6 carbon selectivity #
    ###########################
    
    conc_avg_corr_c2h6     <- pull_value(data, "plasma", "C2H6", "conc_avg_corr")
    conc_avg_corr_c2h6_sd  <- pull_value(data, "plasma", "C2H6", "conc_avg_corr_sd")
    conc_avg_corr_c2h6_rsd <- pull_value(data, "plasma", "C2H6", "conc_avg_corr_rsd")
    
    selec_c_c2h6     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 2,
                                              atoms_in_co2         = 1,
                                              atoms_in_ch4         = 1,
                                              conc_corr_compound   = conc_avg_corr_c2h6,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_c2h6_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 1,
                                                  atoms_in_ch4             = 1,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h6_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_c2h6_sd  <- selec_c_c2h6_rsd * selec_c_c2h6
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "C2H6" & state == "plasma", selec_c_c2h6, selec_c),
                   selec_c_sd  = ifelse(compound == "C2H6" & state == "plasma", selec_c_c2h6_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "C2H6" & state == "plasma", selec_c_c2h6_rsd, selec_c_rsd))
    
    # C2H6 carbon yield #
    #####################
    
    yield_c_c2h6     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 2,
                                        atoms_in_co2        = 1,
                                        atoms_in_ch4        = 1,
                                        conc_corr_compound  = conc_avg_corr_c2h6,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_c2h6_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 1,
                                            atoms_in_ch4           = 1,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h6_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_c2h6_sd  <- yield_c_c2h6_rsd * yield_c_c2h6
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "C2H6" & state == "plasma", yield_c_c2h6, yield_c),
                   yield_c_sd  = ifelse(compound == "C2H6" & state == "plasma", yield_c_c2h6_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "C2H6" & state == "plasma", yield_c_c2h6_rsd, yield_c_rsd))
    
    # C2H6 hydrogen selectivity #
    #############################
    
    selec_h_c2h6     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 6,
                                              atoms_in_co2         = 0,
                                              atoms_in_ch4         = 4,
                                              conc_corr_compound   = conc_avg_corr_c2h6,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_c2h6_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 0,
                                                  atoms_in_ch4             = 4,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h6_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_c2h6_sd  <- selec_h_c2h6_rsd * selec_h_c2h6
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "C2H6" & state == "plasma", selec_h_c2h6, selec_h),
                   selec_h_sd  = ifelse(compound == "C2H6" & state == "plasma", selec_h_c2h6_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "C2H6" & state == "plasma", selec_h_c2h6_rsd, selec_h_rsd))
    
    # C2H6 hydrogen yield #
    #######################
    
    yield_h_c2h6     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 6,
                                        atoms_in_co2        = 0,
                                        atoms_in_ch4        = 4,
                                        conc_corr_compound  = conc_avg_corr_c2h6,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_c2h6_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 0,
                                            atoms_in_ch4           = 4,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h6_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_c2h6_sd  <- yield_h_c2h6_rsd * yield_h_c2h6
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "C2H6" & state == "plasma", yield_h_c2h6, yield_h),
                   yield_h_sd  = ifelse(compound == "C2H6" & state == "plasma", yield_h_c2h6_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "C2H6" & state == "plasma", yield_h_c2h6_rsd, yield_h_rsd))
    
    #################
    # Ethene (C2H4) #
    #################
    
    # C2H4 carbon selectivity #
    ###########################
    
    conc_avg_corr_c2h4     <- pull_value(data, "plasma", "C2H4", "conc_avg_corr")
    conc_avg_corr_c2h4_sd  <- pull_value(data, "plasma", "C2H4", "conc_avg_corr_sd")
    conc_avg_corr_c2h4_rsd <- pull_value(data, "plasma", "C2H4", "conc_avg_corr_rsd")
    
    selec_c_c2h4     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 2,
                                              atoms_in_co2         = 1,
                                              atoms_in_ch4         = 1,
                                              conc_corr_compound   = conc_avg_corr_c2h4,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_c2h4_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 1,
                                                  atoms_in_ch4             = 1,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h6_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_c2h4_sd  <- selec_c_c2h4_rsd * selec_c_c2h4
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "C2H4" & state == "plasma", selec_c_c2h4, selec_c),
                   selec_c_sd  = ifelse(compound == "C2H4" & state == "plasma", selec_c_c2h4_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "C2H4" & state == "plasma", selec_c_c2h4_rsd, selec_c_rsd))
    
    # C2H4 carbon yield #
    #####################
    
    yield_c_c2h4     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 2,
                                        atoms_in_co2        = 1,
                                        atoms_in_ch4        = 1,
                                        conc_corr_compound  = conc_avg_corr_c2h4,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_c2h4_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 1,
                                            atoms_in_ch4           = 1,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h4_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_c2h4_sd  <- yield_c_c2h4_rsd * yield_c_c2h4
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "C2H4" & state == "plasma", yield_c_c2h4, yield_c),
                   yield_c_sd  = ifelse(compound == "C2H4" & state == "plasma", yield_c_c2h4_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "C2H4" & state == "plasma", yield_c_c2h4_rsd, yield_c_rsd))
    
    # C2H4 hydrogen selectivity #
    #############################
    
    selec_h_c2h4     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 4,
                                              atoms_in_co2         = 0,
                                              atoms_in_ch4         = 4,
                                              conc_corr_compound   = conc_avg_corr_c2h4,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_c2h4_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 0,
                                                  atoms_in_ch4             = 4,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h4_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_c2h4_sd  <- selec_h_c2h4_rsd * selec_h_c2h4
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "C2H4" & state == "plasma", selec_h_c2h4, selec_h),
                   selec_h_sd  = ifelse(compound == "C2H4" & state == "plasma", selec_h_c2h4_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "C2H4" & state == "plasma", selec_h_c2h4_rsd, selec_h_rsd))
    
    # C2H4 hydrogen yield #
    #######################
    
    yield_h_c2h4     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 4,
                                        atoms_in_co2        = 0,
                                        atoms_in_ch4        = 4,
                                        conc_corr_compound  = conc_avg_corr_c2h4,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_c2h4_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 0,
                                            atoms_in_ch4           = 4,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h4_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_c2h4_sd  <- yield_h_c2h4_rsd * yield_h_c2h4
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "C2H4" & state == "plasma", yield_h_c2h4, yield_h),
                   yield_h_sd  = ifelse(compound == "C2H4" & state == "plasma", yield_h_c2h4_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "C2H4" & state == "plasma", yield_h_c2h4_rsd, yield_h_rsd))
    
    #################
    # Ethyne (C2H2) #
    #################
    
    # C2H2 carbon selectivity #
    ###########################
    
    conc_avg_corr_c2h2     <- pull_value(data, "plasma", "C2H2", "conc_avg_corr")
    conc_avg_corr_c2h2_sd  <- pull_value(data, "plasma", "C2H2", "conc_avg_corr_sd")
    conc_avg_corr_c2h2_rsd <- pull_value(data, "plasma", "C2H2", "conc_avg_corr_rsd")
    
    selec_c_c2h2     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 2,
                                              atoms_in_co2         = 1,
                                              atoms_in_ch4         = 1,
                                              conc_corr_compound   = conc_avg_corr_c2h2,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_c2h2_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 1,
                                                  atoms_in_ch4             = 1,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h2_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_c2h2_sd  <- selec_c_c2h2_rsd * selec_c_c2h2
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "C2H2" & state == "plasma", selec_c_c2h2, selec_c),
                   selec_c_sd  = ifelse(compound == "C2H2" & state == "plasma", selec_c_c2h2_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "C2H2" & state == "plasma", selec_c_c2h2_rsd, selec_c_rsd))
    
    # C2H2 carbon yield #
    #####################
    
    yield_c_c2h2     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 2,
                                        atoms_in_co2        = 1,
                                        atoms_in_ch4        = 1,
                                        conc_corr_compound  = conc_avg_corr_c2h2,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_c2h2_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 1,
                                            atoms_in_ch4           = 1,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h2_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_c2h2_sd  <- yield_c_c2h2_rsd * yield_c_c2h2
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "C2H2" & state == "plasma", yield_c_c2h2, yield_c),
                   yield_c_sd  = ifelse(compound == "C2H2" & state == "plasma", yield_c_c2h2_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "C2H2" & state == "plasma", yield_c_c2h2_rsd, yield_c_rsd))
    
    # C2H2 hydrogen selectivity #
    #############################
    
    selec_h_c2h2     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 2,
                                              atoms_in_co2         = 0,
                                              atoms_in_ch4         = 4,
                                              conc_corr_compound   = conc_avg_corr_c2h2,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_c2h2_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 0,
                                                  atoms_in_ch4             = 4,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c2h2_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_c2h2_sd  <- selec_h_c2h2_rsd * selec_h_c2h2
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "C2H2" & state == "plasma", selec_h_c2h2, selec_h),
                   selec_h_sd  = ifelse(compound == "C2H2" & state == "plasma", selec_h_c2h2_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "C2H2" & state == "plasma", selec_h_c2h2_rsd, selec_h_rsd))
    
    # C2H2 hydrogen yield #
    #######################
    
    yield_h_c2h2     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 2,
                                        atoms_in_co2        = 0,
                                        atoms_in_ch4        = 4,
                                        conc_corr_compound  = conc_avg_corr_c2h2,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_c2h2_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 0,
                                            atoms_in_ch4           = 4,
                                            conc_corr_compound_rsd = conc_avg_corr_c2h2_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_c2h2_sd  <- yield_h_c2h2_rsd * yield_h_c2h2
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "C2H2" & state == "plasma", yield_h_c2h2, yield_h),
                   yield_h_sd  = ifelse(compound == "C2H2" & state == "plasma", yield_h_c2h2_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "C2H2" & state == "plasma", yield_h_c2h2_rsd, yield_h_rsd))
    
    ##################
    # Propane (C3H8) #
    ##################
    
    # C3H8 carbon selectivity #
    ###########################
    
    conc_avg_corr_c3h8     <- pull_value(data, "plasma", "C3H8", "conc_avg_corr")
    conc_avg_corr_c3h8_sd  <- pull_value(data, "plasma", "C3H8", "conc_avg_corr_sd")
    conc_avg_corr_c3h8_rsd <- pull_value(data, "plasma", "C3H8", "conc_avg_corr_rsd")
    
    selec_c_c3h8     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 3,
                                              atoms_in_co2         = 1,
                                              atoms_in_ch4         = 1,
                                              conc_corr_compound   = conc_avg_corr_c3h8,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_c3h8_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 1,
                                                  atoms_in_ch4             = 1,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c3h8_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_c3h8_sd  <- selec_c_c3h8_rsd * selec_c_c3h8
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "C3H8" & state == "plasma", selec_c_c3h8, selec_c),
                   selec_c_sd  = ifelse(compound == "C3H8" & state == "plasma", selec_c_c3h8_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "C3H8" & state == "plasma", selec_c_c3h8_rsd, selec_c_rsd))
    
    # C3H8 carbon yield #
    #####################
    
    yield_c_c3h8     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 3,
                                        atoms_in_co2        = 1,
                                        atoms_in_ch4        = 1,
                                        conc_corr_compound  = conc_avg_corr_c3h8,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_c3h8_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 1,
                                            atoms_in_ch4           = 1,
                                            conc_corr_compound_rsd = conc_avg_corr_c3h8_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_c3h8_sd  <- yield_c_c3h8_rsd * yield_c_c3h8
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "C3H8" & state == "plasma", yield_c_c3h8, yield_c),
                   yield_c_sd  = ifelse(compound == "C3H8" & state == "plasma", yield_c_c3h8_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "C3H8" & state == "plasma", yield_c_c3h8_rsd, yield_c_rsd))
    
    # C3H8 hydrogen selectivity #
    #############################
    
    selec_h_c3h8     <- calculate_selectivity(alpha_value          = alpha,
                                              atoms_in_compound    = 8,
                                              atoms_in_co2         = 0,
                                              atoms_in_ch4         = 4,
                                              conc_corr_compound   = conc_avg_corr_c3h8,
                                              conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                              conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                              conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_c3h8_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                  alpha_value_rsd          = alpha_rsd,
                                                  atoms_in_co2             = 0,
                                                  atoms_in_ch4             = 4,
                                                  conc_corr_compound_rsd   = conc_avg_corr_c3h8_rsd,
                                                  conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                  conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                  conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                  conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                  conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                  conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                  conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                  conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_c3h8_sd  <- selec_h_c3h8_rsd * selec_h_c3h8
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "C3H8" & state == "plasma", selec_h_c3h8, selec_h),
                   selec_h_sd  = ifelse(compound == "C3H8" & state == "plasma", selec_h_c3h8_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "C3H8" & state == "plasma", selec_h_c3h8_rsd, selec_h_rsd))
    
    # C3H8 hydrogen yield #
    #######################
    
    yield_h_c3h8     <- calculate_yield(alpha_value         = alpha,
                                        atoms_in_compound   = 8,
                                        atoms_in_co2        = 0,
                                        atoms_in_ch4        = 4,
                                        conc_corr_compound  = conc_avg_corr_c3h8,
                                        conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                        conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_c3h8_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                            atoms_in_co2           = 0,
                                            atoms_in_ch4           = 4,
                                            conc_corr_compound_rsd = conc_avg_corr_c3h8_rsd,
                                            conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                            conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                            conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                            conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_c3h8_sd  <- yield_h_c3h8_rsd * yield_h_c3h8
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "C3H8" & state == "plasma", yield_h_c3h8, yield_h),
                   yield_h_sd  = ifelse(compound == "C3H8" & state == "plasma", yield_h_c3h8_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "C3H8" & state == "plasma", yield_h_c3h8_rsd, yield_h_rsd))
    
    ###########################
    # Dimethylether (CH3OCH3) #
    ###########################
    
    # CH3OCH3 carbon selectivity #
    ##############################
    
    conc_avg_corr_ch3och3     <- pull_value(data, "plasma", "CH3OCH3", "conc_avg_corr")
    conc_avg_corr_ch3och3_sd  <- pull_value(data, "plasma", "CH3OCH3", "conc_avg_corr_sd")
    conc_avg_corr_ch3och3_rsd <- pull_value(data, "plasma", "CH3OCH3", "conc_avg_corr_rsd")
    
    selec_c_ch3och3     <- calculate_selectivity(alpha_value          = alpha,
                                                 atoms_in_compound    = 2,
                                                 atoms_in_co2         = 1,
                                                 atoms_in_ch4         = 1,
                                                 conc_corr_compound   = conc_avg_corr_ch3och3,
                                                 conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                 conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                 conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                 conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_ch3och3_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                     alpha_value_rsd          = alpha_rsd,
                                                     atoms_in_co2             = 1,
                                                     atoms_in_ch4             = 1,
                                                     conc_corr_compound_rsd   = conc_avg_corr_ch3och3_rsd,
                                                     conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                     conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                     conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                     conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                     conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                     conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                     conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                     conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_ch3och3_sd  <- selec_c_ch3och3_rsd * selec_c_ch3och3
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "CH3OCH3" & state == "plasma", selec_c_ch3och3, selec_c),
                   selec_c_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", selec_c_ch3och3_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", selec_c_ch3och3_rsd, selec_c_rsd))
    
    # CH3OCH3 carbon yield #
    ########################
    
    yield_c_ch3och3     <- calculate_yield(alpha_value         = alpha,
                                           atoms_in_compound   = 2,
                                           atoms_in_co2        = 1,
                                           atoms_in_ch4        = 1,
                                           conc_corr_compound  = conc_avg_corr_ch3och3,
                                           conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                           conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_ch3och3_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                               atoms_in_co2           = 1,
                                               atoms_in_ch4           = 1,
                                               conc_corr_compound_rsd = conc_avg_corr_ch3och3_rsd,
                                               conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                               conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                               conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_ch3och3_sd  <- yield_c_ch3och3_rsd * yield_c_ch3och3
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "CH3OCH3" & state == "plasma", yield_c_ch3och3, yield_c),
                   yield_c_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", yield_c_ch3och3_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", yield_c_ch3och3_rsd, yield_c_rsd))
    
    # CH3OCH3 hydrogen selectivity #
    ################################
    
    selec_h_ch3och3     <- calculate_selectivity(alpha_value          = alpha,
                                                 atoms_in_compound    = 6,
                                                 atoms_in_co2         = 0,
                                                 atoms_in_ch4         = 4,
                                                 conc_corr_compound   = conc_avg_corr_ch3och3,
                                                 conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                 conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                 conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                 conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_ch3och3_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                     alpha_value_rsd          = alpha_rsd,
                                                     atoms_in_co2             = 0,
                                                     atoms_in_ch4             = 4,
                                                     conc_corr_compound_rsd   = conc_avg_corr_ch3och3_rsd,
                                                     conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                     conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                     conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                     conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                     conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                     conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                     conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                     conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_ch3och3_sd  <- selec_h_ch3och3_rsd * selec_h_ch3och3
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "CH3OCH3" & state == "plasma", selec_h_ch3och3, selec_h),
                   selec_h_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", selec_h_ch3och3_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", selec_h_ch3och3_rsd, selec_h_rsd))
    
    # CH3OCH3 hydrogen yield #
    ##########################
    
    yield_h_ch3och3     <- calculate_yield(alpha_value         = alpha,
                                           atoms_in_compound   = 6,
                                           atoms_in_co2        = 0,
                                           atoms_in_ch4        = 4,
                                           conc_corr_compound  = conc_avg_corr_ch3och3,
                                           conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                           conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_ch3och3_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                               atoms_in_co2           = 0,
                                               atoms_in_ch4           = 4,
                                               conc_corr_compound_rsd = conc_avg_corr_ch3och3_rsd,
                                               conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                               conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                               conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_ch3och3_sd  <- yield_h_ch3och3_rsd * yield_h_ch3och3
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "CH3OCH3" & state == "plasma", yield_h_ch3och3, yield_h),
                   yield_h_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", yield_h_ch3och3_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", yield_h_ch3och3_rsd, yield_h_rsd))
    
    # CH3OCH3 oxygen selectivity #
    ##############################
    
    selec_o_ch3och3     <- calculate_selectivity(alpha_value          = alpha,
                                                 atoms_in_compound    = 1,
                                                 atoms_in_co2         = 2,
                                                 atoms_in_ch4         = 0,
                                                 conc_corr_compound   = conc_avg_corr_ch3och3,
                                                 conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                 conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                 conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                 conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_o_ch3och3_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                     alpha_value_rsd          = alpha_rsd,
                                                     atoms_in_co2             = 2,
                                                     atoms_in_ch4             = 0,
                                                     conc_corr_compound_rsd   = conc_avg_corr_ch3och3_rsd,
                                                     conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                     conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                     conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                     conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                     conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                     conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                     conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                     conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_o_ch3och3_sd  <- selec_o_ch3och3_rsd * selec_o_ch3och3
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "CH3OCH3" & state == "plasma", selec_o_ch3och3, selec_o),
                   selec_o_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", selec_o_ch3och3_sd, selec_o_sd),
                   selec_o_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", selec_o_ch3och3_rsd, selec_o_rsd))
    
    # CH3OCH3 oxygen yield #
    ########################
    
    yield_o_ch3och3     <- calculate_yield(alpha_value         = alpha,
                                           atoms_in_compound   = 1,
                                           atoms_in_co2        = 2,
                                           atoms_in_ch4        = 0,
                                           conc_corr_compound  = conc_avg_corr_ch3och3,
                                           conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                           conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_o_ch3och3_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                               atoms_in_co2           = 2,
                                               atoms_in_ch4           = 0,
                                               conc_corr_compound_rsd = conc_avg_corr_ch3och3_rsd,
                                               conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                               conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                               conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_o_ch3och3_sd  <- yield_o_ch3och3_rsd * yield_o_ch3och3
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "CH3OCH3" & state == "plasma", yield_o_ch3och3, yield_o),
                   yield_o_sd  = ifelse(compound == "CH3OCH3" & state == "plasma", yield_o_ch3och3_sd, yield_o_sd),
                   yield_o_rsd = ifelse(compound == "CH3OCH3" & state == "plasma", yield_o_ch3och3_rsd, yield_o_rsd))
    
    ####################
    # Methanol (CH3OH) #
    ####################
    
    # CH3OH carbon selectivity #
    ############################
    
    conc_avg_corr_ch3oh     <- pull_value(data, "plasma", "CH3OH", "conc_avg_corr")
    conc_avg_corr_ch3oh_sd  <- pull_value(data, "plasma", "CH3OH", "conc_avg_corr_sd")
    conc_avg_corr_ch3oh_rsd <- pull_value(data, "plasma", "CH3OH", "conc_avg_corr_rsd")
    
    selec_c_ch3oh     <- calculate_selectivity(alpha_value          = alpha,
                                               atoms_in_compound    = 1,
                                               atoms_in_co2         = 1,
                                               atoms_in_ch4         = 1,
                                               conc_corr_compound   = conc_avg_corr_ch3oh,
                                               conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                               conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                               conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_ch3oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                   alpha_value_rsd          = alpha_rsd,
                                                   atoms_in_co2             = 1,
                                                   atoms_in_ch4             = 1,
                                                   conc_corr_compound_rsd   = conc_avg_corr_ch3oh_rsd,
                                                   conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                   conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                   conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                   conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                   conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                   conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                   conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                   conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_ch3oh_sd  <- selec_c_ch3oh_rsd * selec_c_ch3oh
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "CH3OH" & state == "plasma", selec_c_ch3oh, selec_c),
                   selec_c_sd  = ifelse(compound == "CH3OH" & state == "plasma", selec_c_ch3oh_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "CH3OH" & state == "plasma", selec_c_ch3oh_rsd, selec_c_rsd))
    
    # CH3OH carbon yield #
    ######################
    
    yield_c_ch3oh     <- calculate_yield(alpha_value         = alpha,
                                         atoms_in_compound   = 1,
                                         atoms_in_co2        = 1,
                                         atoms_in_ch4        = 1,
                                         conc_corr_compound  = conc_avg_corr_ch3oh,
                                         conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                         conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_ch3oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                             atoms_in_co2           = 1,
                                             atoms_in_ch4           = 1,
                                             conc_corr_compound_rsd = conc_avg_corr_ch3oh_rsd,
                                             conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                             conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                             conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                             conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_ch3oh_sd  <- yield_c_ch3oh_rsd * yield_c_ch3oh
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "CH3OH" & state == "plasma", yield_c_ch3oh, yield_c),
                   yield_c_sd  = ifelse(compound == "CH3OH" & state == "plasma", yield_c_ch3oh_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "CH3OH" & state == "plasma", yield_c_ch3oh_rsd, yield_c_rsd))
    
    # CH3OH hydrogen selectivity #
    ##############################
    
    selec_h_ch3oh     <- calculate_selectivity(alpha_value          = alpha,
                                               atoms_in_compound    = 4,
                                               atoms_in_co2         = 0,
                                               atoms_in_ch4         = 4,
                                               conc_corr_compound   = conc_avg_corr_ch3oh,
                                               conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                               conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                               conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_ch3oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                   alpha_value_rsd          = alpha_rsd,
                                                   atoms_in_co2             = 0,
                                                   atoms_in_ch4             = 4,
                                                   conc_corr_compound_rsd   = conc_avg_corr_ch3oh_rsd,
                                                   conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                   conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                   conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                   conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                   conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                   conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                   conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                   conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_ch3oh_sd  <- selec_h_ch3oh_rsd * selec_h_ch3oh
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "CH3OH" & state == "plasma", selec_h_ch3oh, selec_h),
                   selec_h_sd  = ifelse(compound == "CH3OH" & state == "plasma", selec_h_ch3oh_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "CH3OH" & state == "plasma", selec_h_ch3oh_rsd, selec_h_rsd))
    
    # CH3OH hydrogen yield #
    ########################
    
    yield_h_ch3oh     <- calculate_yield(alpha_value         = alpha,
                                         atoms_in_compound   = 4,
                                         atoms_in_co2        = 0,
                                         atoms_in_ch4        = 4,
                                         conc_corr_compound  = conc_avg_corr_ch3oh,
                                         conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                         conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_ch3oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                             atoms_in_co2           = 0,
                                             atoms_in_ch4           = 4,
                                             conc_corr_compound_rsd = conc_avg_corr_ch3oh_rsd,
                                             conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                             conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                             conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                             conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_ch3oh_sd  <- yield_h_ch3oh_rsd * yield_h_ch3oh
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "CH3OH" & state == "plasma", yield_h_ch3oh, yield_h),
                   yield_h_sd  = ifelse(compound == "CH3OH" & state == "plasma", yield_h_ch3oh_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "CH3OH" & state == "plasma", yield_h_ch3oh_rsd, yield_h_rsd))
    
    # CH3OH oxygen selectivity #
    ############################
    
    selec_o_ch3oh     <- calculate_selectivity(alpha_value          = alpha,
                                               atoms_in_compound    = 1,
                                               atoms_in_co2         = 2,
                                               atoms_in_ch4         = 0,
                                               conc_corr_compound   = conc_avg_corr_ch3oh,
                                               conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                               conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                               conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                               conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_o_ch3oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                   alpha_value_rsd          = alpha_rsd,
                                                   atoms_in_co2             = 2,
                                                   atoms_in_ch4             = 0,
                                                   conc_corr_compound_rsd   = conc_avg_corr_ch3oh_rsd,
                                                   conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                   conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                   conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                   conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                   conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                   conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                   conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                   conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_o_ch3oh_sd  <- selec_o_ch3oh_rsd * selec_o_ch3oh
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "CH3OH" & state == "plasma", selec_o_ch3oh, selec_o),
                   selec_o_sd  = ifelse(compound == "CH3OH" & state == "plasma", selec_o_ch3oh_sd, selec_o_sd),
                   selec_o_rsd = ifelse(compound == "CH3OH" & state == "plasma", selec_o_ch3oh_rsd, selec_o_rsd))
    
    # CH3OH oxygen yield #
    ######################
    
    yield_o_ch3oh     <- calculate_yield(alpha_value         = alpha,
                                         atoms_in_compound   = 1,
                                         atoms_in_co2        = 2,
                                         atoms_in_ch4        = 0,
                                         conc_corr_compound  = conc_avg_corr_ch3oh,
                                         conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                         conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_o_ch3oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                             atoms_in_co2           = 2,
                                             atoms_in_ch4           = 0,
                                             conc_corr_compound_rsd = conc_avg_corr_ch3oh_rsd,
                                             conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                             conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                             conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                             conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_o_ch3oh_sd  <- yield_o_ch3oh_rsd * yield_o_ch3oh
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "CH3OH" & state == "plasma", yield_o_ch3oh, yield_o),
                   yield_o_sd  = ifelse(compound == "CH3OH" & state == "plasma", yield_o_ch3oh_sd, yield_o_sd),
                   yield_o_rsd = ifelse(compound == "CH3OH" & state == "plasma", yield_o_ch3oh_rsd, yield_o_rsd))
    
    ####################
    # Ethanol (C2H5OH) #
    ####################
    
    # C2H5OH carbon selectivity #
    #############################
    
    conc_avg_corr_c2h5oh     <- pull_value(data, "plasma", "C2H5OH", "conc_avg_corr")
    conc_avg_corr_c2h5oh_sd  <- pull_value(data, "plasma", "C2H5OH", "conc_avg_corr_sd")
    conc_avg_corr_c2h5oh_rsd <- pull_value(data, "plasma", "C2H5OH", "conc_avg_corr_rsd")
    
    selec_c_c2h5oh     <- calculate_selectivity(alpha_value          = alpha,
                                                atoms_in_compound    = 2,
                                                atoms_in_co2         = 1,
                                                atoms_in_ch4         = 1,
                                                conc_corr_compound   = conc_avg_corr_c2h5oh,
                                                conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_c_c2h5oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                    alpha_value_rsd          = alpha_rsd,
                                                    atoms_in_co2             = 1,
                                                    atoms_in_ch4             = 1,
                                                    conc_corr_compound_rsd   = conc_avg_corr_c2h5oh_rsd,
                                                    conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                    conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                    conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                    conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                    conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                    conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                    conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                    conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_c_c2h5oh_sd  <- selec_c_c2h5oh_rsd * selec_c_c2h5oh
    
    data <- mutate(data,
                   selec_c     = ifelse(compound == "C2H5OH" & state == "plasma", selec_c_c2h5oh, selec_c),
                   selec_c_sd  = ifelse(compound == "C2H5OH" & state == "plasma", selec_c_c2h5oh_sd, selec_c_sd),
                   selec_c_rsd = ifelse(compound == "C2H5OH" & state == "plasma", selec_c_c2h5oh_rsd, selec_c_rsd))
    
    # C2H5OH carbon yield #
    #######################
    
    yield_c_c2h5oh     <- calculate_yield(alpha_value         = alpha,
                                          atoms_in_compound   = 2,
                                          atoms_in_co2        = 1,
                                          atoms_in_ch4        = 1,
                                          conc_corr_compound  = conc_avg_corr_c2h5oh,
                                          conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                          conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_c_c2h5oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                              atoms_in_co2           = 1,
                                              atoms_in_ch4           = 1,
                                              conc_corr_compound_rsd = conc_avg_corr_c2h5oh_rsd,
                                              conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                              conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                              conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_c_c2h5oh_sd  <- yield_c_c2h5oh_rsd * yield_c_c2h5oh
    
    data <- mutate(data,
                   yield_c     = ifelse(compound == "C2H5OH" & state == "plasma", yield_c_c2h5oh, yield_c),
                   yield_c_sd  = ifelse(compound == "C2H5OH" & state == "plasma", yield_c_c2h5oh_sd, yield_c_sd),
                   yield_c_rsd = ifelse(compound == "C2H5OH" & state == "plasma", yield_c_c2h5oh_rsd, yield_c_rsd))
    
    # C2H5OH hydrogen selectivity #
    ###############################
    
    selec_h_c2h5oh     <- calculate_selectivity(alpha_value          = alpha,
                                                atoms_in_compound    = 6,
                                                atoms_in_co2         = 0,
                                                atoms_in_ch4         = 4,
                                                conc_corr_compound   = conc_avg_corr_c2h5oh,
                                                conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_h_c2h5oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                    alpha_value_rsd          = alpha_rsd,
                                                    atoms_in_co2             = 0,
                                                    atoms_in_ch4             = 4,
                                                    conc_corr_compound_rsd   = conc_avg_corr_c2h5oh_rsd,
                                                    conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                    conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                    conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                    conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                    conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                    conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                    conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                    conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_h_c2h5oh_sd  <- selec_h_c2h5oh_rsd * selec_h_c2h5oh
    
    data <- mutate(data,
                   selec_h     = ifelse(compound == "C2H5OH" & state == "plasma", selec_h_c2h5oh, selec_h),
                   selec_h_sd  = ifelse(compound == "C2H5OH" & state == "plasma", selec_h_c2h5oh_sd, selec_h_sd),
                   selec_h_rsd = ifelse(compound == "C2H5OH" & state == "plasma", selec_h_c2h5oh_rsd, selec_h_rsd))
    
    # C2H5OH hydrogen yield #
    #########################
    
    yield_h_c2h5oh     <- calculate_yield(alpha_value         = alpha,
                                          atoms_in_compound   = 6,
                                          atoms_in_co2        = 0,
                                          atoms_in_ch4        = 4,
                                          conc_corr_compound  = conc_avg_corr_c2h5oh,
                                          conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                          conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_h_c2h5oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                              atoms_in_co2           = 0,
                                              atoms_in_ch4           = 4,
                                              conc_corr_compound_rsd = conc_avg_corr_c2h5oh_rsd,
                                              conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                              conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                              conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_h_c2h5oh_sd  <- yield_h_c2h5oh_rsd * yield_h_c2h5oh
    
    data <- mutate(data,
                   yield_h     = ifelse(compound == "C2H5OH" & state == "plasma", yield_h_c2h5oh, yield_h),
                   yield_h_sd  = ifelse(compound == "C2H5OH" & state == "plasma", yield_h_c2h5oh_sd, yield_h_sd),
                   yield_h_rsd = ifelse(compound == "C2H5OH" & state == "plasma", yield_h_c2h5oh_rsd, yield_h_rsd))
    
    # C2H5OH oxygen selectivity #
    #############################
    
    selec_o_c2h5oh     <- calculate_selectivity(alpha_value          = alpha,
                                                atoms_in_compound    = 1,
                                                atoms_in_co2         = 2,
                                                atoms_in_ch4         = 0,
                                                conc_corr_compound   = conc_avg_corr_c2h5oh,
                                                conc_corr_co2_blank  = conc_avg_corr_co2_blank,
                                                conc_corr_co2_plasma = conc_avg_corr_co2_plasma,
                                                conc_corr_ch4_blank  = conc_avg_corr_ch4_blank,
                                                conc_corr_ch4_plasma = conc_avg_corr_ch4_plasma)
    
    selec_o_c2h5oh_rsd <- calculate_selectivity_rsd(alpha_value              = alpha,
                                                    alpha_value_rsd          = alpha_rsd,
                                                    atoms_in_co2             = 2,
                                                    atoms_in_ch4             = 0,
                                                    conc_corr_compound_rsd   = conc_avg_corr_c2h5oh_rsd,
                                                    conc_corr_co2_blank      = conc_avg_corr_co2_blank,
                                                    conc_corr_co2_blank_sd   = conc_avg_corr_co2_blank_sd,
                                                    conc_corr_co2_plasma     = conc_avg_corr_co2_plasma,
                                                    conc_corr_co2_plasma_rsd = conc_avg_corr_co2_plasma_rsd,
                                                    conc_corr_ch4_blank      = conc_avg_corr_ch4_blank,
                                                    conc_corr_ch4_blank_sd   = conc_avg_corr_ch4_blank_sd,
                                                    conc_corr_ch4_plasma     = conc_avg_corr_ch4_plasma,
                                                    conc_corr_ch4_plasma_rsd = conc_avg_corr_ch4_plasma_rsd)
    
    selec_o_c2h5oh_sd  <- selec_o_c2h5oh_rsd * selec_o_c2h5oh
    
    data <- mutate(data,
                   selec_o     = ifelse(compound == "C2H5OH" & state == "plasma", selec_o_c2h5oh, selec_o),
                   selec_o_sd  = ifelse(compound == "C2H5OH" & state == "plasma", selec_o_c2h5oh_sd, selec_o_sd),
                   selec_o_rsd = ifelse(compound == "C2H5OH" & state == "plasma", selec_o_c2h5oh_rsd, selec_o_rsd))
    
    # C2H5OH oxygen yield #
    ######################
    
    yield_o_c2h5oh     <- calculate_yield(alpha_value         = alpha,
                                          atoms_in_compound   = 1,
                                          atoms_in_co2        = 2,
                                          atoms_in_ch4        = 0,
                                          conc_corr_compound  = conc_avg_corr_c2h5oh,
                                          conc_corr_co2_blank = conc_avg_corr_co2_blank,
                                          conc_corr_ch4_blank = conc_avg_corr_ch4_blank)
    
    yield_o_c2h5oh_rsd <- calculate_yield_rsd(alpha_value_rsd        = alpha_rsd,
                                              atoms_in_co2           = 2,
                                              atoms_in_ch4           = 0,
                                              conc_corr_compound_rsd = conc_avg_corr_c2h5oh_rsd,
                                              conc_corr_co2_blank    = conc_avg_corr_co2_blank,
                                              conc_corr_co2_blank_sd = conc_avg_corr_co2_blank_sd,
                                              conc_corr_ch4_blank    = conc_avg_corr_ch4_blank,
                                              conc_corr_ch4_blank_sd = conc_avg_corr_ch4_blank_sd)
    
    yield_o_c2h5oh_sd  <- yield_o_c2h5oh_rsd * yield_o_c2h5oh
    
    data <- mutate(data,
                   yield_o     = ifelse(compound == "C2H5OH" & state == "plasma", yield_o_c2h5oh, yield_o),
                   yield_o_sd  = ifelse(compound == "C2H5OH" & state == "plasma", yield_o_c2h5oh_sd, yield_o_sd),
                   yield_o_rsd = ifelse(compound == "C2H5OH" & state == "plasma", yield_o_c2h5oh_rsd, yield_o_rsd))
    
    #####################
    # H2:CO yield ratio #
    #####################
    
    # Calculation of the yield ratio
    yield_ratio     <- yield_h_h2 / yield_c_co
    
    # Calculation of the RSD of the ratio
    yield_ratio_rsd <- sqrt(yield_c_co_rsd ^ 2 + yield_h_h2_rsd ^ 2)
    
    # Calculation of the SD of the ratio
    yield_ratio_sd  <- yield_ratio_rsd * yield_ratio
    
    # Add these numbers to the data
    data <- mutate(data,
                   yield_ratio     = yield_ratio,
                   yield_ratio_sd  = yield_ratio_sd,
                   yield_ratio_rsd = yield_ratio_rsd,
                   .after = yield_h_rsd)
    
    ##################
    # Carbon balance #
    ##################
    
    # Calculation of the carbon balance
    balance_c_data <- unique(select(filter(data, atoms_c != 0), state, compound, atoms_c, conc_avg_corr, conc_avg_corr_sd))
    balance_c      <- alpha * sum(filter(balance_c_data, state == "plasma")$atoms_c * filter(balance_c_data, state == "plasma")$conc_avg_corr, na.rm = T) /
      sum(filter(balance_c_data, state == "blank")$atoms_c * filter(balance_c_data, state == "blank")$conc_avg_corr, na.rm = T)
    
    # Calculation of the RSD of the C-balance
    balance_c_rsd  <- sqrt(
      alpha_rsd ^ 2 +
        sum(filter(balance_c_data, state == "plasma")$atoms_c ^ 2 * filter(balance_c_data, state == "plasma")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_c_data, state == "plasma")$atoms_c * filter(balance_c_data, state == "plasma")$conc_avg_corr, na.rm = T) ^ 2 +
        sum(filter(balance_c_data, state == "blank")$atoms_c ^ 2 * filter(balance_c_data, state == "blank")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_c_data, state == "blank")$atoms_c * filter(balance_c_data, state == "blank")$conc_avg_corr, na.rm = T) ^ 2
    )
    
    # Calculation of the SD of the C-balance
    balance_c_sd   <- balance_c_rsd * balance_c
    
    # Add these numbers to the data
    data <- mutate(data,
                   balance_c     = balance_c,
                   balance_c_sd  = balance_c_sd,
                   balance_c_rsd = balance_c_rsd,
                   .after = yield_ratio_rsd)
    
    ##################
    # Oxygen balance #
    ##################
    
    balance_o_data <- unique(select(filter(data, atoms_o != 0), state, compound, atoms_o, conc_avg_corr, conc_avg_corr_sd))
    balance_o      <- alpha * sum(filter(balance_o_data, state == "plasma")$atoms_o * filter(balance_o_data, state == "plasma")$conc_avg_corr, na.rm = T) /
      sum(filter(balance_o_data, state == "blank")$atoms_o * filter(balance_o_data, state == "blank")$conc_avg_corr, na.rm = T)
    
    balance_o_rsd  <- sqrt(
      alpha_rsd ^ 2 +
        sum(filter(balance_o_data, state == "plasma")$atoms_o ^ 2 * filter(balance_o_data, state == "plasma")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_o_data, state == "plasma")$atoms_o * filter(balance_o_data, state == "plasma")$conc_avg_corr, na.rm = T) ^ 2 +
        sum(filter(balance_o_data, state == "blank")$atoms_o ^ 2 * filter(balance_o_data, state == "blank")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_o_data, state == "blank")$atoms_o * filter(balance_o_data, state == "blank")$conc_avg_corr, na.rm = T) ^ 2
    )
    
    balance_o_sd   <- balance_o_rsd * balance_o
    
    data <- mutate(data,
                   balance_o     = balance_o,
                   balance_o_sd  = balance_o_sd,
                   balance_o_rsd = balance_o_rsd,
                   .after = balance_c_rsd)
    
    ####################
    # Hydrogen balance #
    ####################
    
    balance_h_data <- unique(select(filter(data, atoms_h != 0), state, compound, atoms_h, conc_avg_corr, conc_avg_corr_sd))
    balance_h      <- alpha * sum(filter(balance_h_data, state == "plasma")$atoms_h * filter(balance_h_data, state == "plasma")$conc_avg_corr, na.rm = T) /
      sum(filter(balance_h_data, state == "blank")$atoms_h * filter(balance_h_data, state == "blank")$conc_avg_corr, na.rm = T)
    
    balance_h_rsd  <- sqrt(
      alpha_rsd ^ 2 +
        sum(filter(balance_h_data, state == "plasma")$atoms_h ^ 2 * filter(balance_h_data, state == "plasma")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_h_data, state == "plasma")$atoms_h * filter(balance_h_data, state == "plasma")$conc_avg_corr, na.rm = T) ^ 2 +
        sum(filter(balance_h_data, state == "blank")$atoms_h ^ 2 * filter(balance_h_data, state == "blank")$conc_avg_corr_sd ^ 2, na.rm = T) /
        sum(filter(balance_h_data, state == "blank")$atoms_h * filter(balance_h_data, state == "blank")$conc_avg_corr, na.rm = T) ^ 2
    )
    
    balance_h_sd   <- balance_h_rsd * balance_h
    
    data <- mutate(data,
                   balance_h     = balance_h,
                   balance_h_sd  = balance_h_sd,
                   balance_h_rsd = balance_h_rsd,
                   .after = balance_o_rsd)
    
    ###############################
    # Specific Energy Input (SEI) #
    ###############################
    
    # Calculation the average plasma power, its SD and its RSD
    data <- data %>%
      group_by(state, compound) %>%
      mutate(plasma_power_watt_avg = ifelse(state == "blank", NA, mean(plasma_power_watt, na.rm = T)),
             plasma_power_watt_sd  = ifelse(state == "blank", NA, sd(plasma_power_watt, na.rm = T)),
             plasma_power_rsd      = ifelse(state == "blank", NA, plasma_power_watt_sd / plasma_power_watt_avg),
             .after = plasma_power_watt) %>%
      ungroup()
    
    # Take average power level, SD and RSD (compound does not matter, can be any)
    plasma_power_avg <- pull_value(data, "plasma", "CO2", "plasma_power_watt_avg")
    plasma_power_sd  <- pull_value(data, "plasma", "CO2", "plasma_power_watt_sd")
    plasma_power_rsd <- pull_value(data, "plasma", "CO2", "plasma_power_rsd")
    
    # Ugly way of adding the plasma power to the row of the total conversion
    data <- data %>%
      mutate(plasma_power_watt_avg = ifelse(state=="plasma", plasma_power_avg, NA),
             plasma_power_watt_sd  = ifelse(state=="plasma", plasma_power_sd, NA),
             plasma_power_rsd = ifelse(state=="plasma", plasma_power_rsd, NA))
    
    # Calculate SEI (J/mmol same as kJ/mol) (molar gas volume at 1 atm & 20°C) and its SD and RSD
    sei     <- (plasma_power_avg / (flow_co2 + flow_ch4)) * 60 * 24.055
    sei_rsd <- sqrt(plasma_power_rsd ^ 2 + (flow_co2_sd ^ 2 + flow_ch4_sd ^ 2) / (flow_co2 + flow_ch4) ^ 2)
    sei_sd  <- sei_rsd * sei
    
    # Adding values to the data
    data <- mutate(data,
                   sei_kjmol    = ifelse(state == "plasma", sei, NA),
                   sei_kjmol_sd = ifelse(state == "plasma", sei_sd, NA),
                   sei_rsd      = ifelse(state == "plasma", sei_rsd, NA),
                   .after = plasma_power_rsd)
    
    #####################
    # Energy efficiency #
    #####################
    
    # Plasma temperature (K) now set at 200°C
    plasma_temp_kelv <- 273.15 + unique(data$plasma_temp_celc)
    
    # Gibbs Free Enthalpy of Formation of compounds in function of temperature (sixth order polynomial fit from NIST-JANAF data)
    gf_co      <- -1.48747E-20*(plasma_temp_kelv ^ 6) + 2.90543E-16*(plasma_temp_kelv ^ 5) - 2.18412E-12*(plasma_temp_kelv ^ 4) + 7.80039E-09*(plasma_temp_kelv ^ 3) - 1.14364E-05*(plasma_temp_kelv ^ 2) - 8.19286E-02*plasma_temp_kelv - 1.12455E+02
    gf_co2     <-  1.21850E-21*(plasma_temp_kelv ^ 6) - 2.63973E-17*(plasma_temp_kelv ^ 5) + 2.25893E-13*(plasma_temp_kelv ^ 4) - 9.56091E-10*(plasma_temp_kelv ^ 3) + 2.75906E-06*(plasma_temp_kelv ^ 2) - 4.68102E-03*plasma_temp_kelv - 3.93205E+02
    gf_ch4     <-  4.80094E-20*(plasma_temp_kelv ^ 6) - 9.80918E-16*(plasma_temp_kelv ^ 5) + 7.88569E-12*(plasma_temp_kelv ^ 4) - 3.14933E-08*(plasma_temp_kelv ^ 3) + 6.47785E-05*(plasma_temp_kelv ^ 2) + 4.77680E-02*plasma_temp_kelv - 6.92593E+01
    gf_c2h6    <- -32.9
    gf_c2h4    <-  2.54394E-20*(plasma_temp_kelv ^ 6) - 5.36461E-16*(plasma_temp_kelv ^ 5) + 4.48934E-12*(plasma_temp_kelv ^ 4) - 1.88332E-08*(plasma_temp_kelv ^ 3) + 4.14627E-05*(plasma_temp_kelv ^ 2) + 3.84775E-02*plasma_temp_kelv + 5.37924E+01
    gf_c2h2    <-  1.56648E-21*(plasma_temp_kelv ^ 6) - 3.97814E-17*(plasma_temp_kelv ^ 5) + 4.10279E-13*(plasma_temp_kelv ^ 4) - 2.17928E-09*(plasma_temp_kelv ^ 3) + 6.79746E-06*(plasma_temp_kelv ^ 2) - 6.26320E-02*plasma_temp_kelv + 2.27284E+02
    gf_c3h8    <- -23.4
    gf_c3h6    <-  74.7
    gf_c3h4    <-  194.2
    gf_ch3oh   <- -166.4
    gf_c2h5oh  <- -174.9
    gf_ch3och3 <- -114.1
    
    
    data <- mutate(data,
                   gf = ifelse(compound == "CO", gf_co, 0),
                   gf = ifelse(compound == "CO2", gf_co2, gf),
                   gf = ifelse(compound == "CH4", gf_ch4, gf),
                   gf = ifelse(compound == "C2H6", gf_c2h6, gf),
                   gf = ifelse(compound == "C2H4", gf_c2h4, gf),
                   gf = ifelse(compound == "C2H2", gf_c2h2, gf),
                   gf = ifelse(compound == "C3H8", gf_c3h8, gf),
                   gf = ifelse(compound == "C3H6", gf_c3h6, gf),
                   gf = ifelse(compound == "C3H4", gf_c3h4, gf),
                   gf = ifelse(compound == "CH3OH", gf_ch3oh, gf),
                   gf = ifelse(compound == "C2H5OH", gf_c2h5oh, gf),
                   gf = ifelse(compound == "CH3OCH3", gf_ch3och3, gf),
                   .after = sei_rsd)
    
    # Energy efficiency (%) based on the Gibbs free enthalpies of formation of reactant and products (used in scientific settings)
    
    ee_gf_perc <- (alpha *
                     sum(
                       unique(
                         filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
                           filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$gf
                       ),
                       na.rm = T
                     )
                   -
                     sum(
                       unique(
                         filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$conv *
                           filter(data, state == "blank"  & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                           filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$gf
                       ),
                       na.rm = T
                     )
    ) / sei * 100
    
    ee_gf_rsd  <- sqrt(
      sei_rsd ^ 2 +
        (
          sum(
            unique(
              (
                alpha_rsd ^ 2 + filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr_rsd ^ 2
              ) *
                (
                  alpha *
                    filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
                    filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$gf
                ) ^ 2
            ),
            na.rm = T
          )
          +
            sum(
              unique(
                (
                  filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$conv_rsd ^ 2 +
                    filter(data, state == "blank"  & compound %in% c("CH4", "CO2"))$conc_avg_corr_rsd ^ 2
                )
                *
                  (
                    filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$conv *
                      filter(data, state == "blank"  & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                      filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$gf
                  ) ^ 2
              ),
              na.rm = T
            )
        )
      /
        (
          alpha *
            sum(
              unique(
                filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
                  filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$gf
              ),
              na.rm = T
            )
          -
            sum(
              unique(
                filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$conv *
                  filter(data, state == "blank"  & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                  filter(data, state == "plasma" & compound %in% c("CH4", "CO2"))$gf
              ),
              na.rm = T
            )
        ) ^ 2
    )
    
    
    ee_gf_perc_sd <- ee_gf_rsd * ee_gf_perc
    
    data <- mutate(data,
                   ee_gf_perc    = ifelse(state == "plasma", ee_gf_perc, NA),
                   ee_gf_perc_sd = ifelse(state == "plasma", ee_gf_perc_sd, NA),
                   ee_gf_rsd     = ifelse(state == "plasma", ee_gf_rsd, NA),
                   .after = plasma_temp_celc)
    
    # Energy efficiency (%) based on the Lower Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry
    
    lhv_h2   <- 246.47
    lhv_co   <- 289.5
    lhv_ch4  <- 815.61
    lhv_c2h6 <- 1460.9
    lhv_c2h4 <- 1371.3
    
    data <- mutate(data,
                   lhv = ifelse(compound == "H2", lhv_h2, 0),
                   lhv = ifelse(compound == "CO", lhv_co, lhv),
                   lhv = ifelse(compound == "CH4", lhv_ch4, lhv),
                   lhv = ifelse(compound == "C2H6", lhv_c2h6, lhv),
                   lhv = ifelse(compound == "C2H4", lhv_c2h4, lhv),
                   .after = gf)
    
    ee_lhv_perc    <- alpha *
      sum(
        unique(
          filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
            filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$lhv
        ),
        na.rm = T
      ) /
      (
        sei +
          sum(
            unique(
              filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$lhv
            ),
            na.rm = T
          )
      ) * 100
    ee_lhv_rsd   <- sqrt(
      sum(
        unique(
          (
            alpha_rsd ^ 2 +
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr_rsd ^ 2
          ) *
            (
              alpha *
                filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
                filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$lhv
            ) ^ 2
        ),
        na.rm = T
      ) /
        sum(
          unique(
            alpha *
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$lhv
          ),
          na.rm = T
        ) ^ 2 +
        (
          sei_sd ^ 2 + sum(
            unique(
              filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr_sd ^ 2 *
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$lhv ^ 2
            ),
            na.rm = T
          )
        ) /
        (
          sei +
            sum(
              unique(
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                  filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$lhv
              ),
              na.rm = T
            )
        ) ^ 2
    )
    
    ee_lhv_perc_sd <- ee_lhv_rsd * ee_lhv_perc
    
    data <- mutate(data,
                   ee_lhv_perc    = ifelse(state == "plasma", ee_lhv_perc, NA),
                   ee_lhv_perc_sd = ifelse(state == "plasma", ee_lhv_perc_sd, NA),
                   ee_lhv_rsd     = ifelse(state == "plasma", ee_lhv_rsd, NA),
                   .after = ee_gf_rsd)
    
    # Energy efficiency (%) based on the Higher Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry
    # LHV and HHV values for CO are the same
    
    hhv_h2   <- 291.28
    hhv_co   <- 289.5
    hhv_ch4  <- 906.13
    hhv_c2h6 <- 1598.0
    hhv_c2h4 <- 1461.8
    
    data <- mutate(data,
                   hhv = ifelse(compound == "H2", hhv_h2, 0),
                   hhv = ifelse(compound == "CO", hhv_co, hhv),
                   hhv = ifelse(compound == "CH4", hhv_ch4, hhv),
                   hhv = ifelse(compound == "C2H6", hhv_c2h6, hhv),
                   hhv = ifelse(compound == "C2H4", hhv_c2h4, hhv),
                   .after = lhv)
    
    ee_hhv_perc    <- alpha *
      sum(
        unique(
          filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
            filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$hhv
        ),
        na.rm = T
      ) /
      (
        sei +
          sum(
            unique(
              filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$hhv
            ),
            na.rm = T
          )
      ) * 100
    
    ee_hhv_rsd <- sqrt(
      sum(
        unique(
          (
            alpha_rsd ^ 2 +
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr_rsd ^ 2
          ) *
            (
              alpha *
                filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
                filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$hhv
            ) ^ 2
        ),
        na.rm = T
      ) /
        sum(
          unique(
            alpha *
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$conc_avg_corr *
              filter(data, state == "plasma" & !(compound %in% c("CH4", "CO2", "N2")))$hhv
          ),
          na.rm = T
        ) ^ 2 +
        (
          sei_sd ^ 2 + sum(
            unique(
              filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr_sd ^ 2 *
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$hhv ^ 2
            ),
            na.rm = T
          )
        ) /
        (
          sei +
            sum(
              unique(
                filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$conc_avg_corr *
                  filter(data, state == "blank" & compound %in% c("CH4", "CO2"))$hhv
              ),
              na.rm = T
            )
        ) ^ 2
    )
    
    ee_hhv_perc_sd <- ee_hhv_rsd * ee_hhv_perc
    
    data <- mutate(data,
                   ee_hhv_perc    = ifelse(state == "plasma", ee_hhv_perc, NA),
                   ee_hhv_perc_sd = ifelse(state == "plasma", ee_hhv_perc_sd, NA),
                   ee_hhv_rsd     = ifelse(state == "plasma", ee_hhv_rsd, NA),
                   .after = ee_lhv_rsd)
    
    ############################################
    # Write the calculated data to a .csv file #
    ############################################
    
    # Shorten data by deselecting columns not needed for creating data overviews
    data_short <- data %>%
      filter(state == "plasma") %>%
      select(!c(
        state,
        flow_mlmin_sd,
        flow_max_mlmin,
        #contains("flow"),
        conc,
        conc_avg,
        conc_sd,
        #contains("conc"),
        alpha_sd,
        plasma_power_watt,
        source_power_watt,
        contains("rsd"),
        contains("atoms"),
        contains("beta"),
        gf,
        lhv,
        hhv
      )) %>%
      unique()
    
    write_csv(data, gsub(".csv", "-calc.csv", filename))
    write_csv(data_short, gsub(".csv", "-calc-short.csv", filename))
  },
  error = function(e) {
    # Handle the error
    message(sprintf("Error in file %s: %s", filename, e$message))
    return(NULL)  # Return NULL or any other appropriate value
  })
}

# Set working directory and list all files
setwd(file.path("N:", "FWET", "FDCH", "AdsCatal", "General", "personal_work_folders", "plasmacatdesign", "drm", "ugent", "sasol-1.8-fe2o3-02%", "pwr-const"))
all_files <- list.files(pattern = "\\d+\\.\\ds-\\d+\\.csv")

# Create a cluster (number of cores to use)
no_cores <- detectCores() - 1 # leave one core free for system stability
cl <- makeCluster(no_cores)

# Export required variables and functions to each worker in the cluster
clusterExport(cl, varlist = c("process_file"))
clusterEvalQ(cl, {
  library(tidyverse)
  source('N:/FWET/FDCH/AdsCatal/General/personal_work_folders/plasmacatdesign/scripts/scripts-R/dry-reforming-methane/dry-reforming-methane-functions.R')
})

# Apply the function to all files using parLapply
results <- parLapply(cl, all_files, process_file)

# Stop the cluster
stopCluster(cl)