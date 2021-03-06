#' Multivariate joint entropy decomposition of dataframes
#' 
#' Returns several different flavours of entropies depending on the structure 
#' the data is provided to the function. There are specialized versions for
#' (contingency) tables, confusion matrices and data frames.
#' @param data The data being provided to the function. 
#' @return  A dataframe with the entropies of the marginals
#' @details Unless specified by the user explicitly, this function uses base 2 
#'   logarithms for the entropies.
#' @seealso \code{\link[entropy]{entropy}, \link[infotheo]{entropy}, \link{sentropies}}
#' @import dplyr
#' @export
jentropies <- function(X, Y, ...) UseMethod("jentropies") 

#' Mutivariate Joint Entropy decomposition of a data frame
#' 
#' @return Another dataframe with the main entropy coordinates of every variable Xi
#'   in the original conditioned on the datatables Y, which are now the rows of the returned data.frame.
#' @export
#' @import infotheo
#' @import dplyr
jentropies.data.frame <- function(X, Y, ...){
    if (ncol(X) == 0 || nrow(X) == 0 ) 
        stop("Can only work with non-empty data.frames X!")
    if (ncol(Y) == 0 || nrow(Y) == 0 )
        stop("Can only condition on non-empty data.frame Y! ")
    if (nrow(X) != nrow(Y) )
        stop("Can only condition on variable lists with the same number of instances!")
    if (!all(sapply(X, is.factor))){
        warning("Discretizing data before entropy calculation!")
        X <- infotheo::discretize(X, disc="equalwidth", ...) # infotheo::str(dfdiscretize generates ints, not factors.
    }
    if (!all(sapply(Y, is.factor))){
        warning("Discretizing conditioning data before entropy calculation!")
        Y <- infotheo::discretize(Y, disc="equalwidth", ...) # infotheo::str(dfdiscretize generates ints, not factors.
    }
    # suppose the dataframe is categorical
    # Find simple entropies, divergences and entropies of the uniform marginals. 
    VI_P <- natstobits(c(condentropy(X,Y), condentropy(Y,X)))
    edf <- data.frame(
        name = c("X", "Y"), # After an idyosincracy of dplyr, the rownames do not survive a mutate.
        H_P = natstobits(c(infotheo::entropy(X), infotheo::entropy(Y))),
        H_U = c(
            sum(sapply(X, function(v){log2(length(unique(v)))})),
            sum(sapply(Y, function(v){log2(length(unique(v)))}))
        ),
        stringsAsFactors = FALSE #Keep the original variable names as factors!
    ) %>% dplyr::mutate(
        DeltaH_P = H_U - H_P, 
        M_P = H_P - VI_P,
        VI_P = VI_P
    ) 
    # #M_Pxi = H_Pxi - VI_Pxi)
    # if (ncol(X) == 1){
    #     warning("Single variable: providing only entropy")
    #     #         edf <- data.frame(
    #     #             name = colnames(df?append),
    #     #             H_Uxi = log2(length(unique(df[,1]))),
    #     #             H_Pxi = infotheo::entropy(df[,1])
    #     #         ) %>% mutate(DeltaH_Pxi = H_Uxi - H_Pxi)
    # } else {
    #     #entropyNames <- c("name", "H_Uxi", "H_Pxi", "VI_Pxi", "DeltaH_Pxi","M_Pxi")
    #     #colnames(edf) <- entropyNames
    #     #name <- colnames(df) # get the colnames once and for all
    #     #nn <- length(name)
    #     #H_Uxi <-  unlist(lapply(df, function(v){log2(length(unique(v)))}))
    #     #H_Pxi <- unlist(lapply(df, function(v){natstobits(infotheo::entropy(v))}))
    #     #VI_Pxi <- sapply(name, function(n){infotheo::condentropy(df[,n], Y=df[,setdiff(name, n)])})
    #     #         edf <- data.frame(
    #     #             name = colnames(df), # After an idyosincracy of dplyr, the rownames donot survive a mutate.
    #     #             H_Uxi = unlist(lapply(df, function(v){log2(length(unique(v)))})),
    #     #             H_Pxi = unlist(lapply(df, function(v){natstobits(infotheo::entropy(v))})), 
    #     #             VI_Pxi = sapply(name, function(n){infotheo::condentropy(df[,n], Y=df[,setdiff(name, n)])})
    #     #         ) %>% 
    #     #             mutate(DeltaH_Pxi = H_Uxi - H_Pxi, 
    #     #                    M_Pxi = H_Pxi - VI_Pxi)
    #     VI_Pxi <- vector("numeric", length(name))
    #     for(i in 1:length(name)){
    #         VI_Pxi[i] <- natstobits(condentropy(X=X[,i], Y=cbind(X[,-i], Y)))
    #     }
    #     edf <- mutate(edf, VI_Pxi, M_Pxi = H_Pxi - VI_Pxi)
    #     #         edf <- mutate(edf,
    #     #                       VI_Pxi = sapply(name, function(x){natstobits(infotheo::condentropy(df[,x], df[, setdiff(name, x)]))}),
    #     #                       M_Pxi = H_Pxi - VI_Pxi
    #     #                       )
    # }
    # Add the joint balance equations
    return(rbind(edf,cbind(name="XY", as.data.frame(lapply(edf[,2:6], sum)))))
    #return(edf)
}

#' Entropy decomposition of a contingency matrix
#' 
#' Given a contingency matrix, provide one row of entropy coordinates. 
#' NOTE: the reference variable has to index the ROWS of the table, while the predicted
#' variable indexes the columns, unlike, e.g. \code{\link[caret]{contingencyTable}}
#' @param Nxy An n-contingency matrix where n > 2
#' @param unit The logarithm to be used in working out the sentropies as per 
#' \code{entropy}. Defaults to "log2".
#' @export
#' @import infotheo
#' @import dplyr
# @importFrom dplyr left_join
## @example jentropies(UCBAdmissions)
jentropies.table <- function(Nxy, ...){
    # 0. Parameter checking
    Nxy <- as.table(Nxy) # is this necessary?
    dims <- dim(Nxy)
    if (length(dims) < 2)
        stop("Cannot process joint entropies for tables with less than 2 dimensions.")
    if (length(dims) > 2)
        stop("Cannot process joint entropies for tables of more than 2 dimensionss")
    #    if (length(dims) < 2 | length(dims) > 3)
    #        stop("Cannot process tables with more than 3 dimensions or less than 2 dimensions.")
    if (dims[1] < 2 | dims[2] < 2)
        stop("jentropies are not defined for distributions with a singleton domain.")
    # 1. Start processing: this is a candidate por sentropies_raw
    #require(entropy)
    #unless otherwise specified, we use log2 logarithms
    # CAVEAT: use a more elegant kludge
    vars <- list(...);
    #    if (!("unit" %in% names(vars)))
    if (is.null(vars$unit))
        vars$unit <- "log2"
    if (length(dims)==2){ # N is a plain contingency on X and Y
        Nx <- apply(Nxy, 1, sum) # to be transformed into a probability
        #N <- sum(Nx)
        #H_x <- sapply(Nx, function(n){- n/N * log2(n/N)})
        H_x <- entropy::entropy(Nx, unit="log2")
        #Hx <- do.call(entropy, c(list(y=Nx), vars)) #entropy(Nx,vars)
        Ny <- apply(Nxy, 2, sum)
        H_y <- sum(sapply(Ny, function(n){- n/N * log2(n/N)}))
        H_y <- entropy::entropy(Ny, unit="log2")
        #H_xy <- sum(sum((Nxy/N)*log2((Nxy * N)/(Nx %*% t(Ny)))))
        #H_xy <- sum(sum(-(Nxy/N)*log2(Nxy/N)))
        H_xy <- entropy::entropy(Nxy, unit="log2")
        #Hy <- do.call(entropy, c(list(y=Ny), vars)) #entropy(Ny, vars)
        Ux <- log2(dims[1]) #entropy(rep(1/dims[1],dims[1]),unit="log2",...)
        Uy <- log2(dims[2]) #entropy(rep(1/dims[2],dims[2]),unit="log2",...)
        #Hxy <- do.call(entropy, c(list(y=Nxy), vars)) #entropy(Nxy, vars) 
        VI_P <- c(H_xy - H_y, H_xy - H_x)
        edf <- data.frame(
            name = c("X", "Y"), # After an idyosincracy of dplyr, the rownames do not survive a mutate.
            H_P = c(H_x, H_y), #natstobits(c(infotheo::entropy(X), infotheo::entropy(Y))),
            H_U = c(
                Ux, Uy
                #sum(sapply(X, function(v){log2(length(unique(v)))})),
                #sum(sapply(Y, function(v){log2(length(unique(v)))}))
            ),
            stringsAsFactors = FALSE #Keep the original variable names as factors!
        ) %>% dplyr::mutate(
            DeltaH_P = H_U - H_P, 
            M_P = H_P - VI_P,
            VI_P = VI_P #The ordering of the fields is important for exploratory purposes.s
        ) 
        #df <- data.frame(Ux = Ux, Uy = Uy, Hx = Hx, Hy = Hy, Hxy = Hxy)
    } else {  #DEAD CODE # N is a multiway table: we analyze on the first two margins, but store the second
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
    #return(df)
    return(rbind(edf,cbind(name="XY", as.data.frame(lapply(edf[,2:6], sum)))))
}
