#----------------------------------------------#
#----------------------------------------------#
#---------------- Parse the flags -------------#
#----------------------------------------------#
#----------------------------------------------#

# Default values
in_dir=""
out_dir=""
log_dir=""
cores=""


# Usage example
function print_usage() {
    echo "Usage: $0 -i <input_directory> -o <genespace_input_directory> -l <log_dir> -c <cores>" 
}

# Parse command line options using getopts 
while getopts "i:o:l:c:" flag; do
    case "$flag" in
        i)
            in_dir="$OPTARG" ;;
        o)
            out_dir="$OPTARG" ;;
        l)
            log_dir="$OPTARG" ;;
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
if test -z "$log_dir"; then
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
export log_dir=$log_dir
export in_dir=$in_dir
export out_dir=$out_dir
export bed_dir=$bed_dir
export pep_dir=$pep_dir

agat_log_dir=${log_dir}/agat_logs/

normal_exit=false

# Function to delete tmp files after premature interuption
cleanup() {
    find . -maxdepth 1 -name "*.agat.log" | xargs -I {} mv {} ${agat_log_dir}
    if [ -f ${no_input_progenitors} ]; then
        echo "An error occured due to wrong input data. Exiting..."
        find $out_dir -name ".tmp*" | xargs --no-run-if-empty rm
        exit 1 
    elif [ -f ${no_output_progenitors} ]; then
        echo "An error occured during parsing. Check parsing logs. Exiting..."
        find $out_dir -name ".tmp*" | xargs --no-run-if-empty rm
        exit 1      
    else
        echo "Parsing completed successfully."
        find $out_dir -name ".tmp*" | xargs --no-run-if-empty rm
        exit 0    
    fi
}

# Trap the script interruption (SIGINT) and execute the cleanup function
trap cleanup EXIT


#----------------------------------------------#
#----------------------------------------------#
#------- Make GENESPACE input directory -------#
#----------------------------------------------#
#----------------------------------------------#

mkdir -p ${bed_dir} ${pep_dir} ${agat_log_dir}

# Function to keep primary isoform only from annotation, extract cbs and convert to peptide and convert gff to bed. 
# Then also rename primary isoform bed and peptide fasta to have same name. 
create_files() {

    progenitor=$1
    gff_file=$(find $in_dir/$progenitor \( -name "*.gff" -o -name "*.gff3" \))
    fa_file=$(find $in_dir/$progenitor \( -name "*.fa" -o -name "*.fasta" -o -name "*.fq" -o -name "*.fna" -o -name "fastq" \))

    if [ -z "$gff_file" ]; then
        echo "ERROR: No GFF file found for ${progenitor}. Exiting."
        echo "- ${progenitor}: No gff input file" >> $no_input_progenitors
        exit 1
    fi
    if [ -z "$fa_file" ]; then
        echo "ERROR: No FASTA file found for ${progenitor}. Exiting."
        echo "- ${progenitor}: No fasta input file" >> $no_input_progenitors
        exit 1
    fi
    if [ "$(echo "$gff_file" | wc -l)" -gt 1 ]; then
        echo "ERROR: More than one gff file for ${progenitor}. Exiting."
        echo "- ${progenitor}: More than one gff input file" >> $no_input_progenitors
        exit 1
    fi
    if [  "$(echo "$fa_file" | wc -l)" -gt 1 ]; then
        echo "ERROR: More than one fasta file for ${progenitor}. Exiting."
        echo "- ${progenitor}: More than one fasta input file" >> $no_input_progenitors
        exit 1
    fi
    
    # To avoid https://github.com/NBISweden/AGAT/issues/56
    max_line_len=$(wc -L ${fa_file} | awk '{print $1}') 

    if [ "${max_line_len}" -gt 65536 ]; then
    
        fasta_formatter -i $fa_file -w 60 > ${pep_dir}/.tmp_multi_line_${progenitor}.fa
        fa_file=${pep_dir}/.tmp_multi_line_${progenitor}.fa

    fi

    primary_iso_gff=${pep_dir}/.tmp_${progenitor}_primary.gff

    tmp_primary_iso_pep_fa=${pep_dir}/.tmp_${progenitor}.fa
    tmp_bed=${bed_dir}/.tmp_${progenitor}.bed

    primary_iso_pep_fa=${pep_dir}/${progenitor}.fa
    primary_iso_bed=${bed_dir}/${progenitor}.bed
    
    agat_sp_keep_longest_isoform.pl -gff $gff_file -o $primary_iso_gff 2> /dev/null

    agat_sp_extract_sequences.pl --gff $primary_iso_gff --fasta $fa_file -t cds -p -o $tmp_primary_iso_pep_fa 2> /dev/null

    agat_convert_sp_gff2bed.pl --gff $primary_iso_gff -o $tmp_bed 2> /dev/null
    
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
                print $1 "\t" $2 "\t" $3 "\t" $4  >> bed;
            }

        }' ${tmp_primary_iso_pep_fa} ${tmp_bed}

    if [ ! -f "${primary_iso_pep_fa}" ]; then
        echo "ERROR: peptide file for ${progenitor} was not created. Check agat logs."
        echo "- ${progenitor}: No peptide fasta file produced" >> $no_output_progenitors
        exit 1
    elif [ ! -f "${primary_iso_bed}" ]; then
        echo "ERROR: bed file for ${progenitor} was not created. Check agat logs."
        echo "- ${progenitor}: No bed file produced" >> $no_output_progenitors
        exit 1
    fi
    
    # ":" is not allowed in gene names by genespace. 
    sed -i 's/:/_/g' ${primary_iso_pep_fa}
    sed -i 's/:/_/g' ${primary_iso_bed}
    
    echo "Finished renaming for ${progenitor}."

}


# If bed and peptide file already present it copies them to the output directory.
move_input_files(){

    directory=$1 
    
    if [ "${directory}" == "bed" ]; then

        cp ${in_dir}/${directory}/* ${bed_dir}/

    elif [ "${directory}" == "peptide" ]; then

        cp ${in_dir}/${directory}/* ${pep_dir}/

    fi

}

# export the function & variables
export -f create_files
export -f move_input_files

no_input_progenitors=.tmp_missing_input_progenitors
no_output_progenitors=.tmp_missing_output_progenitors 
ls ${in_dir} | grep -v -E 'bed|peptide'| xargs -I {}  -P ${cores} bash -ec 'create_files "{}" 2>&1 | tee ${log_dir}/"{}".log'
if [ -f ${no_input_progenitors} ]; then
    echo "ERROR: The following progenitors had erroneous input data:"
    cat ${no_input_progenitors}
    exit 1
fi
if [ -f ${no_output_progenitors} ]; then
    echo "ERROR: The following progenitors had erroneous output data:"
    cat ${no_output_progenitors}
    exit 1
fi
ls ${in_dir} | grep -E 'bed|peptide'| xargs -I {}  -P ${cores} bash -c 'move_input_files "{}"'


normal_exit=true