#!/usr/bin/perl
use strict;
use Getopt::Std;
my $outputcsv=0;
my $summary_line=0;
my $vat_factor=1.06;
my %options;
getopts ('si:o:h', \%options);
my $usage= <<'ENDMESSAGE';
Usage: $0 -i <inputfile> [-o <outputfile>] 
	-i: filename of CSV file to process
	-o: filename of CSV file to output analysis to
	-s: if supplied; will add a summary-line in output CSV with order_total statistics
	-t: VAT factor to use (defeault: 1.06).

Format of input csv:
vendor|product|crate_size|crates_ordered|crate_cost(ex vat)|bottle_sales_price (inc VAT)

Format of output csv is the same as the input CSV, except it concatenates the following fields for each entry:
crate_cost(inc VAT)|total_bottles_ordered|bottle_cost(inc VAT)|bottle_profit|bottle_margin_percentage|order_cost| \
order_income|order_profit|order_profit_margin|vat_factor_used

If supplied, the -s flag will produce an extra line at the end of the file containing totals.
THe format will be as follows:
ORDER|TOTAL||total_crates_ordered|total_order_cost(ex VAT)|average_bottle_sales_price(inc VAT)| \
total_order_cost(inc VAT)|total_bottles_over_order|average_bottle_cost(inc VAT)|average_bottle_profit| \
average_bottle_margin_percentage|total_order_income|total_order_profit|vat_factor_used

ENDMESSAGE
if ($options{'h'}) {
	print $usage;
	exit 1;
}
if (! $options{'i'}) {
	print "Please provide input file\n";
	exit 1;
}

if ($options{'o'}) {
	open(OUTPUTFILE, "> ".$options{'o'}) || die 'Couldnt open file '.$options{'o'};
	$outputcsv=1;
}

if ($options{'s'}) {
	$summary_line=1;
}
if ($options{'t'}) {
	$vat_factor=$options{'t'};
}

my $order_running_crates;
my $order_running_bottles;
my $order_running_cost_ex;
my $order_running_income;
my $order_running_cost;
my $order_running_profit;

open (INPUTFILE, $options{'i'}) || die 'Couldnt open file '.$options{'i'}.": $!";

while (<INPUTFILE>) {
	chomp $_;
	(my $vendor, my $product, my $lot_size, my $order_amount, my $lot_price_ex, my $sales_price) = split (/\|/, $_);
	my $lot_price;
	if (uc($vendor) ne 'STATIEGELD') {
		$lot_price=$lot_price_ex*$vat_factor;
	} else {
		$lot_price=$lot_price_ex;
	}
	my $bottle_price=($lot_price/$lot_size);
	my $bottle_profit=($sales_price-$bottle_price);
	my $bottle_profit_margin=(($bottle_profit/$bottle_price)*100);
	my $order_total_size=$lot_size*$order_amount;
	print "For a crate ($lot_size) of $vendor - $product:\n";
	print "- We pay $bottle_price per item that we sell for $sales_price\n";
	print "- This means there is a $bottle_profit profit, $bottle_profit_margin%\n";
	print "- In the last order, we had $order_amount batches of $lot_size items\n";
        my $order_cost=$lot_price*$order_amount;
	my $order_income=$order_total_size*$sales_price;	
	my $order_profit=$order_income-$order_cost;
	my $order_profit_margin=(($order_profit/$order_cost)*100);
	my $bottle_count=$order_amount*$lot_size;
	print "- These $bottle_count items cost us ".$order_cost." euros and sold for ".$order_income." euros\n";
	print "- The profit on this is ".$order_profit." euros. A margin of ".$order_profit_margin."%\n";
	print "----\n:";
	if ($outputcsv) {
		print OUTPUTFILE $_."|";
		if (uc($vendor) ne 'STATIEGELD') {
			print OUTPUTFILE $lot_price."|".$order_total_size."|".$bottle_price."|".$bottle_profit."|".$bottle_profit_margin."|".$order_cost."|".$order_income."|".$order_profit."|".$order_profit_margin."|".$vat_factor."\n";
		$order_running_crates+=$order_amount;
		$order_running_bottles+=$bottle_count;
		} else {
			print OUTPUTFILE $lot_price."|".$order_total_size."|".$bottle_price."|".$bottle_profit."|".$bottle_profit_margin."|".$order_cost."|".$order_income."|".$order_profit."|".$order_profit_margin."|0\n";
		}
	}

	$order_running_income+=$order_income;
	$order_running_cost+=$order_cost;
	$order_running_cost_ex+=($lot_price_ex*$order_amount);
	if (uc($vendor) ne 'STATIEGELD') {
		$order_running_profit+=$order_profit;
	}
}
print "+------------------+\n";
print "Total crates ordered: $order_running_crates\n";
print "Total bottle ordered: $order_running_bottles\n";
print "Total order cost: $order_running_cost\n";
print "Total order income: $order_running_income\n";
print "Total order profit: $order_running_profit\n";
print "Combined order margin: ".(($order_running_profit/$order_running_cost)*100)."%\n";

if ($outputcsv && $summary_line) {
	my $order_bottle_average_sales_price=($order_running_income/$order_running_bottles);
	my $order_bottle_average_cost=($order_running_cost/$order_running_bottles);
	my $order_bottle_average_profit=($order_running_profit/$order_running_bottles);
	my $order_bottle_average_profit_margin=($order_bottle_average_profit/$order_bottle_average_cost)*100;
	
	print OUTPUTFILE "ORDER|TOTAL||$order_running_crates|$order_running_cost_ex|$order_bottle_average_sales_price|";
	print OUTPUTFILE "$order_running_cost|$order_running_bottles|$order_bottle_average_cost|$order_bottle_average_profit|";
	print OUTPUTFILE "$order_bottle_average_profit_margin|$order_running_income|$order_running_profit|$vat_factor\n";
	close OUTPUTFILE;
}
close INPUTFILE;
