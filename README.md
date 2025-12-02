# `snake-GENESPACE`

[![Snakemake](https://img.shields.io/badge/snakemake-≥9-brightgreen.svg)](https://snakemake.github.io)

(for Linux OS only)

A Snakemake workflow to automate and facilitate usage of GENESPACE, an analytical pipeline to understand patterns of synteny and orthology across multiple genomes. 

The aim of this workflow is to make GENESPACE easier to use and improve reproducibility. It does so by automating the most annoying parts of a GENESPACE analysis, namely:

- Input data formating
- Software installation

It also produces a detailed "reproducibility report" with information about software versions, operating system, input and output files. 

Input data formating is the "trickiest part of running GENESPACE" (see [GENESPACE](https://github.com/jtlovell/GENESPACE) section 3). With the snake-GENESPACE workflow you can have your data as GFF structural annotations and fasta genome assemblies. The workflow automatically:

- Converts the GFF file into bed format.
- Extracts and translates coding sequences into peptide fasta files.
- Renames each bed and fasta entry to have the exact same (gene) name.

This is done with the brilliant [AGAT suite of tools](https://github.com/NBISweden/AGAT) and some custom awk script. 
You can also have part or all of your data already in the right format for GENESPACE. In this case you can include it in the snake-GENESPACE input directory (details below). Even if all your data is in the right format you might still want to use snake-GENESPACE to install all the required softwares.

GENESPACE depends on the stand alone tools MCScanX and Orthofinder as well as a number of R-packages. It can be frustrating to manage installation of all the dependecies. Snakemake makes such dependencies easy to deal with by installing them automatically in a conda environment. **All this means** is that you just need to [install Snakemake via Conda](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) and to git clone this repository to have all the GENESPACE requirement met. 

## Bugs, Suggestions, Help 

If you wish to report an error/bug, ask for help, or suggest changes and new features, please open an issue [here](https://github.com/kenji-yt/snake-GENESPACE/issues). 

## Installation 

- [install Snakemake via Conda](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).
- git clone snake-GENESPACE: 
```
git clone https://github.com/kenji-yt/snake-GENESPACE.git
```
[**Note:** Make sure to have a valid C++ compiler installed. Snake-GENESPACE does not take care of this dependency because MacOS and Linux users need different C++ compilers.]

## Input 

The input to snake-GENESPACE is a directory. Inside it you should have one directory for each species (or genome). The name of the directory should be the species or genome name and will appear as such in the GENESPACE output figures. In these directories you should have **only** two files: a gff annotation and a fasta assembly. Name these files as you wish as long as they have one of the following extensions: "gff","gff3" for annotations; "fa","fasta","fq","fna","fastq" for assemblies. 

If you have some data already in the right format for GENESPACE just put your "bed" and "peptide" directories within the snake-GENESPACE input directory. In brief, GENESPACE requires an annotation in bed format and a fasta file with peptide sequences. The gene or feature names in the bed file should match the sequence names in the fasta exactly. All bed files should be put in a directory called "bed" and all fasta files in a directory called "peptide". The name of each file should be the desired species (or genome) name and should be the same for corresponding bed and fasta. Getting data in this format is what snake-GENESPACE does using [AGAT](https://github.com/NBISweden/AGAT) and custom bash and awk script (see "snake-GENESPACE/workflow/scripts/parse_genespace_input.sh"). 


Your input directory should have the following structure:
```
input_directory/
├── species_1/
│   ├── annotation.gff
│   └── assembly.fa
├── species_2/
│   ├── annotation.gff
│   └── assembly.fa
├── species_3/
│   ├── annotation.gff
│   └── assembly.fa
(etc...) 

You can also have some inputs already GENESPACE formated:
├── peptide/
│   ├── species_5.fa
│   └── species_6.fa
└── bed/
    ├── species_5.bed
    └── species_6.bed
```
At present, snake-GENESPACE does not provide any option to specify your own run parameters. This is because GENESPACE is said to cover a wide range of evolutionary scenarios under its default mode. If this is something that is really desired feel free to open an issue to request it. 

You can find an **input directory template** in the `snake-GENESPACE` directory. This is not a test dataset as it only contains empty files. It just serves as a guide for your own input directory.  


## Analysis 

That's it, you are ready to run a GENEPSACE analysis. From within the "snake-GENESPACE/" directory run:
```
snakemake --use-conda --cores N --config INPUT_DIR='your/input/directory'
```
Make sure to have snakemake make installed, to replace 'your/input/directory' with the path to you input directory and 'N' with the number of cores you wish to allocate to the job. If you installed snakemake in a conda environment make sure to activate it (eg. "conda activate snakemake_env").  

The outputs will now be generated in a results directory within the snake-GENESPACE directory. 

**IMPORTANT NOTE:** A lot of errors are due to strange input files. Unfortunately, snake-GENESPACE is not the best at producing informative error messages (and AGAT messages are also confusing). Some common error sources are: 
- Chromosome names are not the same between the annotation and assembly
- The number of characters per line in the assembly is not constant (in folded fasta files)

*Extra:* If you are new to snakemake you might find it weird to run the program from within its source directory. This is how snakemake works and it's nothing to worry about. Finally, do not be alarmed if the messages printed to the terminal are confusing. This is normal since multiple processes print out at the same time (if -c >1). If you want to know what happened check out the log files in the log directory within your specified output directory. 
