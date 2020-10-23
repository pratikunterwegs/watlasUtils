#' Remove attractor points.
#'
#' @param df A dataframe which contains capitalised X and Y coordinates.
#' @param atp_xmin The min X coordinates of attractor locations.
#' @param atp_xmax The max X coordinates of attractor locations.
#' @param atp_ymin The min Y coordinates of attractor locations.
#' @param atp_ymax The max Y coordinates of attractor locations.
#'
#' @return A data frame of tracking locations with attractor points removed.
#' @export
#'
wat_rm_attractor <- function(df,
                             atp_xmin = 639470,
                             atp_xmax = 639472,
                             atp_ymin = 5887143,
                             atp_ymax = 5887145) {
  X <- Y <- NULL
  # check input type
  assertthat::assert_that("data.frame" %in% class(df),
    msg = "rmAttractor: input not a dataframe object!"
  )

  # include asserts checking for required columns
  dfnames <- colnames(df)
  namesReq <- c("X", "Y")
  purrr::walk(namesReq, function(nr) {
    assertthat::assert_that(nr %in% dfnames,
      msg = glue::glue("rmAttractor: {nr} is
                         required but missing from data!")
    )
  })


  # check input length of attractors
  assertthat::assert_that(length(unique(
    length(atp_xmin),
    length(atp_xmax),
    length(atp_ymin),
    length(atp_ymax)
  )) == 1,
  msg = "rmAttractor: different attractor coord lengths"
  )

  # convert to data.table
  # convert both to DT if not
  if (is.data.table(df) != TRUE) {
    data.table::setDT(df)
  }

  # remove attractors
  purrr::pwalk(
    list(atp_xmin, atp_xmax, atp_ymin, atp_ymax),
    function(axmin, axmax, aymin, aymax) {
      df <- df[!((X > axmin) & (X < axmax) &
        (Y > aymin) & (Y < aymax)), ]
    }
  )

  assertthat::assert_that("data.frame" %in% class(df),
    msg = "cleanData: cleanded data is not a dataframe object!"
  )

  return(df)
}

# ends here
