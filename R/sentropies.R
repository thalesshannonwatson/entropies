#' Multivariate Source Entropy decomposition of a dataframe.
#' 
#' Returns several different flavours of sentropies depending on the structure 
#' the data is provided to the function. There are specialized versions for
#' (contingency) tables, confusion matrices and data frames.
#' @param data The data being provided to the function. 
#' @return  A dataframe with the sentropies of the marginals
#' @details Unless specified by the user explicitly, this function uses base 2 
#'   logarithms for the sentropies.
#' @seealso \code{\link[entropy]{entropy}, \link[infotheo]{entropy}}
#' @import dplyr
#' @export
sentropies <- function(data, ...) UseMethod("sentropies")

#' Entropy decomposition of a contingency matrix
#' 
#' Given a contingency matrix, provide one row of entropy coordinates. 
#' NOTE: the reference variable has to index the ROWS of the table, while the predicted
#' variable indexes the columns, unlike, e.g. \code{\link[caret]{contingencyTable}}
#' @param Nxy An n-contingency matrix where n > 2
#' @param unit The logarithm to be used in working out the sentropies as per 
#' \code{entropy}. Defaults to "log2".
#' @export
#' @importFrom entropy entropy
# @importFrom dplyr left_join
# @example sentropies(UCBAdmissions)
sentropies.table <- function(Nxy, ...){
    # 0. Parameter checking
    Nxy <- as.table(Nxy) # is this necessary?
    dims <- dim(Nxy)
    if (length(dims) < 2)
        stop("Cannot process tables with less than 2 dimensions.")
#    if (length(dims) < 2 | length(dims) > 3)
#        stop("Cannot process tables with more than 3 dimensions or less than 2 dimensions.")
    if (dims[1] < 2 | dims[2] < 2)
        stop("sentropies are not defined for distributions with a singleton domain.")
    # 1. Start processing: this is a candidate por sentropies_raw
    #require(entropy)
    #unless otherwise specified, we use log2 logarithms
    # CAVEAT: use a more elegant kludge
    vars <- list(...);
#    if (!("unit" %in% names(vars)))
    if (is.null(vars$unit))
        vars$unit <- "log2"
    if (length(dims)==2){ # N is a plain contingency on X and Y
        Nx <- apply(Nxy, 1, sum); 
        Hx <- do.call(entropy::entropy, c(list(y=Nx), vars)) #entropy(Nx,vars)
        Ny <- apply(Nxy, 2, sum); 
        Hy <- do.call(entropy::entropy, c(list(y=Ny), vars)) #entropy(Ny, vars)
        Ux <- log2(dims[1]) #entropy(rep(1/dims[1],dims[1]),unit="log2",...)
        Uy <- log2(dims[2]) #entropy(rep(1/dims[2],dims[2]),unit="log2",...)
        Hxy <- do.call(entropy, c(list(y=Nxy), vars)) #entropy(Nxy, vars) 
        df <- data.frame(Ux = Ux, Uy = Uy, Hx = Hx, Hy = Hy, Hxy = Hxy)
    } else {  # N is a multiway table: we analyze on the first two margins, but store the second
        Nx <- margin.table(Nxy, c(1,3:length(dims)))
        Hx <- apply(Nx, c(2:length(dim(Nx))), function(x) {do.call(entropy, c(list(y=x), vars)) })
        #Ux <- apply(Nx, 2, function(x) { log2(length(x))})
        Ux <- apply(Nx, c(2:length(dim(Nx))), function(x) { log2(dims[1])})
        Ny <- margin.table(Nxy, c(2,3:length(dims)))
        Hy <- apply(Ny, c(2:length(dim(Ny))), function(x) {do.call(entropy, c(list(y=x), vars)) })
        #Uy <- apply(Ny, 2, function(x) { log2(length(x))})
        Uy <- apply(Ny, c(2:length(dim(Nx))), function(x) { log2(dims[1])})
        Hxy <- apply(Nxy, 3:length(dims), function(x) {do.call(entropy, c(list(y=x), vars))})
        #df <- data.frame(Ux = Ux, Uy = Uy, Hx = Hx, Hy = Hy, Hxy = Hxy)
        THx <- as.data.frame.table(as.table(Hx), responseName = "Hx")
        TUx <- as.data.frame.table(as.table(Ux), responseName = "Ux")
        THy <- as.data.frame.table(as.table(Hy), responseName = "Hy")
        TUy <- as.data.frame.table(as.table(Uy), responseName = "Uy")
        THxy <- as.data.frame.table(as.table(Hxy), responseName = "Hxy")
        df <- left_join(left_join(left_join(TUx, TUy), left_join(THx, THy)), THxy)
        #df <- data.frame(Ux = Ux, Uy = Uy, Hx = Hx, Hy = Hy, Hxy = Hxy)
        #df <- cbind(df, dimnames(Nxy)[3:length(dims)])# Keep the third  and greater dimension's names
        #name <- colnames(N[1,,]) # This is a hack to manifest the values in the 3rd dimension
    } 
    return(df)
}

#' Entropy decomposition of a confusion table
#' 
#' @export
#' @importFrom caret confusionMatrix
sentropies.confusionMatrix <- function(ct, ...){
    return(sentropies(t(ct$table), ...))
}

#' Multivariate source entropy decomposition of a data frame
#' 
#' @return Another dataframe with the main entropy coordinates of every variable
#'   in the original, which are now the rows of the returned data.frame. If the columns have no
#'   names, artificial ones are returned based in pre prefix "x" and their column number.
#' @export
#' @import infotheo
#' @import dplyr
sentropies.data.frame <- function(df, ...){
    if (ncol(df) == 0 || nrow(df) == 0)
        stop("Can only work with non-empty data.frames!")
    if (!all(sapply(df, is.factor))){
        warning("Discretizing data before entropy calculation!")
        df <- infotheo::discretize(df, disc="equalwidth", ...) # infotheo::str(dfdiscretize generates ints, not factors.
    }
    # suppose the dataframe is categorical
    if (is.null(names(df))){
        warning("No names for columns: providing dummy names!")
        names(df) <- paste0("x",1:ncol(df))
    }
    name <-  names(df)
    # Find simple sentropies, divergences and sentropies of the uniform marginals. 
    edf <- data.frame(
        name = name, # After an idyosincracy of dplyr, the rownames do not survive a mutate.
        H_Uxi = unlist(lapply(df, function(v){log2(length(unique(v)))})),
        H_Pxi = unlist(lapply(df, function(v){natstobits(infotheo::entropy(v))})),
         stringsAsFactors = FALSE #Keep the original variable names as factors!
        ) %>% dplyr::mutate(DeltaH_Pxi = H_Uxi - H_Pxi) 
               #M_Pxi = H_Pxi - VI_Pxi)
    if (ncol(df) == 1){
        warning("Single variable: providing only entropy")
        VI_Pxi <- edf[1,"H_Pxi"]
    } else {
        VI_Pxi <- vector("numeric", length(name))
        for(i in 1:length(name)){
            VI_Pxi[i] <- natstobits(condentropy(df[,i], df[,-i], ...))
        }
    }
    edf <- edf %>% mutate(M_Pxi = H_Pxi - VI_Pxi, VI_Pxi)
    return(rbind(edf,cbind(name="ALL", as.data.frame(lapply(edf[,2:6], sum)))))
}