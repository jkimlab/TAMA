#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd 'abs_path';

my $example_ref_path = abs_path("$Bin/../examples");
my $in_list = "$example_ref_path/custom_ref_data/LIST";
open(FREX, ">$Bin/../examples/ref_list.example");
open(FLIST, $in_list);
while(<FLIST>){
		chomp;
		my ($file_name, $tax_id) = split(/\s+/,$_);
		print FREX "$example_ref_path/custom_ref_data/$file_name.gz\t$tax_id\n";
}
close(FLIST);
close(FREX);
