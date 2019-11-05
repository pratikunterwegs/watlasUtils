#' segPath2
#'
#' @param revdata A string filepath to data in csv format. The data must be the output of recurse analysis, or must include, in addition to X, Y and time columns, a residence time column named resTime, id, and tidalcycle.
#' @param resTimeLimit A numeric giving the time limit in minutes against which residence time is compared.
#' @param travelSeg A numeric value of the number of fixes, or rows, over which a smoother function is applied.
#' @param infPatchTimeDiff A numeric duration in seconds, of the minimum time difference between two points, above which, it is assumed worthwhile to examine whether there is a missing residence patch to be inferred.
#' @param infPatchSpatDiff A numeric distance in metres, of the maximum spatial distance between two points, below which it may be assumed few extreme movements took place between them.
#' @param htdata A string filepath to data in csv format. The data must be the output of tidal cycle finding analysis, or must include, in addition to X, Y and time columns, a tidaltime column named tidaltime; also id, and tidalcycle for merging.
#'
#' @return A data.frame extension object. This dataframe has additional inferred points, indicated by the additional column for empirical fixes ('real') or 'inferred'.
#' @import data.table
#' @export
#'

funcInferResidence <- function(revdata,
                               htdata,
                               resTimeLimit = 2,
                               travelSeg = 5,
                               infPatchTimeDiff = 1800,
                               infPatchSpatDiff = 100){

  # handle global variable issues
  infPatch<-nfixes<-posId<-resPatch<-resTime<-resTimeBool<-rollResTime <- NULL
  spatdiff <- time <- timediff <- type <- x <- y <- npoints <- NULL

  # adding the inferPatches argument to prep for inferring
  # residence patches from missing data between travel segments

  # read the file in
  {
    df <- revdata
    htdf <- htdata

    # convert both to DT if not
    if(is.data.table(df) != TRUE) {setDT(df)}
    if(is.data.table(htdf) != TRUE) {setDT(htdf)}

    # merge with ht data
    df <- base::merge(df, htdf, by = intersect(names(df), names(htdf)), all = FALSE)
    print(glue::glue('\n\nindividual {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
    rm(htdf); gc()
  }

  # get names and numeric variables
  dfnames <- names(df)
  namesReq <- c("id", "tidalcycle", "x", "y", "time", "resTime")
  numvars <- c("x","y","time","resTime")

  # include asserts checking for required columns
  {
    for (i in 1:length(namesReq)) {
      assertthat::assert_that(namesReq[i] %in% dfnames,
                              msg = glue::glue('{namesReq[i]} is required but missing from data!'))
    }
  }

  ## SET THE DF IN ORDER OF TIME ##
  data.table::setorder(df,time)

  # check this has worked
  {
    assertthat::assert_that(min(diff(df$time)) >= 0,
                            msg = "data for segmentation is not ordered by time")
  }

  # make a df with id, tidalcycle and time seq, with missing x and y
  # identify where there are missing segments more than 2 mins long
  # there, create a sequence of points with id, tide, and time in 3s intervals
  # merge with true df
  tempdf <- df[!is.na(time),]
  # get difference in time and space
  tempdf <- tempdf[,`:=`(timediff = c(diff(time), NA),
                         spatdiff = funcDistance(df = tempdf, x = "x", y = "y"))]

  # find missing patches if timediff is greater than specified (default 30 mins)
  # AND spatdiff is less than specified (100 m)
  tempdf[,infPatch := cumsum(timediff > infPatchTimeDiff & spatdiff < infPatchSpatDiff)]

  # subset the data to collect only the first two points of an inferred patch
  tempdf[,posId := 1:(.N), by = "infPatch"]
  # remove NA patches
  tempdf <- tempdf[posId <= 2 & !is.na(infPatch),]
  # now count the max posId per patch, if less than 2, merge with next patch
  # merging is by incrementing infPatch by 1
  tempdf[,npoints:=max(posId), by="infPatch"]
  tempdf[,infPatch:=ifelse(npoints == 2, yes = infPatch, no = infPatch+1)]
  tempdf <- tempdf[npoints >= 2,]
  # recount the number of positions, each inferred patch must have minimum 2 pos
  {
    assertthat::assert_that(min(tempdf$npoints) > 1,
                            msg = "some inferred patches with only 1 position")
  }
  # remove unn columns
  set(tempdf, ,c("posId","npoints"), NULL)

  # handle cases where there are inferred patches

  # add type to real data
  df[,type:="real"]

  # enter this step only if there are 2 or more rows of data between which to infer patches
  if(nrow(tempdf) >= 2)
  {
    print(glue::glue('\n... data has {max(tempdf$infPatch)} inferred patches\n\n'))
    # make list column of expected times with 3 second interval
    # assume coordinate is the mean between 'takeoff' and 'landing'
    infPatchDf <- tempdf[,nfixes:=length(seq(from = min(time), to = max(time), by = 3)),
                         by = c("id", "tidalcycle", "infPatch")
                         ][,.(time = seq(from = min(time), to = max(time), by = 3),
                              x = mean(x),
                              y = mean(y),
                              resTime = resTimeLimit),
                           by = c("id", "tidalcycle", "infPatch","nfixes")
                           ][infPatch > 0,
                             ][,type:="inferred"]

    rm(tempdf); gc()
    # merge inferred data to empirical data
    df <- base::merge(df, infPatchDf, by = intersect(names(df), names(infPatchDf)), all = T)
  } else {print(glue::glue('\n... {unique(df$id)} has 0 inferred patches'))}


  # sort by time
  data.table::setorder(df, time)

  # check this has worked
  {
    assertthat::assert_that(min(diff(df$time)) >= 0,
                            msg = "data for segmentation is not ordered by time")
  }

  return(df)

}

# ends here