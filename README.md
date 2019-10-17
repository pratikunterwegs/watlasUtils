# WATLAS Utilities

**Functions to handle data from the Wadden Sea ATLAS project**

<!-- badges: start -->
  [![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/pratikunterwegs/watlasUtils?branch=master&svg=true)](https://ci.appveyor.com/project/pratikunterwegs/watlasUtils) [![Build Status](https://travis-ci.org/pratikunterwegs/watlasUtils.svg?branch=master)](https://travis-ci.org/pratikunterwegs/watlasUtils) [![codecov.io](https://codecov.io/github/pratikunterwegs/watlasUtils/coverage.svg?branch=master)](https://codecov.io/github/pratikunterwegs/watlasUtils/branch/master)
<!-- badges: end -->

`watlasUtils` is an `R` package with functions that process high-resolution shorebird tracking data collected by the [Wadden Sea ATLAS project](https://www.nioz.nl/en/about/cos/coastal-movement-ecology/shorebird-tracking/watlas-tracking-regional-movements). WATLAS is part of the [Coastal Movement Ecology (C-MovE)](https://www.nioz.nl/en/about/cos/coastal-movement-ecology) group at the Royal Netherlands Institute for Sea Research's Department of Coastal Systems. This package is written and maintained by [Pratik Gupte](https://www.rug.nl/staff/p.r.gupte), at the [University of Groningen's Theoretical Biology Group](https://www.rug.nl/research/gelifes/tres/).

For more information on the system, contact WATLAS PI [Allert Bijleveld (COS-NIOZ)](https://www.nioz.nl/en/about/organisation/staff/allert-bijleveld).

## Installation

```r
# This package can be installed using devtools
install.packages("devtools")

# library("devtools")
devtools::install_github("pratikunterwegs/watlasUtils")
```

## Current functions

The package currently has the following main functions:

  - `funcSegPath` manual segmentation of movement data with an option to infer residence patches based on gaps in the data.
  - `funcGetResPatches` construction of `sf`-based residence patches and calculation of patch- and trajectory-specific metrics.

## Planned functions

It may be a good idea to split off some components of the two main functions to make them more modular, and to add some smaller diagnostic functions.

### Modularity in main functions

- `funcInferPatches` a function to detect temporal gaps in the data and convert these to 'inferred patches' if the data on either side of the gap satisfies some criteria. To be split off from `funcSegPath`, which already has this functionality.
- `funcGetPatchSpatials` a function to construct `sf` `MULTIPOLYGON` objects from patch data, and export to local file.
- `funcVisPatches` a function taking data with id and tidal-cycle information, and visualising (and optionally saving) the output as a map-like image.
