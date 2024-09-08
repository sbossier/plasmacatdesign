import os
import pandas as pd
import numpy as np

def clean_data(df):
    # Replace '_x000D_' with a space in all cells
    df = df.astype(str).applymap(lambda x: x.replace('_x000D_', ''))
    
    # Remove leading and trailing whitespace
    df = df.applymap(lambda x: x.strip() if isinstance(x, str) else x)
    
    # Try to convert the data back to its original type
    df = df.apply(pd.to_numeric, errors='ignore')

    df = df[df.iloc[:, 0].isin(['nan', 'CH4', 'CO2', 'N2', 'CH3CH2OH', 'CH3OCH3', 'CH3OH'])]

    # Convert 'nan' strings to actual NaN values
    df = df.replace('nan', np.nan)
    
    # Drop all-NaN rows
    df = df.dropna(axis=0, how='all')
    
    return df

def convert_xlsx_to_csv_and_concat(folder_path):
    # Get all the .xlsx filenames in the specified folder
    xlsx_files = [f for f in os.listdir(folder_path) if f.endswith(".xlsx")]

    # Load each .xlsx file, clean, and convert to .csv
    csv_files = []  # List to store the names of converted .csv files
    for filename in xlsx_files:
        filepath = os.path.join(folder_path, filename)
        df = pd.read_excel(filepath)

        # Clean the dataframe
        df = clean_data(df)
        
        # Convert DataFrame to .csv
        csv_filename = os.path.splitext(filename)[0] + '.csv'
        csv_filepath = os.path.join(folder_path, csv_filename)
        df.to_csv(csv_filepath, index=False, header=False)
        
        csv_files.append(csv_filepath)

    # Load the first CSV file with header
    df_concat = pd.read_csv(csv_files[0])
    
    # Load the remaining CSV files without header and concatenate
    for file in csv_files[1:]:
        df = pd.read_csv(file, header=None)
        df_concat = pd.concat([df_concat, df], ignore_index=True)

    # Save the concatenated dataframe as .csv in the same folder
    output_filename = os.path.join(folder_path, 'output.csv')
    df_concat.to_csv(output_filename, index=False)
    print(f"Converted {len(xlsx_files)} .xlsx files to {output_filename}")



# Example usage:
convert_xlsx_to_csv_and_concat(r'C:\Users\sbossier\Desktop\test\ExtractTextTableInfoFromPDF\tables')