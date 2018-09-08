# oocytescript.R
#
# A script for fitting oocyte data to four parameter dose response curves from csv files.
#
# HOW TO USE THIS FILE
# syntax:
#         >  Rscript SCRIPT_PATH\oocytescript.R CSV_FILE_PATH b_const t_const
#
# where SCRIPT_PATH is the location of this script
# and CSV_FILE_PATH is the location of the csv files to be read
# and b_const is (TRUE/FALSE) indicating if the top is constrained in the fit equation model
# and t_const is (TRUE/FALSE) indicating if the bottom is constrained in the fit equation model
#
# dplyr has useful data processing functions, it is required to run this script.
library(dplyr)
# 4paramDRC.R is the base function that is used to fit the data.
source("C:/Users/jpa/source/repos/oocytedb/4paramDRC.R")
# taking args from commandline
args = commandArgs(trailingOnly = TRUE)
# BELOW COMMENTED CODE IS FOR  TESTING ONLY
# This lets me test run the file without having to call it from command line
#args <- c("C:/Users/jpa/Desktop/csvdump/090518-MB1-Gly.csv", TRUE, TRUE)
#
# This script will return an error if you don't give it arguments
if (length(args) == 0) {
  stop("This scripts requires you to specify an input file", call.=FALSE)
}
# will assume that bot and top are constrained if not specified explicitly
if (length(args) == 1) {
  b_const <- TRUE
  t_const <- TRUE
}
# will assume that top is constrained if not otherwise specified
if (length(args) == 2) {
  b_const <- as.logical(args[2])
  t_const <- TRUE
}
# explicit declaration of args
if (length(args) == 3) {
  b_const <- as.logical(args[2])
  t_const <- as.logical(args[3])
}
inputfile <- args[1]
# reads the csv file specified by the commandline argument
csv <- read.csv(inputfile, header = TRUE, na.string = "NA")
# this code removes any rows where the dbinfo column specifies DEL
# deltes the data before it makes it to the database upload

# genuploaddata is from oocyte_functions.R, generates the fits
fitCSV <- function(csv, b_const, t_const) {
  # This is a data processing script for used to process daily recording sheets in preparation for database upload
  # 
  # Args:
  # csv, b_const, t_const
  # csv ------- the data set derrived from the csv file
  # b_const --- the agrument supplied by the command line, determines how the data is fit (see 4paramDRC's documentation)
  # t_const --- similar to above variable
  #
  # returns:
  # a dataframe including the original csv, but with added columns of fits at the end
  #
  # START
  # removes all rows that have the dbinfo code DEL.
  csv %>%
    filter(dbinfo != "DEL") -> csvtemp
  if (nrow(csvtemp) != 0) {
    csv <- csvtemp
  }
  # removes all rows that are all NA, just in case they didn't get the dbinfo DEL code
  csv <- csv[rowSums(is.na(csv)) != ncol(csv), ]
  # subsets only the data that is used for fitting
  responses <- csv[,c(6:24)]
  # storing the filenames for later
  # Calculate the doses to be supplied. This is in micromolar.
  conc <- c(0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000)
  # convert to concentrations logarithmic doses
  dose <- sapply(conc, function(x) log10(x / 1000000))
  # The apply function applies by each row from the responses data frame.
  # Each row creates a vector of responses, these are each in turn supplied to the calcfourparamfit function.
  # This function takes vector of doses and responses, as well as the constraints, and returns a list of 
  # calculated values for the EC50/IC50, hillslope, ymin, ymax, formula, and convergence
  fits <- apply(responses, 1, calcfourparamfit, dose, b_const, t_const)
  # This list is converted to a data frame, however each of these lists is a column, and the rows
  fits <- as.data.frame(fits)
  # The t() function is a matrix transpose function that takes a matrix or dataframe and switches rows and columns
  # It returns a matrix, so the as.data.frame() returns it back to a data.frame
  fits <- as.data.frame(t(fits))
  # Adding column names to the data frame
  names(fits) <- c("logec50", "hillslope", "ymin", "ymax", "formula", "isConv")
  # adding in the files from the original csv data
  fits$file <- as.vector(csv[,2])
  # joining the two dataframes on the column file
  # this creates a big data frame ready to be written to a csv file.
  suppressWarnings(right_join(csv, fits, by = "file"))
}
# Finally, the fit csv function is called and fits are calculated
csvwithfits <- fitCSV(csv, b_const, t_const)
# These newly calculated fits are added to the original csv inputfile
write.csv(csvwithfits, file = inputfile, na = "", row.names = FALSE)
