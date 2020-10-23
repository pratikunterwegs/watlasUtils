context("residence patches and classified points")
testthat::test_that("patch calc on empirical data", {

  # read in data
  somedata <- data.table::fread("../testdata/435_025_revisit.csv")

  # run function for patch inference
  inference_output <- watlastools::wat_infer_residence(data = somedata,
                                                      inf_patch_time_diff = 60,
                                                      inf_patch_spat_diff = 100)


  # run function for classification
  classified_output <- watlastools::wat_classify_points(data = inference_output)

  # run function for patch construction
  testoutput <- watlastools::wat_make_res_patch(data = classified_output,
                                             buffer_radius = 10,
                                             lim_spat_indep = 100,
                                             lim_time_indep = 30,
                                             lim_rest_indep = 10,
                                             min_fixes = 3)

  # do tests
  # test that the sf output class is at least sf
  testthat::expect_s3_class(object = testoutput,
                            class = c("sf", "data.frame", "data.table"))

  # test that names are present in output cols
  expnames <- c("id", "tide_number", "type", "patch", "time_mean",
                "tidaltime_mean", "x_mean", "y_mean", "duration", "distInPatch",
                "distBwPatch",  "dispInPatch")
  watlastools:::wat_check_data(data = testoutput,
                               names_expected = expnames)

  # check that data are ordered in time
  testthat::expect_gt(min(as.numeric(diff(testoutput$time_mean)),
                          na.rm = TRUE), 0)
})

testthat::test_that("patch data access function works", {

  # read in data
  somedata <- data.table::fread("../testdata/435_025_revisit.csv")

  # run function for patch inference
  inference_output <- watlastools::wat_infer_residence(data = somedata,
                                                      inf_patch_time_diff = 30,
                                                      inf_patch_spat_diff = 100)


  # run function for classification
  classified_output <- watlastools::wat_classify_points(data = inference_output)

  # run function for patch construction
  testoutput <- watlastools::wat_make_res_patch(data = classified_output,
                                             buffer_radius = 10,
                                             lim_spat_indep = 50,
                                             lim_time_indep = 30)

  # access testoutput summary
  data_access_smry <- watlastools::wat_get_patch_summary(res_patch_data =
                                                           copy(testoutput),
                                                      which_data = "summary")

  # access testoutput spatial
  data_access_sf <- watlastools::wat_get_patch_summary(res_patch_data =
                                                         copy(testoutput),
                                                  which_data = "spatial")

  # access testoutput spatial
  data_access_pt <- watlastools::wat_get_patch_summary(res_patch_data =
                                                         copy(testoutput),
                                                  which_data = "points")

  # test class summary
  testthat::expect_s3_class(object = data_access_smry,
                            class = c("data.frame", "tbl"))
  # test class pts
  testthat::expect_s3_class(object = data_access_pt,
                            class = c("data.frame", "tbl"))
  # test class sf
  testthat::expect_s3_class(object = data_access_sf, class = c("sf"))

  # test that names are present in output cols
  expnames <- c("id", "tide_number", "type", "patch", "time_mean",
                "tidaltime_mean", "x_mean", "y_mean", "duration", "distInPatch",
                "waterlevel_mean", "distBwPatch", "dispInPatch")
  # test col names in data access
  watlastools:::wat_check_data(data_access_sf,
                               expnames)

  # check that data are ordered in time
  testthat::expect_gt(min(as.numeric(diff(testoutput$time_mean)),
                          na.rm = TRUE), 0)

})

# ends here
