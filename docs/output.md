# Arcadia-Science/seqqc: Output

## Introduction

This document describes the output produced by the pipeline. 
Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. 
All paths are relative to the top-level results directory.

While each output may be useful, the primary output is the MultiQC html file, which contains visual summaries and explanation for every step in the pipeline.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [sourmash sketch](#sourmash-sketch) - Generates FracMinHash sketches from raw reads
- [sourmash compare](#sourmash-compare) - Compares samples to assess similarity
- [sourmash gather](#sourmash-gather) - Compares each sample against a database of common contaminants to see if any are present in the reads
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

![MultiQC - FastQC sequence counts plot](images/mqc_fastqc_counts.png)

![MultiQC - FastQC mean quality scores plot](images/mqc_fastqc_quality.png)

![MultiQC - FastQC adapter content plot](images/mqc_fastqc_adapter.png)

> **NB:** The FastQC plots displayed in the MultiQC report shows _untrimmed_ reads. They may contain adapter sequence and potentially regions with low quality.

### sourmash sketch

<details markdown="1">
<summary>Output files</summary>

- `sourmash/`
  - `*sig`: JSON file containing FracMinHash sketches and metadata.

[sourmash sketch](https://sourmash.readthedocs.io/en/latest/command-line.html#sourmash-sketch-make-sourmash-signatures-from-sequence-data) generates a sourmash signature that contains three FracMinHash sketches, one for each k-mer length 21, 31, and 51, as well as abundance information for each of the k-mers included in the sketch.
sourmash sketch uses a "scaled" value to determine which k-mers are included in the sketch.
This pipeline uses a scaled value of 1000, meaning approximately 1/1000th of all distinct k-mers in each raw read file is included in the final sketch.
Importantly, the same fraction of sequences are subsampled across different samples which allows accurate comparisons of overall sample similarity.
Each signature is a JSON file containing the sketches and associated metdata. 
For more information, see the [sourmash documentation](https://sourmash.readthedocs.io/en/latest/).

### sourmash compare

<details markdown="1">
<summary>Output files</summary>

- `sourmash/`
  - `comp.npy`: numpy array recording the square similarity matrix.   
  - `comp.npy.labels.txt`: labels (sample names) for the numpy array.
  - `comp.csv`: CSV of the square similarity matrix and sample names.

[sourmash compare](https://sourmash.readthedocs.io/en/latest/command-line.html#sourmash-compare-compare-many-signatures) compares sketches of the raw sequencing reads to estimate sample similarity.
Sourmash compare uses angular similarity which takes abundance information into account when estimating sample similarity.
The output is a square matrix where each entry *[i, j]* contains the estimated angular similarity between sample *i* and sample *j*. 
Values range between 0 and 1, where 0 means there is no overlap between two samples and 1 means there is perfect overlap.
For more information, see the [sourmash documentation](https://sourmash.readthedocs.io/en/latest/).

### sourmash gather

<details markdown="1">
<summary>Output files</summary>

- `sourmash/`
  - `*csv`: a CSV file recording the fraction of overlap between the sample and a database.

[sourmash gather](https://sourmash.readthedocs.io/en/latest/command-line.html#sourmash-gather-find-metagenome-members) selects the best reference genomes to use for a metagenome analysis, by finding the smallest set of non-overlapping matches to the query in a database.
This pipeline uses a database of over 4000 genomes from common laboratory, kit, or sequencer contaminants to assess whether the raw reads are contaminated. 
For more information on how sourmash gather works, see the [sourmash documentation](https://sourmash.readthedocs.io/en/latest/).

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from FastQC and sourmash. 
The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. 
For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
