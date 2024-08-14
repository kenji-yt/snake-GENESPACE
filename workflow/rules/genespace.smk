
rule download_MCScanX:
    output:
        mc_scan_zip=f"{OUTPUT_DIR}/genespace/MCScanX/MCscanX.zip",
    log:
        f"{OUTPUT_DIR}/logs/genespace/MScanX_dowload.log",
    conda:
        "../../envs/genespace.yaml"
    shell:
        "wget https://github.com/wyp1125/MCScanX.git -O {output.mc_scan_zip}"
