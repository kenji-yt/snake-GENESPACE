library(devtools)

if (!requireNamespace("GENESPACE", quietly = TRUE))
    devtools::install_github("jtlovell/GENESPACE", quiet = TRUE, upgrade="never")

library(GENESPACE)

gpar <- init_genespace(
  wd = snakemake@input[["genespace_run_dir"]], 
  path2mcscanx = snakemake@params[["mc_scan_dir"]],
  nCores= snakemake@threads)

gpar <- run_genespace(gsParam = gpar,) 