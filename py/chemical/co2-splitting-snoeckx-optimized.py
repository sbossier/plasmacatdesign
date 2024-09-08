import os
import pandas as pd
import numpy as np

os.chdir("H:/data/co2-splitting/vito/PlAl-21002-1450/pwr-cte")

filename = "70.0s-01.csv"
na_values = ["NA", "na", "Na", "nA", "N A", "N/A", "N a", "n A", "n a"]
data = pd.read_csv(filename, na_values=na_values)

data_grouped = data.groupby(['state', 'compound'])
data['conc_avg'] = data_grouped['conc'].transform('mean')
data['conc_sd'] = data_grouped['conc'].transform('std')
data['conc_rsd'] = data['conc_sd'] / data['conc_avg']

flow_co2, flow_n2 = data.loc[data['compound'] == 'CO2', 'flow_mlmin'].unique(), data.loc[data['compound'] == 'N2', 'flow_mlmin'].unique()
flow_n2 = 0 if flow_n2.size == 0 else flow_n2[0]

gamma, beta = flow_co2 / (flow_co2 + flow_n2), flow_n2 / flow_co2

data['conc_avg_corr'] = np.where(data['compound'] != 'N2', data['conc_avg'] * (1 + beta), np.nan)
data['conc_avg_corr_sd'] = np.where(data['compound'] != 'N2', data['conc_sd'] * (1 + beta), np.nan)
data['conc_avg_corr_rsd'] = np.where(data['compound'] != 'N2', data['conc_rsd'], np.nan)

co2_data = data[data['compound'] == 'CO2']
conc_avg_co2 = co2_data.pivot(index=None, columns='state', values='conc_avg')
conc_sd_co2 = co2_data.pivot(index=None, columns='state', values='conc_sd')
conc_rsd_co2 = co2_data.pivot(index=None, columns='state', values='conc_rsd')

conv_co2_gc = 1 - (conc_avg_co2['plasma'] / conc_avg_co2['blank'])
conv_co2_gc_rsd = np.sqrt(conc_rsd_co2['blank'] ** 2 + conc_rsd_co2['plasma'] ** 2)

conv_co2 = conv_co2_gc / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)
conv_co2_rsd = np.sqrt(
    conv_co2_gc_rsd ** 2 +
    ((conv_co2_gc_rsd * (gamma / 2) * conv_co2_gc) / ((1 + gamma / 2) - (gamma / 2) * conv_co2_gc)) ** 2
)

data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv'] = conv_co2.values
data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv_sd'] = (conv_co2_rsd * conv_co2).values
data.loc[(data['state'] == 'plasma') & (data['compound'] == 'CO2'), 'conv_rsd'] = conv_co2_rsd.values
data['delta'] = 1 + conv_co2 / 2
