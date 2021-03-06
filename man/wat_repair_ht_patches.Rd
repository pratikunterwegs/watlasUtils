% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/func_repair_ht_patches.r
\name{wat_repair_ht_patches}
\alias{wat_repair_ht_patches}
\title{A function to repair high tide data.}
\usage{
wat_repair_ht_patches(
  patch_data_list,
  lim_spat_indep = 100,
  lim_time_indep = 30,
  buffer_radius = 10
)
}
\arguments{
\item{patch_data_list}{A list of data.tables, each the output of
make_res_patch. Must have an sfc geometry column.}

\item{lim_spat_indep}{The spatial independence limit.}

\item{lim_time_indep}{The temporal independence limit.}

\item{buffer_radius}{The buffer size for spatial polygons.}
}
\value{
A datatable with repaired high tide patches.
}
\description{
A function to repair high tide data.
}
