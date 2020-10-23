context("remove attractors data\n")
testthat::test_that("attractor points removed", {

  # make testdata
  testdata <- data.table::data.table(
    X = as.double(1:1e3),
    Y = as.double(1:1e3)
  )

  testdata <- testdata[200:500, `:=`(
    X = rnorm(301, 300, 20),
    Y = rnorm(301, 800, 20)
  )]

  # run function
  testoutput <- watlastools::wat_rm_attractor(
    df = testdata,
    atp_xmin = 200:201, atp_xmax = 400:401,
    atp_ymin = 700:701, atp_ymax = 900:901
  )

  # do tests
  # test that the vector class is data.table and data.frame
  testthat::expect_s3_class(object = testoutput, class = c(
    "data.table",
    "data.frame"
  ))

  # check that some rows are removed or that none are added
  testthat::expect_gte(nrow(testdata), nrow(testoutput))
})
