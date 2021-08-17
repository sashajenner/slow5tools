#!/bin/bash
# Run f2s with different file, input and output formats.
Usage="f2s_output_test.sh"

# Relative path to "slow5/tests/"
REL_PATH="$(dirname $0)/" 

NC='\033[0m' # No Color
RED='\033[0;31m'
GREEN='\033[0;32m'

# terminate script
die() {
    echo -e "${RED}$1${NC}" >&2
    echo
    exit 1
}

OUTPUT_DIR="$REL_PATH/data/out/f2s_output"
test -d  $OUTPUT_DIR && rm -r "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR" || die "Creating $OUTPUT_DIR failed"

FAST5_DIR=$REL_PATH/data/raw/f2s_output
EXP_SLOW5_DIR=$REL_PATH/data/exp/f2s_output
SLOW5_EXEC_WITHOUT_VALGRIND=$REL_PATH/../slow5tools

if [ "$1" = 'mem' ]; then
    SLOW5_EXEC="valgrind --leak-check=full --error-exitcode=1 $SLOW5_EXEC_WITHOUT_VALGRIND"
else
    SLOW5_EXEC=$SLOW5_EXEC_WITHOUT_VALGRIND
fi

echo "-------------------slow5tools version-------------------"
$SLOW5_EXEC --version || die "slow5tools version failed"
echo

TESTCASE_NO=1
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:file process:single_process output:stdout-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5/sss1.fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single-fast5 input:file process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=2
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:file process:single_process output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5/sss1.fast5 -d $OUTPUT_DIR/single-fast5-output --iop 1 --to slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/0.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single-fast5 input:file process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=3
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:directory process:single_process output:stdout-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/directory_single-fast5.slow5 $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "ERROR: diff failed for 'f2s format:single-fast5 input:directory process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/single-fast5-output/*
TESTCASE_NO=4
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:directory process:single_process output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5 -d $OUTPUT_DIR/single-fast5-output --iop 1 --to slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/directory_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/0.slow5 2>/dev/null || die "ERROR: diff failed for 'f2s format:single-fast5 input:directory process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=5
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:file process:single_process output:stdout-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5/ssm1.fast5 --iop 1 --to slow5>$OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/file_multi-fast5.slow5 $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=6
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:file process:single_process output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5/ssm1.fast5 --iop 1 --to slow5 -d $OUTPUT_DIR/multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/file_multi-fast5.slow5 $OUTPUT_DIR/multi-fast5/ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=7
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:directory process:single_process output:stdout-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5 --iop 1 --to slow5>$OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/directory_multi-fast5.slow5 $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:directory process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/multi-fast5/*
TESTCASE_NO=8
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:directory process:single_process output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5 --iop 1 --to slow5 -d $OUTPUT_DIR/multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm1.slow5 $OUTPUT_DIR/multi-fast5/ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:single_process output"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm2.slow5 $OUTPUT_DIR/multi-fast5/ssm2.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:single_process output"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm3.slow5 $OUTPUT_DIR/multi-fast5/ssm3.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/stdout.slow5
#input:directory on a single process cannot be tested as the order of the files read by the program can vary.
TESTCASE_NO=9
echo "------------------- f2s testcase $TESTCASE_NO: format:single_and_multi-fast5 input:file process:single_process output:stdout-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-and-multi-fast5/1ssm1.fast5 $FAST5_DIR/single-and-multi-fast5/2sss1.fast5 $FAST5_DIR/single-and-multi-fast5/3ssm2.fast5 $FAST5_DIR/single-and-multi-fast5/4sss2.fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/file_single-and-multi-fast5.slow5 $OUTPUT_DIR/stdout.slow5 || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=10
echo "------------------- f2s testcase $TESTCASE_NO: format:single_and_multi-fast5 input:directory process:single_process output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-and-multi-fast5 --iop 1 --to slow5 -d $OUTPUT_DIR/single-and-multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/0.slow5 $OUTPUT_DIR/single-and-multi-fast5/0.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:single_process output"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/1ssm1.slow5 $OUTPUT_DIR/single-and-multi-fast5/1ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:single_process output"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/3ssm2.slow5 $OUTPUT_DIR/single-and-multi-fast5/3ssm2.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:single_process output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

# ----------------------------------------------- multi process --------------------------------------------

echo
rm $OUTPUT_DIR/single-fast5-output/*
TESTCASE_NO=11
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:file process:multi output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5/sss1.fast5 -d $OUTPUT_DIR/single-fast5-output --iop 4 --to slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/0.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single-fast5 input:file process:multi output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/single-fast5-output/*
TESTCASE_NO=12
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:directory process:multi output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-fast5 -d $OUTPUT_DIR/single-fast5-output --iop 4 --to slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/0.slow5 2>/dev/null || die "ERROR: diff failed for 'f2s format:single-fast5 input:directory process:multi output"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/1.slow5 2>/dev/null || die "ERROR: diff failed for 'f2s format:single-fast5 input:directory process:multi output"
diff -s $EXP_SLOW5_DIR/single-fast5-output/a_single-fast5.slow5 $OUTPUT_DIR/single-fast5-output/2.slow5 2>/dev/null || die "ERROR: diff failed for 'f2s format:single-fast5 input:directory process:multi output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/multi-fast5/*
TESTCASE_NO=13
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:file process:multi output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5/ssm1.fast5 --iop 4 --to slow5 -d $OUTPUT_DIR/multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/file_multi-fast5.slow5 $OUTPUT_DIR/multi-fast5/ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:multi output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/multi-fast5/*
TESTCASE_NO=14
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:directory process:multi output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/multi-fast5 --iop 4 --to slow5 -d $OUTPUT_DIR/multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm1.slow5 $OUTPUT_DIR/multi-fast5/ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:multi output"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm2.slow5 $OUTPUT_DIR/multi-fast5/ssm2.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:multi output"
diff -s $EXP_SLOW5_DIR/multi-fast5-output/ssm3.slow5 $OUTPUT_DIR/multi-fast5/ssm3.slow5 2>/dev/null || die "ERROR: diff failed for 'format:multi-fast5 input:file process:multi output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/single-and-multi-fast5/*
TESTCASE_NO=15
echo "------------------- f2s testcase $TESTCASE_NO: format:single_and_multi-fast5 input:directory process:multi output:directory-------------------"
$SLOW5_EXEC f2s $FAST5_DIR/single-and-multi-fast5 --iop 4 --to slow5 -d $OUTPUT_DIR/single-and-multi-fast5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/1ssm1.slow5 $OUTPUT_DIR/single-and-multi-fast5/1ssm1.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:multi output"
diff -s $EXP_SLOW5_DIR/single-and-multi-fast5-output/3ssm2.slow5 $OUTPUT_DIR/single-and-multi-fast5/3ssm2.slow5 2>/dev/null || die "ERROR: diff failed for 'format:single_and_multi-fast5 input:directory process:multi output"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

#----------------------------------------- run id conflicts -------------------------------------------

echo
TESTCASE_NO=16
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:directory process:single_process output:stdout run_id_conflicts-------------------"
$SLOW5_EXEC_WITHOUT_VALGRIND f2s $FAST5_DIR/run_id_conflicts/single_fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
rm $OUTPUT_DIR/single-fast5-output/*
TESTCASE_NO=17
echo "------------------- f2s testcase $TESTCASE_NO: format:single-fast5 input:directory process:single_process output:directory run_id_conflicts-------------------"
$SLOW5_EXEC_WITHOUT_VALGRIND f2s $FAST5_DIR/run_id_conflicts/single_fast5 -d $OUTPUT_DIR/single-fast5-output --iop 1 --to slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=18
echo "------------------- f2s testcase $TESTCASE_NO: format:multi-fast5 input:directory process:single_process output:stdout run_id_conflicts-------------------"
$SLOW5_EXEC_WITHOUT_VALGRIND f2s $FAST5_DIR/run_id_conflicts/multi_fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=19
echo "------------------- f2s testcase $TESTCASE_NO: format:single_and_multi-fast5 input:directory process:single_process output:stdout run_id_conflicts-------------------"
$SLOW5_EXEC_WITHOUT_VALGRIND f2s $FAST5_DIR/run_id_conflicts/single_fast5 $FAST5_DIR/run_id_conflicts/multi_fast5 --iop 1 --to slow5 > $OUTPUT_DIR/stdout.slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=20
echo "------------------- f2s testcase $TESTCASE_NO: format:single_and_multi-fast5 input:directory process:single_process output:directory run_id_conflicts-------------------"
$SLOW5_EXEC_WITHOUT_VALGRIND f2s $FAST5_DIR/run_id_conflicts/single_fast5 $FAST5_DIR/run_id_conflicts/multi_fast5 --iop 1 -d $OUTPUT_DIR/single_and_multi-fast5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=21
echo "------------------- f2s testcase $TESTCASE_NO >>> current directory:fast5 file directory-------------------"
cd $FAST5_DIR/single-fast5
CD_BACK=../../../../..
$CD_BACK/slow5tools f2s sss1.fast5 --iop 1 --to slow5 > $CD_BACK/$OUTPUT_DIR/stdout.slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
cd -
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=22
echo "------------------- f2s testcase $TESTCASE_NO >>> auxiliary field missing fast5-------------------"
mkdir -p $OUTPUT_DIR/unusual_fast5 || die "creating $OUTPUT_DIR/unusual_fast5 failed"
$SLOW5_EXEC f2s $FAST5_DIR/unusual_fast5/median_before_missing.fast5 --iop 1 -o $OUTPUT_DIR/unusual_fast5/median_before_missing.slow5 --to slow5 2>/dev/null || die "testcase $TESTCASE_NO failed"
diff -s $EXP_SLOW5_DIR/unusual_fast5/median_before_missing.slow5 $OUTPUT_DIR/unusual_fast5/median_before_missing.slow5 2>/dev/null || die "ERROR: diff failed for auxiliary field missing fast5"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=23
echo "------------------- f2s testcase $TESTCASE_NO >>> primary field missing fast5-------------------"
mkdir -p $OUTPUT_DIR/unusual_fast5 || die "creating $OUTPUT_DIR/unusual_fast5 failed"
$SLOW5_EXEC f2s $FAST5_DIR/unusual_fast5/offset_missing.fast5 --iop 1 -o $OUTPUT_DIR/unusual_fast5/offset_missing.slow5 --to slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

echo
TESTCASE_NO=24
echo "------------------- f2s testcase $TESTCASE_NO >>> primary field missing fast5-------------------"
mkdir -p $OUTPUT_DIR/unusual_fast5 || die "creating $OUTPUT_DIR/unusual_fast5 failed"
$SLOW5_EXEC f2s $FAST5_DIR/unusual_fast5/offset_missing.fast5 --iop 1 -o $OUTPUT_DIR/unusual_fast5/offset_missing.slow5 --to slow5 2>/dev/null && die "testcase $TESTCASE_NO failed"
echo -e "${GREEN}testcase $TESTCASE_NO passed${NC}"

rm -r $OUTPUT_DIR || die "Removing $OUTPUT_DIR failed"

exit 0
