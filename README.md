
<!-- README.md is generated from README.Rmd. Please edit that file -->

# crformats

<!-- badges: start -->

[![R-CMD-check](https://github.com/gigu003/crformats/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gigu003/crformats/actions/workflows/R-CMD-check.yaml)
[![Quarto](https://img.shields.io/badge/Quarto-≥1.8-blue)](https://quarto.org)
[![Typst](https://img.shields.io/badge/Typst-0.13+-green)](https://typst.app)
<!-- badges: end -->

Provides Quarto extension templates, styles, and helper functions for
generating high-quality cancer registry reports.

## Installation

You can install the development version of crformats from
[GitHub](https://github.com/gigu003/crformats) with:

``` r
# install.packages("devtools")
devtools::install_github("gigu003/crformats")
```

or you can install crformats using the r-universe

``` r
install.packages('crformats', repos = c('https://gigu003.r-universe.dev', 'https://cloud.r-project.org'))
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(crformats)
use_quarto_ext(ext_name = "qcreport")
```
