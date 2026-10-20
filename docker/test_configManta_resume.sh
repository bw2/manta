#!/usr/bin/env bash

# Tests configManta.py --resume inside the weisburd/manta image, using Manta's demo data and expected results.
# Run with:  docker run --rm -v "$PWD/docker:/tests" weisburd/manta:latest bash /tests/test_configManta_resume.sh
#
#  1. --resume on a run directory that doesn't exist yet configures it as usual
#  2. a run interrupted with SIGINT, then continued by rerunning the same configManta.py --resume command and
#     runWorkflow.py, gives the demo's expected results
#  3. rerunning the same configManta.py --resume command leaves the configured run directory unchanged
#  4. without --resume, configuring an existing run directory still fails, as in upstream Manta
#  5. --resume with a changed option fails and names the changed option

set -euo pipefail

demo_dir=/opt/manta/share/demo/manta
run_dir=/tmp/resume_test

configure_demo() {
  configManta.py \
    --normalBam="$demo_dir/data/HCC1954.NORMAL.30x.compare.COST16011_region.bam" \
    --tumorBam="$demo_dir/data/G15512.HCC1954.1.COST16011_region.bam" \
    --referenceFasta="$demo_dir/data/Homo_sapiens_assembly19.COST16011_region.fa" \
    --region=8:107652000-107655000 \
    --region=11:94974000-94989000 \
    --exome \
    --runDir="$run_dir" \
    "$@"
}

fail() {
  echo "FAILED: $1"
  exit 1
}

# 1.
configure_demo --resume > /dev/null || fail "--resume did not configure a new run directory"
[ -f "$run_dir/runWorkflow.py" ] || fail "--resume did not create runWorkflow.py"
echo "PASSED: --resume configures a new run directory"

# 2. Interrupt the workflow about 1 second in (it takes a few seconds in total). If it happens to finish first,
# the rerun below is a no-op and the check still applies.
timeout -s INT 1 python2 "$run_dir/runWorkflow.py" -j 1 > /dev/null 2>&1 || true
configure_demo --resume > /dev/null || fail "--resume with the same options failed after an interrupted run"
python2 "$run_dir/runWorkflow.py" -j 1 > /dev/null 2>&1 || fail "rerunning runWorkflow.py after an interruption failed"
for expected_vcf in "$demo_dir"/expectedResults/*.vcf.gz ; do
  diff <(zcat "$expected_vcf" | grep -v -E '^##(fileDate|source|startTime|reference|cmdline)') \
       <(zcat "$run_dir/results/variants/$(basename "$expected_vcf")" | grep -v -E '^##(fileDate|source|startTime|reference|cmdline)') \
    || fail "results of the resumed run differ from $expected_vcf"
done
echo "PASSED: an interrupted run continued with --resume matches the demo's expected results"

# 3.
before=$(md5sum "$run_dir/runWorkflow.py" "$run_dir/runWorkflow.py.config.pickle")
output=$(configure_demo --resume) || fail "--resume with the same options failed"
echo "$output" | grep -q "left unchanged" || fail "--resume with the same options did not report the run directory as unchanged"
[ "$before" = "$(md5sum "$run_dir/runWorkflow.py" "$run_dir/runWorkflow.py.config.pickle")" ] \
  || fail "--resume with the same options rewrote the run directory"
echo "PASSED: --resume with the same options leaves the run directory unchanged"

# 4.
if configure_demo > /dev/null 2>&1 ; then fail "configuring an existing run directory without --resume succeeded" ; fi
echo "PASSED: configuring an existing run directory without --resume fails"

# 5.
if output=$(configure_demo --resume --scanSizeMb 10 2>&1) ; then fail "--resume with a changed option succeeded" ; fi
echo "$output" | grep -q "scanSizeMb: 12 (earlier run) vs. 10 (this command)" \
  || fail "--resume with a changed option did not name the change. Output was: $output"
echo "PASSED: --resume with a changed option fails and names the change"
