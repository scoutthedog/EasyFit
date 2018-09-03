#HOW TO USE THIS FILE
#syntax:
#         >  Rscript oocyte_cmd.R filepath b_const t_const
#
#  where filepath is the location of the csv file
#  and b_const is (TRUE/FALSE) indicating if the top is constrained in the fit equation model
#  and t_const is (TRUE/FALSE) indicating if the bottom is constrained in the fit equation model

#CURRENT PATH
#    Rscript C:\Users\jpa\source\repos\oocytedb\oocyte_cmd.R C:\Users\jpa\Desktop\csvdump\080218-MB2-Glut.csv

#A script for fitting oocyte data
suppressMessages(library(RMySQL))
suppressMessages(library(DBI))
#widens the command prompt output to prevent text wrapping
options(width = 10000)
options(warn=-1)
options(show.error.messages=FALSE)


#oocyte_functions.R is the base function that contains many of the tools for oocyte data analysis, etc
source("C:/Users/jpa/source/repos/oocytedb/oocyte_functions.R")

#taking args
args = commandArgs(trailingOnly = TRUE)
#below is for testing purposes only
#args <- c("C:/Users/jpa/Desktop/csvdump/080218-MB2-Glut.csv", TRUE, TRUE)
if (length(args) == 0) {
  stop("This scripts requires you to specify an input file", call.=FALSE)
}
#will assume that bot and top are constrained if not specified explicitly
if (length(args) == 1) {
  b_const <- TRUE
  t_const <- TRUE
}
#will assume that top is constrained if not otherwise specified
if (length(args) == 2) {
  b_const <- as.logical(args[2])
  t_const <- TRUE
}
#explicit declaration of args
if (length(args) == 3) {
  b_const <- as.logical(args[2])
  t_const <- as.logical(args[3])
}
inputfile <- args[1]

#reads the csv file specified by the commandline argument
db <- read.csv(inputfile, header = TRUE, na.string = "NA")
#this code removes any rows where the dbinfo column specifies DEL
#deltes the data before it makes it to the database upload
db %>%
  filter(dbinfo != "DEL") -> db2
if (nrow(db2) == 0) {
  newdb <- db
} else {
  newdb <- db2
}
#genuploaddata is from oocyte_functions.R, generates the fits
uploaddata <- gorilla_genuploaddata(newdb, b_const, t_const)
write.csv(uploaddata, file = inputfile, na = "", row.names = FALSE)

#if (input == "y") {
 # write.csv(uploaddata, file = inputfile, na = "", row.names = FALSE)
  #print("csv written for python")
  #database operations
  #con <- dbConnect(RMySQL::MySQL(), dbname = "oocytedb", user = "root")
  #dbWriteTable(con, name = "temp_oocytes", value = uploaddata, overwrite = TRUE, row.names = FALSE)
  #dbDisconnect(con)

  #selecting variables for csv
  #uploaddata %>%
  #  select(file, glun1, glun2, ymin, ymax, logec50, hillslope) -> csv
  #csv$logec50  <- as.numeric(csv$logec50)
  #csv <- mutate(csv, uMEC50 = touM(logec50))
  
  #writing csv
  #filenocsv <- substr(inputfile, 30, nchar(inputfile)-4)
  #filepath <- substr(inputfile, 1, 21)
  #  write.csv(csv, file = paste(filepath, "fits/", filenocsv, "-fit.csv", sep = ""), na = "", row.names = FALSE)
  
  #print("data uploaded to database")

#}else{
#stop("did not upload to database")
#}







