#########################################
## Let's make a reproducibility report ##
#########################################

input_dir=$1
n_cores=$2
report=results/snake-GENESPACE-reproducibility_report.txt
CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "******************" >> "${report}"
echo "* snake-GENESPACE *" >> "${report}"
echo "******************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
echo "Reproducibility report for snake-GENESPACE." >> "${report}"
echo "Run date & time: ${CURRENT_DATETIME}" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
echo "**************" >> "${report}"
echo "* INPUT DATA *" >> "${report}"
echo "**************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"

# Loop through each file in the input directory
for sub_input_dir in "${input_dir}"/*; do
    if [ -d "${sub_input_dir}" ]; then
        echo $(basename "${sub_input_dir}") >> "${report}"
        find "${sub_input_dir}" -maxdepth 1 -type f | \
        xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"   
    echo "" >> "${report}"
    echo "" >> "${report}"
    fi
done

echo "" >> "${report}"
echo "" >> "${report}"
echo "*********" >> "${report}"
echo "* TOOLS *" >> "${report}"
echo "*********" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"

environment="workflow/envs/genespace.yaml"
append_lines=false

# Read the input file line by line
while IFS= read -r line; do
    if [ "$append_lines" = true ]; then
        if [[ "$line" =~ ^[[:space:]]*- ]]; then
            # Strip the leading '- ' and write to the output file
            echo "${line:4}" >> "$report"
        else
            break
        fi
    fi

    if [[ "$line" =~ ^dependencies: ]]; then
        append_lines=true
    fi
done < "$environment"

echo "" >> "${report}"
echo "" >> "${report}"
echo "****************" >> "${report}"
echo "* OUTPUT FILES *" >> "${report}"
echo "****************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
find "results/genespace/run_dir/bed" -name "*.bed" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
echo "" >> "${report}"
find "results/genespace/run_dir/peptide" -name "*.fa" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
echo "" >> "${report}"
find "results/genespace/run_dir/results" -name "*.csv" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
