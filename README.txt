README.txt

This is a program to help fit oocyte data.
There are sevral components of it

start.py - This is the main script that will start the program
gui.py - Uses Tkinter to build a GUI
database.py - Contains the functions you need to interact with the database
reader.py - Backend code to read excel documents
excelcoordinates.py - Backend code to read excel documents
reformat.py - Backend code to reformat old documents
oocytescript.R - Backend code to fit data
4paramDRC.R - Backend code to fit data

General program flow
A) start.py
B) Enter path of read directory
C) enter path of write directory
D) enter mode
modes:
read only
read and write
database upload

READ ONLY
1) Starts with the file in read directory
2) Writes a csv files to write directory
3) Writes fit data to the csv file using R
4) Reads the fitted data as text to the user
5) Shows a graph of the fits data
6) Deletes csv file when finished
repeat steps 1-5 for each file in the read directory
* no modifications are made to the original excel file in this script
* a temporary csv file is written, so some disk space is needed for this

READ AND WRITE
1) Starts with the file in read directory
2) Writes a csv files to write directory
3) Writes fit data to the csv file using R
4) Reads the fitted data as text to the user
5) Shows a graph of the fits data (with the defualt fitting method)
6) Asks the user if the data looks good
	IF YES
	------
	7) Adds the fits data to the excel file on seprate tab (fits)
	8) Generates a png file of the graphs
	8) Adds the graphs to the excel file in the tab

	IF NO
	-----
	7) Asks the user if they want to try a different method
		IF YES
		------
		

