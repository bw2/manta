# External packages

This directory contains external packages for building manta.

## Package modification notes

### boost

To reduce size, certain files have been removed from the
full boost source distribution acccording to:

    ${ROOT_PATH}/scratch/make_boost_subset.bash

### htslib/samtools

htslib-1.21.tar.bz2 and samtools-1.21.tar.bz2 are the unmodified release tarballs from
https://github.com/samtools/htslib/releases/tag/1.21 and https://github.com/samtools/samtools/releases/tag/1.21
(sha256 84b510e735f4963641f26fd88c8abdee81ff4cb62168310ae716636aac0f1823 and
05724b083a6b6f0305fcae5243a056cc36cf826309c3cb9347a6b89ee3fc5ada). They replaced the size-reduced
htslib/samtools 1.9 tarballs in this fork so that htslib can read gs:// and s3:// URLs: htslib 1.9 has no
Google Cloud Storage requester-pays support and only signs S3 requests with AWS Signature Version 2. The copy
of htslib inside the samtools tarball is not used; samtools is built against the htslib 1.21 above.

### cmake-modules

cmake-modules-c99fd3 modified to show git describe --dirty

