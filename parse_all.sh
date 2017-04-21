#!/bin/bash

for i in `cd order_info/csv;ls order*`
do
echo $i
utils/drinkparser.pl -s -i order_info/csv/$i -o analysis_info/analysis-$i
done

