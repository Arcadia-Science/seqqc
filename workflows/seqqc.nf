/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowSeqqc.initialise(params, log)

// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'

//
// MODULE: Local modules
//
include { DOWNLOAD_SOURMASH_GATHER_DBS } from '../modules/local/download_sourmash_gather_dbs'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                       } from '../modules/nf-core/fastqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS  } from '../modules/nf-core/custom/dumpsoftwareversions/main'

//
// MODULE: Modified from nf-core/modules
include { SOURMASH_SKETCH              } from '../modules/local/nf-core-modified/sourmash/sketch/main'
include { SOURMASH_COMPARE             } from '../modules/local/nf-core-modified/sourmash/compare/main'
include { SOURMASH_GATHER              } from '../modules/local/nf-core-modified/sourmash/gather/main'
include { MULTIQC                      } from '../modules/local/nf-core-modified/multiqc/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow SEQQC {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //
    // MODULE: Run FastQC
    //
    FASTQC (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: sourmash sketch
    //
    SOURMASH_SKETCH (
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(SOURMASH_SKETCH.out.versions)

    //
    // MODULE: download sourmash gather databases
    //
    DOWNLOAD_SOURMASH_GATHER_DBS ()
    ch_versions = ch_versions.mix(DOWNLOAD_SOURMASH_GATHER_DBS.out.versions)

    //
    // MODULE: sourmash gather
    //
    SOURMASH_GATHER (
        SOURMASH_SKETCH.out.signatures,
        DOWNLOAD_SOURMASH_GATHER_DBS.out.zips,
        [], // val save_unassigned
        [], // val save_matches_sig
        [], // val save_prefetch
        []  // val save_prefetch_csv
    )
    ch_versions = ch_versions.mix(SOURMASH_GATHER.out.versions)

    //
    // MODULE: sourmash compare
    //

    // the sourmash compare module takes a meta map so that different groups can be specified
    ch_sketch_for_compare = SOURMASH_SKETCH.out.signatures
        .collect{ it[1] }
        .map {
            signatures ->
                def meta = [:]
                meta.id  = "k21"
                [ meta, signatures ]
    }

    SOURMASH_COMPARE (
        ch_sketch_for_compare,
        [],   // path to file list for --from-file
        true, // save_numpy_matrix
        true  // save_csv
    )

    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowSeqqc.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowSeqqc.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SOURMASH_GATHER.out.result.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files = ch_multiqc_files.mix(SOURMASH_COMPARE.out.matrix.collect{it[1, 2]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.collect().ifEmpty([]),
        ch_multiqc_custom_config.collect().ifEmpty([]),
        ch_multiqc_logo.collect().ifEmpty([])
    )
    multiqc_report = MULTIQC.out.report.toList()
    ch_versions    = ch_versions.mix(MULTIQC.out.versions)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        def email_params = NfcoreTemplate.get_email_params(workflow, params, summary_params, projectDir, log, multiqc_report)

        // Note: this is a mild hack, because sendMail does not work with S3 URIs.
        // First, we attempt to send our email regularly. If email_params.mqcFile is
        // a local file path (ie you're running this pipeline on an HPC or locally),
        // this will succeed. If it refers to an S3 object, this would fail.
        // When it fails, we can forgo the main body of the email (mostly pipeline metadata)
        // and try make MultiQC HTML (which already has some of the metadata), the
        // body of our email.

        try {
            // Send email using Nextflow's built-in emailer:
            // https://www.nextflow.io/docs/latest/mail.html#advanced-mail
            sendMail (
                to: email_params.to,
                subject: email_params.subject,
                body: email_params.email_html,
                attach: email_params.mqcFile
            )
        } catch (Exception e) {
            sendMail (
                to: email_params.to,
                subject: email_params.subject,
                body: email_params.mqcFile.text
            )
        }
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.adaptivecard(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
