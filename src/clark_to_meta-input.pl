#!/usr/bin/perl
use strict;
use warnings;

my $clark_result = $ARGV[0];
my $spc_link = $ARGV[1];
my $out_file = $ARGV[2];

my %hs_spc_link = ();
open(FSPC, "$spc_link");
while(<FSPC>){
		chomp;
		my @t = split(/\s+/,$_);
		$hs_spc_link{$t[0]} = $t[2];
}
close(FSPC);

if($clark_result =~ /.gz$/){ open(FCLARK, "gunzip -c $clark_result|"); }
else{ open(FCLARK, "$clark_result"); }
open(FOUT, ">$out_file");
while(<FCLARK>){
		chomp;
		if($_ =~ /^Object_ID/){ next; }
		my @t = split(/,/,$_);
		my ($first_assign, $second_assign) = ("", "");
		my ($first_score, $second_score) = (0, 0);
		if(!exists $hs_spc_link{$t[3]} && $t[3] ne "NA"){ die "$t[3].\n"; }

		if(exists $hs_spc_link{$t[3]}){ $first_assign = $hs_spc_link{$t[3]}; }
		else{ $first_assign = $t[3]; }
		$first_score = $t[4];

		if(exists $hs_spc_link{$t[5]}){ $second_assign = $hs_spc_link{$t[5]}; }
		else{ $second_assign = $t[5]; }
		$second_score = $t[6];

		if($first_assign eq $second_assign){
				$first_score += $second_score;
				$second_score = 0;
		}

		if($first_score == 0 && $second_score == 0){
				print FOUT "$t[0]\tNA\t0\n";
		}
		else{
			my $confidence_score = ($first_score)/($first_score+$second_score);
			my $normalized_cs = ($confidence_score-0.5)/(1-0.5);
			print FOUT "$t[0]\t$first_assign\t$normalized_cs\n";
		}
}
close(FOUT);
close(FCLARK);
