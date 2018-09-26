import numpy as np
import matplotlib.pyplot as plt
import matplotlib.backends.tkagg as tkagg
from matplotlib.backends.backend_tkagg import (
    FigureCanvasTkAgg, NavigationToolbar2Tk)
import tkinter as tk
from matplotlib.backend_bases import key_press_handler
from matplotlib.figure import Figure
from openpyxl import load_workbook

def showgraph(wslist):
    """
    opens a matplotlib window and displays a graph using the csv data
    """
    X = np.linspace(-11, 1, 100)
    fig = plt.figure(figsize=(16,12))
    conc = [0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000]
    def conv(x):
        x = np.log10(x / 1000000)
        return x
    dose = list(map(conv, conc))
    def get_cmap(n, name='hsv'):
        '''Returns a function that maps each index in 0, 1, ..., n-1 to a distinct 
        RGB color; the keyword argument name must be a standard mpl colormap name.'''
        return plt.cm.get_cmap(name, n)
    varlist = [] # blank list of variants to be added to
    for row in wslist: # adds each unique variant found in the csv data
        # this will be used later to add labels and colors
        if wslist.index(row) == 0:
            continue
        variant = row[2] + '/' + row[3]
        if variant not in varlist:
            varlist.append(variant)
        else:
            continue
    # creates a color map the size of the number of variants in the data
    cmap = get_cmap(len(varlist) + 1, name = 'jet')
    fig = Figure(figsize=(5, 4), dpi=100)
    sub1 = fig.add_subplot(111)
    sub1.set_title('Daily Recording Test')
    sub1.set_ylabel('% Response')
    sub1.set_xlabel('log[Agonist]')
    for row in wslist:
        if wslist.index(row) == 0:
            continue
        if row[27] == '':
            continue
        rowvar = row[2] + '/' + row[3]
        varindex = varlist.index(rowvar)
        color = cmap(varindex)
        datalist = row[5:24]
        def none_float(string):
            if string == "":
                return(None)
            else:
                return(float(string))
        datalist = list(map(none_float, datalist) )
        c = float(row[27])
        h = float(row[28])
        b = float(row[29])
        t = float(row[30])
        file = row[0]
        outputlist = [file] + [rowvar] + [c] + [h] + [b] + [t] + datalist
        print(outputlist)
        sub1.plot(dose, datalist, 'o', color = color)
        Y = b + ((t - b)/(1+(10**((c-X)*h))))
        sub1.plot(X, Y, color = color, label = rowvar + '  ...  ' + file)
    sub1.legend(loc = 0)
    return(fig)
    