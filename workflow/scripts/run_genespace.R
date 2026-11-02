sink(snakemake@log[[1]], split=TRUE, append=TRUE)

# GENESPACE version (GitHub tag or commit) set in the Snakefile; (re)install if a different one is installed
genespace_version <- snakemake@params[["genespace_version"]]
if (!requireNamespace("GENESPACE", quietly = TRUE) ||
    !identical(utils::packageDescription("GENESPACE")$RemoteRef, genespace_version))
    remotes::install_github(paste0("jtlovell/GENESPACE@", genespace_version), quiet = TRUE, upgrade = "never", force = TRUE)

library(GENESPACE)

tryCatch({
   
  gpar <- init_genespace(
    wd = snakemake@input[["genespace_run_dir"]], 
    path2mcscanx = snakemake@params[["mc_scan_dir"]],
    nCores= snakemake@threads)

  gpar <- run_genespace(gsParam = gpar) 

  # Marker for downstream rules, written only if GENESPACE finished without an error
  writeLines(paste0("GENESPACE run completed. Log: ", snakemake@log[[1]]), snakemake@output[[1]])

}, error = function(e) {

    cat("ERROR:", conditionMessage(e), "\n")
    quit(status = 1)

}, finally = {
    sink()
})
