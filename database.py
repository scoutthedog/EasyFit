#! C:/Users/jpa/Anaconda3/python

"""
For processing and uploading oocyte recording data stored in excel files into a MySQL database

A general outline of the flow of this program.
1) Uses openpyxl to read excel files and import them into python lists.
2) The lists are then written to csv files
3) The csv files are read by an R subprocess which calls Rscript and passes arguments from commandline
4) The Rscript generates fits for the data and rewrites the csv file including the information about the fits
5) The now fit data is uploaded to the MySQL database
"""

import os
import csv
import subprocess
import mysql.connector as mysql
import pandas as pd
import datetime
import reader

from openpyxl import load_workbook

RECORDING_FILES_DIRECTORY = 'C:/Users/jpa/Desktop/uploaddata'
CSV_WRITE_DIRECTORY = 'C:/Users/jpa/Desktop/_2_csvdump'
RSCRIPT_PATH = 'C:/Users/jpa/source/repos/oocytedb/oocytescript.R'
DATABASE = 'oocytedb'

def dbcon():
    """
    opens a new MySQL database connection
    """
    con = mysql.connect(user='root', host='localhost', database=DATABASE)
    return con
def experiments_update(explist):
    """
    Connects to a MySQL database and uploads a list of experiment data to the table 'experiments'
    """
    if explist == []:
        return(None)
    con = dbcon()
    cursor = con.cursor()
    query = ("REPLACE INTO experiments"
             "(expID, assay, date_inj, date_rec, vhold, coagonist, phsol, drugID, rig, initials, experiment_info)"
             "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
             )
    cursor.execute(query, explist)
    con.commit()
    cursor.close()
    con.close
    return(None)
def oocytes_update(oocytelist):
    """
    Connects to a MySQL database and uploads a maxtrix (2-dimentional list) of data to the table 'oocytes'

    Prints data on command line, and the user confirms that the data is accurate before it is uploaded.
    The MySQL query uses the REPLACE syntax which means that old data is overwritten if the primary key (file)
    is already found in the 'oocytes' table.
    """
    con = dbcon()
    cursor = con.cursor()
    #pandas dataframe used to format the matrix nicely
    print(pd.DataFrame(oocytelist).to_string())
    for sublist in oocytelist:
        query = ("REPLACE INTO oocytes" 
                 "(expID,file,glun1,glun2,maxcurrent,ph68vs76,"
                 "logm10,logm95,logm9,logm85,logm8,logm75,logm7,logm65,logm6,logm55,logm5,logm45,logm4,logm35,"
                 "logm3,logm25,logm2,logm15,logm1,notes,dbinfo,logec50,hillslope,ymin,ymax,formula,isConv)"
                 "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, "
                 "%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
                 )
        cursor.execute(query, sublist)
    isgood = input("Does this look good? (y/n) ")
    if isgood == "y":
        con.commit()
        print("Uploaded to database")
        code = 1
    else:
        con.close
        print("Did not upload")
        code = 0
    con.close
    # code = 1 : uploaded
    # code = 0 : not uploaded
    return code


# Primary function.
def dbupload(wtm_function_experiments, wtm_function_oocytes): # This is the main script function  
    
    print('\nInitiating csv creation for R subprocess\n')
    reader.excel_to_csv(RECORDING_FILES_DIRECTORY, CSV_WRITE_DIRECTORY, wtm_function_oocytes) 
    print('\nInitiating R curve fitting\n')
    reader.call_rscript(CSV_WRITE_DIRECTORY, RSCRIPT_PATH)
    print('\nCurves fit. Preparing for database upload\n')
    reader.csv_to_db(CSV_WRITE_DIRECTORY, oocytes_update)
    print('Initiating experiments data upload\n')
    reader.excel_to_db(RECORDING_FILES_DIRECTORY, wtm_function_experiments, experiments_update) 
    return None
#testing


#---------------------------------------------------------------------------
#MAIN
def main():
    dbupload(turtle_wtm_experiments, turtle_wtm_oocytes)
    #iterexcel('C:/Users/jpa/Desktop/OOCYTES_RESULTS_DATA/oldtest', turtle_wtm_oocytes)
    return None
if __name__ == "__main__":
    main()


