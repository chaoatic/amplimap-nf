#! /usr/bin/env nextflow

// Declare help message
def helpMessage() {
    log.info """
        Usage:
        nextflow run amplimap.nf [OPTION...]

        Mandatory arguments:
          -profile          Configuration profile to use. [Available: conda, docker]
          --data_dir        Path to sequences directory with sequences in fastq.gz format
          --db              Path to database file with sequences in fasta format
          --result_dir      Path to directory containing results
        
        Optional arguments:
          --min_length      Minimum length (bp) for a read to be retained
                            [Default: 1]
          --max_length      Maximum length (bp) for a read to be retained
                            [Default: 2147483647]
          --min_qscore      Minimum average PHRED score for a read to be retained
                            [Default: 1]
          --threads         Number of parallel threads to use
                            [Default: 4]
        """
        .stripIndent(true)
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

// Concatenate raw read sequences 
process concatenateFastq {
    publishDir "${params.result_dir}/sequence", mode: "copy"

    input:
    path data_dir

    output:
    path "${data_dir}.fastq.gz"

    script:
    """
    cat ${data_dir}/* > ${data_dir}.fastq.gz
    """
}

// Visualization of raw read sequences
process rawSequenceVisualization {
    publishDir "${params.result_dir}/visualization/${concatenate_fastq.simpleName}", mode: "copy"

    input:
    path concatenate_fastq

    output:
    path "*"

    script:
    """
    NanoPlot --threads ${params.threads} --no_static --fastq ${concatenate_fastq}
    """
}

// Filter raw read sequences
process filterFastq {
    publishDir "${params.result_dir}/sequence", mode: "copy"

    input:
    path concatenate_fastq

    output:
    path "${concatenate_fastq.simpleName}_filter.fastq.gz"

    script:
    """
    gunzip -c ${concatenate_fastq} | \
    chopper \
        --minlength ${params.min_length} \
        --maxlength ${params.max_length} \
        --quality ${params.min_qscore} \
        --threads ${params.threads} |\
    gzip > ${concatenate_fastq.simpleName}_filter.fastq.gz
    """
}

// Visualization of filter read sequences
process filterSequenceVisualization {
    publishDir "${params.result_dir}/visualization/${filter_fastq.simpleName}", mode: "copy"

    input:
    path filter_fastq

    output:
    path "*"

    script:
    """
    NanoPlot --threads ${params.threads} --no_static --fastq ${filter_fastq}
    """
}

// Align filter reads to a reference database with minimap2
process alignReadToReference {
    publishDir "${params.result_dir}/alignment", mode: "copy"

    input:
    path filter_fastq

    output:
    path "${filter_fastq.simpleName}.bam"

    script:
    """
    minimap2 -ax map-ont ${params.db} ${filter_fastq} > map.sam

    samtools view -F 2048 -bo filter.bam map.sam

    samtools sort -o ${filter_fastq.simpleName}.bam filter.bam
    """
}

// Generate raw and filter sequences reports in tsv format
process generateSequenceReport {
    publishDir "${params.result_dir}/report", mode: "copy"
    input:
    path concatenate_fastq
    path filter_fastq

    output:
    path "${concatenate_fastq.simpleName}.tsv"
    path "${filter_fastq.simpleName}.tsv"

    script:
    """
    seqkit stats -a --threads ${params.threads} ${concatenate_fastq} > ${concatenate_fastq.simpleName}.tsv
    seqkit stats -a --threads ${params.threads} ${filter_fastq} > ${filter_fastq.simpleName}.tsv
    """
}

// Generate coverage reports in tsv format
process generateCoverageReport {
    publishDir "${params.result_dir}/report", mode: "copy"

    input:
    path alignment_bam

    output:
    path "${alignment_bam.simpleName}_coverage.tsv"

    script:
    """
    samtools coverage -o coverage.tsv ${alignment_bam}
    (head -n 1 coverage.tsv && tail -n +2 coverage.tsv | sort -n -r -t\$'\t' -k 4 | awk '\$4!=0' -) > ${alignment_bam.simpleName}_coverage.tsv
    """
}

workflow {
    Channel
        .fromPath("${params.data_dir}/*", type: 'dir', checkIfExists: true)
        .set { input_ch }
    concatenateFastq(input_ch)
    rawSequenceVisualization(concatenateFastq.out)
    filterFastq(concatenateFastq.out)
    filterSequenceVisualization(filterFastq.out)
    alignReadToReference(filterFastq.out)
    generateSequenceReport(concatenateFastq.out, filterFastq.out)
    generateCoverageReport(alignReadToReference.out)
}