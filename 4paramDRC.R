# 4 paramDRC.R
#
# This file is designed to create robust and reproduceable R script for fitting 4 parameter dose response curves.
# TODO: add to this

fourparamfit <- setRefClass(
  "FourParamFit", 
  fields =  list(Tconstraint = "logical", Bconstraint = "logical", equation = "numeric", dose = "numeric", response = "numeric",
             #slots used to store information about the fit calculated from FourParam.nls()
             c = "numeric", h = "numeric", t = "numeric", b = "numeric", isConv = "logical"),
  methods = list(
    fourparamnls = function(d, r) {
      #
      # Function Body
      #
      # Defning Variables
      dose <<- d
      response <<- r
      drt <- data.frame(dose, response)

      fitstarts <- function(drt) {
        # This function calculates the starting values for the nls function
        #
        # Args:
        # drt - referes to the dose resposne table supplied in the original fitdatta function
        # it is a table of doses and responses
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
      starts <- suppressWarnings(try(fitstarts(drt), silent = TRUE))
      if ("try-error" %in% class(starts)) {
        isConv <<- FALSE
      }
      c_start <- starts[[1]] #the starting value for the ec50/ic50
      h_start <- starts[[2]] #the starting value for the hillslope
      b_start <- starts[[3]] #the starting value for the bottom
      t_start <- starts[[4]] #the starting value for the top
      
      
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
      
      #
      # Defining the equations to be used
      #
      fccfit <- function() {
        nlsfit <- nls(cc_eq, data = drt, start = list(c = c_start, h = h_start), 
                      control = list(maxiter = 200), na.action = na.exclude)
      }
      fucfit <- function() {
        nlsfit <- nls(uc_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start), control = list(maxiter = 200),
                      algorithm = "port", lower = c(c = -Inf, h = -Inf , b = 0), na.action = na.exclude)
      }
      fcufit <- function() {
        nlsfit <- nls(cu_eq, data = drt, start = list(c = c_start, h = h_start, t = t_start), control = list(maxiter = 200), na.action = na.exclude)
      }
      fuufit <- function() {
        nlsfit <- nls(uu_eq, data = drt, start = list(c = c_start, h = h_start, b = b_start, t = t_start), control = list(maxiter = 200), 
                      algorithm = "port", lower = c(c = -Inf, h = -Inf, b = 0, t = 0), na.action = na.exclude)
      }
      
      if (Bconstraint & Tconstraint) {
        equation <<- 0
        nlsfit <- try(fccfit(), silent = TRUE)
      } else if (Bconstraint == FALSE & Tconstraint == TRUE) {
        equation <<- 1
        nlsfit <- try(fucfit(), silent = TRUE)
      } else if (Bconstraint == TRUE & Tconstraint == FALSE) {
        equation <<- 2
        nlsfit <- try(fcufit(), silent = TRUE)
      } else {
        equation <<- 3
        nlsfit <- try(fuufit(), silent = TRUE)
      }
      if ("try-error" %in% class(nlsfit)) {
        isConv <<- FALSE
      }else{
        isConv <<- TRUE
        coef <- summary(nlsfit)$coefficients
        if (equation == 0) {
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- 0
          t <<- 100
        } else if (equation == 1) {
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- coef[3,1]
          t <<- 100
        } else if (equation == 2) {
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- 0
          t <<- coef[3,1]
        } else if (equation == 3) {
          c <<- coef[1,1]
          h <<- coef[2,1]
          b <<- coef[3,1]
          t <<- coef[4,1]
        }
      }
    },
    show = function() {
      print(paste0("Topconstr: ", Tconstraint))
      print(paste0("Botconstr: ", Bconstraint))
      print(paste0("dose:      ", list(dose)))
      print(paste0("response:  ", list(response)))
      print(paste0("ec50/ic50: ", c))
      print(paste0("hillslope: ", h))
      print(paste0("ymin:      ", b))
      print(paste0("ymax:      ", t))
      print(paste0("Conv?:     ", isConv))
    }
    )
)
d <- c(-8.52,-8,-7.52,-7,-6.52,-5.52,-4)
r <- c(0.7,1.2,3.2,17,49.5,85.7,100) 
ccfit <- fourparamfit$new(Bconstraint = TRUE, Tconstraint = TRUE)
ucfit <- fourparamfit$new(Bconstraint = FALSE, Tconstraint = TRUE)
cufit <- fourparamfit$new(Bconstraint = TRUE, Tconstraint = FALSE)
uufit <- fourparamfit$new(Bconstraint = FALSE, Tconstraint = FALSE)
ccfit$fourparamnls(d, r)
ucfit$fourparamnls(d, r)
cufit$fourparamnls(d, r)
uufit$fourparamnls(d, r)
ccfit$show()
ucfit$show()
cufit$show()
uufit$show()


