#!/bin/bash

# steps
# cat slow5 files
# cat blow5 files
# convert catenated blow5 to slow5
# compare slow5s against the expected
# additional error catching testcases

RED='\033[0;31m' ; GREEN='\033[0;32m' ; NC='\033[0m' # No Color
die() { echo -e "${RED}$1${NC}" >&2 ; echo ; exit 1 ; } # terminate script
info() {  echo ; echo -e "${GREEN}$1${NC}" >&2 ; }
# Relative path to "slow5/tests/"
REL_PATH="$(dirname $0)/" 

#...directories files tools arguments commands clean
OUTPUT_DIR="$REL_PATH/data/out/cat"
test -d "$OUTPUT_DIR" && rm -r "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR" || die "Failed creating $OUTPUT_DIR"
#commands ...

RAW_DIR="$REL_PATH/data/raw/cat"
SLOW5TOOLS_WITHOUT_VALGRIND=$REL_PATH/../slow5tools

if [ "$1" = 'mem' ]; then
    SLOW5TOOLS="valgrind --leak-check=full --error-exitcode=1 $SLOW5TOOLS_WITHOUT_VALGRIND"
else
    SLOW5TOOLS=$SLOW5TOOLS_WITHOUT_VALGRIND
fi

TESTCASE=1
EXP_SLOW5_FILE="$REL_PATH/data/exp/cat/expected_multi_group.slow5"
info "testcase:$TESTCASE - cat multi_read_group files"
$SLOW5TOOLS cat "$RAW_DIR/multi_read_group/cat_test_0.slow5" "$RAW_DIR/multi_read_group/cat_test_1.slow5" > "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE slow5tools cat failed"
diff $EXP_SLOW5_FILE "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE diff failed"

EXP_SLOW5_FILE="$REL_PATH/data/exp/cat/expected_single_group.slow5"

TESTCASE=2
info "testcase:$TESTCASE - cat two slow5s. output-stdout"
$SLOW5TOOLS cat "$RAW_DIR/slow5s/" > "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE slow5tools cat failed"
diff $EXP_SLOW5_FILE "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE diff failed"

TESTCASE=3
info "testcase:$TESTCASE - cat two blow5s. output-stdout"
$SLOW5TOOLS cat "$RAW_DIR/blow5s/" > "$OUTPUT_DIR/output.blow5" || die "testcase:$TESTCASE slow5tools cat failed"
$SLOW5TOOLS view "$OUTPUT_DIR/output.blow5" > "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE slow5tools view failed"
diff $EXP_SLOW5_FILE "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE diff failed"

TESTCASE=4
info "testcase:$TESTCASE - cat two slow5s. output-file"
$SLOW5TOOLS cat "$RAW_DIR/slow5s/" -o "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE slow5tools cat failed"
diff $EXP_SLOW5_FILE "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE diff failed"

TESTCASE=5
info "testcase:$TESTCASE - cat two blow5s. output-file"
$SLOW5TOOLS cat "$RAW_DIR/blow5s/" -o "$OUTPUT_DIR/output.blow5" || die "testcase:$TESTCASE slow5tools cat failed"
$SLOW5TOOLS view "$OUTPUT_DIR/output.blow5" > "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE slow5tools view failed"
diff $EXP_SLOW5_FILE "$OUTPUT_DIR/output.slow5" || die "testcase:$TESTCASE diff failed"

TESTCASE=6
info "testcase:$TESTCASE - cat two slow5s. output-file. wrong file extension"
$SLOW5TOOLS cat "$RAW_DIR/slow5s/" -o "$OUTPUT_DIR/output.blow5" && die "testcase:$TESTCASE slow5tools cat failed"

TESTCASE=7
info "testcase:$TESTCASE - cat two blow5s. output-file. wrong file extension"
$SLOW5TOOLS cat "$RAW_DIR/blow5s/" -o "$OUTPUT_DIR/output.slow5" && die "testcase:$TESTCASE slow5tools cat failed"

TESTCASE=8
info "testcase:$TESTCASE - cat different format files"
$SLOW5TOOLS cat "$RAW_DIR/mixed_format/" > "$OUTPUT_DIR/output.slow5" && die "testcase:$TESTCASE slow5tools cat failed"

TESTCASE=9
info "testcase:$TESTCASE - cat different compression types files"
$SLOW5TOOLS cat "$RAW_DIR/mixed_compression/" > "$OUTPUT_DIR/output.slow5" && die "testcase:$TESTCASE slow5tools cat failed"

info "all $TESTCASE cat testcases passed"
rm -r "$OUTPUT_DIR" || die "could not delete $OUTPUT_DIR"
exit 0
# If you want to log to the same file: command1 >> log_file 2>&1
# If you want different files: command1 >> log_file 2>> err_file
# use ANSI syntax format to view stdout/stderr on SublimeText
# use bash -n [script] and shellcheck [script] to check syntax
