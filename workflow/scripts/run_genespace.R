library(GENESPACE)
gpar <- init_genespace(
  wd = "/path/to/your/workingDirectory", 
  path2mcscanx = "/path/to/MCScanX/")
gpar <- run_genespace(gsParam = gpar) 