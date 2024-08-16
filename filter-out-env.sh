#!/bin/sh

# info message dipslayed on misconfiguration errors
function usage
{
    cat << EOF


Usage: $0 input.tsv

Input file name is REQUIRED and must be the final argument.

Optional arguments:
  -x OUTDIR:            Directory for output file.
                        Default: $OUTDIR
  -x OUTEXT:            Extension used for the output file.
                        Default: $OUTEXT
  -f FILTEROUT:            Text to filter out from taxa names.
                        This should be a | separated list with no other characters between
                        the words. Partial matches will be found, like
                        "environmental" for "environment".
                        Default: '$FILTEROUT'
  -m MODE:              Mode for when NO blast hits pass the filter.
                          strict: No output is put in the out file.
                          relaxed: Top hit is put in the out file.
                        Default: $MODE
  -s STAXID_COL:        Which column of the tsv has the taxon name of
                        the blast hit.
                        Default: $STAXID_COL
  -v                    Enable verbose logging. Default: disabled.
  -n                    No warning before overwriting an exiting output file.
                        Default: disabled
  -h                    This help message.

EOF
exit 1
}

# Defaults:
# Species words to filter
FILTEROUT='uncultured|environment'
# Logging level
LOGLEVEL=
# Extension for outfile
OUTEXT=.out
# Extension for tmp file
TMPEXT=.tmp
# Extension for file with unqiue seq names
UNIQEXT=.uniq.tmp
# Where output files go
OUTDIR=.
# Column with Species name
STAXID_COL=4
# mode for nothing passing filter
MODE=strict



###
# Process command line options
###

while getopts "x:f:vd:s:m:nh" option; do
    case "${option}" in
        x)
            OUTEXT=${OPTARG}
            ;;
        f)
            FILTEROUT=${OPTARG}
            ;;
        v)
            LOGLEVEL=verbose
            ;;
        d)
            OUTDIR=${OPTARG}
            ;;
        s)
            STAXID_COL=${OPTARG}
            ;;
        m)
            MODE=${OPTARG}
            ;;
        n)
            WARN=no
            ;;
        h)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

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
  echo "ERROR: Give the TSV blast output file as the program argument"
  usage
fi
if [ ! -e $INFILE ]; then
  echo "ERROR: The given input file was not found: $INFILE"
  exit 1
fi
ScriptLogging "Input file: $INFILE"

# Test if a proper mode was given
# make MODE lowercase
MODE=$(echo $MODE | tr '[:upper:]' '[:lower:]')
if [ ! $MODE = "strict" ] && [ ! $MODE = "relaxed" ]; then
  echo "ERROR: the given mode is not valid: $MODE"
  usage
fi

# Test writing to the OUTDIR
RAND=$OUTDIR/$RANDOM$RANDOM.tmp
touch $RAND 2>/dev/null
[ ! -e $RAND ] && echo "ERROR: there was an error writing to the specified temporary directory: $OUTDIR" && exit 1
rm -f $RAND

# Where tmp files will go with the path and the input file name without extensions
TMPFILEBASE="${OUTDIR}/${INFILE%.*}"

# Output file
OUTFILE=${TMPFILEBASE}${OUTEXT}
ScriptLogging "Output file: $OUTFILE"
# If the file exists, prompt the user if they want to remove it, otherwise exit
if [ -e $OUTFILE ] && [ -z $WARN ]; then
  ScriptLogging "Output file found (${OUTFILE}), overwrite? (y/n)"
  rm -i $OUTFILE
  [ -e $OUTFILE ] && exit 1
fi

# Tmp file
TMPFILE=${TMPFILEBASE}${TMPEXT}
[ -e $TMPFILE ] && rm $TMPFILE
[ -e $TMPFILE ] && exit 1

# Unique names file
UNIQFILE=${TMPFILEBASE}${UNIQEXT}
[ -e $UNIQFILE ] && rm $UNIQFILE
[ -e $UNIQFILE ] && exit 1

ScriptLogging "Subject Taxonomy ID is in columns: $STAXID_COL" verbose
ScriptLogging "Taxa names to filter out: $FILTEROUT" verbose

# Get all the unqiue sequence names
awk '{print $1}' $INFILE | uniq >$UNIQFILE
QUERYCOUNT=$(wc -l $UNIQFILE | awk '{print $1}')
ScriptLogging "Unique query sequence names: $QUERYCOUNT"

if [ ! -s $UNIQFILE ]; then
  echo "ERROR: There was an error determining the unique sequence names."
  echo "This file was not found or is empty. It should contain the unique names: $UNIQFILE"
  exit 1
fi

# Iterate through sequence names
while read SEQUENCE; do
  ScriptLogging "Processing $SEQUENCE" verbose
  # Create a file with only those sequence's results
  grep -E "^${SEQUENCE}[[:space:]]" $INFILE > $TMPFILE
  HITCOUNT=$(wc -l $TMPFILE | awk '{print $1}')
  ScriptLogging "  Results found: $HITCOUNT" verbose
  # "TODO: Sort by bit score"
  # Iterate for each blast hit
    CURRHIT=1
    while read CURRLINE; do
      if [ "$CURRHIT" -eq "1" ]; then
        # Save the first hit. If we're in relaxed mode, this will be used if everything is filtered
        FIRSTLINE="$CURRLINE"
      fi
      # check for words that indicate we should skip this line
      echo "$CURRLINE" | grep -q -E $FILTEROUT || break
      CURRHIT=$((CURRHIT+1))
    done <$TMPFILE
    if [ "$CURRHIT" -ge "$HITCOUNT" ]; then
      # Not good hits found
      if [ $MODE = "strict" ]; then
        # Nothing is output
        ScriptLogging "  $SEQUENCE: NO good results found. Nothing being added to the output file."
      else
        echo "$FIRSTLINE" >> $OUTFILE
        ScriptLogging "  $SEQUENCE: NO good results found. Best hit has been added."
      fi
    else
      ScriptLogging "  $SEQUENCE: Good result found on line $CURRHIT, adding it to \"$OUTFILE\"." verbose
      echo "$CURRLINE" >> $OUTFILE
    fi
  # Clean up from the previous iteration, just to be extra sure we're not getting values from a previous sequence
  rm -f $TMPFILE
  unset FIRSTLINE
done <$UNIQFILE

# remove file with unique names
rm -f $UNIQFILE

ScriptLogging "DONE processing samples"

exit 0

# Some code I didn't use:
#  CURRLINE="$(sed -n '1p' $OUTDIR/${SEQUENCE}.tmp)"
#  CURRSP="$(sed -n '1p' $OUTDIR/${SEQUENCE}.tmp | cut -f $STAXID_COL)"