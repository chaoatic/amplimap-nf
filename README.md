# amplimap-nf
Pipeline for mapping amplicon reads to dna sequence database.
## Getting started
### Prerequisites
- [Nextflow](https://nf-co.re/docs/usage/installation)
- [Conda](https://docs.conda.io/projects/miniconda/en/latest/miniconda-install.html)
### Installation
```
git clone https://github.com/chaoatic/amplimap-nf.git
cd amplimap-nf
```
### Usage
```
Usage: nextflow run amplimap.nf [OPTION...]

Mandatory arguments:
    --data_dir      Path to sequences directory with sequences in fastq.gz format
    --db            Path to database file with sequences in fasta format
    --result_dir    Path to directory containing results

Optional arguments:
    --min_length    Minimum length (bp) for a read to be retained
                    [Default: 1]
    --max_length    Maximum length (bp) for a read to be retained
                    [Default: 2147483647]
    --min_qscore    Minimum average PHRED score for a read to be retained
                    [Default: 1]
    --threads       Number of parallel threads to use
                    [Default: 4]
```
## Overview of the pipeline
## Database
## Output
## Citations