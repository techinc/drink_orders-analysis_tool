#!/usr/bin/perl -w

use strict;

use DateTime;
use Getopt::Long;

my $usage = <<'END_MESSAGE';
Usage: date-match.pl --directory <DIR> --start <DATE> [--end <DATE>]

The tool will return all files between 'start' and 'end' date found in directory <DIR>. Files are matched by NAME with the last segment of the filename checked to see if it's an ISO-standard YYYMMDD date-format.

	--directory	Directory to parse dates in. The 
	--start		Start date of interval
	--end		End date of interval. If empty assumed to be now();
END_MESSAGE

my $dir;
my $start;
my $dt_start;
my $end;
my $dt_end;

if (!GetOptions (	"directory=s"=> \$dir,
		"start=s" => \$start,
		"end=s" => \$end) 
) {
	print $usage;
	exit 1;
}

if ("z$dir"eq"z") {
	print $usage;
	exit;
}
if ("z$start"eq"z") {
        print "No (valid) start-date defined\n";
        print $usage;
        exit 1
} else {
	my @ret;
	@ret = $start =~ m/(\d{4})(\d{2})(\d{2})/;
	$dt_start=DateTime->new (
		year	=>	$ret[0],
		month	=>	$ret[1],
		day	=>	$ret[2],
	) or die "invalid date";
}
if (!$end) {
	$dt_end=DateTime->now;
	#print "No end-date supplied for interval\n";
	#print "Assuming now(); ";
	#print $dt_end->year.$dt_end->month.$dt_end->day;
	#print "\n";
}

opendir(my $dh, $dir) || die "Can't opendir $dir: $!";

while (readdir $dh) {
#	print "$dir -> $_\n";
	my $date;
	if (($date)=$_=~/.*(\d{8})$/) {
		my @ret;
		@ret=$date=~/(\d{4})(\d{2})(\d{2})/;
		my $dt_date=DateTime->new (
			year =>	$ret[0],
			month=> $ret[1],
			day  =>	$ret[2],
		) or next;

		if ($dt_date->epoch <= $dt_end->epoch and $dt_date->epoch >= $dt_start->epoch) {
			#print $dt_start->epoch." - ".$dt_date->epoch." - ".$dt_end->epoch."\n";
			print "$dir/$_\n";
		}
	}
	
	
}

closedir $dh;
