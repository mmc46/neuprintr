# hidden
neuprint_fetch <- function(path, body = NULL, conn = NULL, parse.json = TRUE,
                           include_headers = TRUE, simplifyVector = FALSE, ...){
  path = gsub("\\/$|^\\/","",path)
  conn = neuprint_login(conn)
  # you cannot have double / in any part of path
  server = sub("\\/$", "", conn$server)
  req <-
    if (is.null(body)) {
      httr::GET(url = file.path(server, path, fsep = "/"),
                config = conn$config,  ...)
    }else {
      httr::POST(url = file.path(server, path, fsep = "/"),
           body = body, config = conn$config, ...)
    }
  httr::stop_for_status(req)
  if (parse.json) {
    parsed = neuprint_parse_json(req, simplifyVector = simplifyVector)
    if (length(parsed) == 2 && isTRUE(names(parsed)[2] =="error")) {
      stop("neuprint error: ", parsed$error)
    }
    if (include_headers) {
      fields_to_include = c("url", "headers")
      attributes(parsed) = c(attributes(parsed), req[fields_to_include])
    }
    parsed
  }
  else req
}

# hidden
neuprint_parse_json <- function (req, simplifyVector = FALSE, ...) {
  text <- httr::content(req, as = "text", encoding = "UTF-8")
  if (identical(text, ""))
    stop("No output to parse", call. = FALSE)
  jsonlite::fromJSON(text, simplifyVector = simplifyVector, ...)
}

#' Parse neuprint return list to a data frame
#'
#' @details A low level function tailored to the standard neuprint list return
#'   format. Should handle those times when jsonlite's simplifcation doesn't
#'   work. The normal return value of \code{\link{neuprint_fetch_custom}} is a
#'   list formatted as follows: \itemize{
#'
#'   \item{columns}{ List of column names}
#'
#'   \item{data}{ Nested list of data, with each row formatted as a single
#'   sublist}
#'
#'   \item{debug }{ Character vector containing query}}
#'
#'   If \code{neuprint_list2df} receives such a list it will use the
#'   \code{columns} to define the names for a data.frame constructed from the
#'   \code{data} field.
#'
#' @param x A list returned by \code{\link{neuprint_fetch_custom}}
#' @param cols Character vector specifying which columns to include (by default
#'   all of those named in \code{x}, see details).
#' @param return_empty_df Return a zero row data frame when there is no result.
#' @param ... Additional arguments passed to \code{\link{as.data.frame}}
#' @export
neuprint_list2df <- function(x, cols=NULL, return_empty_df=FALSE, ...) {

  if(length(x)>=2 && all(c("columns", "data") %in% names(x))) {
    if(is.null(cols)) cols=unlist(x$columns)
    x=x$data
    colidxs=match(cols, cols)
  } else {
    colidxs=seq_along(cols)
  }

  if(!length(x)) {
    return(if(return_empty_df){
      as.data.frame(structure(replicate(length(cols), logical(0)), .Names=cols))
    } else NULL)
  }

  l=list()
  for(i in seq_along(cols)) {
    colidx=colidxs[i]
    raw_col = sapply(x, "[[", colidx)
    if(is.list(raw_col)) {
      raw_col[sapply(raw_col, is.null)]=NA
      sublens=sapply(raw_col, length)
      if(all(sublens==1))
        raw_col=unlist(raw_col)
      else raw_col=sapply(raw_col, paste, collapse=',')
    }
    l[[cols[i]]]=raw_col
  }
  as.data.frame(l, ...)
}

#' @importFrom memoise memoise
neuprint_name_field <- memoise(function(conn=NULL) {
  if (is.null(conn))
    stop(
      "You must do\n  conn = neuprint_login(conn)\n",
      "before using neuprint_name_field(conn) in your function!",
      call. = FALSE
    )
  q="MATCH (n :hemibrain_Neuron) WHERE exists(n.instance) RETURN count(n)"
  n=unlist(neuprint_fetch_custom(q, include_headers=F)[['data']])
  return(ifelse(n>0, "instance", "name"))
})

neuprint_dataset_prefix <- memoise(function(dataset, conn=NULL) {
  if (is.null(conn))
    stop(
      "You must do\n  conn = neuprint_login(conn)\n",
      "before using neuprint_dataset_prefix(conn) in your function!",
      call. = FALSE
    )
  q=sprintf("MATCH (n:`%s_Neuron`) RETURN count(n)", dataset)
  n=unlist(neuprint_fetch_custom(q, include_headers=F)[['data']])
  paste0(dataset, ifelse(n>0, "_", "-"))
})

check_dataset <- function(dataset=NULL) {
  # Get a default dataset if none specified
  if(is.null(dataset)){
    dataset = unlist(getenvoroption("dataset"))
    if(is.null(dataset))
      stop("Please supply a dataset or set a default one using the ",
           "neuprint_dataset environment variable! See ?neuprint_login for details.")
  }
  dataset
}
