#' @title Use a cypher to make a custom query to the neuPrint server specifying the information you want to obtain
#'
#' @description  Get summary information about the datasets hosted by the neuPrint server in which you are interested
#' @param cypher the cypher by which to make your search, the default returns the available datasets and the servers that host their associated mesh data
#' @param conn optional, a neuprintr connection object, which also specifies the neuPrint server see \code{?neuprint_login}.
#' If NULL, your defaults set in your R.profile or R.environ are used.
#' @param ... methods passed to \code{neuprint_login}
#' @seealso \code{\link{neuprint_login}}, \code{\link{neuprint_available}}
#' @export
#' @rdname neuprint_fetch_custom
neuprint_fetch_custom <- function(cypher = "MATCH (n:Meta) RETURN n.dataset, n.meshHost",
                                  conn = NULL, ...){
  Payload = sprintf('{"cypher":"%s"}',cypher)
  class(Payload) = "json"
  custom = neuprint_fetch(path = 'api/custom/custom', body = Payload, conn = conn, ...)
  custom
}










