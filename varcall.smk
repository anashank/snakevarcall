#Variant calling pipeline

#To be run after sorting, indexing BAM files

import os,sys

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
        expand("snp_filtered/{sample}_snp.filtered.vcf", sample=samples),expand("indel_filtered/{sample}_indel.filtered.vcf",sample=samples)


rule pileup:
   input:
       "sorted/{sample}.sorted.bam"
   output:
       "pileup/{sample}.pileup"
   log:
       pileup = "log/{sample}.pileuplog"
   shell:
      "samtools mpileup -B -f {config[chr_path]} {input} -o {output} &> {log.pileup}"


rule snp_indel:
   input:
       "pileup/{sample}.pileup"
   output:
       "snp/{sample}_snp.vcf","indel/{sample}_indel.vcf"
   shell:
      '''
      java -jar VarScan.v2.4.3.jar mpileup2snp {input} --min-reads2 5 --p-value 0.01 --output-vcf 1 > {output[0]} 
      java -jar VarScan.v2.4.3.jar mpileup2indel {input} --min-reads2 5 --p-value 0.01 --output-vcf 1 > {output[1]}
      '''

rule vcf_var:
   input:
       "snp/{sample}_snp.vcf","indel/{sample}_indel.vcf"
   output:
       "snp_var/{sample}_snp.var","indel_var/{sample}_indel.var"
   shell:
      '''
      awk \'BEGIN {{OFS=\"\\t\"}} {{if (!/^#/) {{ isDel=(length($4) > length($5)) ? 1 : 0; print $1,($2+isDel),($2+isDel); }}}}\' {input[0]} > {output[0]};
      awk \'BEGIN {{OFS=\"\t\"}} {{if (!/^#/) {{ isDel=(length($4) > length($5)) ? 1 : 0; print $1,($2+isDel),($2+isDel); }}}}\' {input[1]} > {output[1]};
      '''

rule vcf_readcount:
   input:
       "snp_var/{sample}_snp.var","indel_var/{sample}_indel.var"
   output:
       "snp_readcount/{sample}_snp.readcount","snp_indel/{sample}_indel.readcount"
   params:
      p1="sorted/{sample}.sorted.bam"
   shell:
      '''
      build/bin/bam-readcount -q 10 -b 20 -w 1 -l {input[0]} -f ./chr11.fa {params.p1} > {output[0]}
      build/bin/bam-readcount -q 10 -b 20 -w 1 -l {input[1]} -f ./chr11.fa {params.p1} > {output[1]}
      '''

rule vcf_filter:
   input:
       "snp_readcount/{sample}_snp.readcount","snp_indel/{sample}_indel.readcount"
   output:
       "snp_filtered/{sample}_snp.filtered.vcf","indel_filtered/{sample}_indel.filtered.vcf"
   log:
      snpfilter="log/{sample}_snpfilter.log",
      indelfilter="log/{sample}_indelfilter.log"
   params:
      p1="snp/{sample}_snp.vcf",
      p2="indel/{sample}_indel.vcf"
   shell:
      '''
      java -jar VarScan.v2.4.3.jar fpfilter {params.p1} {input[0]} --min-ref-avgrl 50 --min-var-avgrl 50 --output-file {output[0]} &> {log.snpfilter}
      java -jar VarScan.v2.4.3.jar fpfilter {params.p2} {input[1]} --min-ref-avgrl 50 --min-var-avgrl 50 --output-file {output[1]} &> {log.indelfilter}
      '''


 


 








