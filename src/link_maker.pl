#!/usr/bin/perl
use strict;
use warnings;

my $in_nodes = $ARGV[0]; 
my $target = $ARGV[1];
my $out_file = $ARGV[-1];

my %hs_all_nodes = ();
if($in_nodes =~ /.gz$/){ open(FNODES, "gunzip -c $in_nodes |"); }
else{ open(FNODES, "$in_nodes"); }
while(<FNODES>){
	chomp;
	my @t = split(/\t/,$_);
	$hs_all_nodes{$t[0]} = "$t[2]\t$t[4]";
}
close(FNODES);

open(FOUT, ">$out_file");
my %hs_phylum = ();
foreach my $k (sort {$a<=>$b} keys %hs_all_nodes){
	my $update_id = $k;
	my $phylum = "";
	while(1){
		my @t = split(/\t/,$hs_all_nodes{$update_id});
		if($t[1] eq "no rank" && $t[0] == 1){ last; }
		if($t[1] eq "$target"){
			$hs_phylum{$k} = $update_id;
			print FOUT "$k = $update_id\n";
			last;
		}
		else{
			$update_id = $t[0];
		}
	}
}
close(FOUT);
