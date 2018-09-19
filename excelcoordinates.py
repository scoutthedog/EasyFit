class excelcoordinates:
    """
    This class is used in order to convert older spreadsheet files for database entry.

    Methods:
    getexperiments(wslist):
    Takes a list matrix and reformats it properly based on the initiation of the class (which coordinates were given)
    Outputs
    On class initiation, the coordinates are entered as tuples. A matrix of values derrived straight from
    the excel spreadsheet are inputted and then it returns a correctly formatted matrix.
    """
    def __init__(self, assay, postp, date_inj, date_rec, vhold,
                coagonist, phsol, drugid, rig, 
                initials, note, filename, glun1, 
                glun2, current, d_start,
               d_end, r_start, r_end, rec_note):
        """
        The Class is initialized with the coordinates as tuples. assay and postp are the only non tuple arguments
        """
        self.assay = assay #assay string
        self.postp = postp #post processing function used for the class instance
        
        # self.experiments : contains a dictionary of tuples as coordinates 
        # that refer to their location in the wtm_function
        # wtm_function -> raw data as a list-> excelcoordinates -> postp -> ready for database upload
        self.experiments = ({'date_inj':date_inj, 'date_rec':date_rec, 'vhold':vhold, 
                             'coagonist':coagonist, 'phsol':phsol, 'drugid':drugid, 'rig':rig, 'initials':initials, 
                             'note':note})
        # Some aberviations:
        # d_start - dose start
        # d_end - dose end - these are the headers for the data, determines where the data should be placed
        # r_start - response start
        # r_end - response end
        # self.oocytes : also a dictionary of tuples that refer to the locations 
        # that the data is found on the excel spreadsheet.
        self.oocytes = ({'filename':filename, 'glun1':glun1, 
                             'glun2':glun2, 'current':current, 'd_start':d_start, 
                             'd_end':d_end, 'r_start':r_start, 'r_end':r_end, 'rec_note':rec_note})
    def getexperiments(self, wslist):
        # leaves the first value expID blank, and sets assay to what was given at initialization
        experimentlist = [None, self.assay]
        # iterating through keys and value of the experiments dictionary
        for key, value in self.experiments.items():
            if value == None:
                # checking if the dictionary value is None
                # value stays None
                wsvalue = value
            else:
                # value is set to whatever is in the coordinates of wslist
                x = value[0]
                y = value[1]
                wsvalue = wslist[x][y]
            experimentlist.append(wsvalue)
        # postp processes the values in the experiment list (see postp functions)
        return(self.postp(experimentlist))
    def getoocytes(self, wslist):
        # d is now the dictionary of oocytes coordinates
        d = self.oocytes
        # an integer specifing the first row containing data (usually row 6 or 7)
        rowstart = d['filename'][0]
        # an integer specified the row containing the dose/concentration
        dosestart = d['d_start'][0]
        # using its own method getexperiments()
        explist = self.getexperiments(wslist)
        # experiment id will be used to calculate the filnames
        expid = explist[0]
        # left blank
        oocytes = [['expID','file','glun1','glun2','maxcurrent','ph68vs76',
                 'logm10','logm95','logm9','logm85','logm8','logm75','logm7',
                 'logm65','logm6','logm55','logm5','logm45','logm4','logm35',
                 'logm3','logm25','logm2','logm15','logm1','notes','dbinfo']]
        # behavior is different for pH
        if self.assay == 'pH':
            for row in range(rowstart, len(wslist)):
                filename = wslist[row][d['filename'][1]]
                k = filename.rfind('-')
                filename = expid + filename[k:]
                note = wslist[row][d['rec_note'][1]]
                nonelist = [None] * 17
                rowlist = [expid] + [filename] + [wslist[row][d['glun1'][1]],
                                                 wslist[row][d['glun2'][1]], 
                                                 wslist[row][d['current'][1]], 
                                                 wslist[row][d['r_start'][1]]] + nonelist + [wslist[row][d['rec_note'][1]]] + [None]
                oocytes.append(rowlist)
        # all other assays
        else:
            # the header is just a temporary placeholder that will be used to determine where to place the data
            header = ['filename','glun1','glun2','current']
            for dose in range(d['d_start'][1], d['d_end'][1] + 1):
                heading = wslist[dosestart][dose]
                header.append(heading)
            doses = header[4:]
            # this code is designed to figure out how many 'none' values need to be added before and after...
            #... in order to properly align the data for database entry.
            fulldose = [-10, -9.52, -9, -8.52, -8, -7.52, -7, -6.52, -6,
                       -5.52, -5, -4.52, -4, -3.52, -3, -2.52, -2, -1.52, -1]
            rounded = []
            for value in doses:
                if value == None:
                    pass
                else:
                    value = round(value, 2)
                rounded.append(value)
            indexes = []
            for value in rounded:
                if value == None:
                    pass
                else:
                    value = fulldose.index(value)
                    indexes.append(value)
            # cal
            nonecolspre = [None] * min(indexes)
            nonecolspost = [None] * (18 - (max(indexes)))
            for row in range(rowstart, len(wslist)):
                # creating the filename
                filename = wslist[row][d['filename'][1]]
                k = filename.rfind('-')
                filename = expid + filename[k:]
                note = wslist[row][d['rec_note'][1]]
                rowlist = [expid] + [filename] + [wslist[row][d['glun1'][1]], 
                                                  wslist[row][d['glun2'][1]], 
                                                  wslist[row][d['current'][1]]] + [None] + nonecolspre
                for response in range(d['r_start'][1], d['r_start'][1] + len(indexes)):
                    record = wslist[row][response]
                    rowlist.append(record)
                rowlist = rowlist + nonecolspost + [note] + [None]
                oocytes.append(rowlist)
        return(oocytes)



