#' A function to repair high tide data.
#'
#' @param patch_data_list A list of data.tables, each the output of
#' make_res_patch. Must have an sfc geometry column.
#' @param lim_spat_indep The spatial independence limit.
#' @param lim_time_indep The temporal independence limit.
#' @param buffer_radius The buffer size for spatial polygons.
#' @return A datatable with repaired high tide patches.
#' @import data.table
#' @export
#'
wat_repair_ht_patches <- function(patch_data_list,
                                  lim_spat_indep = 100,
                                  lim_time_indep = 30,
                                  buffer_radius = 10) {

  # set gloabl variables to NULL
  patch <- polygons <- tide_number <- NULL
  time_start <- time_end <- x_start <- NULL
  x_end <- y_start <- y_end <- newpatch <- NULL
  timediff <- spatdiff <- new_tide_number <- NULL
  patchdata <- id <- patchSummary <- x <- NULL
  y <- resTime <- tidaltime <- waterlevel <- NULL
  distInPatch <- distBwPatch <- dispInPatch <- NULL
  type <- duration <- area <- nfixes <- time <- NULL

  # check data assumptions
  # check for dataframe and sf object
  # check if data frame
  assertthat::assert_that(is.list(patch_data_list),
                          msg = glue::glue('wat_repair_ht: input not a \\
              list, has class \\
              {stringr::str_flatten(class(patch_data_list),
              collapse = " ")}!'))

  assertthat::assert_that(min(c(buffer_radius, lim_spat_indep,
                                lim_time_indep)) > 0,
                      msg = "wat_repair_ht: function needs positive arguments")

  # check that list elements are data tables with correct names
  names_required <- c("id", "tide_number", "patch",
                      "x_start", "y_start", "x_end", "y_end",
                      "time_start", "time_mean", "time_end",
                      "type")

  # convert variable units
  lim_time_indep <- lim_time_indep * 60

  tryCatch({

  # bind all datatable into a single datatable
  # this needs to change
  patch_data_list <- patch_data_list[unlist(purrr::map(patch_data_list,
      function(l) {
        data.table::is.data.table(l) & nrow(l) > 0 &
          all(names_required %in% colnames(l))
        }
      )
  )]
  data <- data.table::rbindlist(patch_data_list, use.names = TRUE)

  # select first and last rows from each tide_number
  # and assess independence
  # subset edge cases from main data
  edge_data <- data[data[, .I[patch == min(patch) | patch == max(patch)],
                         by = list(tide_number)]$V1]

  data <- data[data[, .I[patch != min(patch) & patch != max(patch)],
                    by = list(tide_number)]$V1]

  edge_data_summary <- edge_data[, list(patch, time_start, time_end,
                                     x_start, x_end,
                                     y_start, y_end,
                                     tide_number)]

  edge_data_summary[, `:=`(timediff = c(Inf,
                              as.numeric(time_start[2:length(time_start)] -
                                      time_end[seq_len(length(time_end) - 1)])),
                           spatdiff = c(wat_bw_patch_dist(
                             data = edge_data_summary,
                             x1 = "x_end", x2 = "x_start",
                             y1 = "y_end", y2 = "y_start")
                           ))]

  edge_data_summary[1, "spatdiff"] <- Inf

  # which patches are independent?
  # assign NA as tide number of non-independent patches
  # and to the patch number of non-indep patches
  edge_data_summary[, newpatch := (timediff > lim_time_indep |
                                     spatdiff > lim_spat_indep)]
  edge_data_summary[newpatch == FALSE, "tide_number"] <- NA
  edge_data_summary[, newpatch := ifelse(newpatch == TRUE, patch, NA)]

  # nafill with last obs carried forward for now NA tides and patches
  edge_data_summary[, `:=`(new_tide_number = data.table::nafill(tide_number,
                                                                "locf"),
                           newpatch = data.table::nafill(newpatch, "locf"))]
  edge_data_summary <- edge_data_summary[, list(tide_number, patch,
                                             new_tide_number, newpatch)]

  # merge summary with data
  # make a temporary reeating seq of id, tide and patch
  temp_ed <- edge_data[, list(id, tide_number, patch)]
  temp_ed <- temp_ed[rep(seq_len(nrow(temp_ed)),
                         purrr::map_int(edge_data$patchdata, nrow)), ]
  edge_data <- cbind(temp_ed, data.table::rbindlist(edge_data$patchdata,
                                                    use.names = TRUE))
  rm(temp_ed)

  edge_data <- data.table::merge.data.table(edge_data, edge_data_summary,
                                            by = c("tide_number", "patch"))


  # recalculate patch ids among the new tides
  edge_data[, `:=`(tide_number = new_tide_number,
                   new_tide_number = NULL,
                   patch = newpatch,
                   newpatch = NULL)]

  edge_data <- edge_data[, list(list(.SD)),
                         by = list(id, tide_number, patch)]
  data.table::setnames(edge_data, old = "V1", new = "patchdata")

  # get basic data summaries
  edge_data[, patchSummary := lapply(patchdata, function(dt) {
    dt <- dt[, list(time, x, y,
                 resTime, tidaltime, waterlevel)]
    dt <- data.table::setDF(dt)
    dt <- dplyr::summarise_all(.tbl = dt,
                               .funs = list(start = dplyr::first,
                                            end = dplyr::last,
                                            mean = mean))
    return(data.table::setDT(dt))
  })]

  # advanced metrics on ungrouped data
  # distance in a patch in metres
  edge_data[, distInPatch := lapply(patchdata, function(df) {
    sum(wat_simple_dist(data = df), na.rm = TRUE)
  })]

  # distance between patches
  tempdata <- edge_data[, unlist(patchSummary, recursive = FALSE),
                        by = list(id, tide_number, patch)]

  edge_data[, patchSummary := NULL]
  edge_data[, distBwPatch := wat_bw_patch_dist(data = tempdata,
                                                x1 = "x_end", x2 = "x_start",
                                                y1 = "y_end", y2 = "y_start")]
  # displacement in a patch
  # apply func bw patch dist reversing usual end and begin
  tempdata[, dispInPatch := sqrt((x_end - x_start) ^ 2 + (y_end - y_start) ^ 2)]
  # type of patch
  edge_data[, type := lapply(patchdata, function(df) {
    a <- ifelse(sum(c("real", "inferred") %in% df$type) == 2,
                "mixed", data.table::first(df$type))
    return(a)
  })]

  # even more advanced metrics
  tempdata[, duration := (time_end - time_start)]
  # true spatial metrics
  edge_data[, polygons := lapply(patchdata, function(df) {
    p1 <- sf::st_as_sf(df, coords = c("x", "y"))
    p2 <- sf::st_buffer(p1, dist = buffer_radius)
    p2 <- sf::st_union(p2)
    return(p2)
  })]

  # add area and circularity
  edge_data[, area := purrr::map_dbl(polygons, sf::st_area)]
  edge_data[, `:=`(circularity = (4 * pi * area) /
                     purrr::map_dbl(polygons, function(pgon) {
                       boundary <- sf::st_boundary(pgon)
                       perimeter <- sf::st_length(boundary)
                       return(as.numeric(perimeter) ^ 2)
                     }
                     )
  )]

  # remove polygons here too
  edge_data[, polygons := NULL]

  # remove patch summary from some data and add temp data, then del tempdata
  edge_data <- data.table::merge.data.table(edge_data,
                                            tempdata,
                                            by = c("id", "tide_number",
                                                   "patch"))
  edge_data[, nfixes := unlist(lapply(patchdata, nrow))]

  # reattach edge cases to regular patch data and set order by start time
  data <- rbind(data, edge_data)
  data.table::setorder(data, time_start)

  # fix distance between patches
  data[, distBwPatch := wat_bw_patch_dist(data)]

  # fix patch numbers in tides
  data[, patch := seq_len(.N), by = list(tide_number)]

  # unlist all list columns
  data <- data[, lapply(.SD, unlist),
               .SDcols = setdiff(colnames(data), "patchdata")]

  return(data)
  },
  error = function(e) {
    message(glue::glue("there was an error in repair"))
  })
}
