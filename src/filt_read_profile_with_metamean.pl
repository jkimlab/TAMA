#!/usr/bin/perl
use strict;
use warnings;

my $in_metamean = $ARGV[0]; # ex. tdb.sim.metascore_stat.txt
my $in_read_profile = $ARGV[1]; # ex. TDB_SimRead_10spc_1.25_3/TAMA_0.result 
my $cutoff = $ARGV[2];
my $out_file = $ARGV[-1];

my %hs_metamean = ();
open(FM, "$in_metamean");
while(<FM>){
		chomp;
		my ($taxon_id, $cnt, $mean, $total) = split(/\t/,$_);
		if($taxon_id eq "NA"){ next; }
		$hs_metamean{$taxon_id} = $mean;
}
close(FM);
open(FOUT, ">$out_file");
if($in_read_profile =~ /.gz$/){ open(FRP, "gunzip -c $in_read_profile|"); }
else{ open(FRP, "$in_read_profile"); }
while(<FRP>){
		chomp;
		my ($read_id, $taxon_id, $meta_score) = split(/\t/,$_);
		if($taxon_id eq "NA"){
				print FOUT "$read_id\t$taxon_id\t$meta_score\n"; 
				next;
		}
		my @t_id = split(/,/,$taxon_id);
		my @new_taxon_id;
		for(my $i = 0; $i <= $#t_id; $i++){
				if($hs_metamean{$t_id[$i]} >= $cutoff){
						push(@new_taxon_id,$t_id[$i]);
				}
		}
		my $new_t = join(",",@new_taxon_id);
		if($new_t eq ""){ print FOUT "$read_id\tNA\t$meta_score\n"; }
		else{ print FOUT "$read_id\t$new_t\t$meta_score\n"; }
}
close(FRP);

