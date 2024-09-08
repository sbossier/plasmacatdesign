import os
from PyPDF2 import PdfMerger

def merge_pdfs_in_folder(folder_path, output_filename):
    merger = PdfMerger()

    # Get all the PDF filenames in the specified folder
    pdf_files = [f for f in os.listdir(folder_path) if f.endswith(".pdf")]

    # Merge each PDF file
    for filename in pdf_files:
        merger.append(os.path.join(folder_path, filename))

    # Write the merged PDF to a file
    merger.write(output_filename)
    merger.close()
    print(f"Merged {len(pdf_files)} PDFs into {output_filename}")

# Example usage:
merge_pdfs_in_folder(r'C:\Users\sbossier\Desktop\test', r'C:\Users\sbossier\Desktop\test\output.pdf')
