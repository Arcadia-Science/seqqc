# Arcadia-Science/seqqc: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0dev - December 2022

Initial release of Arcadia-Science/seqqc, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Local module to download sourmash GTDB database and human signature
- Workflow to run sourmash gather to detect routine contamination
- Workflow to run sourmash compare to determine sequence similarity between samples
- Integration of sourmash outputs into the MultiQC outputs
- Documentation for the pipeline

### `Fixed`

### `Dependencies`

- `fastqc=0.11.9`
- `multiqc=1.13` # currently installed from a dev branch, https://github.com/taylorreiter/MultiQC/tree/ter/add-sourmash-gather commit 47808ae
- `sourmash=4.5.0`
- `wget=1.20.1`

### `Deprecated`
