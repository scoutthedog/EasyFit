"""
gui.py

creates a tkinter gui application for fitting oocyte data




"""
import tkinter as tk
import matplotlib.pyplot as plt
import numpy as np
from tkinter import filedialog
import fitgraph
import subprocess
import reader
import database
import os
from openpyxl import load_workbook
from matplotlib.backends.backend_tkagg import (
    FigureCanvasTkAgg, NavigationToolbar2Tk)
# Implement the default Matplotlib key bindings.
from matplotlib.backend_bases import key_press_handler
from matplotlib.figure import Figure

class Window(tk.Frame):
    #__slots__ = ['master.title', 'master.wm_iconbitmap', 'singlecsv', 'drttodb','wslist']
    def __init__(self, master = None):
        """
        Initiates the master window, where the user is taken when they start the program
        """
        tk.Frame.__init__(self, master)
        self.pack()
        self.init_window()
    def init_window(self):
        """
        Creates buttons for the user to supply commands
        """
        self.master.title("EasyFit")
        self.master.wm_iconbitmap('EasyFit.ico')
        self.singlecsv = tk.Button(self.master, text = "single csv import", command = self.import_csv_data)
        self.dirtodb = tk.Button(self.master, text = "database import", command = self.database_import)
        # CAREFUL THIS IS THE OLD SCRIPT
        #self.oldbutton = tk.Button(self.master, text = "old import method script", command = lambda : 
        #                           database.dbupload(reader.turtle_wtm_experiments, reader.turtle_wtm_oocytes))
        self.singlecsv.pack({"side" : "top"})
        self.dirtodb.pack({"side" : "top"})
        #self.oldbutton.pack({"side" : "top"})
    def import_csv_data(self):
        dir = filedialog.askopenfilename(initialdir = "/", title = "Select csv file")
        self.wslist = reader.read_csv(dir)
        fig = fitgraph.showgraph(wslist)
        # places the figure output from matplotlib in the tkinter canvas
        canvas = FigureCanvasTkAgg(fig, master = self.master)  # A tk.DrawingArea.
        canvas.draw()
        canvas.get_tk_widget().pack(side = tk.TOP, fill = tk.BOTH, expand = 1)
        # creates the toolbar from matplotlib in the tkinter gui
        toolbar = NavigationToolbar2Tk(canvas, self.master)
        toolbar.update()
        canvas.get_tk_widget().pack(side = tk.TOP, fill = tk.BOTH, expand = 1)
    def database_import(self, wtm_function = reader.gorilla_wtm_oocytes):
        """
        This is the general database import script to be used the user

        First prompts the user to specify a directory to read the excel files
        Then prompts the user to specify a directory to write the csv files
        The csv files are written, and the fits are applied.
        """
        self.wslist = []
        readdir = filedialog.askdirectory(initialdir = "C:/Users/jpa/Desktop", title = "Select directory for database upload")
        writedir = filedialog.askdirectory(initialdir = "C:/Users/jpa/Desktop", title = "Select working directory")
        for filename in os.listdir(readdir):
            csvfilename = filename[0:(len(filename)-4)] + 'csv' # same name as excel file with .csv extention
            readfulldir = readdir + '/' + filename # the directory of the excel file
            writefulldir = writedir + '/' + csvfilename # the directory of the csv file to be created
            fig = self.fit_csv(filename, readfulldir, writefulldir,)
            
    def fit_csv(self, filename, readfulldir, writefulldir, 
                wtm_function = reader.gorilla_wtm_oocytes,
                scriptpath = 'C:/Users/jpa/source/repos/oocytedb/oocytescript.R', 
                command = 'Rscript'):
        """
            
        """
        reader.write_csv(readfulldir, writefulldir, wtm_function) # see reader.py for documentation
        if filename[11:13] == 'Zn':
            # if the file is a zinc file it will default to leaving the bottom uncontrained
            bot = 'FALSE'
            top = 'TRUE'
        else:
            # otherwise the bottom will be contrained
            # keep in mind the script can be re-run in order to use the desired contraints
            bot = 'TRUE'
            top = 'TRUE' 
        cmd = [command , scriptpath , writefulldir, bot, top] # contructing the command to be used by Rscript
        subprocess.call(cmd) # calling R subprocess
        self.wslist = reader.read_csv(writefulldir) # reads the csv file and saves it
        fig = fitgraph.showgraph(self.wslist)
        canvas = FigureCanvasTkAgg(fig, master = self.master)  # A tk.DrawingArea.
        canvas.draw() 
        canvas.get_tk_widget().pack(side = tk.TOP, fill = tk.BOTH, expand = 1)
        toolbar = NavigationToolbar2Tk(canvas, self.master)
        toolbar.update()
        canvas.get_tk_widget().pack(side = tk.TOP, fill = tk.BOTH, expand = 1)
        return(fig)
        


def setreaddir():
    readdir = filedialog.askdirectory(initialdir = "/",title = "Select read directory")
    return readdir
def setwritedir():
    writedir = filedialog.askdirectory(initialdir = "/", title = "Select write directory")
    global v
    for dir in os.listdir(writedir):
        v = reader.read_csv(dir)
        fitgraph.showgraph(v)


def main():
    root = tk.Tk()
    app = Window(root)
    root.mainloop()
    return(None)

