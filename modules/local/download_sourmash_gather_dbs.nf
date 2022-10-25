process DOWNLOAD_SOURMASH_GATHER_DBS {
    tag "gatherdb"
    label 'process_single'

    conda (params.enable_conda ? "anaconda::wget=1.20.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wget:1.20.1' :
        'quay.io/biocontainers/wget:1.20.1' }"

    input:

    output:
    path '*.zip'       , emit: zips // GTDB database
    path '*.sig'       , emit: sig  // human siganture 
    path "versions.yml", emit: versions

    script: //
    """
    # download GTDB reps data base
    wget -O gtdb-rs207.genomic-reps.dna.k21.zip https://osf.io/f2wzc/download
    # download human signature
    wget -O GCF_000001405.39_GRCh38.p13_genomic.sig https://osf.io/fxup3/download
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version | grep '^GNU' | sed 's/GNU Wget //' | sed 's/ .*//')
    END_VERSIONS
    """
}
