# Arcadia-Science/seqqc cron launcher

This folder implements a simple cron job that triggers the [Arcadia-Science/seqqc](https://github.com/Arcadia-Science/seqqc) pipeline on a regular basis. As implemented, the cron job will run at 12.05AM UTC every day. The [job](./src/job.ts) is implemented in Typescript and is deployed via [GitHub actions](../.github/workflows/cron.yml).

## Motivation

At Arcadia Science, our scientists will be uploading new sequencing data to a private, Arcadia Science-only S3 bucket `arcadia-seqqc`. Each data set will be uploaded into a new folder under the `indir` directory. The folder should be named `<year>-<initials>-<descriptor>` where descriptor is an up to 10 character descriptor of your sequencing data (ie `s3://arcadia-seqqc/indir/2023-ter-timecheese`).

We want to be able to automatically process these files on a regular cadence and notify the scientists once the seqqc pipeline runs are complete. This cron job will check whether there is new data in `s3://arcadia-seqqc/indir`. If there is, the cron job will run the seqqc pipeline on the FASTQ files that are specified in the accompanying CSV files. The job determines whether a file is new or not based on the last modified date on the S3 bucket objects. This is slightly brittle, but should be good enough for our use case.

When the pipeline finishes, the output files will be available in `s3://arcadia-seqqc/outdir` and the scientists will be notified via email with the quality control report attached. This report contains inline documentation for how to interpret the results. The cron job will attempt to get the scientist's email using the S3 object owner metadata. If this information is not available, only the email specified by the `NOTIFICATION_EMAIL` environment variable is notified.

## Getting started

Create `.env` file with:

```
// .env
# AWS credential constants
AWS_BUCKET_NAME=arcadia-seqqc
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=us-west-1

# AWS bucket constants–these specify source and destination folders within the same bucket for the files
AWS_SOURCE_PREFIX=indir

# Notification constants - optional
NOTIFICATION_EMAIL=

# Tower constants, see https://help.tower.nf/21.10/pipeline-actions/pipeline-actions/
TOWER_URL=
TOWER_ACCESS_TOKEN=
```

Install packages using [npm](https://www.npmjs.com/) v8.19.2 and run using [node](https://nodejs.org/en/) v18.10.0.

```
npm install
```

Once the installation is complete, you can build the job with `npm run build` or `npm run watch`. To execute the job run `npm run runJob`.
