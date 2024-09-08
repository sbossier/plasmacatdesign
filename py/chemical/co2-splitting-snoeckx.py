import os
import pandas as pd
import numpy as np

# Set working directory
os.chdir("H:/data/co2-splitting/vito/PlAl-21002-1450/pwr-cte")

# Read in starting data & replace different ways of NA with a logical NA (ugly done, maybe by using regex it could be more elegantly done)
# Only forward slashes
filename = "70.0s-01.csv"
na_values = ["NA", "na", "Na", "nA", "N A", "N/A", "N a", "n A", "n a"]
data = pd.read_csv(filename, na_values=na_values)

# Calculate average concentration, standard deviation, and relative standard deviation for each compound in each test
data_grouped = data.groupby(['state', 'compound'])
data['conc_avg'] = data_grouped['conc'].transform(lambda x: x.mean(skipna=True))
data['conc_sd'] = data_grouped['conc'].transform(lambda x: x.std(skipna=True))
data['conc_rsd'] = data['conc_sd'] / data['conc_avg']

# Calculate gamma
flow_co2 = data.loc[data['compound'] == 'CO2', 'flow_mlmin'].unique()[0]
flow_n2 = data.loc[data['compound'] == 'N2', 'flow_mlmin'].unique()
flow_n2 = 0 if pd.isna(flow_n2) else flow_n2[0]

gamma = flow_co2 / (flow_co2 + flow_n2)
gamma_sd = 0
gamma_rsd = 0

beta = flow_n2 / flow_co2
beta_sd = 0
beta_rsd = 0

data['conc_avg_corr'] = np.where(data['compound'] != 'N2', data['conc_avg'] * (1 + beta), np.nan)
data['conc_avg_corr_sd'] = np.where(data['compound'] != 'N2', data['conc_sd'] * (1 + beta), np.nan)
data['conc_avg_corr_rsd'] = np.where(data['compound'] != 'N2', data['conc_rsd'], np.nan)

# Acquire all relevant CO2 concentration values
conc_avg_co2_blank = data.loc[(data['state'] == 'blank') & (data['compound'] == 'CO2'), 'conc_avg'].unique()
conc_sd_co2_blank = data.loc[(data['state'] == 'blank') & (data['compound'] == 'CO2'), 'conc_sd'].unique()
conc_rsd_co2_blank = data.loc[(data['state'] == 'blank') & (data['compound'] == 'CO2'), 'conc_rsd'].unique()

conc_avg_co2_plasma = data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conc_avg'].unique()
conc_sd_co2_plasma = data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conc_sd'].unique()
conc_rsd_co2_plasma = data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conc_rsd'].unique()

# Calculation of incorrect conversion simply based on GC results
conv_co2_gc = 1 - (conc_avg_co2_plasma / conc_avg_co2_blank)
conv_co2_gc_rsd = np.sqrt(conc_rsd_co2_blank ** 2 + conc_rsd_co2_plasma ** 2)
conv_co2_gc_sd = conv_co2_gc_rsd * conv_co2_gc

# Calculation of the CO2 conversion according to the method by Snoeckx
conv_co2 = conv_co2_gc / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)
conv_co2_rsd = np.sqrt(
    conv_co2_gc_rsd ** 2 +
    ((conv_co2_gc_rsd * (gamma / 2) * conv_co2_gc) / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)) ** 2
)
conv_co2_sd = conv_co2_rsd * conv_co2

# delta can be calculated from this and performs the same role of alpha in the general method
delta = 1 + conv_co2 / 2
delta_sd = 0
delta_rsd = 0

# Add data to framework
data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv'] = conv_co2
data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv_sd'] = conv_co2_sd
data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv_rsd'] = conv_co2_rsd
data['delta'] = delta
