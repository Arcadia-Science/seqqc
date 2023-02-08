# Arcadia-Science/seqqc: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0 - February 2023

Initial release of Arcadia-Science/seqqc, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Local module to download sourmash GTDB database and human signature
- Workflow to run sourmash gather to detect routine contamination
- Workflow to run sourmash compare to determine sequence similarity between samples
- Integration of sourmash outputs into the MultiQC outputs (when run with docker profile only)
- Conda, Docker, and Singularity integration
- Documentation for the pipeline
- MultiQC interpretation documentation
- Test profiles for different sequencing chemistries
- Updates to email template
- Added the cron job that automatically triggers the pipeline runs

### `Fixed`

### `Dependencies`

- `fastqc=0.11.9`
- `multiqc=1.14` # currently installed from a [dev branch](https://github.com/taylorreiter/MultiQC/tree/47808aea9b05305e82927ba51f8e266ca0b919c6)
- `sourmash=4.6.1`
- `gnu-wget=1.18`

### `Deprecated`
