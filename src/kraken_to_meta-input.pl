#!/usr/bin/perl
use warnings;
use strict;

my $kraken = $ARGV[0];
my $rank_link = $ARGV[1];
my $result = $ARGV[2];


my %rank = ();	
open RANK, "$rank_link";
while (<RANK>){
	chomp;
	my @split = split (/ = /, $_);

	$rank{$split[0]} = $split[1];
}
close RANK;

if($kraken =~ /.gz$/){ open(KRAKEN, "gunzip -c $kraken |"); }
else{
open KRAKEN, "$kraken";
}

open RESULT, ">$result";
while (<KRAKEN>){
	chomp;
	my @split = split(/\s+/, $_);
	if($split[1] =~ /\/1$/){ $split[1] = substr($split[1],0,-2); }

	if ($split[0] eq "U"){	print RESULT "$split[1]\tNA\t0\n";	}
	else {
		if (exists $rank{$split[2]}){
			my $score=0;	my $rank=0;	my $length=0;
		
			for (my $i=4; $i<=$#split; $i++){
				my @split_c = split (/:/, $split[$i]);
				
				if (exists $rank{$split_c[0]} && $rank{$split_c[0]} == $rank{$split[2]}){
					$score = $score+$split_c[1];
				}

				if ($split_c[0] =~ /^\d/){	$length = $length+$split_c[1];	}
			}

			$score = $score/$length;

			print RESULT "$split[1]\t$rank{$split[2]}\t$score\n";
		}
		else {	print RESULT "$split[1]\tNA\t0\n";	}
	}
}
close RESULT;
close KRAKEN;
