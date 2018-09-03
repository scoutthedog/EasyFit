#! C:/Users/jpa/Anaconda3/python

import os
from openpyxl import load_workbook
import csv
import subprocess
import mysql.connector
import pandas
import datetime

#git test

#--------------------------------------------------------------------------
#database connections
def dbcon():
    con = mysql.connector.connect(user='root',
                              host='localhost',
                              database='oocytedb')
    return(con)
def experiments_update(list):
    con = dbcon()
    cursor = con.cursor()
    query = ("REPLACE INTO experiments (expID, assay, date_inj, date_rec, vhold, coagonist, phsol, drugID, rig, initials, experiment_info) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")
    cursor.execute(query, list)
    con.commit()
    cursor.close()
    con.close
    return None
def oocytes_update(list):
    con = dbcon()
    cursor = con.cursor()
    print(pandas.DataFrame(list).to_string())
    for sublist in list:
        query = ("REPLACE INTO oocytes (expID,file,glun1,glun2,maxcurrent,ph68vs76,logm10,logm95,logm9,logm85,logm8,logm75,logm7,logm65,logm6,logm55,logm5,logm45,logm4,logm35,logm3,logm25,logm2,logm15,logm1,notes,dbinfo,logec50,hillslope,ymin,ymax,formula,isConv) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")
        result = cursor.execute(query, sublist)
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
    return code

#-------------------------------------------------------------------------
#wtm functions (worksheet to matrix). 
#These functions convert an excel file into a python list of lists.
#usually raw data from excel files.
#sometimes this is acceptable.
def fox_wtm(ws):
    #reads oocyte data files of the format 'fox'
    #I made up this name just to make it easier to remember what functions are being used for each file type.
    wslist = []
    nonelist = [None] * 37
    for row in ws.iter_rows(min_row=3, min_col=1, max_row=100, max_col=37):
        rowlist = []
        for cell in row:
            rowlist.append(cell.value)
        if rowlist == nonelist:
            break
        else:
            wslist.append(rowlist)
    header = ['assay','file','glun1','glun2','maxcurrent','ph68vs76','logm10','logm95','logm9','logm85','logm8','logm75','logm7','logm65','logm6','logm55','logm5','logm45','logm4','logm35','logm3','logm25','logm2','logm15','logm1','notes','date_inj','date_rec','vhold','coagonist','phsol','rig','initials','dpi','rnapotglun1','rnapotglun2','dbinfo']
    wslist = [header] + wslist
    return wslist
def gorilla_wtm_oocytes(ws):
    #gorilla is the most recent version of oocyte data templates
    wslist = []
    nonelist = [None] * 27
    for row in ws.iter_rows(min_row=3, min_col=1, max_row=100, max_col=26):
        rowlist = []
        counter = 0
        for cell in row:
            if counter == 0:
                if cell.value == None:
                    break
                rowlist.append(expid(cell.value))
            rowlist.append(cell.value)
            counter = counter + 1
        if rowlist == nonelist:
            break
        else:
            wslist.append(rowlist)            
    header = ['expID','file','glun1','glun2','maxcurrent','ph68vs76','logm10','logm95','logm9','logm85','logm8','logm75','logm7','logm65','logm6','logm55','logm5','logm45','logm4','logm35','logm3','logm25','logm2','logm15','logm1','notes','dbinfo']
    wslist = [header] + wslist
    return wslist
def gorilla_wtm_experiments(ws):

    wslist = []
    nonelist = [None] * 10
    for row in ws.iter_rows(min_row=3, min_col=27, max_row=3, max_col=36):
        file1 = ws['A3'].value
        experimentid = expid(file1)
        rowlist = [experimentid]
        for cell in row:
            rowlist.append(cell.value)
        if rowlist == nonelist:
            break
    #header = ['experimentid','assay','date_inj','date_rec','vhold','coagonist','phsol','drugid','rig','initials','experiment_info']
    #wslist = [header] + wslist
    print(rowlist[0] + ' --- uploaded to experiments table in database')
    return rowlist
def turtle_wtm(ws):
    #turtle is for working with older oocytes templates
    wslist = []
    nonelist = [None] * 16
    nonecounter = 0
    for row in ws.iter_rows(min_row=1, min_col=2, max_row=100, max_col=17):
        rowlist = []
        for cell in row:
            rowlist.append(cell.value)
        if rowlist == nonelist:
           nonecounter += 1
           if nonecounter == 2:
               break
        else:
            wslist.append(rowlist)     
    return wslist

def getassay(wslist):
    assay = wslist[2][5]
    if assay == 'Glycine DRC (uM)':
        assay = 'glyDRC'
    elif assay == 'Glutamate DRC (uM)':
        assay = 'gluDRC'
    elif assay == 'pH':
        assay = 'pH'
    elif assay == '1 min 1 conc ':
        assay = '1min1conc'
    elif assay == None:
        assay = wslist[2][4]
        if assay == 'Mg2+ (uM)':
            assay = 'mgDRC'
    else:
        assay = wslist[0][3]
        if assay == 'Zn2+ inhibition (10 mM Tricine)':
            assay = 'znDRC'
        else:
            assay = wslist[1][3]
            if assay == 'in 100 uM Glutamate and 100uM Glycine':
                assay = 'mGluGly'
    return assay
def postpA(explist):
    date_inj = explist[2]
    if type(date_inj) != datetime.datetime:
        date_inj = None
    explist[2] = date_inj
    vhold = explist[4]
    vhold = vhold.strip('Vhold=')
    vhold = vhold.strip(' mV')
    explist[4] = vhold
    phsol = explist[6]
    phsol = phsol.strip('pH ')
    explist[6] = phsol
    rig = explist[8].replace('#','')
    explist[8] = rig
    initials = explist[9]
    if initials == 'skim':
        initials = 'sk'
    explist[9] = initials
    minidate = explist[3].strftime('%m%d%y')
    miniassay = explist[1].strip('DRC')
    explist[0] = miniassay + '-' + rig + '-' + initials + '-' + minidate
    return(explist)
def assayfinder(wslist):
    assay = getassay(wslist)
    if assay == 'gluDRC':
        explist = glu.getexperiments(wslist)
        oocytes = glu.getoocytes(wslist)
    elif assay == 'glyDRC':
        explist = gly.getexperiments(wslist)
        oocytes = gly.getoocytes(wslist)
    elif assay == 'mgDRC':
        explist = mg.getexperiments(wslist)
        oocytes = mg.getoocytes(wslist)
    elif assay == 'znDRC':
        explist = zn.getexperiments(wslist)
        oocytes = zn.getoocytes(wslist)
    elif assay == 'pH':
        explist = ph.getexperiments(wslist)
        oocytes = ph.getoocytes(wslist)
    else:
        explist = []
        oocytes = []
    print(explist)
    for row in oocytes:
        print(row)
    return None

#classes
class excelcoordinates:
    def __init__(self, assay, postp, date_inj, date_rec, vhold,
                coagonist, phsol, drugid, rig, 
                initials, note, filename, glun1, 
                glun2, current, d_start,
               d_end, r_start, r_end, rec_note):
        self.assay = assay #assay string
        self.postp = postp #post processing function used for the class instance
        #contains a dictionary of tuples as coordinates that refer to their location in the wtm_function
        #wtm_function -> raw data as a list-> excelcoordinates -> postp -> ready for database upload
        self.experiments = ({'date_inj':date_inj, 'date_rec':date_rec, 'vhold':vhold, 
                             'coagonist':coagonist, 'phsol':phsol, 'drugid':drugid, 'rig':rig, 'initials':initials, 
                             'note':note})
        #d_start - dose start
        #d_end - dose end - these are the headers for the data, determines where the data should be placed
        #r_start - response start
        #r_end - response end
        self.oocytes = ({'filename':filename, 'glun1':glun1, 
                             'glun2':glun2, 'current':current, 'd_start':d_start, 
                             'd_end':d_end, 'r_start':r_start, 'r_end':r_end, 'rec_note':rec_note})
    def getexperiments(self, wslist):
        #leaves the first value expID blank, and sets assay to what was given at initialization
        experimentlist = [None, self.assay]
        #iterating through keys and value of the experiments dictionary
        for key, value in self.experiments.items():
            if value == None:
                #checking if the dictionary value is None
                #value stays None
                wsvalue = value
            else:
                #value is set to whatever is in the coordinates of wslist
                x = value[0]
                y = value[1]
                wsvalue = wslist[x][y]
            experimentlist.append(wsvalue)
        #postp processes the values in the experiment list (see postp functions)
        return(self.postp(experimentlist))
    def getoocytes(self, wslist):
        #behavior is different for pH
        if self.assay == 'pH':
            oocytes = []
        #all other assays
        else:
            #d is now the dictionary of oocytes coordinates
            d = self.oocytes
            rowstart = d['filename'][0]
            dosestart = d['d_start'][0]
            oocytes = []
            header = ['filename','glun1','glun2','current']
            for dose in range(d['d_start'][1], d['d_end'][1] + 1):
                heading = wslist[dosestart][dose]
                header.append(heading)
            doses = header[4:]
            rounded = []
            fulldose = [-10, 9.52, -9, -8.52, -8, -7.52, -7, -6.52, -6, -5.52, -5, -4.52, -4, -3.52, -3, -2.52, -2, -1.52, -1]
            explist = self.getexperiments(wslist)
            expid = explist[0]
            for value in doses:
                if value == None:
                    pass
                else:
                    value = round(value, 2)
                rounded.append(value)
            indexes = []
            for value in rounded:
                value = fulldose.index(value)
                indexes.append(value)
            nonecolspre = [None] * min(indexes)
            nonecolspost = [None] * (18 - max(indexes))
            for row in range(rowstart, len(wslist)):
                filename = wslist[row][d['filename'][1]]
                k = filename.rfind('-')
                filename = expid + filename[k:]
                note = wslist[row][d['rec_note'][1]]
                rowlist = [filename] + [wslist[row][d['glun1'][1]], wslist[row][d['glun2'][1]], wslist[row][d['current'][1]]] + [None] + nonecolspre
                for response in range(d['r_start'][1], d['r_end'][1] + 1):
                    record = wslist[row][response]
                    rowlist.append(record)
                rowlist = rowlist + nonecolspost + [note] + [None]
                oocytes.append(rowlist)
        return(oocytes)


#class instances
#glu instance of class excelcoordinates
glu = excelcoordinates(assay = 'gluDRC', postp = postpA, date_inj = (0,1), date_rec = (1,1), vhold = (0,3), coagonist = (1,3), phsol = (0,5), drugid = None,
                       initials = (0,7), rig = (1,7), note = (0,9), filename = (5,0), glun1 = (5,1), glun2 = (5,2), 
                       current = (5,3), d_start = (4,5), d_end = (4,14), r_start = (5,5), r_end = (5,14), rec_note = (5,15))
gly = glu
gly.assay = 'glyDRC'
#
mg = excelcoordinates(assay = 'mgDRC', postp = postpA, date_inj = (0,1), date_rec = (1,1), vhold = (0,5), coagonist = (1,3), phsol = (1,5), drugid = None,
                      initials = (0,8), rig = (1,8), note = (0,10), filename = (5,0), glun1 = (5,1), glun2 = (5,2),
                      current = (5,3), d_start = (4,5), d_end = (4,13), r_start = (5,5), r_end = (5,13), rec_note = (7,14))
ph = excelcoordinates(assay = 'pH', postp = postpA, date_inj = (0,1), date_rec = (1,1), vhold = (0,5), coagonist = (1,2), phsol = (0,2), drugid = None,
                      initials = (0,9), rig = (1,9), note = (0,11), filename = (7,0), glun1 = (7,1), glun2 = (7,2),
                      current = (7,3), d_start = (4,6), d_end = (4,6), r_start = (7,6), r_end = (7,6), rec_note = (7,15))
zn = excelcoordinates(assay = 'znDRC', postp = postpA, date_inj = (0,1), date_rec = (1,1), vhold = (0,5), coagonist = (1,3), phsol = (1,5), drugid = None,
                      initials = (0,7), rig = (1,7), note = (0,9), filename = (5,0), glun1 = (5,1), glun2 = (5,2),
                      current = (5,3), d_start = (4,5), d_end = (4,10), r_start = (5,5), r_end = (5,10), rec_note = (5,14))
#---------------------------------------------------------------------------
#other functions
def find_nth(str, x, n, i = 0):
    #to find the nth occurence of x in the string str
    i = str.find(x, i)
    if n == 1 or i == -1:
        return i 
    else:
        return find_nth(str, x, n - 1, i + len(x))
def expid(file):
    test = find_nth(file, '-', 4)
    #find the 4th occurance of '-' in file
    expid = file[:test]
    #remove anything after the 4th occurance of '-'
    #example: glu-mb1-jpa-082918-14.5   -->  glu-mb1-jpa-082918
    return expid
def createcsv(filename, csvname, wtm_function): # you should specify which wtm function you use (worksheet to matrix)
    wb = load_workbook(filename, data_only = True)
    ws = wb['DataEntry']
    wslist = wtm_function(ws)
    #wtm_function chosen based on arguments
    with open(csvname, 'w', newline = '') as csvfile:
        testwriter = csv.writer(csvfile)
        for wslist in wslist:
            testwriter.writerow(wslist)
        return(None)
    return(None)
def foldertocsv(readdir, writedir, wtm_function): #writes all excel files in a folder to a csv in a folder
    for filename in os.listdir(readdir):
        csvfilename = filename[0:(len(filename)-4)] + 'csv'
        readfulldir = readdir + '/' + filename
        writefulldir = writedir + '/' + csvfilename
        createcsv(readfulldir, writefulldir, wtm_function)
        #wtm_function chosen based on arguments
        print(csvfilename + ' --- written to desktop folder csvdump')
    writelen = len(os.listdir(readdir))
    writestr = str(writelen) + " files written to csv"
    print(writestr)
    return(None)
def foldertodb(readdir, wtm_function, db_function):
    for filename in os.listdir(readdir):
        readfulldir = readdir + '/' + filename
        wb = load_workbook(readfulldir, data_only = True)
        ws = wb['DataEntry']
        db_function(wtm_function(ws))
    writelen = len(os.listdir(readdir))
    writestr = str(writelen) + " files written to database"
    print(writestr)
    return None
def rscript(readdir, scriptpath): #exectues an Rscript as a subprocess
    command = 'Rscript'
    for filename in os.listdir(readdir):
        filefull = readdir + '/' + filename
        if filename[11:13] == 'Zn':
            bot = 'FALSE'
            top = 'TRUE'
        else:
            bot = 'TRUE'
            top = 'TRUE' 
        cmd = [command , scriptpath , filefull, bot, top]
        subprocess.call(cmd)
        print(filefull + '--- added fits to the file')
    return(None)
def csvreader(csvfile):  
  with open(csvfile, mode = 'r') as fp:
    reader = csv.reader(fp, delimiter=',', quotechar='"')
    # next(reader, None)  # skip the headers
    data_read = [row for row in reader]
  return(data_read)
def folderreadtodatabase(readdir, db_function):
    count = 0
    for filename in os.listdir(readdir):
        readfulldir = readdir + '/' + filename
        print(readfulldir)
        filelist = csvreader(readfulldir)
        code = db_function(filelist)
        count += code
    print(str(count) + " file(s) uploaded to database")
    return None

#---------------------------------------------------------------------------
#body
def dbupload():
    print('Initiating experiments data upload\n')
    foldertodb('C:/Users/jpa/Desktop/uploaddata', gorilla_wtm_experiments, experiments_update)
    print('\nInitiating csv creation for R subprocess\n')
    foldertocsv('C:/Users/jpa/Desktop/uploaddata', 'C:/Users/jpa/Desktop/csvdump', gorilla_wtm_oocytes)
    print('\nInitiating R curve fitting\n')
    rscript('C:/Users/jpa/Desktop/csvdump', 'C:/Users/jpa/source/repos/oocytedb/oocyte_cmd.R')
    print('\nCurves fit. Preparing for database upload\n')
    folderreadtodatabase('C:/Users/jpa/Desktop/csvdump', oocytes_update)
    return None
def iterexcel(readdir, wtm_function, listfunction, wsname):
    for filename in os.listdir(readdir):
        readfulldir = readdir + '/' + filename
        wb = load_workbook(readfulldir, data_only = True)
        ws = wb.worksheets[0]
        wslist = wtm_function(ws)
        listfunction(wslist)
    return wslist


iterexcel('C:/Users/jpa/Desktop/oldformat', turtle_wtm, assayfinder, 'Sheet1')


