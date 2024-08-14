#!/bin/sh

# Species words to filter
# This should be a | separated list, with no other characters between the words.
# Partial matches will be found, like "environmental" for "environment"
# exmaple: 'uncultured|environment'
FILTEROUT='uncultured|environment'

# Set to "verbose" for verbose output
LOGLEVEL=

# Logging function
function ScriptLogging {
    # $1: message to be logged
    # $2: what level message this is (verbose if this should only be output if verbose mode is enabled)
    # Uses $LOG variable, if set, to output to a logfile, otherwise it outputs to stdout only
    local DATE=$(date +%Y-%m-%d\ %H:%M:%S)
    LOGMSGLEVEL=$(echo $2 | tr '[:upper:]' '[:lower:]')
    if [ -z $LOGMSGLEVEL ] || [ "$LOGLEVEL" = "$LOGMSGLEVEL" ]; then
        echo "[$DATE]" " $1" | tee -a $LOG
    fi
}

# Input file
INFILE=$1
if [ -z $INFILE ]; then
  echo "Give the TSV blast output file as the program argument"
  echo "For example:"
  echo "  $0 infile.tsv"
  exit 1
fi
if [ ! -f $INFLIE ]; then
  echo "The given input file was not found: $INFILE"
  exit 1
fi
ScriptLogging "Input file: $INFILE"

# Output file
OUTEXT=".out"
OUTFILE="${INFILE%.*}"${OUTEXT}
ScriptLogging "Output file: $OUTFILE"
# If the file exists, prompt the user if they want to remove it, otherwise exit
[ -f $OUTFILE ] && ScriptLogging "Output file found, remove?" && rm -i $OUTFILE
[ -f $OUTFILE ] && exit 1

# TMPDIR
TMPDIR=tmp
rm -rf $TMPDIR 2>/dev/null
mkdir $TMPDIR
ScriptLogging "Temporary output going in: $TMPDIR" verbose

# Column with Species name
STAXID_COL=4
ScriptLogging "Subject Taxonomy ID is in columns: $STAXID_COL" verbose


# Get all the unqiue sequence names
awk '{print $1}' $INFILE | uniq >$TMPDIR/uniq_query_names
QUERYCOUNT=$(wc -l $TMPDIR/uniq_query_names | awk '{print $1}')
ScriptLogging "Unique query sequence names: $QUERYCOUNT"

# Iterate through sequence names
while read SEQUENCE; do
  ScriptLogging "Processing $SEQUENCE" verbose
  # Create a file with only those sequence's results
  grep -E "^${SEQUENCE}[[:space:]]" $INFILE > $TMPDIR/${SEQUENCE}.tmp
  BLASTCOUNT=$(wc -l $TMPDIR/${SEQUENCE}.tmp | awk '{print $1}')
  ScriptLogging "  Results found: $BLASTCOUNT" verbose
  # "TODO: Check for no results (is that possible?)"
  # "TODO: Sort by bit score"
  # Iterate for each blast hit
    CURRCOUNT=1
    while read CURRLINE; do
      # check for words that indicate we should skip this line
      echo "$CURRLINE" | grep -q -E $FILTEROUT || break
      CURRCOUNT=$((CURRCOUNT+1))
    done <$TMPDIR/${SEQUENCE}.tmp
    if [ "$CURRCOUNT" -ge "$BLASTCOUNT" ]; then
      ScriptLogging "  $SEQUENCE: NO good results found. Nothing being added to the output file."
    else
      ScriptLogging "  $SEQUENCE: Good result found on line $CURRCOUNT, adding it to \"$OUTFILE\"." verbose
      echo "$CURRLINE" >> $OUTFILE
    fi

  # Get first line
#  CURRLINE="$(sed -n '1p' $TMPDIR/${SEQUENCE}.tmp)"
  # TODO: prserver tabs in CURRLINE
#  CURRSP="$(sed -n '1p' $TMPDIR/${SEQUENCE}.tmp | cut -f $STAXID_COL)"
#  echo $CURRSP
  
done <$TMPDIR/uniq_query_names

# remove tmp directory
rm -rf $TMPDIR

ScriptLogging "DONE processing samples"