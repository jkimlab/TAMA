#!/usr/bin/env perl
use strict;
use warnings;

my $in_read_profile = $ARGV[0];
my $out_file = $ARGV[-1];

my %hs_total_mscore = ();
my %hs_taxon_cnt = ();
if($in_read_profile =~ /.gz$/){ open(FR, "gunzip -c $in_read_profile|"); }
else{ open(FR, "$in_read_profile"); }
while(<FR>){
		chomp;
		my ($readid, $taxonid, $metascore) = split(/\t/,$_);
		if($taxonid eq "NA"){ next; }
		my @t_id = split(/,/,$taxonid);
		for(my $i = 0; $i <= $#t_id; $i++){
				if(!exists($hs_taxon_cnt{$t_id[$i]})){
						$hs_taxon_cnt{$t_id[$i]} = 1;
						$hs_total_mscore{$t_id[$i]} = $metascore;
				}
				else{
						$hs_taxon_cnt{$t_id[$i]} += 1;
						$hs_total_mscore{$t_id[$i]} += $metascore;
				}
		}
}
close(FR);

open(FOUT, ">$out_file");
foreach my $t (sort {$a<=>$b} keys(%hs_taxon_cnt)){
		my $avg = sprintf("%.5f",($hs_total_mscore{$t}/$hs_taxon_cnt{$t}));
		print FOUT "$t\t$hs_taxon_cnt{$t}\t$avg\t$hs_total_mscore{$t}\n";
}
