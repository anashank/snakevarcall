#Snakemake script to sort and index BAM files
import os,sys

#Replace < > with appropriate paths/folder names


path = "<path to BAM files folder>"
dirs = os.listdir(path)

samples = []
for file in dirs:
	if file.endswith('.bam'):
		name = file.strip().split('.')
		samples.append(name[0])


configfile: "config.yaml"



rule all:
    input:
        expand("sorted/{sample}.sorted.bam.bai", sample=samples)


#Sort bam files
rule sort_bam:
   input:
       "<BAM files folder>/{sample}.bam"
   output:
       "sorted/{sample}.sorted.bam"
   log:
       sort = "log/{sample}.sort"
   shell:
   		"samtools sort {config[sort_params]} -o {output} {input} &> {log.sort}"

#Index bam files
rule index_bam:
    input:  
        "sorted/{sample}.sorted.bam"
    output: 
        "sorted/{sample}.sorted.bam.bai"
    log:    
        index = "log/{sample}.index_bam"
    shell:
        "samtools index {input} &> {log.index}"