#' getData
#'
#' @param tag A three digit numeric representing the ToA tag.
#' @param tracking_time_start Character representation of time (Central European Time, +1 UTC) from which start point data should be retrieved.
#' @param tracking_time_end Character time representing the end point corresponding to the above start point.
#' @param tag_prefix A numeric specifying the tag prefix. Defaults to \code{31001000}
#' @param db Name of the database on the host, to be passed internally to the function \code{DBI}.
#'
#' @return
#' @import RMySQL
#' @export
#'
#' @examples
funcGetData<-function(tag,
                      tracking_time_start,
                      tracking_time_end,
                      tag_prefix="31001000",
                      database = "db",
                      host = "abtdb1.nioz.nl",
                      username = "someuser",
                      password = "somepassword"){

  # check data types
  {
    assertthat::assert_that(is.numeric(tag), msg = "tag provided must be numeric")
    assertthat::assert_that(is.character(tracking_time_start), msg = "start tracking time is not a character")
    assertthat::assert_that(is.character(tracking_time_end), msg = "end tracking time is not a character")
    assertthat::assert_that(as.character(tag_prefix) == "31001000", msg = "tag prefix is not 31001000")

    db_params = c(host, username, password)
    for(i in 1:length(db_params))
    {
      assertthat::assert_that(is.character(db_params[i]),
                              msg = glue('{db_params[i]} is not a character'))
    }
  }

  # process function arguments for sql database
  {
    tag<- paste(tag_prefix,tag,sep="")
    # convert to POSIXct format
    tracking_time_start <- as.POSIXct(tracking_time_start, tz="CET")
    tracking_time_end <- as.POSIXct(tracking_time_end, tz="CET")
    # convert time to UTC (which is the database format)
    attributes(tracking_time_start)$tzone <- "UTC"
    attributes(tracking_time_end)$tzone <- "UTC"
    # convert to numeric and ms (database format)
    tracking_time_start <- as.numeric(tracking_time_start) * 1000
    tracking_time_end <- as.numeric(tracking_time_end) * 1000
  }

  # connect to the ATLAS server
  {
    mydb = dbConnect(MySQL(), user=username, password=password, dbname=database, host=host)
  }

  # SQL code to retrive data
  {
    sql <- paste("select TAG, TIME, X, Y, NBS, VARX, VARY, COVXY  from LOCALIZATIONS where TAG = ", tag, " AND ","TIME > '",tracking_time_start,"' AND ","TIME < '",tracking_time_end,"' ","ORDER BY TIME ASC",sep="")
  }

  # getdata
  d <- dbGetQuery(mydb, sql)

  # add aproximate SD of localization
  # d$SD<-maxSD(d)
  # a bit indirect, but there were some strange warnings with NaN produced.
  if(nrow(d)>0)
  {
    tmp <- d$VARX + d$VARY + 2*d$COVXY
    d$SD <- 0
    d$SD[tmp>0] <- sqrt(tmp[tmp>0])
  }else{
    d$SD <- numeric(0)
  }

  # close connection
  dbDisconnect(mydb)

  # or close all connections
  # lapply( dbListConnections(MySQL()), function(x) dbDisconnect(x)

  # return a dataframe of values
  return(d)
}