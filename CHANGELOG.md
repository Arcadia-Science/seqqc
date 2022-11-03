# Arcadia-Science/seqqc: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0dev - November 2022

Initial release of Arcadia-Science/seqqc, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- Local module to download sourmash GTDB database and human signature
- Workflow to run sourmash gather to detect routine contamination
- Workflow to run sourmash compare to determine sequence similarity between samples

### `Fixed`

### `Dependencies`

- `fastqc=0.11.9`
- `multiqc=1.13`
- `sourmash=4.5.0`
- `wget=1.20.1`

### `Deprecated`
