#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd 'abs_path';

my $in_taxids = "$Bin/../DB/tama/CLARK/.custom.fileToTaxIDs";
my $in_tax_rank = shift;

my %hs_rank = ();
my $i = 0; 
foreach my $r ("species", "genus", "family", "order", "class", "phylum"){
	$hs_rank{$r} = $i;
	$i++;
}
open(FTX, "$in_taxids");
open(FOUT, ">$Bin/../DB/tama/CLARK/targets.txt");
while(<FTX>){
	chomp;
	my ($file, $taxid, @t_rank) = split(/\s+/,$_);
	if($t_rank[$hs_rank{$in_tax_rank}] eq "UNKNOWN"){ next; }
	print FOUT "$file\t$t_rank[$hs_rank{$in_tax_rank}]\n";
}
close(FTX);

