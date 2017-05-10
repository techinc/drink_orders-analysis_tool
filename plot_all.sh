#!/bin/bash

# first we establish a list of years

export TMPFILE="/tmp/tmp.$$"
for i in `cd analysis_info; ls analysis-order*`
do
	echo $i | sed "s/^analysis-order_\([0-9]\{4\}\)[0-9]\{4\}-[0-9]\{8\}/\1/" >> $TMPFILE;
done

for year in `uniq $TMPFILE`
do
	echo "Running plots for: $year"
	echo -n 'Order plot........'
	`cd gnuplot_scripts;./orders.sh $year`
	echo [DONE]
	echo -n 'Cost/Income plot..'
	`cd gnuplot_scripts;./years.sh $year`
	echo [DONE]

done

rm $TMPFILE;
