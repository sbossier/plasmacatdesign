import os
import csv
import datetime
import matplotlib.pyplot as plt
import matplotlib.pyplot as plt
import random
# Create a 3x3 grid of subplots
fig, axes = plt.subplots(nrows=3, ncols=3)
# Set the size of the figure
fig.set_size_inches(15, 10)
# Adjust the spacing between subplots
fig.subplots_adjust(hspace=0.5, wspace=0.2)

# Get the directory where the Python script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
directory = "C:/Users\woute/OneDrive - Universiteit Antwerpen\Master stage/Data/currenplots"
randomgetal1 = random.randint(1,11)
randomgetal2 = random.randint(1,5)
# Create a dictionary to store the data for each plot and subset
data = {}
# Iterate over all CSV files in the directory
for i, filename in enumerate(os.listdir(directory)):
    if filename.endswith(".csv"):
        # Open the CSV file
        with open(os.path.join(directory, filename)) as csvfile:
            csvreader = csv.reader(csvfile)
            # Skip the first row (header) of the CSV file
            next(csvreader)
            # Iterate over each row in the CSV file
            for row in csvreader:
                # Get the integers in the third and fourth columns
                plot_id = int(row[2])
                subset_id = int(row[3])
                # Add the row to the data dictionary
                if plot_id not in data:
                    data[plot_id] = {}
                if subset_id not in data[plot_id]:
                    data[plot_id][subset_id] = []
                data[plot_id][subset_id].append(row)
        #kiest random 2 getallen die gebruikt worden om een random current profile te selecteren        
        plot_id = 1
        subset_id = 1
        if plot_id in data and subset_id in data[plot_id]:
            for h in range(11):
                for g in range(5):
                    # Extract the x and y values from the data dictionary
                    iteratie_plot = h+1
                    iteratie_subplot = g+1
                    rows = data[iteratie_plot][iteratie_subplot]
                    x_values = [float(row[0]) for row in rows]
                    y_values = [float(row[1]) for row in rows]
                    #geneer de juiste plek voor de grafiek
                    row_index, col_index = divmod(i, 3)
                    ax = axes[row_index, col_index]
                    #plot de data in het juiste subplot
                    ax.plot(x_values, y_values, color='black', alpha = 0.1)
                    ax.set_xlabel("Time (ms)")
                    ax.set_ylabel("Current (mA)")
                    # Set the title to the filename without the ".csv" extension
                    if filename == 'AlNO3-F90.csv':
                        filename = 'AlNO₃-F90'
                    ax.set_title(os.path.splitext(filename)[0])
                    # Set the x-axis range to [0, 10] and y-axis range to [0, 20]
                    ax.set_ylim(0,150)
            
            
        data = {}
        
timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
plot_filename = "Current plots-test" + timestamp + ".png"
plot_path = os.path.join(script_dir, plot_filename)
plt.savefig(plot_path)
plt.show()
plt.close()

             
       

