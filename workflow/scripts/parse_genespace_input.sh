#----------------------------------------------#
#----------------------------------------------#
#---------------- Parse the flags -------------#
#----------------------------------------------#
#----------------------------------------------#

# Default values
in_dir=""
out_dir=""
pep_dir=""
bed_dir=""
export in_dir=$in_dir
export out_dir=$out_dir
export pep_dir=$pep_dir
export bed_dir=$bed_dir

# Usage example
function print_usage() {
    echo "Usage: $0 -i <input_directory> -o <output_directory> -b <bed_directory> -p <peptide_directory>" 
}

# Parse command line options using getopts 
while getopts "i:o:b:p:" flag; do
    case "$flag" in
        i)
            in_dir="$OPTARG" ;;
        o)
            out_dir="$OPTARG" ;;
        b)
            bed_dir="$OPTARG" ;;
        p)
            pep_dir="$OPTARG" ;;
        *) 
            print_usage 
            exit 1 ;;
    
    esac
done


# Check if required flags are provided
if test -z "$in_dir"; then
    echo "-i flags is required."
    print_usage
    exit 1
fi
if test -z "$out_dir"; then
    echo "-o flags is required."
    print_usage
    exit 1
fi
if test -z "$bed_dir"; then
    echo "-b flags is required."
    print_usage
    exit 1
fi
if test -z "$pep_dir"; then
    echo "-p flags is required."
    print_usage
    exit 1
fi


#----------------------------------------------#
#----------------------------------------------#
#------ Extract Primary Peptide Sequence ------#
#----------------------------------------------#
#----------------------------------------------#

mkdir -p ${out_dir}/${bed_dir} ${out_dir}/${pep_dir}

make_peptide_files() {

    progenitor=$1
    gff_file=$(find $in_dir/progenitor/$progenitor -name "*gff")
    fa_file=$(find $in_dir/progenitor/$progenitor -name "*fa")
    
    primary_iso_gff=${out_dir}/${pep_dir}/${progenitor}_primary.gff
    primary_iso_pep_fa=${out_dir}/${pep_dir}/${progenitor}.fa

    agat_sp_keep_longest_isoform -gff $gff_file -o primary_iso

    gffread $primary_iso -g $fa_file -J -E -y $primary_iso_pep_fa

}

make_bed_files() {

    progenitor=$1
    gff_file=$(find $in_dir/progenitor/$progenitor -name "*gff")
    fa_file=$(find $in_dir/progenitor/$progenitor -name "*fa")

    gff2bed < $gff_file > ${out_dir}/${bed_dir}/${progenitor}.bed

}


# export the function & variables
export -f make_peptide_files
export -f make_bed_files

# Make the files
wkd=$(pwd)
ls $wkd
ls $in_dir/progenitor | xargs -I {} bash -c 'make_peptide_files "{}"'
ls $in_dir/progenitor | xargs -I {} bash -c 'make_bed_files "{}"'