# `snake-GENESPACE`

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.3.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/<owner>/<repo>/workflows/Tests/badge.svg?branch=main)](https://github.com/<owner>/<repo>/actions?query=branch%3Amain+workflow%3ATests)


A Snakemake workflow to automate and facilitate identification of synteny and orthology using GENESPACE. 

The aim of this workflow is to make the use of GENESPACE easier. It does so by automating the most annoying parts of a GENESPACE analysis, namely:

- Input data formating
- Software instalation

Input data formating is the "trickiest part of running GENESPACE" (see [GENESPACE](https://github.com/jtlovell/GENESPACE) section 3). With the snake-GENESPACE workflow you can have your data as GFF structural annotations and fasta genome assemblies. The workflow automatically:

- Converts the GFF file into bed format.
- Extracts and translates coding sequences into peptide fasta files.
- Renames each bed and fasta entry to have the exact same (gene) name.

This is done with the brilliant [AGAT suite of tools](https://github.com/NBISweden/AGAT) and some custom awk script. 

GENESPACE also depends on the stand alone tools MCScanX and Orthofinder as well as a number of R-packages. It can be frustrating to manage installation of all the dependecies. Snakemake makes such dependencies easy to deal with by installing them automatically in a conda environment. **All this means** is that you just need to [install Snakemake via Conda](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) and to git clone this repository to have all the GENESPACE requirement met. 


## Usage

- Install snakemake via conda.
- git clone snake-GENESPACE.
- format input directory.
- modify config file.
- run (Do not be alarmed if the messages printed to the terminal are confusing. This is normal since multiple processes print out at the same time. If you want to know what happened check out the log files in the log directory within your specified output directory). 

# TODO

* Replace `<owner>` and `<repo>` everywhere in the template (also under .github/workflows) with the correct `<repo>` name and owning user or organization.
* Replace `<name>` with the workflow name (can be the same as `<repo>`).
* Replace `<description>` with a description of what the workflow does.
* The workflow will occur in the snakemake-workflow-catalog once it has been made public. Then the link under "Usage" will point to the usage instructions if `<owner>` and `<repo>` were correctly set.