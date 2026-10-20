# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "marimo",
#     "numpy>=2",
#     "pandas>=2.2",
#     "pyarrow>=19",
# ]
# [tool.uv]
# exclude-newer = "2026-10-20T00:00:00Z"
# ///

import marimo

__generated_with = "0.25.2"
app = marimo.App()


@app.cell
def _():
    import marimo as mo

    return (mo,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    Starting from the old system, I will try to simplify the workflow.
    The goal of this script is to create a single file with all the data from the raw lissajous measurements starting from the .psdata files.
    The script will be written in python and will use the pandas library to create a dataframe with all the data.
    The script will take a file path as input, but that file path has to be structured very specifically.
    The order of the folders in the file path is important, because the script will use the folder names to create the dataframe. This process uses indexing of the file path, so the order of the folders is important. It is a rudimentary way of creating a database, but it works.
    The file path should be structured as follows:
    ...\personal_work_folders\project_name\reaction_type\packing_material_supplier\packing_material_name\wattage_constant\lissajous\xy.zs-ab-plasma
    with:
    - project_name: the name of the project
    - reaction_type: the type of reaction (e.g. drm, co2-splitting, etc.)
    - packing_material_supplier: the supplier of the packing material (e.g. ugent, uhasselt, etc.)
    - packing_material_name: the name of the packing material (e.g. gamma-alumina-beads, etc.)
    - wattage_constant: the wattage constant used for the reaction (e.g. pwr-const, sei-const, etc.) (this is leftover from the comparison to old measurements acquired at 30W plasma power with a 8 mm diameter of the internal electrode and an inner diamter of 22.2 mm for the outer dielectric barrier)
    - lissajous: literally the word 'lissajous' as folder name
    - xy.zs: the residence time of the gas in the reactor (e.g. 05.0s, 10.0s, etc.)
    - ab: the number of the experiment (e.g. 01, 02, etc.)
    - plasma: literally the word 'plasma' to indicate that the measurements were acquired during plasma operation, if necessary, one can adapt the code to give a different meaning to this variable (e.g. 'stabilizing' to indicate that the measurements were acquired during plasma stabilization)
    """)
    return


@app.cell
def _():
    import os
    import shutil
    import tempfile
    import gc
    import re
    import subprocess
    import pandas as pd
    import numpy as np

    return gc, os, pd, re, shutil, subprocess, tempfile


@app.cell
def _():
    # Specify the top folder
    top_dir = r'C:\Users\Sande\OneDrive - Universiteit Antwerpen\plasmacatdesign\co2-splitting\uhasselt\SiO2_Type_S_1.6-1.8_mm\pwr-const\lissajous'

    picoscope_exe = r"C:\Program Files (x86)\Pico Technology\PicoScope6\PicoScope.exe"

    # View name depends on the PicoScope language ('Scope 1' in English)
    picoscope_view = 'Scoop 1'

    # Folder directly above project_name in the file path
    parent_dir_project = 'OneDrive - Universiteit Antwerpen'
    return parent_dir_project, picoscope_exe, picoscope_view, top_dir


@app.cell
def _(mo):
    # Nothing is converted or deleted until the button is pressed,
    # so editing a cell above does not trigger a full reconversion
    overwrite = mo.ui.checkbox(
        label="Delete existing lissajous_data.parquet files first"
    )
    run = mo.ui.run_button(label="Convert")
    mo.hstack([overwrite, run], justify="start")
    return overwrite, run


@app.cell
def _(os):
    # walk over top_dir and delete all files
    # called 'lissajous_data.parquet'
    def delete_existing_parquets(top_dir):
        for root, dirs, files in os.walk(top_dir):
            for file in files:
                if file == 'lissajous_data.parquet':
                    try:
                        os.remove(os.path.join(root, file))
                        print(f'{file} in {root} deleted')
                    except:
                        print(f'Error deleting {file} in {root}')

    return (delete_existing_parquets,)


@app.function
# Define a function to convert a variable to SI units
def convert_to_si(value, unit):
    conversion_factors = {
        'ms': 1e-3,
        's': 1,
        'nC': 1e-9,
        'knC': 1e-6,
        'A': 1,
        'mA': 1e-3,
        'W': 1,
        'kW': 1e3,
        'V': 1,
        'kV': 1e3,
    }

    return value * conversion_factors[unit]


@app.cell
def _(os, pd, re):
    # Define a function to return measurement information
    def parse_file_path(file_path, parent_dir_project='OneDrive - Universiteit Antwerpen'):
        # Split the file path into parts
        parts = file_path.split(os.sep)

        # Find the index of "parent_dir_project"
        try:
            base_idx = parts.index(parent_dir_project) + 1
        except ValueError:
            raise ValueError(
                f"The directory {parent_dir_project} was not found"
                "in the file path."
            )

        # Extract information based on the position
        # in the path relative to parent_dir_project
        project_name = parts[base_idx]
        reaction_type = parts[base_idx + 1]
        material_supplier = parts[base_idx + 2]
        material_name = parts[base_idx + 3]
        wattage_const = parts[base_idx + 4]
        psdata_file_name = parts[base_idx + 7]

        # Use regex to extract residence time,
        # measurement number, and plasma state
        match = re.match(r'(\d+\.\d+)s-(\d+)-(\w+)', parts[base_idx + 6])
        if not match:
            raise ValueError(
                "The file path does not match the expected format for "
                "residence time, measurement number, and plasma state"
            )

        # Convert residence time to float and measurement number to int
        residence_time = float(match.group(1))
        measurement_number = int(match.group(2))
        plasma_state = match.group(3)

        # Extract date from filename
        date_str = os.path.splitext(parts[-1])[0].split('-')[0]
        date = '-'.join([date_str[:4], date_str[4:6], date_str[6:]])

        # Create a dataframe to hold the extracted information
        info = pd.DataFrame(
            data=[[project_name, reaction_type, material_supplier,
                   material_name, wattage_const, residence_time,
                   measurement_number, plasma_state, date, psdata_file_name]],
            columns=['project_name', 'reaction_type', 'material_supplier',
                     'material_name', 'wattage_const', 'residence_time_s',
                     'measurement_number', 'plasma_state', 'date',
                     'psdata_file_name']
        )

        return info

    return (parse_file_path,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    After some function definitions, the script will start with the main function.
    This main part will do following things:
    1. Walk through the given top directory and all its subdirectories.
    2. It will check if the word 'lissajous' is in the path, if not so, it will skip to the next file path, if so, it will look for .psdata files in the directory.
    3. It will check if there are .parquet files in the directory, if so, it will skip to the next file path, if not so, it will look for .psdata files in the directory.
    4. If no .parquet file, try to find .psdata files in the directory, if there are no .psdata files, skip to the next file path, if there are .psdata files, start the data processing.
    5. The data processing will start by converting all the .psdata files to .csv files.
    6. All the .csv files are concatenated and saved as a .parquet file.
    """)
    return


@app.cell
def _(gc, os, parse_file_path, pd, shutil, subprocess, tempfile):
    # Convert all .psdata files in one directory into lissajous_data.parquet
    def convert_folder(
        dirpath, filenames, picoscope_exe, picoscope_view, parent_dir_project
    ):
        try:
            # Collect .psdata filepaths
            psdata_filepaths = [
                os.path.join(dirpath, f)
                for f in filenames if f.endswith('.psdata')
            ]

            # Create a temporary directory to work with .psdata files
            with tempfile.TemporaryDirectory() as temp_dir:
                # Copy .psdata files to the temporary directory
                for file_path in psdata_filepaths:
                    shutil.copy(file_path, temp_dir)

                # Get the list of filenames in the temporary directory
                temp_filenames = os.listdir(temp_dir)

                # Loop over the .psdata filenames in temp directory
                for temp_psdata_filename in temp_filenames:
                    print(f'Converting {temp_psdata_filename} to .csv')
                    temp_psdata_file_path = os.path.join(
                        temp_dir,
                        temp_psdata_filename
                    )

                    # Convert the psdata file to csv using a subroutine
                    try:
                        subprocess.run(
                            [
                                picoscope_exe, "/c", temp_psdata_file_path, "/f",
                                "csv", "/q", "/b", "all", "/v", picoscope_view
                            ],
                            check=True
                        )
                    except subprocess.CalledProcessError as e:
                        print(f"Failed to convert {temp_psdata_filename}: {e}")

                # Refresh the list of filenames after conversion
                csv_filenames = [
                    f for f in os.listdir(temp_dir) if f.endswith('.csv')
                ]

                # Join the csv filenames with the temp directory path
                csv_filepaths = [
                    os.path.join(temp_dir, csv_filename)
                    for csv_filename in csv_filenames
                ]

                # Loop over the csv filepaths to load the data
                # and concatenate into a single DataFrame
                data = []

                for csv_filepath in csv_filepaths:
                    df = pd.read_csv(
                        csv_filepath,
                        header=0,
                        names=[
                            "time_s",
                            "charge_C",
                            "voltage_V",
                            "current_reactor_A",
                            "current_source_A"
                            ],
                        usecols=[0, 1, 2, 3, 4],
                        low_memory=False
                    )

                    # Read the units from the first row and store as df,
                    # and remove string parentheses to parse units
                    df_units = df.iloc[[0],:].map(lambda x: x[1:-1])

                    # Remove the first row (containing unformated units)
                    df = df.drop(labels=0, axis=0).reset_index(drop=True)

                    # Coerce the data to numeric
                    df = df.apply(pd.to_numeric)

                    # Convert the units to SI units
                    for column in df.columns:
                        unit = df_units.loc[0, column]
                        df[column] = df[column].apply(
                            lambda x: convert_to_si(x, unit)
                        )

                    # Retrieve original psdata filepath
                    psdata_filepath = os.path.join(
                        dirpath,
                        os.path.splitext(
                            os.path.basename(csv_filepath)
                        )[0] + '.psdata'
                    )

                    # Parse information from the original filepath
                    df_info = parse_file_path(
                        file_path=psdata_filepath,
                        parent_dir_project=parent_dir_project
                    )

                    # Add a temporary key column to both DataFrames
                    df['key'] = 1
                    df_info['key'] = 1

                    # Merge the DataFrames on the temporary key
                    df_combined = pd.merge(df, df_info, on='key')

                    # Drop the temporary key column
                    df_combined = df_combined.drop(columns=['key'])

                    # Append the combined DataFrame to the list
                    data.append(df_combined)

                # Concatenate the list of DataFrames into a single df
                data_final = pd.concat(
                    data,
                    ignore_index=True
                )

                # Write the data to a parquet file in the same directory
                data_final.to_parquet(
                    os.path.join(dirpath, 'lissajous_data.parquet'),
                    index=False,
                    compression='gzip'
                )

                # Delete the .csv files
                for csv_filepath in csv_filepaths:
                    os.remove(csv_filepath)

                # Clean up the memory
                gc.collect()
        except Exception as e:
            print(f'Error in {dirpath}: {e}')

    return (convert_folder,)


@app.cell
def _(
    convert_folder,
    delete_existing_parquets,
    mo,
    os,
    overwrite,
    parent_dir_project,
    picoscope_exe,
    picoscope_view,
    run,
    top_dir,
):
    # Runs on button press, or unconditionally as a script (uv run)
    mo.stop(
        not (run.value or mo.app_meta().mode == "script"),
        mo.md("Press **Convert** to start.")
    )

    if overwrite.value:
        delete_existing_parquets(top_dir)

    # Walk through each directory in the folder tree
    for _dirpath, _dirnames, _filenames in os.walk(top_dir):
        # Check if the dirpath contains the string 'lissajous'
        if 'lissajous' not in _dirpath:
            continue

        # Check if the dirpath contains 'ignore' and skip if so
        if 'ignore' in _dirpath:
            continue

        # Check if lissajous_data.parquet is not present in the filenames
        if 'lissajous_data.parquet' not in _filenames:
            convert_folder(
                _dirpath, _filenames, picoscope_exe, picoscope_view,
                parent_dir_project
            )
    return


if __name__ == "__main__":
    app.run()
