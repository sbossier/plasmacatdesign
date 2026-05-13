import os
import shutil
import argparse

def copy_selected_files(source_dir, dest_dir, extensions=(".csv", ".psdata")):
    """
    Recursively copy files with specified extensions from source_dir to dest_dir,
    preserving the subdirectory structure.
    
    :param source_dir: The source parent directory.
    :param dest_dir: The destination directory.
    :param extensions: A tuple of file extensions to include (default: .csv and .psdata).
    """
    for root, dirs, files in os.walk(source_dir):
        # Create the corresponding destination folder by preserving the relative path.
        relative_path = os.path.relpath(root, source_dir)
        destination_folder = os.path.join(dest_dir, relative_path)
        os.makedirs(destination_folder, exist_ok=True)

        for file in files:
            if file.lower().endswith(extensions):
                src_file = os.path.join(root, file)
                dest_file = os.path.join(destination_folder, file)
                shutil.copy2(src_file, dest_file)  # copy2 preserves metadata
                print(f"Copied: {src_file} -> {dest_file}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Copy only .csv and .psdata files from a parent folder to a destination folder, preserving subfolders."
    )
    parser.add_argument("source", help="The source directory containing files and subfolders.")
    parser.add_argument("destination", help="The destination directory where files will be copied.")

    args = parser.parse_args()

    copy_selected_files(args.source, args.destination)
