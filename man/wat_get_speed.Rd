% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/func_get_speed.r
\name{wat_get_speed}
\alias{wat_get_speed}
\title{Calculate instantaenous speed.}
\usage{
wat_get_speed(data, x = "x", y = "y", time = "time")
}
\arguments{
\item{data}{A dataframe or similar which must have the columns
specified by \code{x}, \code{y}, and \code{time}.}

\item{x}{The x coordinate.}

\item{y}{The y coordinate.}

\item{time}{The timestamp in seconds since the UNIX epoch.}
}
\value{
A vector of numerics representing speed.
The first position is assigned a speed of NA.
}
\description{
Calculate instantaenous speed.
}
