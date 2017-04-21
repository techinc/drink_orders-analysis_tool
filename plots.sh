#!/bin/bash

for input in `ls analysis_info/`
do
 echo Processing $input
 DATE=$(echo "$input" | sed 's/^.*_.*-\(.*\)$/\1/g')
 ORDER=$(echo "$input" | sed 's/^.*_\(.*\)-.*$/\1/g')
 output_directory=test
 echo $ORDER was placed on $DATE
 for script in `ls gnuplot_scripts/`
 do
  echo Running $script
  gnuplot -e "output_directory='$output_directory' inputfile='$input' outputfile='$output'"  gnuplot_scripts/$script
  
 done
 echo ----
done
