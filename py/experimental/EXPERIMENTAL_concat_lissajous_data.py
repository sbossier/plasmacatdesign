import pandas as pd
import os
import re

# Specify the parent directory
parent_dir = 'H:/data/drm/ugent/'  # put your directory path here

# List to store DataFrame objects
data_frames = []

# Walk through each directory and its subdirectories
for dirpath, dirnames, filenames in os.walk(parent_dir):
    # For each file
    for filename in filenames:
        # If the file is 'calculations_no_outliers.csv'
        if filename == 'calculations_no_outliers.csv':
            # Construct full file path
            file_path = os.path.join(dirpath, filename)
            # Read the CSV file
            df = pd.read_csv(file_path)

            # Get material and res_time_sec from the file_name column
            file_name = df['file_name'].iloc[0]
            material = re.search(r'(sasol-1.8-.*?)(?=\\)', file_name).group(1)
            res_time_sec = re.search(r'\\(\d+\.?\d*)s-', file_name).group(1)

            # Drop the file_name column
            df = df.drop('file_name', axis=1)

            # Calculate averages and standard deviations
            avg_df = df.mean().to_frame().T
            avg_df.columns = [str(col) + '_avg' for col in avg_df.columns]
            sd_df = df.std().to_frame().T
            sd_df.columns = [str(col) + '_sd' for col in sd_df.columns]
            
            # Combine averages and standard deviations, and add material and res_time_sec
            avg_sd_df = pd.concat([avg_df, sd_df], axis=1)
            avg_sd_df['material'] = material
            avg_sd_df['res_time_sec'] = res_time_sec

            # Order columns as requested
            cols = avg_sd_df.columns.tolist()
            cols.remove('material')
            cols.remove('res_time_sec')
            cols = ['material', 'res_time_sec'] + sorted(cols)
            avg_sd_df = avg_sd_df[cols]

            # Add to the data frames list
            data_frames.append(avg_sd_df)

# Concatenate all data frames
stats_df = pd.concat(data_frames, ignore_index=True)

# Save to new Excel file in the parent directory
stats_df.to_excel(os.path.join(parent_dir, 'ugent-drm-lissajous-calculations.xlsx'), index=False)

print("Statistics for all 'calculations_no_outliers.csv' files have been successfully calculated and saved to 'ugent-drm-lissajous-calculations.xlsx'!")