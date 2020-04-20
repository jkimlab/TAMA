#!/usr/bin/perl

use strict;
use warnings;
use FindBin '$Bin';
use File::Basename;
use Sort::Key::Natural 'natsort';

my $param_f = shift;
my $input_f = shift;
#my $names_f = shift; ## names.dmp file
#my $sizes_f = shift; ## tax.avg.sizes file
my $minReadCount = shift; ## Use >= minCount

##### Read parameter file #####
my $db_name = "";
my $ref_fa = "";
my $rank = "";
my %multi_sample = ();

if($param_f =~ /.gz$/){ open(F, "gunzip -c $param_f|"); }
else{
		open(F,"$param_f");
}
while(<F>){
	chomp;
	if($_ =~ /^#/||$_ eq ""){next;}
	elsif($_ =~ /^>/){
		my @arr = split(/>/);
		my $sample_name = basename($arr[1]);
		$multi_sample{$sample_name} = $arr[1];
	} else {
		my @arr = split(/=/);
		if($arr[0] eq "DBNAME"){
			$db_name = $arr[1];
		} elsif($arr[0] eq "SEQUENCE"){
			$ref_fa = $arr[1];
		} elsif($arr[0] eq "RANK"){
			$rank = $arr[1];
		}
	}
}
close(F);

##### PATH info #####
my $names_f = "";
if(-f "$Bin/../DB/$db_name/taxonomy_data/names.dmp"){ ## names.dmp file
		$names_f = "$Bin/../DB/$db_name/taxonomy_data/names.dmp";
}
if(-f "$Bin/../DB/$db_name/taxonomy_data/names.dmp.gz"){ ## names.dmp file
		$names_f = "$Bin/../DB/$db_name/taxonomy_data/names.dmp.gz";
}
my $sizes_f = "$Bin/../DB/$db_name/taxonomy_data/tax.avg.sizes"; ## tax.avg.sizes file

##### Read taxonomy => name data #####
my %tax2name;

if($names_f =~ /\.gz$/){
	open(F,"gunzip -c $names_f |");
} else {
	open(F,"$names_f");
}
while(<F>){
	chomp;
	$_ =~ s/\t+//g;
	my @arr = split(/\|/);
	if($arr[3] eq "scientific name"){
		$tax2name{$arr[0]} = $arr[1];
	}
}
close(F);

##### Read average genome size #####
my %sizes;
if($rank eq "species"){
	if($sizes_f =~ /\.gz$/){
		open(F,"gunzip -c $sizes_f |");
	} else {
		open(F,"$sizes_f");
	}
	while(<F>){
		chomp;
		my @arr = split(/\s+/);
		$sizes{$arr[0]} = $arr[1];
	}
	close(F);
}

##### Calculate abundances #####
foreach my $sample_name (natsort keys %multi_sample){
	my %hs_tax = ();
	$hs_tax{'NA'}=0;
	my $total_gi_size = 0;
	my $meta_out_f = $input_f;
	if(!-f $meta_out_f){next;}
	if($meta_out_f =~ /\.gz$/){
		open(F,"gunzip -c $meta_out_f|");
	} else {
		open(F,"$meta_out_f");
	}
	while(<F>){
		chomp;
		my ($read,$tax_id,$score) = split(/\s+/);
		if($tax_id =~ /,/){
			my @tax_arr = split(/,/,$tax_id);
			if($#tax_arr > 0){
				my %hs_tmp = ();
				my %hs_tmp2 = ();
				foreach my $t_id (@tax_arr){
					if(exists $hs_tmp{$t_id}){
						$hs_tmp{$t_id}++;
					} else {
						$hs_tmp{$t_id} = 1;
					}
				}
				foreach my $t_id (keys %hs_tmp){
					$hs_tmp2{$hs_tmp{$t_id}}{$t_id} = 0;
				}
				my $max_num = (reverse(natsort keys %hs_tmp2))[0];
				my @tids = keys %{$hs_tmp2{$max_num}};
				if($#tids > 0){
					my $t_id = 'NA';
					if(exists $hs_tax{$t_id}){
						$hs_tax{$t_id}++;
					} else {
						$hs_tax{$t_id} = 1;
					}
				} else {
					my $t_id = $tids[0];
					if(exists $hs_tax{$t_id}){
						$hs_tax{$t_id}++;
					} else {
						$hs_tax{$t_id} = 1;
					}
				}
			} else {
				my $t_id = $tax_arr[0];
				if(exists $hs_tax{$t_id}){
					$hs_tax{$t_id}++;
				} else {
					$hs_tax{$t_id} = 1;
				}
			}
		} else {
			if(exists $hs_tax{$tax_id}){
				$hs_tax{$tax_id}++;
			} else {
				$hs_tax{$tax_id} = 1;
			}
		}
	}
	close(F);
	
	my $total_read = 0;
	foreach my $tax_id (keys %hs_tax){
		if($hs_tax{$tax_id} >= $minReadCount){
			$total_read += $hs_tax{$tax_id};
		} else {
			delete $hs_tax{$tax_id};
		}
	}

	my %hs_ratio;
	my $na_ratio = 0;
	my %hs_abd;
	my $total_countSize = 0;
	foreach my $tax_id (keys %hs_tax){
		my $ratio = $hs_tax{$tax_id}/$total_read;
		if($tax_id eq "NA"){
			$na_ratio = $ratio;
		} else {
			if($rank ne "species"){
				$hs_ratio{$ratio}{$tax_id} = $tax2name{$tax_id};
				$hs_abd{$tax_id} = "-";
				$sizes{$tax_id} = "-";
			} else {
				if(!exists $sizes{$tax_id}){
					print STDERR "No size $tax_id\n";
				} else {
					$hs_ratio{$ratio}{$tax_id} = $tax2name{$tax_id};
					my $count_size = $hs_tax{$tax_id}/$sizes{$tax_id};
					$hs_abd{$tax_id} = $count_size;
					$total_countSize += $count_size;
				}
			}
		}
	}

	if($rank eq "species"){
		foreach my $tax_id (keys %hs_abd){
			my $count_size = $hs_abd{$tax_id};
			$hs_abd{$tax_id} = $count_size/$total_countSize;
		}
	}

	my %sort_abundance = ();
	foreach my $ratio (sort{$b<=>$a} keys %hs_ratio){
		foreach my $tax_id (sort keys %{$hs_ratio{$ratio}}){
			$sort_abundance{$hs_abd{$tax_id}}{$tax_id} = "$hs_ratio{$ratio}{$tax_id}\t$tax_id\t$sizes{$tax_id}\t$ratio\t$hs_tax{$tax_id}\t$total_read\t$hs_abd{$tax_id}";
		}
	}
	
	print "Scientific name\tTaxonomy ID\tGenome size\tRatio\t# of Read count\t# of Total read\tAbundance\n";
	print "NA\tNA\tNA\t$na_ratio\t$hs_tax{'NA'}\t$total_read\t-\n";
	foreach my $abd (sort{$b<=>$a} keys %sort_abundance){
		foreach my $tax_id (natsort keys %{$sort_abundance{$abd}}){
			print "$sort_abundance{$abd}{$tax_id}\n";
		}
	}
}
