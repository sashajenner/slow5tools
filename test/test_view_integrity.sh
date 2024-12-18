#!/bin/bash

# MIT License

# Copyright (c) 2020 Hiruna Samarakoon
# Copyright (c) 2020 Sasha Jenner
# Copyright (c) 2020,2023 Hasindu Gamaarachchi

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

###############################################################################

# steps
# view slow5
# view blow5
# diff md5sum original and created blow5

RED='\033[0;31m' ; GREEN='\033[0;32m' ; NC='\033[0m' # No Color
die() { echo -e "${RED}$1${NC}" >&2 ; echo ; exit 1 ; } # terminate script
info() { echo -e "${GREEN}$1${NC}" >&2 ;  echo ; }

#ask before deleting. if yes then delete. if no then exit.
# to automatically answer yes | script or use yes n | script
ask() { echo -n "Directory $1 exists. Delete and create again? (y/n)? " ; read answer ; if [ "$answer" != "${answer#[Nn]}" ] ;then exit ; fi ; echo ; }

#getting bash arguments
Usage="view_integrity_test.sh .blow5 temp_dir_path"
NUMBER_ARGS=2
if [[ "$#" -lt $NUMBER_ARGS ]]; then
	info "Usage: $Usage"
	exit 1
fi
BLOW5_FILE=$1

#...directories files tools arguments commands clean
OUTPUT_DIR=$2
test -d "$OUTPUT_DIR" && ask "$OUTPUT_DIR"
test -d "$OUTPUT_DIR" && rm -r "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR" || die "Failed creating $OUTPUT_DIR"
#commands ...

# Relative path to "slow5tools/tests/"
REL_PATH="$(dirname $0)/"
SLOW5TOOLS=$REL_PATH/../slow5tools

NUM_THREADS=40
BATCH_SIZE=10000

$SLOW5TOOLS view --from blow5 --to slow5 "$BLOW5_FILE" -o "$OUTPUT_DIR/view.slow5" -t $NUM_THREADS -K $BATCH_SIZE
$SLOW5TOOLS view --from slow5 --to blow5 -c none "$OUTPUT_DIR/view.slow5" -o "$OUTPUT_DIR/view.blow5" -t $NUM_THREADS -K $BATCH_SIZE

cmp "$OUTPUT_DIR/view.blow5" "$BLOW5_FILE" || die "Files are different. view_integrity_test failed"
info "Files are the same. Success!"

rm -r "$OUTPUT_DIR" || die "Could not delete $OUTPUT_DIR"
info "done"
exit 0
# If you want to log to the same file: command1 >> log_file 2>&1
# If you want different files: command1 >> log_file 2>> err_file
# use ANSI syntax format to view stdout/stderr on SublimeText
# use bash -n [script] and shellcheck [script] to check syntax
