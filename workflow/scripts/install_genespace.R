# Install GENESPACE from github

library(devtools)

if (!requireNamespace("GENESPACE", quietly = TRUE))
    devtools::install_github("jtlovell/GENESPACE", quiet = TRUE, upgrade="never")