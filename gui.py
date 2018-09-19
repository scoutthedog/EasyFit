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


v = []

class Window(tk.Frame):
    def __init__(self, master = None):
        """
        TODO
        """
        tk.Frame.__init__(self, master)
        self.master = master
        self.init_window()
    def init_window(self):
        """
        TODO
        """
        self.master.title("EasyFit")
        self.master.wm_iconbitmap('EasyFit.ico')
        self.singlecsv = tk.Button(self.master, text = "single csv import", command = import_csv_data)
        self.dirtodb = tk.Button(self.master, text = "database import", command = database_import)
        self.oldbutton = tk.Button(self.master, text = "old import method script", command = lambda : 
                                   database.dbupload(reader.turtle_wtm_experiments, reader.turtle_wtm_oocytes))
        self.singlecsv.pack()
        self.dirtodb.pack()
        self.oldbutton.pack()
        


def setreaddir():
    readdir = filedialog.askdirectory(initialdir = "/",title = "Select read directory")
    return readdir
def setwritedir():
    writedir = filedialog.askdirectory(initialdir = "/", title = "Select write directory")
    global v
    for dir in os.listdir(writedir):
        v = reader.read_csv(dir)
        fitgraph.showgraph(v)
def import_csv_data():
    global v
    dir = filedialog.askopenfilename(initialdir = "/", title = "Select csv file")
    v = reader.read_csv(dir)
    fitgraph.showgraph(v)
def database_import(wtm_function = reader.gorilla_wtm_oocytes):
    global v
    readdir = filedialog.askdirectory(initialdir = "C:/Users/jpa/Desktop", title = "Select directory for database upload")
    writedir = filedialog.askdirectory(initialdir = "C:/Users/jpa/Desktop", title = "Select working directory")
    scriptpath = 'C:/Users/jpa/source/repos/oocytedb/oocytescript.R'
    command = 'Rscript'
    for filename in os.listdir(readdir):
        csvfilename = filename[0:(len(filename)-4)] + 'csv'
        print(csvfilename)
        readfulldir = readdir + '/' + filename
        print(readfulldir)
        writefulldir = writedir + '/' + csvfilename
        print(writefulldir)
        reader.write_csv(readfulldir, writefulldir, wtm_function)
        if filename[11:13] == 'Zn':
            bot = 'FALSE'
            top = 'TRUE'
        else:
            bot = 'TRUE'
            top = 'TRUE' 
        cmd = [command , scriptpath , writefulldir, bot, top]
        print(cmd)
        subprocess.call(cmd)
        v = reader.read_csv(writefulldir)
        fitgraph.showgraph(v)
        input("Press Enter to continue...")
    

def main():
    root = tk.Tk()
    app = Window(root)
    root.mainloop()
    return(None)

