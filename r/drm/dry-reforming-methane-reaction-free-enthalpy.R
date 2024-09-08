library(tidyverse)

# Input

t_K = 273.15 + 650
t = t_K / 1000

#######################
# Carbon Dioxide, C02 #
#######################

co2_H_std = -393.52
co2_S_std = 213.79

a_co2 = ifelse(
          between(t_K, 298, 1200),
          24.99735,
          ifelse(
            between(t_K, 1200, 6000),
            58.16639,
            print("a_co2, temperature should be between 298 and 6000K")
            )
           )
  
b_co2 = ifelse(
  between(t_K, 298, 1200),
  55.18696,
  ifelse(
    between(t_K, 1200, 6000),
    2.720074,
    print("b_co2, temperature should be between 298 and 6000K")
  )
)

c_co2 = ifelse(
  between(t_K, 298, 1200),
  -33.69137,
  ifelse(
    between(t_K, 1200, 6000),
    -0.492289,
    print("c_co2, temperature should be between 298 and 6000K")
  )
)

d_co2 = ifelse(
  between(t_K, 298, 1200),
  7.948387,
  ifelse(
    between(t_K, 1200, 6000),
    0.038844,
    print("d_co2, temperature should be between 298 and 6000K")
  )
)

e_co2 = ifelse(
  between(t_K, 298, 1200),
  -0.136638,
  ifelse(
    between(t_K, 1200, 6000),
    -6.447293,
    print("e_co2, temperature should be between 298 and 6000K")
  )
)

f_co2 = ifelse(
  between(t_K, 298, 1200),
  -403.6075,
  ifelse(
    between(t_K, 1200, 6000),
    -425.9186,
    print("f_co2, temperature should be between 298 and 6000K")
  )
)

g_co2 = ifelse(
  between(t_K, 298, 1200),
  228.2431,
  ifelse(
    between(t_K, 1200, 6000),
    263.6125,
    print("f_co2, temperature should be between 298 and 6000K")
  )
)

h_co2 = ifelse(
  between(t_K, 298, 1200),
  -393.5224,
  ifelse(
    between(t_K, 1200, 6000),
    -393.5224,
    print("f_co2, temperature should be between 298 and 6000K")
  )
)

co2_Cp_atm = a_co2 + b_co2*t + c_co2*t^2 + d_co2*t^3 + e_co2/t^2

co2_H_atm = a_co2 * t + b_co2 * t^2 / 2 + c_co2 * t^3/3 + d_co2 * t^4/4 - e_co2/t + f_co2 - h_co2 + co2_H_std

co2_S_atm = a_co2*log(t) + b_co2 * t + c_co2 * t^2/2 + d_co2 * t^3/3 - e_co2/(2*t^2) + g_co2

co2_G_atm = co2_H_atm - t_K * co2_S_atm/1000

# Cp = heat capacity (J/mol*K)
# H° = standard enthalpy (kJ/mol)
# S° = standard entropy (J/mol*K)

################
# Methane, CH4 #
################

ch4_H_std = -74.6
ch4_S_std = 186.25

a_ch4 = ifelse(
  between(t_K, 298, 1300),
  -0.703029,
  ifelse(
    between(t_K, 1300, 6000),
    85.81217,
    print("a_ch4, temperature should be between 298 and 6000K")
  )
)

b_ch4 = ifelse(
  between(t_K, 298, 1300),
  108.4773,
  ifelse(
    between(t_K, 1300, 6000),
    11.26467,
    print("b_ch4, temperature should be between 298 and 6000K")
  )
)

c_ch4 = ifelse(
  between(t_K, 298, 1300),
  -42.52157,
  ifelse(
    between(t_K, 1300, 6000),
    -2.114146,
    print("c_ch4, temperature should be between 298 and 6000K")
  )
)

d_ch4 = ifelse(
  between(t_K, 298, 1300),
  5.862788,
  ifelse(
    between(t_K, 1300, 6000),
    0.138190,
    print("d_ch4, temperature should be between 298 and 6000K")
  )
)

e_ch4 = ifelse(
  between(t_K, 298, 1300),
  0.678565,
  ifelse(
    between(t_K, 1300, 6000),
    -26.42221,
    print("e_ch4, temperature should be between 298 and 6000K")
  )
)

f_ch4 = ifelse(
  between(t_K, 298, 1300),
  -76.84376,
  ifelse(
    between(t_K, 1300, 6000),
    -153.5327,
    print("f_ch4, temperature should be between 298 and 6000K")
  )
)

g_ch4 = ifelse(
  between(t_K, 298, 1300),
  158.7163,
  ifelse(
    between(t_K, 1300, 6000),
    224.4143,
    print("f_ch4, temperature should be between 298 and 6000K")
  )
)

h_ch4 = ifelse(
  between(t_K, 298, 1300),
  -74.87310,
  ifelse(
    between(t_K, 1300, 6000),
    -74.87310,
    print("f_ch4, temperature should be between 298 and 6000K")
  )
)

ch4_Cp_atm = a_ch4 + b_ch4*t + c_ch4*t^2 + d_ch4*t^3 + e_ch4/t^2

ch4_H_atm = a_ch4 * t + b_ch4 * t^2 / 2 + c_ch4 * t^3/3 + d_ch4 * t^4/4 - e_ch4/t + f_ch4 - h_ch4 + ch4_H_std

ch4_S_atm = a_ch4*log(t) + b_ch4 * t + c_ch4 * t^2/2 + d_ch4 * t^3/3 - e_ch4/(2*t^2) + g_ch4

ch4_G_atm = ch4_H_atm - t_K * ch4_S_atm/1000

#######################
# Carbon Monoxide, CO #
#######################

co_H_std = -110.53
co_S_std = 197.66

a_co = ifelse(
  between(t_K, 298, 1300),
  25.56759,
  ifelse(
    between(t_K, 1300, 6000),
    35.15070,
    print("a_co, temperature should be between 298 and 6000K")
  )
)

b_co = ifelse(
  between(t_K, 298, 1300),
  6.096130,
  ifelse(
    between(t_K, 1300, 6000),
    1.300095,
    print("b_co, temperature should be between 298 and 6000K")
  )
)

c_co = ifelse(
  between(t_K, 298, 1300),
  4.054656,
  ifelse(
    between(t_K, 1300, 6000),
    -0.205921,
    print("c_co, temperature should be between 298 and 6000K")
  )
)

d_co = ifelse(
  between(t_K, 298, 1300),
  -2.671301,
  ifelse(
    between(t_K, 1300, 6000),
    0.013550,
    print("d_co, temperature should be between 298 and 6000K")
  )
)

e_co = ifelse(
  between(t_K, 298, 1300),
  0.131021,
  ifelse(
    between(t_K, 1300, 6000),
    -3.282780,
    print("e_co, temperature should be between 298 and 6000K")
  )
)

f_co = ifelse(
  between(t_K, 298, 1300),
  -118.0089,
  ifelse(
    between(t_K, 1300, 6000),
    -127.8375,
    print("f_co, temperature should be between 298 and 6000K")
  )
)

g_co = ifelse(
  between(t_K, 298, 1300),
  227.3665,
  ifelse(
    between(t_K, 1300, 6000),
    231.7120,
    print("f_co, temperature should be between 298 and 6000K")
  )
)

h_co = ifelse(
  between(t_K, 298, 1300),
  -110.5271,
  ifelse(
    between(t_K, 1300, 6000),
    -110.5271,
    print("f_co, temperature should be between 298 and 6000K")
  )
)

co_Cp_atm = a_co + b_co*t + c_co*t^2 + d_co*t^3 + e_co/t^2

co_H_atm = a_co * t + b_co * t^2 / 2 + c_co * t^3/3 + d_co * t^4/4 - e_co/t + f_co - h_co + co_H_std

co_S_atm = a_co*log(t) + b_co * t + c_co * t^2/2 + d_co * t^3/3 - e_co/(2*t^2) + g_co

co_G_atm = co_H_atm - t_K * co_S_atm/1000

################
# Hydrogen, H2 #
################

h2_H_std = 0
h2_S_std = 130.68

a_h2 = ifelse(
  between(t_K, 298, 1000),
  33.066178,
  ifelse(
    between(t_K, 1000, 2500),
    18.563083,
    ifelse(
      between(t_K, 2500, 6000),
      43.413560,
      print("a_h2, temperature should be between 298 and 6000K")
      )
    )
  )

b_h2 = ifelse(
  between(t_K, 298, 1000),
  -11.363417,
  ifelse(
    between(t_K, 1000, 2500),
    12.257357,
    ifelse(
      between(t_K, 2500, 6000),
      -4.293079,
      print("b_h2, temperature should be between 298 and 6000K")
    )
  )
)

c_h2 = ifelse(
  between(t_K, 298, 1000),
  11.432816,
  ifelse(
    between(t_K, 1000, 2500),
    -2.859786,
    ifelse(
      between(t_K, 2500, 6000),
      1.272428,
      print("c_h2, temperature should be between 298 and 6000K")
    )
  )
)

d_h2 = ifelse(
  between(t_K, 298, 1000),
  -2.772874,
  ifelse(
    between(t_K, 1000, 2500),
    0.268238,
    ifelse(
      between(t_K, 2500, 6000),
      -0.096876,
      print("d_h2, temperature should be between 298 and 6000K")
    )
  )
)

e_h2 = ifelse(
  between(t_K, 298, 1000),
  -0.158558,
  ifelse(
    between(t_K, 1000, 2500),
    1.977990,
    ifelse(
      between(t_K, 2500, 6000),
      -20.533862,
      print("e_h2, temperature should be between 298 and 6000K")
    )
  )
)

f_h2 = ifelse(
  between(t_K, 298, 1000),
  -9.980797,
  ifelse(
    between(t_K, 1000, 2500),
    -1.147438,
    ifelse(
      between(t_K, 2500, 6000),
      -38.515158,
      print("f_h2, temperature should be between 298 and 6000K")
    )
  )
)

g_h2 = ifelse(
  between(t_K, 298, 1000),
  172.707974,
  ifelse(
    between(t_K, 1000, 2500),
    156.288133,
    ifelse(
      between(t_K, 2500, 6000),
      162.081354,
      print("g_h2, temperature should be between 298 and 6000K")
    )
  )
)

h_h2 = ifelse(
  between(t_K, 298, 1000),
  0,
  ifelse(
    between(t_K, 1000, 2500),
    0,
    ifelse(
      between(t_K, 2500, 6000),
      0,
      print("g_h2, temperature should be between 298 and 6000K")
    )
  )
)

h2_Cp_atm = a_h2 + b_h2*t + c_h2*t^2 + d_h2*t^3 + e_h2/t^2

h2_H_atm = a_h2 * t + b_h2 * t^2 / 2 + c_h2 * t^3/3 + d_h2 * t^4/4 - e_h2/t + f_h2 - h_h2 + h2_H_std

h2_S_atm = a_h2*log(t) + b_h2 * t + c_h2 * t^2/2 + d_h2 * t^3/3 - e_h2/(2*t^2) + g_h2

h2_G_atm = h2_H_atm - t_K * h2_S_atm/1000

##############################
# DRM Reaction Free Enthalpy #
##############################

print((2 * co_G_atm + 2 * h2_G_atm) - (co2_G_atm + ch4_G_atm))
