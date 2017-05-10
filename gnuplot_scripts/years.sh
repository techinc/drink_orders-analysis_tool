#!/bin/bash

if [ "$1" == "" ]
then
	echo 'please provide a year'
	exit
fi

export YEAR=$1;

export GNUPLOT_DATA="tmp.$$"
./year_data.pl -y $1 > $GNUPLOT_DATA
gnuplot -c year_cost_income-accum-histo.gpl
gnuplot -c year_cost_income-non_accum-histo.gpl
rm $GNUPLOT_DATA
