process DOWNLOAD_SOURMASH_GATHER_DBS {
    tag "gatherdb"
    label 'process_single'

    conda "conda-forge::wget=1.20.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wget:1.20.3' :
        'quay.io/biocontainers/wget:1.20.3' }"

    input:

    output:
    path '*.zip'       , emit: zips // contam db
    path "versions.yml", emit: versions

    script: //
    """
    # download contam db built by Arcadia-Science/seqqc-build-contam-db
    wget -O contamdb.dna.k21.zip https://osf.io/ma8cf/download

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version | grep '^GNU' | sed 's/GNU Wget //' | sed 's/ .*//')
    END_VERSIONS
    """
}
