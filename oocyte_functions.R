# oocyte_functions.R
# 
# This file has tools for fitting oocyte data using a Nonlinear Least Sqares Regression.
# There are also some tools for data visualization.

suppressMessages(library(ggplot2))
suppressMessages(library(tidyverse))

#These are the  concentrations 
CONC <- c(0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000)
DOSE <- sapply(CONC, function(x) log10(x / 1000000))

#functions
removeNArows <- function(df) {
  df[rowSums(is.na(df)) != ncol(df), ]
}
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}
touM <- function(x) {
  (10^x)*1000000
}

fitdata <- function(drt, b_const, t_const) {
  
  if (drt == "EMPTY") {
    return("EMPTY")
  } else {
  
  #An okay fitting scheme that just works
  
  fitstarts <- function(drt) {
    # This function calculates the starting values for the nls function
    #
    # Args:
    # drt - referes to the dose resposne table supplied in the original fitdatta function
    # it is a table of doses and responses
    drt <- drt[complete.cases(drt),] 
    dose <- drt[,1] 
    response <- drt[,2]
    ymin <- min(response)
    doseymin <- drt[drt[,"response"] == ymin, "dose"]
    doseymin <- doseymin[1]
    ymax <- max(response)
    doseymax <- drt[drt[,"response"] == ymax, "dose"]
    doseymax <- doseymax[1]
    ymid <- ((ymin+ ymax)/2)
    y1 <- min(response[response > ymid])
    y2 <- max(response[response < ymid])
    x1 <- drt[drt[,"response"] == y1,"dose"]
    x2 <- drt[drt[,"response"] == y2, "dose"]
    slope <- (y2- y1)/(x2 - x1)
    xatymid <- (((ymid-y1)/slope)+x1)
    if (doseymin < doseymax) {
      h_start <- 1
    }
    if (doseymin > doseymax) {
      h_start <- -1
    } else {
      h_start <- 1
    }
    c_start <- xatymid
    b_start <- ymin
    if (b_start < 0) {
      b_start <- 0
    }
    t_start <- ymax
    starts <- list(c_start, h_start, b_start, t_start)
  }
  
  starts <- try(fitstarts(drt))
  if ("try-error" %in% class(starts)) {
    return("ALL_FITS_FAILED")
  }
  c_start <- starts[[1]]
  h_start <- starts[[2]]
  b_start <- starts[[3]]
  t_start <- starts[[4]]
  #
  #Equation guide:
  #cc -> Bottom Constrained Top Constrained
  #uc -> Bottom Unconstrained Top Contrained
  #cu -> Bottom Constrained Top Unconstrained
  #uu -> Bottom Unconstrained Top Unconstrained
  #
  cc_eq <- formula(response ~ 100/(1+(10^((c-dose)*h))))
  uc_eq <- formula(response ~ (b+((100-b)/(1+(10^((c-dose)*h))))))
  cu_eq <- formula(response ~ t/(1+(10^((c-dose)*h))))
  uu_eq <- formula(response ~ (b+((t-b)/(1+(10^((c-dose)*h))))))
  
  #functions
  
  fccfit <- function() {
    fit <- nls(cc_eq, data = drt, start = list(c = c_start, h = h_start), 
               control = list(maxiter = 200), na.action = na.exclude)
  }
  fucfit <- function() {
    fit <- nls(uc_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start), control = list(maxiter = 200),
               algorithm = "port", lower = c(c = -Inf, h = -Inf , b = 0), na.action = na.exclude)
  }
  fcufit <- function() {
    fit <- nls(cu_eq, data = drt, start = list(c = c_start, h = h_start, t = t_start), control = list(maxiter = 200), na.action = na.exclude)
  }
  fuufit <- function() {
    fit <- nls(uu_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start, t = t_start), control = list(maxiter = 200), 
               algorithm = "port", lower = c(c = -Inf, h = -Inf, b = 0, t = 0), na.action = na.exclude)
  }
  #below: the worst function ever made
  #both are mostly depreciated
  trybetterfitscheme <- function(fit) {
    if ("try-error" %in% class(fit)) {
      fit <- try(fccfit())
    } else {
      return(fit)
    }
    
    return(fit)
  }
  tryfitscheme <- function(fit) {
    if ("try-error" %in% class(fit)) {
      fit <- try(fccfit(), silent = TRUE)
      if ("try-error" %in% class(fit)) {
        fit <- try(fucfit(), silent = TRUE)
          if ("try-error" %in% class(fit)) {
            fit <- try(fcufit(), silent = TRUE)
            if ("try-error" %in% class(fit)) {
              fit <- try(fuufit(), silent = TRUE)
              if ("try-error" %in% class(fit)) {
                return("ALL_FITS_FAILED")
              }else{
                return(fit)
              }
            } else {
              return(fit)
            }
          } else {
            return(fit)
          }
      } else {
          return(fit)
        }
    }
  }
  
  if (b_const & t_const) {
    fit <- try(fccfit())
  } else if (b_const == FALSE & t_const == TRUE) {
    fit <- try(fucfit())
  } else if (b_const == TRUE & t_const == FALSE) {
    fit <- try(fcufit())
  } else {
    fit <- try(fuufit())
  }
  if ("try-error" %in% class(fit)) {
    fit <- try(fuufit())
    if ("try-error" %in% class(fit)) {
      return("ALL_FITS_FAILED")
    }else{
      return(fit)
    }
  }else{
    return(fit)
  }
  }
}
fox_fitlist <- function(fit) {
  
  cc_eq <- formula(response ~ 100/(1+(10^((c-dose)*h))))
  uc_eq <- formula(response ~ (b+((100-b)/(1+(10^((c-dose)*h))))))
  cu_eq <- formula(response ~ t/(1+(10^((c-dose)*h))))
  uu_eq <- formula(response ~ (b+((t-b)/(1+(10^((c-dose)*h))))))
  
  if (fit == "ALL_FITS_FAILED" || fit == "EMPTY" || ("try-error" %in% class(fit)) == TRUE) {
    list <- c(logec50 = NA,
              logeec50_std_error = NA,
              logec50_t_value = NA,
              logec50_p_value = NA,
              hillslope = NA,
              hillslope_std_error = NA,
              hillslope_t_value = NA,
              hillslope_p_value = NA,
              ymin = NA,
              ymin_std_error = NA,
              ymin_t_value = NA,
              ymin_p_value = NA,
              ymax = NA,
              ymax_std_error = NA,
              ymax_t_value = NA,
              ymax_p_value = NA,
              formula = NA,
              isConv = FALSE,
              stopMessage = "failed")
  } else {
  
  formulatemp <- formula(fit)
  formulafit <- paste(formulatemp[2], "=",formulatemp[3], sep = " ")
  summaryfit <- summary(fit)
  cofit <- summaryfit$coefficients
  if (formula(fit) == cc_eq) {
    ymin <- 0
    ymin_std_error <- NA
    ymin_t_value <- NA
    ymin_p_value <- NA
    ymax <- 100
    ymax_std_error <- NA
    ymax_t_value <- NA
    ymax_p_value <- NA
  }
  if (formula(fit) == cu_eq) {
    ymin <- 0
    ymin_std_error <- NA
    ymin_t_value <- NA
    ymin_p_value <- NA
    ymax <- cofit[3,1]
    ymax_std_error <- cofit[3,2]
    ymax_t_value <- cofit[3,3]
    ymax_p_value <- cofit[3,4]
  }
  if (formula(fit) == uc_eq) {
    ymin <- cofit[3,1]
    ymin_std_error <- cofit[3,2]
    ymin_t_value <- cofit[3,3]
    ymin_p_value <- cofit[3,4]
    ymax <- 100
    ymax_std_error <- NA
    ymax_t_value <- NA
    ymax_p_value <- NA
  }
  if (formula(fit) == uu_eq) {
    ymin <- cofit[3,1]
    ymin_std_error <- cofit[3,2]
    ymin_t_value <- cofit[3,3]
    ymin_p_value <- cofit[3,4]
    ymax <- cofit[4,1]
    ymax_std_error <- cofit[4,2]
    ymax_t_value <- cofit[4,3]
    ymax_p_value <- cofit[4,4]
  }
  list <- c(logec50 = cofit[1,1],
            logeec50_std_error = cofit[1,2],
            logec50_t_value = cofit[1,3],
            logec50_p_value = cofit[1,4],
            hillslope = cofit[2,1],
            hillslope_std_error = cofit[2,2],
            hillslope_t_value = cofit[2,3],
            hillslope_p_value = cofit[2,4],
            ymin = ymin,
            ymin_std_error = ymin_std_error,
            ymin_t_value = ymin_t_value,
            ymin_p_value = ymin_p_value,
            ymax = ymax,
            ymax_std_error = ymax_std_error,
            ymax_t_value = ymax_t_value,
            ymax_p_value = ymax_p_value,
            formula = formulafit, 
            isConv = fit$convInfo$isConv, 
            stopMessage = fit$convInfo$stopMessage)
  }
  list
}
gorilla_fitlist <- function(fit) {
  
  cc_eq <- formula(response ~ 100/(1+(10^((c-dose)*h))))
  uc_eq <- formula(response ~ (b+((100-b)/(1+(10^((c-dose)*h))))))
  cu_eq <- formula(response ~ t/(1+(10^((c-dose)*h))))
  uu_eq <- formula(response ~ (b+((t-b)/(1+(10^((c-dose)*h))))))
  
  if (fit == "ALL_FITS_FAILED" || fit == "EMPTY" || ("try-error" %in% class(fit)) == TRUE) {
    list <- c(logec50 = NA,
              hillslope = NA,
              ymin = NA,
              ymax = NA,
              formula = NA,
              isConv = FALSE)
  } else {
  
  formulatemp <- formula(fit)
  if (formulatemp == cc_eq) {
  	  formulafit <- 0
  } else if (formulatemp == uc_eq) {
  	  formulafit <- 1
  } else if (formulatemp == cu_eq) {
  	  formulafit <- 2
  } else {
  	  formulafit <- 3
  }
  summaryfit <- summary(fit)
  cofit <- summaryfit$coefficients
  if (formula(fit) == cc_eq) {
    ymin <- 0
    ymax <- 100
  }
  if (formula(fit) == cu_eq) {
    ymin <- 0
    ymax <- cofit[3,1]
  }
  if (formula(fit) == uc_eq) {
    ymin <- cofit[3,1]
    ymax <- 100
  }
  if (formula(fit) == uu_eq) {
    ymin <- cofit[3,1]
    ymax <- cofit[4,1]
  }
  if (fit$convInfo$isConv == TRUE) {
  	  isConv <- 0
  } else {
  	  inConv <- 1
  }
  list <- c(logec50 = cofit[1,1],
            hillslope = cofit[2,1],
            ymin = ymin,
            ymax = ymax,
            formula = formulafit, 
            isConv = isConv)
  }
  list
}
fox_genuploaddata <- function(db, b_const = TRUE, t_const = TRUE) {
  #removes rows that contain all NA's
  db <- removeNArows(db)
  #adds a column to the data called 'variant' that is just a combination of glun1/glun2
  db <- addvarcol(db)
  #this subsets only the columns that contain numerical data for fitting, as well as the file
  fitdf <- db[,c(2,7:25)]
  #storing the files for later
  files <- as.vector(db[,2])
  #creates a list of "drt" or dose-response tables
  fitdrt <- apply(fitdf, 1, calcdrt)
  #here is where the fitting occurs. Here are the steps in this code:
  #1. The list of "drt"s is applied to produce a list of fit objects.
  #2. The fit ojects has the fitlist function applied to it, which extracts the information we want from the fit object as a vector
  #3. The list of vectors in now made into a dataframe with the fits for each oocyte as a COLUMN
  #4. We want each ROW to represent an oocyte in our data, so t() transforms it an it is again made into a dataframe and stored into fitdump
  fitdump <- as.data.frame(t(as.data.frame(lapply(lapply(fitdrt, fitdata, b_const, t_const), fox_fitlist))))
  #the files we stored for later are added back in
  fitdump$file <- files
  #we rejoin the orginal data with our newly calculated fits.
  suppressWarnings(full_join(db, fitdump, by = "file"))
}
gorilla_genuploaddata <- function(db, b_const = TRUE, t_const = TRUE) {
  #removes rows that contain all NA's
  db <- removeNArows(db)
  #adds a column to the data called 'variant' that is just a combination of glun1/glun2
  #db <- addvarcol(db)
  #this subsets only the columns that contain numerical data for fitting, as well as the file
  fitdf <- db[,c(2,6:24)]
  #storing the files for later
  files <- as.vector(db[,2])
  #creates a list of "drt" or dose-response tables
  fitdrt <- apply(fitdf, 1, calcdrt)
  #here is where the fitting occurs. Here are the steps in this code:
  #1. The list of "drt"s is applied to produce a list of fit objects.
  #2. The fit ojects has the fitlist function applied to it, which extracts the information we want from the fit object as a vector
  #3. The list of vectors in now made into a dataframe with the fits for each oocyte as a COLUMN
  #4. We want each ROW to represent an oocyte in our data, so t() transforms it an it is again made into a dataframe and stored into fitdump
  fitdump <- as.data.frame(t(as.data.frame(lapply(lapply(fitdrt, fitdata, b_const, t_const), gorilla_fitlist))))
  #the files we stored for later are added back in
  fitdump$file <- files
  #we rejoin the orginal data with our newly calculated fits.
  suppressWarnings(full_join(db, fitdump, by = "file"))
}

calcresponse <- function(df) {
  # finds the response for row n given the assay data
  #does not use the first column (file)
  response <- as.numeric(df[2:length(df)])
}
calcdrt <- function (df) {
  # creates a table of dose and response
  #dose <- calcdose(df)
  response <- calcresponse(df)
  if (all(is.na(response))) {
    return("EMPTY")
  } else {
      df <- data.frame(dose, response)
  }
}
calcdose <- function(df) {
  # calculates the log[dose] from the column names
  conc <- names(df)
  conc <- conc[2:length(conc)]
  conc <- gsub("x",".", conc)
  conc <- gsub("[a-z]","", conc)
  conc <- as.numeric(conc)
  concmoles <- (conc / 1000000)
  dose <- log10(concmoles)
  dose <- dose[!is.na(dose)]
  #dose <- round(dose, digits = 2)
  return(dose)
}
addvarcol <- function(df) {
  combinevar <- function(df) {
    glun1 <- df["glun1"]
    glun2 <- df["glun2"]
    paste(glun1, glun2, sep ="/")
  }
  comblist <- apply(df, 1, combinevar)
  df$variant <- comblist
  df
}
selectvar <- function(var, df) {
  df <- df[apply(df, 1, function(x) df$variant == var),]
  df <- removeNArows(df)
  df
}
calcdf <- function(db) {
  db <- removeNArows(db)
  db <- addvarcol(db)
  df <- db[,c(2,7:25,38)]
  vars <- as.list(unique(df$variant))
  dflist <- lapply(vars, selectvar, df)
  names(dflist) <- vars
  removevarcol <- function(df) {
    df <- df[,1:20]
  }
  lapply(dflist, removevarcol) 
}
ccalcpdf <- function(df, xmin, xmax) {
  # creates a prediction data frame (pdf) of projected doses and predicted responses
  # for use with graphing the line of best fit
  dose.p <- data.frame(dose = seq(from = xmin,to = xmax, by = 0.1))
  fit <- cfitdata(df, 1)
  pred <- predict(fit, dose.p, "predict")
  pdf <- cbind(dose.p, pred)
  a <- mutate(pdf, file = df[1,1])
  for (i in 1:nrow(df)-1) {
    fit <- cfitdata(df, i+1)
    pred <- predict(fit, dose.p)
    pdf <- cbind(dose.p, pred)
    b <- mutate(pdf, file = df[i+1,1])
    a <- bind_rows(a, b)
  }
  colnames(a)[1] <- "test"
  return(a)
}
calcdfdrt <- function(df) {
  applydrt <- function(df) {
    apply(df, 1, calcdrt)
  }
  lapply(df, applydrt)
}

# graphs
fitplot <- function(df, variant = "h1_/h2_-___", assay = "___DRC", wt = "___") {
  drts <- apply(df, 1, calcdrt)
  f <- ggplot(data = pdf, aes(x = test, y = pred, color = file),na.rm=TRUE) +
    theme_jpa()+
    labs(
      title = paste(variant, assay, wt, sep = " "),
      x = paste("log[", assay, "]"), 
      y = "% current response") +
    ylim(0,100) +
    xlim(xmin,xmax) +
    geom_point(data = drt, aes(x = dose, y = response), na.rm = TRUE) +
    geom_line()
  return(f)
}
fit2plot <- function(vardf, wtdf, const, variant = "variant", assay = "assay", wt = "var") {
  df <- meandf(vardf, wtdf)
  drt <- meanbigdrt(vardf, wtdf)
  xmin <- drt[1,"dose"] - 2
  xmax <- drt[nrow(drt),"dose"] + 2
  if (const == "n") {
    pdf <- u2calcpdf(df, xmin, xmax)
  }
  if (const == "y") {
    pdf <- c2calcpdf(df, xmin, xmax)
  }
  f <- ggplot(data = pdf, aes(x = dose, y = pred, group = wt, color = wt),na.rm=TRUE) +
    theme_jpa()+
    labs(
      title = paste(wt, "/", variant, assay, sep = " "),
      x = paste("log[", assay, "]"), 
      y = "% current response") +
    ylim(0,100) +
    xlim(xmin,xmax) +
    geom_point(data = drt, aes(x = dose, y = response), na.rm = TRUE) +
    geom_line()
  return(f)
}