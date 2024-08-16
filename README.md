# filter-out-env

Script to filter out blast results for a query sequence that have certain text in the species name.
The first result without the forbidden text is added to the output file.

**Note: This has only been tested with GNU grep and awk that are typically found on Linux systems. It has not been tested on the BSD versions on macOS**

On **Mac**, you can install GNU grep and sed using conda:
`conda create -n grepsed-env -n -c conda-forge --override-channels conda-forge::sed conda-forge:grep`

Usage:

```{base}
$ ./filter-out-env.sh -h
Usage: ./filter-out-env.sh input.tsv

Input file name is REQUIRED and must be the final argument.

Optional arguments:
  -x OUTDIR:            Directory for output file.
                        Default: .
  -x OUTEXT:            Extension used for the output file.
                        Default: .out
  -f FILTEROUT:            Text to filter out from taxa names.
                        This should be a | separated list with no other characters between
                        the words. Partial matches will be found, like
                        "environmental" for "environment".
                        Default: 'uncultured|environment'
  -m MODE:              Mode for when NO blast hits pass the filter.
                          strict: No output is put in the out file.
                          relaxed: Top hit is put in the out file.
                        Default: strict
  -s STAXID_COL:        Which column of the tsv has the taxon name of
                        the blast hit.
                        Default: 4
  -v                    Enable verbose logging. Default: disabled.
  -n                    No warning before overwriting an exiting output file.
                        Default: disabled
  -h                    This help message.
```

Example:

```{bash}
$ ./filter-out-env.sh input.tsv 
[2024-08-14 14:37:34]  Input file: input.tsv
[2024-08-14 14:37:34]  Output file: input.out
[2024-08-14 14:37:34]  Output file found, remove?
rm: remove regular file 'input.out'? y
[2024-08-14 14:37:36]  Unique query sequence names: 259
[2024-08-14 14:37:41]    ASV_00190: NO good results found. Nothing being added to the output file.
[2024-08-14 14:37:42]    ASV_00207: NO good results found. Nothing being added to the output file.
[2024-08-14 14:37:43]    ASV_00248: NO good results found. Nothing being added to the output file.
[2024-08-14 14:37:44]    ASV_00255: NO good results found. Nothing being added to the output file.
[2024-08-14 14:37:44]  DONE processing samples
```
