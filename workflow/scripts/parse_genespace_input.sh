#----------------------------------------------#
#----------------------------------------------#
#---------------- Parse the flags -------------#
#----------------------------------------------#
#----------------------------------------------#

# Default values
in_dir=""
out_dir=""
log_file=""
cores=""


# Usage example
function print_usage() {
    echo "Usage: $0 -i <input_directory> -o <genespace_input_directory> -l <log_file> -c <cores>" 
}

# Parse command line options using getopts 
while getopts "i:o:l:c:" flag; do
    case "$flag" in
        i)
            in_dir="$OPTARG" ;;
        o)
            out_dir="$OPTARG" ;;
        l)
            log_file="$OPTARG" ;;
        c)
            cores="$OPTARG" ;;
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
if test -z "$log_file"; then
    echo "-l flags is required."
    print_usage
    exit 1
fi
if test -z "$cores"; then
    echo "-c flags is required."
    print_usage
    exit 1
fi

 

bed_dir="${out_dir}/bed"
pep_dir="${out_dir}/peptide"
export log_file=$log_file
export in_dir=$in_dir
export out_dir=$out_dir
export bed_dir=$bed_dir
export pep_dir=$pep_dir


# Function to delete tmp files after premature interuption
delete_file() {
    echo "Keyboard interupt. Deleting temporary files." 
    # If there are any temporary files in the output, delete them. 
    find $out_dir -name ".tmp*" | xargs rm 
    echo "Temporary files deleted successfully."
    find . -name "*.agat.log" | xargs -I {} 'mv {} ${agat_log_dir}'
    exit 1
}
# Trap the script interruption (SIGINT) and execute the delete_file function
trap delete_file INT


#----------------------------------------------#
#----------------------------------------------#
#------ Extract Primary Peptide Sequence ------#
#----------------------------------------------#
#----------------------------------------------#

mkdir -p ${bed_dir} ${pep_dir} ${agat_log_dir}

# function to keep primary isoform only from annotation, extract cbs and convert to peptide and concert gff to bed
make_files() {

    progenitor=$1
    gff_file=$(find $in_dir/progenitor/$progenitor -name "*gff")
    fa_file=$(find $in_dir/progenitor/$progenitor -name "*fa")

    primary_iso_gff=${pep_dir}/.tmp_${progenitor}_primary.gff

    tmp_primary_iso_pep_fa=${pep_dir}/.tmp_${progenitor}.fa
    tmp_bed=${bed_dir}/.tmp_${progenitor}.bed

    primary_iso_pep_fa=${pep_dir}/${progenitor}.fa
    primary_iso_bed=${bed_dir}/${progenitor}.bed

    agat_sp_keep_longest_isoform.pl -gff $gff_file -o $primary_iso_gff

    agat_sp_extract_sequences.pl --gff $primary_iso_gff --fasta $fa_file -t cds -p -o $tmp_primary_iso_pep_fa

    agat_convert_sp_gff2bed.pl --gff $primary_iso_gff -o $tmp_bed
    
    echo "Renaming primary transcripts after gene name for ${progenitor}."
    
    awk -v peptide="${primary_iso_pep_fa}" -v bed="${primary_iso_bed}" '
        
        FNR==NR {

            if( $1 ~ /^>/ ){
                key = substr($1, 2);
                match($2, /^gene=(.*)$/, arr);
                value = arr[1];
                dict[key] = value;
                gene_name = ">" value;
                print gene_name >> peptide;
                next;
            } else {
                print $0 >> peptide;
            }
            next;
        }

        {

            if ($4 in dict) {
                $4 = dict[$4];
            }
            print $1 "\t" $2 "\t" $3 "\t" $4  >> bed;

        }' ${tmp_primary_iso_pep_fa} ${tmp_bed}

    echo "Finished renaming for ${progenitor}."
}


# export the function & variables
export -f make_files

# Make the files
ls ${in_dir}/progenitor | xargs -I {}  -P ${cores} bash -c 'make_files "{}"'

# Delete temporary files & move agat logs.
find ${out_dir} -name ".tmp*" | xargs rm 
find . -name "*.agat.log" | xargs -I {} cat {} >> ${log_file}
find . -name "*.agat.log" | xargs -I {} rm {}