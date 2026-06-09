rule fastq_dump:    
    output: 
        output_dir + "SRA/{sample}_1.fastq.gz",
        output_dir + "SRA/{sample}_2.fastq.gz"
    threads: THREADS
    conda:
        "../env/sra-tools.yaml"
    params:
        sra=lambda wildcards: config["samples"][wildcards.sample],
        output_dir=output_dir
    shell:
        """
        fasterq-dump --split-3 -e {threads} -O {params.output_dir}/SRA {params.sra}
        gzip {params.output_dir}/SRA/{params.sra}_1.fastq
        gzip {params.output_dir}/SRA/{params.sra}_2.fastq
        mv {params.output_dir}/SRA/{params.sra}_1.fastq.gz {params.output_dir}/SRA/{wildcards.sample}_1.fastq.gz
        mv {params.output_dir}/SRA/{params.sra}_2.fastq.gz {params.output_dir}/SRA/{wildcards.sample}_2.fastq.gz
        """

rule fastqc:
    input:
        fastq=expand([output_dir + "SRA/{sample}_1.fastq.gz",
        output_dir + "SRA/{sample}_2.fastq.gz"], sample=config["samples"])
    output:
        zip = expand([output_dir + "SRA_fastqc/{sample}_1_fastqc.zip",
         output_dir + "SRA_fastqc/{sample}_2_fastqc.zip"], sample=config["samples"]),
        html = expand([output_dir + "SRA_fastqc/{sample}_1_fastqc.html",
         output_dir + "SRA_fastqc/{sample}_2_fastqc.html"], sample=config["samples"])
    conda:
        "../env/fastqc.yaml"
    params:
        output_dir=output_dir
    shell:
        "fastqc -t 12 -o {params.output_dir}/SRA_fastqc -f fastq {input.fastq}"

rule multiqc:
    input:
        zip = expand([output_dir + "SRA_fastqc/{sample}_1_fastqc.zip",
    output_dir +"SRA_fastqc/{sample}_2_fastqc.zip"], sample=config["samples"])
    output:
        output_dir + "multiqc_report.html"
    conda:
        "../env/multiqc.yaml"
    params:
        output_dir=output_dir
    shell:
        "multiqc {input.zip} -o {params.output_dir}"
