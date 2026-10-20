[![Docker Build](https://github.com/bw2/manta/actions/workflows/docker.yml/badge.svg)](https://github.com/bw2/manta/actions/workflows/docker.yml)

### Manta fork based on the last GPLv3 release

This fork starts from [Illumina/manta](https://github.com/Illumina/manta) commit `75b5c38d` (2019-07-17), which is
v1.6.0 plus documentation fixes. It is the last commit before Illumina relicensed Manta from GPLv3 to the PolyForm
Strict license on 2025-10-10. Like the code it is based on, this fork is distributed under the GNU General Public
License v3 (see [LICENSE.txt](LICENSE.txt)).

Changes in this fork:

- 2026-10-19: added `docker/Dockerfile`, `docker/Makefile` and a GitHub Actions workflow
  (`.github/workflows/docker.yml`) that builds the `weisburd/manta` Docker image, runs Manta's demo against its
  expected results, and publishes the image to Docker Hub. The image also includes gcloud.
- 2026-10-19: alignment files (BAM or CRAM) can be read directly from `gs://`, `s3://`, `http(s)://` and `ftp://`
  URLs. The bundled htslib and samtools were upgraded from 1.9 to 1.21 and htslib is now built with libcurl, Google
  Cloud Storage and AWS S3 support. htslib 1.9 only signed S3 requests with AWS Signature Version 2, which buckets
  created in recent years don't accept, and had no support for requester-pays Google buckets. The reference FASTA
  and other inputs must still be local files.

### Reading alignment files from URLs

Pass the URL to `configManta.py` in place of a local path, for example `--bam gs://bucket/sample.cram`. The index
is looked up next to the alignment file (`sample.cram.crai`, or `sample.bam.bai` / `sample.bai`). htslib downloads it
into the directory that `runWorkflow.py` is started from, and reuses a file of the same name that is already there
without checking that it belongs to the same alignment file, so start each run from a directory without other
samples' index files. Credentials are read from the environment by htslib:

- `gs://`: `GCS_OAUTH_TOKEN` (for example `export GCS_OAUTH_TOKEN=$(gcloud auth print-access-token)`), plus
  `GCS_REQUESTER_PAYS_PROJECT` for requester-pays buckets. Access tokens expire after about an hour and htslib does not
  refresh them, so very long runs over `gs://` URLs can fail partway through. Public objects need no token.
- `s3://`: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`, or `~/.aws/credentials`
  (`AWS_PROFILE` selects a profile). Public objects need no credentials.


Manta Structural Variant Caller
===============================

Manta calls structural variants (SVs) and indels from mapped
paired-end sequencing reads. It is optimized for analysis of germline
variation in small sets of individuals and somatic variation in
tumor/normal sample pairs. Manta discovers, assembles and scores
large-scale SVs, medium-sized indels and large insertions within a
single efficient workflow. The method is designed for rapid analysis
on standard compute hardware: NA12878 at 50x genomic coverage is
analyzed in less than 20 minutes on a 20 core server, and most WGS
tumor/normal analyses can be completed within 2 hours. Manta combines
paired and split-read evidence during SV discovery and scoring to
improve accuracy, but does not require split-reads or successful
breakpoint assemblies to report a variant in cases where there is
strong evidence otherwise. It provides scoring models for germline
variants in small sets of diploid samples and somatic variants in
matched tumor/normal sample pairs. There is experimental support for
analysis of unmatched tumor samples as well. Manta accepts input read
mappings from BAM or CRAM files and reports all SV and indel inferences
in VCF 4.1 format. See the [user guide][UserGuide] for a full
description of capabilities and limitations.

[UserGuide]:docs/userGuide/README.md

Methods and benchmarking details are described in:

Chen, X. *et al.* (2016) Manta: rapid detection of structural variants and
indels for germline and cancer sequencing applications. *Bioinformatics*,
32, 1220-1222. [doi:10.1093/bioinformatics/btv710][bpaper]

...and the corresponding [open-access pre-print][preprint].

[bpaper]:https://doi.org/10.1093/bioinformatics/btv710
[preprint]:https://doi.org/10.1101/024232


License
-------

Manta source code is provided under the [GPLv3 license](LICENSE.txt).
Manta includes several third party packages provided under other
open source licenses, please see [COPYRIGHT.txt](COPYRIGHT.txt)
for additional details.


Getting Started
---------------

For linux users, it is recommended to start from the most recent
[binary distribution on the Manta releases page][releases], this
distribution can be unpacked, moved to any convenient directory and
tested by [running a small demo](docs/userGuide/installation.md#demo)
included with the release distribution. Manta can also be installed
and run on OS X. Please see the [installation instructions](docs/userGuide/installation.md)
for full build and installation details of all supported cases.

[releases]:https://github.com/Illumina/manta/releases


Data Analysis and Interpretation
--------------------------------

After completing installation, see the [Manta user guide][UserGuide]
for instructions on how to run Manta, interpret results and estimate
hardware requirements/compute cost, in addition to a high-level methods
overview.


Manta Code Development
----------------------

For manta code development and debugging details, see the
[Manta developer guide][DeveloperGuide]. This includes details
on Manta's developement protocols, special build instructions,
recommended workflows for investigating
calls, and internal documentation details.

[DeveloperGuide]:docs/developerGuide/README.md
