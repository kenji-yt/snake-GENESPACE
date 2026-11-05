#########################################
## Let's make a reproducibility report ##
#########################################

input_dir=$1
n_cores=$2
envs_dir=$3
pipeline_version=$4
genespace_version=$5
report=results/snake_GENESPACE_reproducibility_report.txt
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

echo "snake-GENESPACE=${pipeline_version}" >> "${report}"

genespace_installed=$(Rscript -e 'cat(as.character(utils::packageVersion("GENESPACE")))')
echo "- GENESPACE=${genespace_installed} (GitHub jtlovell/GENESPACE@${genespace_version})" >> "${report}"

mcscanx_commit=$(git -C results/genespace/MCScanX rev-parse HEAD)
echo "- MCScanX=commit ${mcscanx_commit} (GitHub wyp1125/MCScanX)" >> "${report}"

# Pinned packages of the conda environment
purpose=$(sed -n 's/^# Used for: *//p' "${envs_dir}/genespace.yaml")
echo "- conda environment (${purpose:-genespace}):" >> "${report}"
sed -n '/^dependencies:/,$p' "${envs_dir}/genespace.yaml" | grep -E '^[[:space:]]*- ' | sed -E 's/^[[:space:]]*- */    - /; s/[[:space:]]*#.*$//' >> "${report}"

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
echo "" >> "${report}"
echo "" >> "${report}"
echo "***************" >> "${report}"
echo "* PERFORMANCE *" >> "${report}"
echo "***************" >> "${report}"
echo "" >> "${report}"
echo "" >> "${report}"
# Run time of the last snakemake call (start time written by the workflow's onstart handler)
if [ -f results/logs/run_start.txt ]; then
    run_seconds=$(( $(date +%s) - $(cat results/logs/run_start.txt) ))
    printf "Run time (last snakemake call, until this report): %d:%02d:%02d\n" $((run_seconds / 3600)) $((run_seconds % 3600 / 60)) $((run_seconds % 60)) >> "${report}"
    echo "" >> "${report}"
fi
# One row per rule, from the Snakemake benchmark files (results/benchmarks/<rule>/*.tsv).
# Wall and CPU times are summed over the rule's jobs (jobs can run in parallel, so they do not add up to the run time).
# Peak memory is the largest maximum resident set size of any job; '-' when not measured (jobs of a few seconds).
echo "Per rule: number of jobs, wall time (total and longest job), CPU time (total) and peak memory." >> "${report}"
printf "%-45s %5s %12s %12s %12s %14s\n" "rule" "jobs" "wall_total" "wall_max" "cpu_total" "peak_mem_MB" >> "${report}"
for bench_dir in results/benchmarks/*/; do
    [ -d "${bench_dir}" ] || continue
    awk -v rule="$(basename "${bench_dir}")" '
        function hms(x) { x = int(x + 0.5); return sprintf("%d:%02d:%02d", int(x / 3600), int((x % 3600) / 60), x % 60) }
        FNR == 1 { next }
        { n++; wall += $1; if ($1 > wall_max) wall_max = $1; if ($10 != "NA") cpu += $10; if ($3 != "NA" && $3 > mem) mem = $3 }
        END { printf "%-45s %5d %12s %12s %12s %14s\n", rule, n, hms(wall), hms(wall_max), hms(cpu), (mem > 0 ? sprintf("%.0f", mem) : "-") }
    ' "${bench_dir}"*.tsv >> "${report}"
done
