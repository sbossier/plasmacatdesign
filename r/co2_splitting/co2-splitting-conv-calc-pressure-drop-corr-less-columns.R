# Never remove raw data, only expand on the .csv-file

# Load necessary packages
library(tidyverse)

# Clear workspace
rm(list=ls())

# Read in starting data & replace different ways of writing zero with a NA (ugly done, maybe by using regex it could be more elegantly done)
filename <- "res-time-62.5s-1.csv"
data <- read_csv(filename, na = c("0", "0.0","0.00","0.000","0.0000","0.00000"))

#######################################################################################################################
# calculate average concentration, standard deviation, and relative standard deviation for each compound in each test #
#######################################################################################################################

# na.rm = T is added to ignore NA's
data <- data %>%
  group_by(name, compound) %>%
  mutate(concAvg = mean(concentration, na.rm = T) ,
         concSD = sd(concentration, na.rm = T) ,
         concRSD = concSD / concAvg) %>%
  ungroup()

#################################################################
# calculate beta and its standard & relative standard deviation #
#################################################################

# Note 1: 0.005 is the Reading Accuracy of the F-201CV MFCs & 0.001 is the Full Scale value of the F-201CV MFCs (you can find these values on the product page of the MFCs of your choice),
#         all flow (so +/- 100% of flow values according to normal distribution) fall between the sumation for these two errors.

# Note 2: 3.890592 is the z-value for which 99.99% of values fall within a normal curve.

# Note 3: their is no error on beta, as any error from the error on gas flow is indirectly present in the measured concentrations by the GC

data <- data %>%
  mutate( flowSD = ( .005 * flow + .001 * flowMax ) / qnorm(.99995) ,
          flowRSD = flowSD / flow )

# select average N2 concentrations from blank experiment
concAvgN2Blank <- data %>%
  filter(name == "blank" & compound == "N2") %>%
  pull(concAvg) %>%
  unique()

# Select average CO2 concentration from blank experiment
concAvgCO2Blank <- data %>%
  filter(name == "blank" & compound == "CO2") %>%
  pull(concAvg) %>%
  unique()

# calculating beta as the ratio between the concentration of N2 and CO2 as measured by the GC, corrects for the pressure drop across the (packed) reactor (is assume)

data <- data %>%
  mutate( betaValue = concAvgN2Blank / concAvgCO2Blank ,
          betaValueSD = 0 ,
          betaValueRSD = 0 )

##################################################################
# calculate alpha and its standard & relative standard deviation #
##################################################################

# Firstly, we pull all the necessary numbers for the calculations

# select relative standard deviation of the N2 concentration from the blank experiment
concAvgN2BlankRSD <- data %>%
  filter(name == "blank" & compound == "N2") %>%
  pull(concRSD) %>%
  unique()

# select average N2 concentrations from plasma experiment
concAvgN2Plasma <- data %>%
  filter(name == "plasma" & compound == "N2") %>%
  pull(concAvg) %>%
  unique()

# select relative standard deviation of the N2 concentration from the plasma
concAvgN2PlasmaRSD <- data %>%
  filter(name == "plasma" & compound == "N2") %>%
  pull(concRSD) %>%
  unique()

# Secondly, we calculate alpha and set its SD and RSD to 0 (the error on alpha is indirectly present in the error on the concentrations determined by the GC)
# For the blank experiments alpha is equal to 1 (there is no gas expansion)

data <- data %>%
  mutate( alphaValue = ifelse(name == "blank", 1, concAvgN2Blank / concAvgN2Plasma * (1 + betaValue) - betaValue) ,
          alphaValueSD = 0 ,
          alphaValueRSD = 0 )

# From the data, obtain alpha and its RSD

alphaCalc <- data %>%
  filter(name == "plasma") %>%
  pull(alphaValue) %>%
  unique()

alphaCalc <- ifelse(alphaCalc<1,1,alphaCalc)

alphaCalcRSD <- 0

########################################################
# calculate corrected concentrations for the compounds #
########################################################

# Calculation of the corrected average concentrations of CO2, CO, and O2 entering and leaving the reactor
# and the N2 concentration upon addition as internal standard
# This correction however, has no physical meaning for N2, so to avoid confusion, we'll delete is for N2

data <- data %>%
  mutate( concAvgCorr = ifelse(compound == "N2", NA, concAvg * ( 1 + betaValue / alphaValue ) ) ,
          concAvgCorrSD = ifelse(compound == "N2", NA, sqrt(
            ( betaValueRSD ^ 2 + alphaValueRSD ^ 2 )
            *
              ( betaValue / alphaValue ) ^ 2
            /
              ( 1 + betaValue / alphaValue ) ^ 2
            +
              concRSD ^ 2) * concAvgCorr ) ,
          concAvgCorrRSD = ifelse(compound == "N2", NA, concAvgCorrSD / concAvgCorr ) )

##########################
# Calculating conversion # in this case only for CO2
##########################

# Filter the data to keep only the CO2 data (without deleting the rest)

dataCO2 <- data %>%
  filter(compound == "CO2") %>%
  distinct(concAvgCorr, .keep_all = T)

# Obtain also the corrected concentration of CO2 in the blank measurement and its RSD

concAvgCorrCO2Blank <- dataCO2 %>%
  filter(name == "blank") %>%
  pull(concAvgCorr)

concAvgCorrCO2BlankRSD <- dataCO2 %>%
  filter(name == "blank") %>%
  pull(concAvgCorrRSD)

# Obtain also the corrected concentration of CO2 in the plasma measurement and its RSD

concAvgCorrCO2Plasma <- dataCO2 %>%
  filter(name == "plasma") %>%
  pull(concAvgCorr)

concAvgCorrCO2PlasmaRSD <- dataCO2 %>%
  filter(name == "plasma") %>%
  pull(concAvgCorrRSD)

# Calculate the CO2 conversion from these numbers

convCO2 <- 1 - alphaCalc * ( concAvgCorrCO2Plasma / concAvgCorrCO2Blank )

# Calculate the standard deviation on the CO2 conversion

convCO2SD <- sqrt( concAvgCorrCO2BlankRSD ^ 2 + concAvgCorrCO2PlasmaRSD ^ 2 + alphaCalcRSD ^ 2) *
  alphaCalc *
  ( concAvgCorrCO2Plasma / concAvgCorrCO2Blank )

# Calculate the relative standard deviation on the CO2 conversion

convCO2RSD <- convCO2SD / convCO2

# Add these numbers to the data for CO2

data <- data %>%
  mutate(conv = ifelse(compound == "CO2" & name == "plasma", convCO2, NA) ,
         convSD = ifelse(compound == "CO2" & name == "plasma", convCO2SD, NA) ,
         convRSD = ifelse(compound == "CO2" & name == "plasma", convCO2RSD, NA))

#################################################
# Calculate CO2 conversion using Snoeckx method #
#################################################

# X_CO2 = X_GC / ( ( 1 + gamma / 2 ) - ( gamma / 2 ) * X_GC )
# with gamma = ( co2flow ) / ( n2flow + co2flow )
# and X_GC = 1 - c_GC,plasma / c_GC,blank

# Calculate gamma

gamma <- concAvgCO2Blank / ( concAvgCO2Blank + concAvgN2Blank )

# Calculate the CO2 conversion measured by GC (no corrections)

concAvgCO2Blank <- data %>%
  filter(name == "blank" & compound == "CO2") %>%
  pull(concAvg) %>%
  unique()

concRSDCO2Blank <- data %>%
  filter(name == "blank" & compound == "CO2") %>%
  pull(concRSD) %>%
  unique()

concAvgCO2Plasma <- data %>%
  filter(name == "plasma" & compound == "CO2") %>%
  pull(concAvg) %>%
  unique()

concRSDCO2Plasma <- data %>%
  filter(name == "plasma" & compound == "CO2") %>%
  pull(concRSD) %>%
  unique()

convCO2GC <- 1 - ( concAvgCO2Plasma / concAvgCO2Blank )

convCO2GCRSD <- sqrt(
  concRSDCO2Blank ^ 2 + concRSDCO2Plasma ^ 2
)

convCO2GCSD <- convCO2GCRSD * convCO2GC

# calculation of the CO2 conversion according to the method by Snoeckx

convCO2Snoeckx <- convCO2GC / ( (1 + gamma / 2 ) - ( gamma / 2 ) * convCO2GC )

convCO2SnoeckxRSD <- sqrt(
  convCO2GCRSD ^ 2 +
    ( ( convCO2GCRSD * (gamma / 2 ) * convCO2GC ) / ( ( 1 + gamma / 2 ) - ( gamma / 2 ) * convCO2GC ) ) ^ 2
)

convCO2SnoeckxSD <- convCO2SnoeckxRSD * convCO2Snoeckx

data <- data %>%
  mutate(convCO2Snoeckx = ifelse(name == "plasma" & compound == "CO2", convCO2Snoeckx, NA) ,
         convCO2SnoeckxSD = ifelse(name == "plasma" & compound == "CO2", convCO2SnoeckxSD, NA) ,
         convCO2SnoeckxRSD = ifelse(name == "plasma" & compound == "CO2", convCO2SnoeckxRSD, NA))

###################
# Carbon Monoxide #
###################

# Carbon selectivity #
######################

# Alpha and its RSD have already been obtained and are put in the alphaCalc & alphaCalcRSD objects

# The corrected concentration of CO2 in the blank measurements is put in concAvgCorrCO2Blank

# The standard deviation on the corrected CO2 concentration for blank measurements must be obtained

concAvgCorrCO2BlankSD <- dataCO2 %>%
  filter(name == "blank") %>%
  pull(concAvgCorrSD)

# The corrected concentration of CO2 from the plasma measurments is put in concAvgCorrCO2Plasma

# The relative standard deviation on the corrected CO2 concentration for the plasma measurements is put in the object concAvgCorrCO2PlasmaRSD

# From the data, the concentration of CO in plasma experiments must be obtained

concAvgCorrCO <- data %>%
  filter(name == "plasma" & compound == "CO") %>%
  pull(concAvgCorr) %>%
  unique()

# From the data, the RSD of the corrected CO concentration must also be obtained

concAvgCorrCORSD <- data %>%
  filter(name == "plasma" & compound == "CO") %>%
  pull(concAvgCorrRSD) %>%
  unique()

# The CO selectivity can be calculated as follows

CselecCO <- ( alphaCalc * concAvgCorrCO ) / ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma )

# The RSD of the CO selectivity can be calucated as follows

CselecCORSD <- sqrt(
  ( alphaCalcRSD ^ 2 + concAvgCorrCORSD ^ 2)
  +
    (
      ( ( alphaCalcRSD ^ 2 + concAvgCorrCO2PlasmaRSD ^ 2) * alphaCalc ^ 2 * concAvgCorrCO2Plasma ^ 2 + concAvgCorrCO2BlankSD ^ 2)
      /
        ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma ) ^ 2
    )
)

# The SD of the CO selectivity can be calculated then as follows

CselecCOSD <- CselecCORSD * CselecCO

# Add these numbers to the data

data <- data %>%
  mutate(Cselec = ifelse(compound == "CO" & name == "plasma", CselecCO, NA) ,
         CselecSD = ifelse(compound == "CO" & name == "plasma", CselecCOSD, NA) ,
         CselecRSD = ifelse(compound == "CO" & name == "plasma", CselecCORSD, NA))

# Carbon yield #
################

# These calucations are simplyfied by the fact that the yield of CO is the product
# of the conversion of CO2 and the selectivity of CO, both numbers which are already
# stored in objects, just like their SD and RSD

CyieldCO <- convCO2 * CselecCO

CyieldCORSD <- sqrt(
  convCO2RSD ^ 2 + CselecCORSD ^ 2
)

CyieldCOSD <- CyieldCORSD * CyieldCO

# Add these numbers to the data

data <- data %>%
  mutate(Cyield = ifelse(compound == "CO" & name == "plasma", CyieldCO, NA) ,
         CyieldSD = ifelse(compound == "CO" & name == "plasma", CyieldCOSD, NA) ,
         CyieldRSD = ifelse(compound == "CO" & name == "plasma", CyieldCORSD, NA) )

# Oxygen selectivity #
######################

# Alpha and its RSD have already been obtained and are put in the alphaCalc & alphaCalcRSD objects

# The corrected concentration of CO2 in the blank measurements is put in concAvgCorrCO2Blank

# The standard deviation on the corrected CO2 concentration for blank measurements is put in the object concAVGCorrCO2BlankSD

# The corrected concentration of CO2 from the plasma measurments is put in concAvgCorrCO2Plasma

# The relative standard deviation on the corrected CO2 concentration for the plasma measurements is put in the object concAvgCorrCO2PlasmaRSD

# The concentration of CO in plasma experiments is put in the object concAvgCorrCO

# The RSD of the corrected CO concentration is put in object concAvgCorrCORSD

# The CO oxygen-selectivity can be calculated as follows

OselecCO <- ( alphaCalc * concAvgCorrCO ) / ( 2* ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma ) )

# The RSD of the CO oxygen-selectivity can be calucated as follows

OselecCORSD <- sqrt(
  ( alphaCalcRSD ^ 2 + concAvgCorrCORSD ^ 2)
  +
    (
      ( ( alphaCalcRSD ^ 2 + concAvgCorrCO2PlasmaRSD ^ 2) * alphaCalc ^ 2 * concAvgCorrCO2Plasma ^ 2 + concAvgCorrCO2BlankSD ^ 2)
      /
        ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma ) ^ 2
    )
)

# The SD of the CO selectivity can be calculated then as follows

OselecCOSD <- OselecCORSD * OselecCO

# Add these numbers to the data

data <- data %>%
  mutate(Oselec = ifelse(compound == "CO" & name == "plasma", OselecCO, NA) ,
         OselecSD = ifelse(compound == "CO" & name == "plasma", OselecCOSD, NA) ,
         OselecRSD = ifelse(compound == "CO" & name == "plasma", OselecCORSD, NA) )

# Oxygen yield #
################

# These calucations are simplyfied by the fact that the oxygen-yield of CO is the product
# of the conversion of CO2 and the oxygen-selectivity of CO, both numbers which are already
# stored in objects, just like their SD and RSD

OyieldCO <- convCO2 * OselecCO

OyieldCORSD <- sqrt(
  convCO2RSD ^ 2 + OselecCORSD ^ 2
)

OyieldCOSD <- OyieldCORSD * OyieldCO

# Add these numbers to the data

data <- data %>%
  mutate(Oyield = ifelse(compound == "CO" & name == "plasma", OyieldCO, NA) ,
         OyieldSD = ifelse(compound == "CO" & name == "plasma", OyieldCOSD, NA) ,
         OyieldRSD = ifelse(compound == "CO" & name == "plasma", OyieldCORSD, NA) )

##########
# Oxygen #
##########

# Oxygen selectivity #
######################

# Alpha and its RSD have already been obtained and are put in the alphaCalc & alphaCalcRSD objects

# The corrected concentration of CO2 in the blank measurements is put in concAvgCorrCO2Blank

# The standard deviation on the corrected CO2 concentration for blank measurements is put in the object concAVGCorrCO2BlankSD

# The corrected concentration of CO2 from the plasma measurments is put in concAvgCorrCO2Plasma

# The relative standard deviation on the corrected CO2 concentration for the plasma measurements is put in the object concAvgCorrCO2PlasmaRSD

# The concentration of O2 in plasma experiments is put in the object concAvgCorrO2

concAvgCorrO2 <- data %>%
  filter(name == "plasma" & compound == "O2") %>%
  pull(concAvgCorr) %>%
  unique()

# The RSD of the corrected O2 concentration is put in object concAvgCorrO2RSD

concAvgCorrO2RSD <- data %>%
  filter(name == "plasma" & compound == "O2") %>%
  pull(concAvgCorrRSD) %>%
  unique()

# The CO oxygen-selectivity can be calculated as follows

OselecO2 <- ( alphaCalc * concAvgCorrO2 ) / ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma )

# The RSD of the CO oxygen-selectivity can be calucated as follows

OselecO2RSD <- sqrt(
  ( alphaCalcRSD ^ 2 + concAvgCorrO2RSD ^ 2)
  +
    (
      ( ( alphaCalcRSD ^ 2 + concAvgCorrCO2PlasmaRSD ^ 2) * alphaCalc ^ 2 * concAvgCorrCO2Plasma ^ 2 + concAvgCorrCO2BlankSD ^ 2)
      /
        ( concAvgCorrCO2Blank - alphaCalc * concAvgCorrCO2Plasma ) ^ 2
    )
)

# The SD of the CO selectivity can be calculated then as follows

OselecO2SD <- OselecO2RSD * OselecO2

# Add these numbers to the data

data <- data %>%
  mutate(Oselec = ifelse(compound == "O2" & name == "plasma", OselecO2, Oselec) ,
         OselecSD = ifelse(compound == "O2" & name == "plasma", OselecO2SD, OselecSD) ,
         OselecRSD = ifelse(compound == "O2" & name == "plasma", OselecO2RSD, OselecRSD) )

# Calculating the Oxygen-Yield of O2 #
######################################

# These calucations are simplyfied by the fact that the oxygen-yield of O2 is the product
# of the conversion of CO2 and the oxygen-selectivity of O2, both numbers which are already
# stored in objects, just like their SD and RSD

OyieldO2 <- convCO2 * OselecO2

OyieldO2RSD <- sqrt(
  convCO2RSD ^ 2 + OselecO2RSD ^ 2
)

OyieldO2SD <- OyieldO2RSD * OyieldO2

# Add these numbers to the data

data <- data %>%
  mutate(Oyield = ifelse(compound == "O2" & name == "plasma", OyieldO2, Oyield) ,
         OyieldSD = ifelse(compound == "O2" & name == "plasma", OyieldO2SD, Oyield) ,
         OyieldRSD = ifelse(compound == "O2" & name == "plasma", OyieldO2RSD, Oyield) )

#####################################
# CO:O2 yield ratio (should be 2:1) #
#####################################

# Calculation of the yield ratio

yieldRatio <- CyieldCO / OyieldO2

# Calculation of the RSD of the ratio

yieldRatioRSD <- sqrt(
  CyieldCORSD ^ 2 + OyieldO2RSD ^ 2
)

# Calculation of the SD of the ratio

yieldRatioSD <- yieldRatioRSD * yieldRatio

data <- data %>%
  mutate(yieldRatio = yieldRatio ,
         yieldRatioSD = yieldRatioSD ,
         yieldRatioRSD = yieldRatioRSD )

##################
# Carbon Balance #
##################

# Calculation of the carbon balance

Cbalance <- ( alphaCalc * ( concAvgCorrCO + concAvgCorrCO2Plasma ) ) / concAvgCorrCO2Blank

# From the data, the SD of the corrected CO concentration must also be obtained

concAvgCorrCOSD <- data %>%
  filter(name == "plasma" & compound == "CO") %>%
  pull(concAvgCorrSD) %>%
  unique()

# From the CO2 data created earlier, the SD for the corrected CO2 concentration after plasma must be taken

concAvgCorrCO2PlasmaSD <- dataCO2 %>%
  filter(name == "plasma") %>%
  pull(concAvgCorrSD)

# Calculation of the RSD of the C-balance

CbalanceRSD <- sqrt(
  alphaCalcRSD ^ 2 + 
    concAvgCorrCO2BlankRSD ^ 2 +
    ( ( concAvgCorrCOSD ^ 2 + concAvgCorrCO2PlasmaSD) / ( concAvgCorrCO + concAvgCorrCO2Plasma ) ^ 2 )
)

# Calculation of the SD of the C-balance

CbalanceSD <- CbalanceRSD * Cbalance

data <- data %>%
  mutate(Cbalance = Cbalance ,
         CbalanceSD = CbalanceSD ,
         CbalanceRSD = CbalanceRSD )

##################
# Oxygen Balance #
##################

# Calculation of the oxygen balance

Obalance <- ( alphaCalc * ( 2 * concAvgCorrO2 + 1 * concAvgCorrCO + 2 * concAvgCorrCO2Plasma ) ) / ( 2 * concAvgCorrCO2Blank)

# From the data, the SD of the corrected O2 concentration must also be obtained

concAvgCorrO2SD <- data %>%
  filter(name == "plasma" & compound == "O2") %>%
  pull(concAvgCorrSD) %>%
  unique()

# Calculation of the RSD of the O-balance

ObalanceRSD <- sqrt(
  concAvgCorrCO2BlankRSD ^ 2 +
    alphaCalcRSD ^ 2 +
    ( ( 4 * concAvgCorrO2SD ^ 2 + 1 * concAvgCorrCOSD ^ 2 + 4 * concAvgCorrCO2PlasmaSD )
      /
        ( 2 * concAvgCorrO2 + concAvgCorrCO + 2 * concAvgCorrCO2Plasma ) ^ 2 )
)

# Calculation of the SD of the O-balance

ObalanceSD <- ObalanceRSD * Obalance

# Adding values to the data

data <- data %>%
  mutate(Obalance = Obalance ,
         ObalanceSD = ObalanceSD ,
         ObalanceRSD = ObalanceRSD )

###############################
# Specific Energy Input (SEI) #
###############################

# Calculation the average plasma power, its SD and its RSD

data <- data %>%
  group_by(name, compound) %>%
  mutate(powerAvg = ifelse(name == "blank", NA, mean(power, na.rm = T) ) ,
         powerSD = ifelse(name == "blank", NA, sd(power, na.rm = T) ) ,
         powerRSD = ifelse(name == "blank", NA, powerSD / powerAvg )) %>%
  ungroup()

# Take average power level, SD and RSD

powerAvg <- data %>%
  filter(name == "plasma") %>%
  pull(powerAvg) %>%
  unique()

powerSD <- data %>%
  filter(name == "plasma") %>%
  pull(powerSD) %>%
  unique()

powerRSD <- data %>%
  filter(name == "plasma") %>%
  pull(powerRSD) %>%
  unique()

flowCO2 <- data %>%
  filter(compound == "CO2") %>%
  pull(flow) %>%
  unique()

flowCO2RSD <- data %>%
  filter(compound == "CO2") %>%
  pull(flowRSD) %>%
  unique()

# Calculate SEI (J/mmol same as kJ/mol) (molar gas volume at 1 atm & 20°C)

SEI <- ( powerAvg / flowCO2 ) * 60 * 24.055

# Calculate SEI RSD

SEIRSD <- sqrt( powerRSD ^ 2 + flowCO2RSD ^ 2 )

# Calculate SEI SD

SEISD <- SEIRSD * SEI

# Adding values to the data

data <- data %>%
  mutate(SEI = ifelse(name == "plasma", SEI, NA) ,
         SEISD = ifelse(name == "plasma", SEISD, NA) ,
         SEIRSD = ifelse(name == "plasma", SEIRSD, NA))

#####################
# Energy efficiency #
#####################

# Plasma temperature (K) now set at 200°C

Ptemp <- 273.15+200

# Gibbs Free Enthalpy of Formation of CO in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

GfCO <- -1.48747E-20*(Ptemp ^ 6) + 2.90543E-16* (Ptemp ^ 5) - 2.18412E-12 * (Ptemp ^ 4) + 7.80039E-09 * (Ptemp ^ 3) - 1.14364E-05 * (Ptemp ^ 2) - 8.19286E-02 * Ptemp - 1.12455E+02

# Gibbs Free Enthalpy of Formation of CO2 in function of gas temperature (sixth order polynomial fit from NIST-JANAF data)

GfCO2 <- 1.21850E-21* (Ptemp ^ 6) - 2.63973E-17 * (Ptemp ^ 5) + 2.25893E-13 * (Ptemp ^ 4) - 9.56091E-10 * (Ptemp ^ 3) + 2.75906E-06 * (Ptemp ^ 2) - 4.68102E-03 * Ptemp - 3.93205E+02

# Energy efficiency (%) based on the Gibbs free enthalpies of formation of reactant and products (used in scientific settings)

etaGf <-  ( ( alphaCalc * concAvgCorrCO * GfCO ) - ( convCO2 * concAvgCorrCO2Blank * GfCO2 ) ) / ( SEI ) * 100

etaGfRSD <- sqrt(
  SEIRSD ^ 2 +
    ( ( ( alphaCalcRSD ^ 2 + concAvgCorrCORSD ^ 2 ) * ( alphaCalc * concAvgCorrCO * GfCO) ^ 2 + ( convCO2RSD ^ 2 + concAvgCorrCO2BlankRSD ^ 2 ) * ( convCO2 * concAvgCorrCO2Blank * GfCO2 ) ^ 2 ) / ( alphaCalc * concAvgCorrCO * GfCO - convCO2 * concAvgCorrCO2Blank * GfCO2 ) ^ 2 )
)

etaGfSD <- etaGfRSD * etaGf

data <- data %>%
  mutate(etaGf = ifelse(name == "plasma", etaGf, NA) ,
         etaGfSD = ifelse(name == "plasma", etaGfSD, NA) ,
         etaGfRSD = ifelse(name == "plasma", etaGfRSD, NA))

# Energy efficiency (%) based on the Lower Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry

etaLHV <- ( alphaCalc * concAvgCorrCO * 0.323 ) / ( SEI ) * 100

etaLHVRSD <- sqrt(
  SEIRSD ^ 2 +
    ( alphaCalcRSD ^ 2 + concAvgCorrCORSD ^ 2 )
)

etaLHVSD <- etaLHVRSD * etaLHV

data <- data %>%
  mutate(etaLHV = ifelse(name == "plasma", etaLHV, NA) ,
         etaLHVSD = ifelse(name == "plasma", etaLHVSD, NA) ,
         etaLHVRSD = ifelse(name == "plasma", etaLHVRSD, NA))

# Energy efficiency (%) based on the Higher Heating Values of the products and reactants (a metric for the amount of energy one can obtain by combusting the products), used mainly in the oil industry
# LHV and HHV values for CO are the same

etaHHV <- ( alphaCalc * concAvgCorrCO * 0.323 ) / ( SEI ) * 100

etaHHVRSD <- sqrt(
  SEIRSD ^ 2 +
    ( alphaCalcRSD ^ 2 + concAvgCorrCORSD ^ 2 )
)

etaHHVSD <- etaLHVRSD * etaLHV

data <- data %>%
  mutate(etaHHV = ifelse(name == "plasma", etaHHV, NA) ,
         etaHHVSD = ifelse(name == "plasma", etaHHVSD, NA) ,
         etaHHVRSD = ifelse(name == "plasma", etaHHVRSD, NA))

######################################
# Energy efficiency Snoeckx's method #
######################################

etaSnoeckx <- ( ( GfCO - GfCO2 ) * convCO2Snoeckx ) / SEI * 100

etaSnoeckxRSD <- sqrt(
  convCO2SnoeckxRSD ^ 2 + SEIRSD ^ 2
)

etaSnoeckxSD <- etaSnoeckx * etaSnoeckxRSD

data <- data %>%
  mutate(etaSnoeckx = ifelse(name == "plasma", etaSnoeckx, NA) ,
         etaSnoeckxSD = ifelse(name == "plasma", etaSnoeckxSD, NA) ,
         etaSnoeckxRSD = ifelse(name == "plasma", etaSnoeckxRSD, NA))

##############################################################################################
# Calculate difference between the two methods and test if there is a significant difference #
##############################################################################################

# t-test with known means and standard deviations

# m1, m2: the sample means
# s1, s2: the sample standard deviations
# n1, n2: the same sizes
# m0: the null value for the difference in means to be tested for. Default is 0. 
# equal.variance: whether or not to assume equal variance. Default is FALSE. 
t.test2 <- function(m1,m2,s1,s2,n1,n2,m0=0,equal.variance=FALSE)
{
  if( equal.variance==FALSE ) 
  {
    se <- sqrt( (s1^2/n1) + (s2^2/n2) )
    # welch-satterthwaite df
    df <- ( (s1^2/n1 + s2^2/n2)^2 )/( (s1^2/n1)^2/(n1-1) + (s2^2/n2)^2/(n2-1) )
  } else
  {
    # pooled standard deviation, scaled by the sample sizes
    se <- sqrt( (1/n1 + 1/n2) * ((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2) ) 
    df <- n1+n2-2
  }      
  t <- (m1-m2-m0)/se 
  dat <- c(m1-m2, se, t, 2*pt(-abs(t),df))    
  names(dat) <- c("Difference of means", "Std Error", "t", "p-value")
  return(dat) 
}

numMsrmnts <- data %>%
  filter(name=="blank" & compound == "N2") %>%
  nrow()

tTestResult <- t.test2(m1=convCO2,m2=convCO2Snoeckx,s1=convCO2SD,s2=convCO2SnoeckxSD,n1=numMsrmnts,n2=numMsrmnts)

tTestResult
data <- data %>%
  mutate( pValue = tTestResult[4] ,
          tTestResult = ifelse(tTestResult[4] <= .05, "Null hypothesis is rejected (p value <= .05), difference in results from methods is significant", "null hypothesis is accepted (p value > .05), difference in results from methods is insignificant") )

############################################
# Write the calculated data to a .csv file #
############################################

write_csv(data, gsub(".csv", "-calc.csv", filename))