# PACKAGE-WIDE auxiliary functions and variables NOT EXPORTED.

#' A characterization of the variables in a data.frame needed to define the perplexities.
simpleEntropies <- c("Ux", "Uy", "Hx", "Hy", "Hxy")
multiAggregateEntropies <-  c("H_Ux", "H_Px", "VI_Px")    # multivariate simple entropies
splitSmetCoords  <-  c("name", "H_Uxi", "H_Pxi", "VI_Pxi") # multivariate split entropies

#' A caracterization of the variables in a data.frame of derived non-split entropies.
derivedNonSplitEntropies <- c("Uxy", "DeltaHxy", "MIxy2", "VIxy")
multiEntropicCoords <-  c("DeltaH_Px", "M_Px", "VI_Px") #source multivariate aggregate coordinates
# Strictly speaking VI_Px is not derived

#' A caracterization of the variables in a data.frame of derived non-split entropies.
derivedSplitEntropies <- c("DeltaHx", "DeltaHy", "MIxyX", "MIxyY", "VIx", "VIy")
derivedSplitSmetCoords <-  c("DeltaH_Pxi", "M_Pxi", "VI_Pxi", "name") #multivariate entropic coordinates
# Note that, strictly speaking, VI_Pxi is not derived

#' A caracterization of the variables in a data.frame of channel multivariate entropies
cmetEntropicCoords <- c("H_U", "H_P", "VI_P", "DeltaH_P", "M_P")

#' a function to detect if the simple entropies are present.
hasSimpleEntropies <- function(df){all(simpleEntropies %in% names(df))}

#' A function to detect if the derived split entropies are present.
hasDerivedSplitEntropies <- function(df){all(derivedSplitEntropies %in% names(df))}

#' A function to detect if the derived, non-split entropies are present. 
hasDerivedNonSplitEntropies <- function(df) {all(derivedNonSplitEntropies %in% names(df))}

#' a function to detect if the multivariate simple entropies are present: this enables 
#' working out the multivariate simple entropic coordinates
hasMultiAggregateEntropies <- function(df){all(multiAggregateEntropies %in% names(df))}

#' Functions to detect SMET coordinates
#' a function to detect if the source multivariate split entropies are present: this enables 
#' working out the multivariate split entropic coordinates
hasSplitSmetCoords <- function(df){all(derivedSplitSmetCoords %in% names(df))}

#' A function to detect if the source multivariate aggregate entropic coordinates are present
hasAggregateSmetCoords <- function(df){all(multiEntropicCoords %in% names(df))}

#' deprecated!
hasMultiEntropicCoords <- function(df){all(multiEntropicCoords %in% names(df))}


#' A function to detect if the multivariate split entropic coordinates are present
#hasMultiSplitEntropicCoords <- function(df){all(multiSplitEntropicCoords %in% names(df))}
hasMultiSplitEntropicCoords <- function(df){all(derivedSplitSmetCoords %in% names(df))}

#' A function to detect if the the channel multivariate entropic coordinates are present
hasCmetEntropicCoords <- function(df){all(cmetEntropicCoords %in% names(df))}
