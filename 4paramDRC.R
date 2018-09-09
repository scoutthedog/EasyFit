# 4paramDRC.R
#
# This file is designed to create robust and reproduceable R script for fitting 4 parameter dose response curves.
# It uses an RC object (reference class object) to store outputs from the build in R nls() function
# About 4 parameter Dose Reponse Curves:
#
# The four parameters: EC50/IC50, Hillslope, Bottom, Top
#
# EC50/IC50:
# EC50 is the concentration of drug that gives response halfway between baseline and maximum response.
# IC50 is the same thing but the concentration of an inhibitor that reduces the response by half.
# *** represented as the variable c in this file ***
#
# Hillslope
# The slope of the logarithmic curve
# negative slopes are for inhibion curves
# slopes greater than one are steeper slopes
# slopes less than one are shallower slopes
# *** represented as the variable h in this file ***
# 
# Bottom
# The baseline of the equation
# Usually 0 for agonists, often contrained to 0 for this equation
# Sometimes with an inhibitor that does not full inhibit, this is unconstrained
# *** represented as the variable b in this file ***
#
# Top
# The maximum of the equation
# Usually 100 if normalized to 100
# Sometimes with un-normalized data you don't want to constrain it to this.
# *** represented as the variable t in this file ***
#
# Equation guide. each equation has an integer value assinged to it
# cc_eq -> Bottom Constrained Top Constrained. equation code: 0
# uc_eq -> Bottom Unconstrained Top Contrained. equation code: 1
# cu_eq -> Bottom Constrained Top Unconstrained. equatiion code: 2
# uu_eq -> Bottom Unconstrained Top Unconstrained. equation code: 3
#
cc_eq <- formula(response ~ 100/(1+(10^((c-dose)*h))))
uc_eq <- formula(response ~ (b+((100-b)/(1+(10^((c-dose)*h))))))
cu_eq <- formula(response ~ t/(1+(10^((c-dose)*h))))
uu_eq <- formula(response ~ (b+((t-b)/(1+(10^((c-dose)*h))))))
#---------------------------------------------------------------------
fourparamfit <- setRefClass(
  "FourParamFit", 
  fields =  list(Tconstraint = "logical", Bconstraint = "logical", equation = "ANY", level = "numeric", dose = "numeric", response = "numeric",
             # fields used to store information from nls()
             c = "ANY", h = "ANY", t = "ANY", b = "ANY", isConv = "ANY"),
  methods = list(
    fourparamnls = function(r, d) {
      #
      # Method fourparamnls()
      #
      # Args:
      # r, d # abreviated to avoid confusion with the field of the object that this method alters
      # r ---  a numeric vector of responses. 
      # d ---  a numeric vector of doses
      #
      # returns:
      # nothing, but alters a lot of field variables
      #
      # First, some variables must be assinged
      response <<- r
      dose <<- d
      drt <- data.frame(response, dose) # creates a small data frame of doses and responses
      drt <- drt[complete.cases(drt),] # only allows complete cases, or rows for which there is both a dose and response
      dose <<- drt[,2] # added to the field
      response <<- drt[,1] # added to the field
      # Second, we need to calculate the starting values
      estimatestarts <- function(drt) {
        # This function calculates the starting values for the nls function
        #
        # Args:
        # drt --- referes to the dose resposne table supplied in the original fitdatta function
        # it is a table of doses and responses
        #
        # Returns:
        # a list of starting values to be used by the nls() function
        #
        # This function works by finding the middle value of a line near the ec50 of the logarithmic function.
        # This works similarly to how graphpad prisms software calcualtes the ec50 values
        #
        # dose = x value
        # response = y value
        #
        # -----------------------
        # EC50 estimation
        # calculate ymin:
        ymin <- min(response)
        # find the x value (dose) at ymin
        doseymin <- drt[drt[,"response"] == ymin, "dose"]
        doseymin <- doseymin[1]
        # calculate ymax
        ymax <- max(response)
        # find the x value (dose) at ymax
        doseymax <- drt[drt[,"response"] == ymax, "dose"]
        doseymax <- doseymax[1]
        # find ymid by averaging ymin and ymax
        ymid <- ((ymin+ ymax)/2)
        # find the smallest y value that is above ymid
        y1 <- min(response[response > ymid])
        # find the largest y value that is below ymid
        y2 <- max(response[response < ymid])
        # find their correstponding x values (dose)
        x1 <- drt[drt[,"response"] == y1,"dose"]
        x2 <- drt[drt[,"response"] == y2, "dose"]
        # create a line using these new coordinates
        slope <- (y2- y1)/(x2 - x1)
        # find the x value at ymid created by this hypothetical line
        xatymid <- (((ymid-y1)/slope)+x1)
        c_start <- xatymid
        #
        # hillslope estimation
        # if the slope
        if (slope > 0) {
          h_start <- 1
        } else {
          h_start <- -1
        }
        #
        # bottom estimation
        b_start <- ymin #as calculated in EC50 section
        # making sure that the starting value for bottom is not less that zero
        if (b_start < 0) {
          b_start <- 0
        }
        #
        # top estimation
        t_start <- ymax #as calculated in EC50 section
        # returing the starts as a list
        starts <- list(c_start, h_start, b_start, t_start)
      }
      # calling the estimatestarts function, and making sure that it won't end the program if it fails
      # errors will just cause the object to have the isConv field as false
      starts <- suppressWarnings(try(estimatestarts(drt), silent = TRUE))
      if ("try-error" %in% class(starts)) {
        isConv <<- FALSE
      } else {
      # Assigning starting values
      c_start <- starts[[1]] #the starting value for the EC50
      h_start <- starts[[2]] #the starting value for the hillslope
      b_start <- starts[[3]] #the starting value for the bottom
      t_start <- starts[[4]] #the starting value for the top
      # Creating functions for each of the equations. Equations that are unconstrained on the bottom use the port algorithm 
      # This lets the bottom float but not below 0
      # The uu equation is the only truely 4 parameter DRC function, because for the others either the top or bottom or both are set to 0 or 100
      fccfit <- function() {
        # recommended use: For agonists where you know that you are getting maximal response
        # Also useful for inhibitors where you know that you are fully inhibiting response
        nlsfit <- nls(cc_eq, data = drt, start = list(c = c_start, h = h_start), 
                      control = list(maxiter = 50), na.action = na.exclude)
      }
      fucfit <- function() {
        # recommended use: For allosteric modulators where you are not completely inhibiting or activating.
        nlsfit <- nls(uc_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start), control = list(maxiter = 100),
                      algorithm = "port", lower = c(c = -Inf, h = -Inf , b = 0), na.action = na.exclude)
      }
      fcufit <- function() {
        # recommended use: good if you don't think you have acheived maximum activation
        nlsfit <- nls(cu_eq, data = drt, start = list(c = c_start, h = h_start, t = t_start), control = list(maxiter = 100), na.action = na.exclude)
      }
      fuufit <- function() {
        # recommended use: good if all others fail, or you dont think you have acheived maximum and minimum response
        nlsfit <- nls(uu_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start, t = t_start), control = list(maxiter = 200), 
                      algorithm = "port", lower = c(c = -Inf, h = -Inf, b = 0, t = 0), na.action = na.exclude)
      }
      # choosing the right equation based on the constraints given (see equation guide)
      if (Bconstraint & Tconstraint) {
        equation <<- 0 #cc_eq
        nlsfit <- try(fccfit(), silent = TRUE)
      } else if (Bconstraint == FALSE & Tconstraint == TRUE) {
        equation <<- 1 #uc_eq
        nlsfit <- try(fucfit(), silent = TRUE)
      } else if (Bconstraint == TRUE & Tconstraint == FALSE) {
        equation <<- 2 #cu_eq
        nlsfit <- try(fcufit(), silent = TRUE)
      } else {
        equation <<- 3 #uu_eq
        nlsfit <- try(fuufit(), silent = TRUE)
      }
      # if the fit fails, then isConv is FALSE
      if ("try-error" %in% class(nlsfit)) {
        isConv <<- FALSE
      }else{
        # otherwise, the rest of the values will be stored in the fourparamfit object's field
        isConv <<- TRUE
        # a summary of the coefficients
        # the different equations have a different number of coefficients, so they need to be treated seprately
        coef <- summary(nlsfit)$coefficients
        if (equation == 0) { #cc_eq
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- 0
          t <<- 100
        } else if (equation == 1) { #uc_eq
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- coef[3,1]
          t <<- 100
        } else if (equation == 2) { #cu_eq
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- 0
          t <<- coef[3,1]
        } else if (equation == 3) { #uu_eq
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- coef[3,1]
          t <<- coef[4,1]
        }
      }
      } # at this point all of the values have been stored in the object's field. Doesn't show any output.
        # if you want to see output, use the show() method
    },
    show = function() {
      # prints out all the fields
      print(paste0("Top constraint  |  ", Tconstraint))
      print(paste0("Bot constraint  |  ", Bconstraint))
      print(paste0("dose            |  ", list(dose)))
      print(paste0("response        |  ", list(response)))
      print(paste0("EC50/IC50       |  ", c))
      print(paste0("hillslope       |  ", h))
      print(paste0("ymin            |  ", b))
      print(paste0("ymax            |  ", t))
      print(paste0("Conv?           |  ", isConv))
    }
    )
)

choosebestfit <- function(response, dose, b_const, t_const) {
  # This function is designed to choose the best fit for a four param DRC.
  # Args:
  # dose, response, b_const, t_const
  # dose - a numeric vector of doses
  # response - a numeric vector of the same legth of responses
  # b_const - TRUE or FALSE, whether or not the bot should be constrained in fitting
  # t_const - TRUE or FALSE, whether or not the top should be constrained in fitting
  # The b and t constraint will determine which fit is prefered.
  # If the prefered fit fails, then each original prefered fit has "preflist" which determines the order of equations to try
  # the orders are:
  # ----------------------------------
  ccpref <- list(0, 1, 3) # CC->UC->UU
  ucpref <- list(1, 3, 0) # UC->UU->CC
  cupref <- list(2, 3, 0) # CU->UU->CC
  uupref <- list(3, 1, 0) # UU->UC->CC
  # ----------------------------------
  # The 4 fit objects are initialized
  ccfit <- fourparamfit$new(Bconstraint = TRUE, Tconstraint = TRUE)
  ucfit <- fourparamfit$new(Bconstraint = FALSE, Tconstraint = TRUE)
  cufit <- fourparamfit$new(Bconstraint = TRUE, Tconstraint = FALSE)
  uufit <- fourparamfit$new(Bconstraint = FALSE, Tconstraint = FALSE)
  # The prefered fit is calculated
  # choosing pref list based on the supplied constraints
  if (b_const & t_const) {
    preflist <- ccpref
  } else if (b_const == FALSE & t_const == TRUE) {
    preflist <- ucpref
  } else if (b_const == TRUE & t_const == FALSE) {
    preflist <- cupref
  } else {
    preflist <- uupref
  }
  # going throught the pref list. If it works, then it breaks the for loop.
  # If not, then it moves onto the next iteration and tries that fit
  for (i in 1:3) {
    pref <- preflist[i]
    if (pref == 0) {
      ccfit$fourparamnls(response, dose)
      if (ccfit$isConv == TRUE) {
        return(ccfit)
      }
    } else if (pref == 1) {
      ucfit$fourparamnls(response, dose)
      if (ucfit$isConv == TRUE) {
        return(ucfit)
      }
    } else if (pref == 2) {
      cufit$fourparamnls(response, dose)
      if (cufit$isConv == TRUE) {
        return(cufit)
      }
    } else if (pref == 3) {
      uufit$fourparamnls(response, dose)
      if (uufit$isConv == TRUE) {
        return(uufit)
      }
    }
  }
  failedfit <- fourparamfit$new(c = NA, h = NA, b = NA, t = NA, equation = NA, isConv = NA)
  return(failedfit)
  # if none of them worked, then isConv is FALSE
}
calcfourparamfit <- function(response, dose, b_const, t_const) {
  dose <- as.numeric(dose)
  response <- as.numeric(response)
  fit <- choosebestfit(response, dose, b_const, t_const)
  fitlist <- c(fit$c, fit$h, fit$b, fit$t, fit$equation, fit$isConv)
}
testfunction <- function() {
  # You can use this function to test how it works
  # It has some sample dose response data
  dose <- c(-9,-8.52,-8,-7.52,-7,-6.52,-5.52,-4)
  response <- c(NA,0.7,1.2,3.2,17,49.5,85.7,100)
  list <- calcfourparamfit(response, dose, TRUE, TRUE)
}


