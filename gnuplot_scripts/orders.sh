#!/bin/bash

TMPFILE="tmp.$$"
export ABS_DEF=$(cat <<'STOP'
define abs(i) {
    if (i < 0) return (-i)
    return (i)
}
STOP
)

# Euro cost/profit graph
echo "ORDER|COST|PROFIT" >> $TMPFILE
for i in `cd ../analysis_info;ls analysis*`
do
	export my_date=`echo $i | sed "s/^analysis-order_\([0-9]\{8\}\)-[0-9]\{8\}/\1/"`
	echo -n "$my_date|" >> $TMPFILE
	grep -i "DRINKS_ONLY" ../analysis_info/$i| cut -d"|" -f "7,13" >> $TMPFILE
done
export GNUPLOT_DATA=$TMPFILE
gnuplot -c order_euro-stacked_histo.gpl
rm $TMPFILE


# PERCENTILE cost/profit graph
echo "ORDER|COST|PROFIT" >> $TMPFILE
for i in `cd ../analysis_info;ls analysis*`
do
	my_date=`echo $i | sed "s/^analysis-order_\([0-9]\{8\}\)-[0-9]\{8\}/\1/"`
	echo -n "$my_date|" >> $TMPFILE
	my_profit_perc=`grep -i "DRINKS_ONLY" ../analysis_info/$i| cut -d"|" -f "11"`
	my_profit_perc=`echo "$my_profit_perc/(($my_profit_perc+100)/100)" | bc -l`
	my_cost_perc=`echo "100-$my_profit_perc" | bc -l`
	echo "$my_cost_perc|$my_profit_perc" >> $TMPFILE
done
export GNUPLOT_DATA=$TMPFILE
gnuplot -c order_percentage-stacked_histo.gpl
rm $TMPFILE

