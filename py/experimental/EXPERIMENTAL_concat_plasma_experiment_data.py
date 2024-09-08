import pandas as pd
import os
import glob
#import openpyxl

# Specify the parent directory
parent_dir = r'N:\FWET\FDCH\AdsCatal\General\personal_work_folders\plasmacatdesign\drm\ugent'

# List for collecting all data
data_list = []

# Walk through each directory and its subdirectories
for dirpath, dirnames, filenames in os.walk(parent_dir):
    # For each file
    for filename in filenames:
        # If the file ends in '-calc-short.csv'
        if filename.endswith('-calc-short.csv'):
            # Construct full file path
            file_path = os.path.join(dirpath, filename)
            # Read the CSV file and append it to the list
            data_list.append(pd.read_csv(file_path, keep_default_na=True))

# Concatenate all data frames
combined_data = pd.concat(data_list)

# Fill NA values with 'NA'
combined_data.fillna('NA', inplace=True)

# Save to new Excel file in the parent directory
combined_data.to_excel(os.path.join(parent_dir, 'combined_short.xlsx'), index=False)

print("All short CSV files have been successfully combined!")