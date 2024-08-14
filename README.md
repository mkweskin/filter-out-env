# filter-out-env

Script to filter out blast results for a query sequence that have certain text in the species name.
The first result without the forbidden text is added to the output file.

Use:

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
