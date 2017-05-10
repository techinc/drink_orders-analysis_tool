#!/usr/bin/perl
use strict;
use Getopt::Std;
use DateTime;

my $ana_dir="../analysis_info/";
my $plot_dir="plots/";


my %options;

getopt ('y', \%options);
my $usage=<<'ENDMESSAGE';
Usage: $0 -y <YEAR>

ENDMESSAGE

if (! $options{'y'}) {
	print $usage;
	exit;
}

my $year=$options{'y'};
my $first_day="$year"."0101";
my $first_day_dt=DateTime->new(
	year => $year,
	month => 01,
	day => 01
);

my $last_day="$year"."1231";
my $last_day_dt=DateTime->new(
	year => $year,
	month => 12,
	day => 31
);

# Get all files that arent a directory and sort them to get a date-sorted list
my @DIRLIST;
opendir(my $dh,"$ana_dir") || die "Can't opendir $ana_dir: $!";

while (readdir $dh) {
	if ($_ ne '.' && $_ ne '..') {
		push @DIRLIST,$_;
	}
}
closedir $dh;

my @DIRLIST= sort @DIRLIST;
my $last;


# Now stuff an array with hashes that contain info about each entry.
# Also, for all the entries except the first, include the income of the PREVIOUS order in prev_income
# and include info about how long ago the previous order was.
# Income associated with any order is, after all, only assumed to have come in as cash at the 
# time of placing a new order. This assumption is not 'safe', but makes more sense than
# assuming instant income upon delivery of order.

my @DATA;
for (my $item=0;$item<=$#DIRLIST;$item++) {
	my @TEMP=fetch_drinks_only($ana_dir.$DIRLIST[$item]);
	$DATA[$item]->{'cost'}=$TEMP[6];
	$DATA[$item]->{'income'}=$TEMP[11];
	$DATA[$item]->{'filename'}=$DIRLIST[$item];
	(my $yeart, my $montht, my $dayt) =$DIRLIST[$item]=~/^analysis-order_(\d{4})(\d{2})(\d{2}).*$/;
	$DATA[$item]->{'year'} = $yeart;
	$DATA[$item]->{'month'} = $montht;
	$DATA[$item]->{'day'} = $dayt;
	$DATA[$item]->{'datetime'}=DateTime->new(year => $yeart,month => $montht, day => $dayt);
	if ($item != 0) {
		$DATA[$item]->{'income_prev'}=$DATA[$item-1]->{'income'};
		$DATA[$item]->{'delta'} = delta_days($DATA[$item]->{'datetime'},$DATA[$item-1]->{'datetime'});
	} 
}


# Now we iterate through our data to find the entries in the right year interval.
# We produce data columns with both the 'plain' data, as well as 'accumulative' data
# The first entry of the output file should start with $year0101, with values of 0 for cost and income
# The first real data-entry should contain proportional income from 'prev_month';
# A similar 'fitting' should be performed for the end of the year
# An entry for $year1231 should contain the same cost-value as the last real order-data
# The income data should , again, be proportional over whatever time has passed till the end of the year
# Output data format:
# date_ymd|filename|calc_delta|orig_delta|cost|cost_accum|income|income_accum|income_prev|income_prev_accum
my $FIRST_MATCH=-1;
my $LAST_MATCH;
my $SAVED_FIRST_INCOME;
my $cost_accum=0;
my $income_accum=0;
my $income_prev_accum=0;


for (my $j=0; $j<=$#DATA; $j++) {
  if ($DATA[$j]->{'year'} eq $year) {
	$LAST_MATCH=$j;
	if ("$j" eq "0") {
		$FIRST_MATCH=$j;
		print $DATA[$j]->{'year'}.$DATA[$j]->{'month'}.$DATA[$j]->{'day'}."|".
		$DATA[$j]->{'filename'}."|". 
		"0|0|".
		$DATA[$j]->{'cost'}."|".
		"0|".
		$DATA[$j]->{'income'}."|".
		"0|0|0\n";
		$SAVED_FIRST_INCOME=$DATA[$j]->{'income'};
	} elsif  ("$FIRST_MATCH" eq "-1") {
		$FIRST_MATCH=$j;

		# Now we get to calculate what the proportional income was for the first entry
		# if there was any previous entry. If not, use 0;
		my $TMP_PROP_PREV_INCOME;
		my $TMP_PROP_INCOME;
		my $LEFT_OVER_DAYS=0;
		if (! $DATA[$j]->{'delta'}) {	
			$TMP_PROP_PREV_INCOME=0;
			$TMP_PROP_INCOME=$DATA[$j]->{'income'};
			print "$first_day|NAN|NAN|0|0|0|0|0|0|0|0\n";
		} else {
			$TMP_PROP_PREV_INCOME=$DATA[$j]->{'income_prev'}/$DATA[$j]->{'delta'}*delta_days($DATA[$j]->{'datetime'},$first_day_dt);
			$TMP_PROP_INCOME=$DATA[$j]->{'income'}/$DATA[$j]->{'delta'}*delta_days($DATA[$j]->{'datetime'},$first_day_dt);
			$LEFT_OVER_DAYS=$DATA[$j]->{'delta'}-(delta_days($DATA[$j]->{'datetime'},$first_day_dt));
		}
		print "$first_day|NAN|NAN|$LEFT_OVER_DAYS|0|0|0|0|0|0|0|0\n";
		$SAVED_FIRST_INCOME=$TMP_PROP_INCOME;
	
			
		$cost_accum += $DATA[$j]->{'cost'};
		$income_accum += $TMP_PROP_INCOME;
		$income_prev_accum += $TMP_PROP_PREV_INCOME;

		# Now output data
		print $DATA[$j]->{'year'}.$DATA[$j]->{'month'}.$DATA[$j]->{'day'}."|". 
		$DATA[$j]->{'filename'}."|". 
		($DATA[$j]->{'delta'}-$LEFT_OVER_DAYS."|").
		$DATA[$j]->{'delta'}."|". 
		$DATA[$j]->{'cost'}."|". 
		$cost_accum."|". 
		"$TMP_PROP_INCOME|$income_accum|$TMP_PROP_PREV_INCOME|$income_prev_accum\n";
	} else { # simply update accumulative variables and output data
		# THere is one caveat. IF the first entry has a proportionally derived income; the income_prev of the NEXT entry
		# should reflect that.
		my $TMP_INCOME_PREV;
		if ($j==$FIRST_MATCH+1) {
			$TMP_INCOME_PREV=$SAVED_FIRST_INCOME
		} else {
			$TMP_INCOME_PREV=$DATA[$j]->{'income_prev'};
		}
	
		$cost_accum += $DATA[$j]->{'cost'};
		$income_accum += $DATA[$j]->{'income'};
		$income_prev_accum += $TMP_INCOME_PREV;

		print $DATA[$j]->{'year'}.$DATA[$j]->{'month'}.$DATA[$j]->{'day'}."|".
		$DATA[$j]->{'filename'}."|".
		$DATA[$j]->{'delta'}."|".
		$DATA[$j]->{'delta'}."|".
		$DATA[$j]->{'cost'}."|$cost_accum|".
		$DATA[$j]->{'income'}."|$income_accum|".
		$TMP_INCOME_PREV."|$income_prev_accum\n";
	}
  }
}



if ($DATA[$LAST_MATCH+1]) {
	my $NEXT=$LAST_MATCH+1;
	my $TMP_PROP_INCOME=$DATA[$NEXT]->{'income'}/$DATA[$NEXT]->{'delta'}*(delta_days($last_day_dt,$DATA[$LAST_MATCH]->{'datetime'}));
	my $TMP_PROP_PREV_INCOME=$DATA[$NEXT]->{'income_prev'}/$DATA[$NEXT]->{'delta'}*(delta_days($last_day_dt,$DATA[$LAST_MATCH]->{'datetime'}));
	$income_accum += $TMP_PROP_INCOME;
	$income_prev_accum += $TMP_PROP_PREV_INCOME;
	
	print "$year"."1231|NAN|".
	delta_days($last_day_dt,$DATA[$LAST_MATCH]->{'datetime'})."|".
	$DATA[$NEXT]->{'delta'}."|".
	$DATA[$LAST_MATCH]->{'cost'}."|".
	"$cost_accum|$TMP_PROP_INCOME|$income_accum|$TMP_PROP_PREV_INCOME|$income_prev_accum\n";
}


sub delta_days() {
	my $dt1 = shift @_;
	my $dt2 = shift @_;
	
	my @DT1 = $dt1->utc_rd_values;
	my @DT2 = $dt2->utc_rd_values;
	return ($DT1[0]-$DT2[0]);
}
	

sub not_negative() {
	my $filename=shift @_;

	my @TEMP=fetch_drinks_only($filename);
	return ($TEMP[4] > 0);
}


sub fetch_drinks_only() {
	my $filename=shift @_;

	my $result;	
	open (my $FH, "< $filename") || die "Could not open $filename; $!";
	while (<$FH>) {
		if ($_=~/^ORDER|DRINKS_ONLY/) {
			$result=$_;
		}
	}
	close $FH;
	return(split(/\|/, $result));
}	

