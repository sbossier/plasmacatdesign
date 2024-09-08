import PyPDF2
import pandas as pd
import re
import csv
import os

# Open the PDF file


def get_file_name(file_path):
    """
    This function takes a file path as input and returns the file name without the extension.
    """
    file_name = os.path.basename(file_path)  # get the file name from the file path
    file_name_without_extension, extension = os.path.splitext(file_name)  # split the file name and extension
    return file_name_without_extension


def get_pdf_files(path):
    """
    This function takes a path to a folder as input and returns a list of all pdf files in that folder.
    """
    pdf_files = []
    for file_name in os.listdir(path):
        if file_name.endswith('.pdf'):
            pdf_files.append(os.path.join(path, file_name))
    return pdf_files

def read_string_text(lines, header):
    # Initialize an empty list to store the dataframes
    dfs = []
    # Initialize a counter to keep track of the number of dataframes read
    count = 0
   
    # Initialize an empty list to store the rows of each dataframe
    df_rows = []
    # Iterate over the lines
    found_table = False
    for line in lines:
        # Check if the line is one of the keywords that separates the dataframes
        if any([True for word in line.split() if word in header]):
            found_table = True
            df = pd.DataFrame(df_rows)
            # Append the new dataframe to the list of dataframes
            dfs.append(df)
            # Increment the counter
            count += 1
            # Clear the list of rows for the next dataframe
            df_rows = []
        else:
            # If the line is not a keyword, split it into columns and append the row to the list
            row = line.strip().split()
            if row[0] not in compounds:
                row.insert(0, 'N.F')
            df_rows.append(row)
    # Create the final dataframe with the remaining rows
    df = pd.DataFrame(df_rows)
    dfs.append(df)

    # Return the list of dataframes
    if found_table:
        return dfs
   
    return []
       


compounds = [
"CO2",
"CH4",
"N2",
"CO",
"H2",
"O2",
"C2H6",
"C2H4",
"C2H2",
"C3H8",
"CH3OCH3",
"CH3OH",
"CH3CH2OH"]
print('compounds that can be detected:')
print('\n'.join(map(str, compounds)))


path_folder = 'H:/data/co2-splitting/uhasselt/SiO2+TMAH+2-PrOH-220-09H/chromatograms/02.5s-01-plasma.rslt/'
print('folder defined is: ' + path_folder)

pdf_files = get_pdf_files(path_folder)

#loop over all pdf files found in the directory
for pdf_file in pdf_files:
   
    pdf_reader = PyPDF2.PdfReader(pdf_file)

    #extract text in a list containing each page. Each entry is one large string.
    pages_text = []
    for page in pdf_reader.pages:
        pages_text.append(page.extract_text())

    counter = 0
    #process each page string
    for page_string in pages_text:
        lines = page_string.split('\n')
       
        header = ['Compound', 'RT', 'Exp. RT', 'Area (a.u.)', 'Area (%)']
        #get list of dataframse with the tables
        dfs = read_string_text(lines, header)
        if len(dfs) != 0:
            for df in dfs:
                counter += 1
                #TODO we should add a check and see whether the df is really a table
                df.to_csv(path_folder + get_file_name(pdf_file) + '_' + str(counter) + '.csv', sep = ';')
       
        #save as csv only dfs that have the tables in it.