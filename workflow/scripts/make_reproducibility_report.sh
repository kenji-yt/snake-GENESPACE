#########################################
## Let's make a reproducibility report ##
#########################################

input_dir=$1
n_cores=$2
report=results/reproducibility_report.txt
CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M:%S")

echo "******************" >> "${report}"
echo "* snake-GENESPACE *" >> "${report}"
echo "******************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
echo "Reproducibility report for snake-GENESPACE." >> "${report}"
echo "Run date & time: ${CURRENT_DATETIME}" >> "${report}"
echo "Number of allocated cores: ${n_cores}" >> "${report}" 
echo "" >> "${report}"
echo "" >> "${report}"
echo "********************" >> "${report}"
echo "* Operating System *" >> "${report}"
echo "********************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"

OS=$(uname -s)

if [ "$OS" == "Linux" ]; then
    # For Linux, try to get version from /etc/os-release
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "Operating System: $NAME" >> "${report}"
        echo "Version: $VERSION" >> "${report}"
    else
        echo "Linux OS (version unknown)" >> "${report}"
    fi
# Assume anything else is macOS
else
    echo "Operating System: macOS"  >> "${report}"
    sw_vers  >> "${report}"
fi

echo "" >> "${report}"
echo "" >> "${report}"
echo "**************" >> "${report}"
echo "* INPUT DATA *" >> "${report}"
echo "**************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"

# Loop through each file in the input directory
if [ "$OS" == "Linux" ]; then
    echo "Linux md5sum checksums for the input files" >> "${report}"
    for sub_input_dir in "${input_dir}"/*; do
        if [ -d "${sub_input_dir}" ]; then
            echo $(basename "${sub_input_dir}") >> "${report}"
            find "${sub_input_dir}" -maxdepth 1 -type f | \
            xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"   
            echo "" >> "${report}"
            echo "" >> "${report}"
        fi
    done
# Assume anything else is macOS
else
    echo "Mac md5 checksums for the input files" >> "${report}"
    for sub_input_dir in "${input_dir}"/*; do
        if [ -d "${sub_input_dir}" ]; then
            echo $(basename "${sub_input_dir}") >> "${report}"
            find "${sub_input_dir}" -maxdepth 1 -type f | \
            xargs -n${n_cores} md5 | awk '{print $2"\t"$4}' >> "${report}"
            echo "" >> "${report}"  
        fi
    done
fi

echo "" >> "${report}"
echo "" >> "${report}"
echo "*********" >> "${report}"
echo "* TOOLS *" >> "${report}"
echo "*********" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"

version_snake_genespace=$(git describe --tags --abbrev=0 | sed 's/v//g')
echo "snake-GENESPACE=${version_snake_genespace}" >> "${report}"

run_genespace_script="workflow/scripts/run_genespace.R"
genespace_version=$(grep "devtools::install" ${run_genespace_script} | sed 's/.*@v//g' | sed 's/",\ quiet.*//g')
echo "GENESPACE=${genespace_version}" >> "${report}"

MCScanX_exec="results/genespace/MCScanX/MCScanX"
birth_MCScanX=$(ls -l --full-time --time=birth ${MCScanX_exec} | awk '{print $6, $7}')
echo "MCScanX=No version, Created (or last modified) on ${birth_MCScanX}" >> "${report}"

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
if [ "$OS" == "Linux" ]; then
    echo "Linux md5sum checksums for the output files" >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/bed" -name "*.bed" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/peptide" -name "*.fa" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/results" -name "*.csv" | xargs -n${n_cores} md5sum | awk '{print $2"\t"$1}' >> "${report}"
else
    echo "Mac md5 checksums for the output files" >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/bed" -name "*.bed" | xargs -n${n_cores} md5 | awk '{print $2"\t"$4}' >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/peptide" -name "*.fa" | xargs -n${n_cores} md5 | awk '{print $2"\t"$4}' >> "${report}"
    echo "" >> "${report}"
    find "results/genespace/run_dir/results" -name "*.csv" | xargs -n${n_cores} md5 | awk '{print $2"\t"$4}' >> "${report}"
fi