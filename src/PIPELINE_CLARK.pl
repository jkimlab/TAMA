#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';

## Basic variables
my $clark_path = abs_path("$Bin/../tools/CLARKSCV1.2.6");
my $db_path = abs_path("$Bin/../DB");
my $link_file;
my $clark_k = 31;
my $taxonomy_rank;
## Input
my $module_params;
my $cpu;
my $project;
my $db_name;
my $db_seq;
my $in_single_list;
my $in_paired1_list;
my $in_paired2_list;
my $single_result_list;
my $paired_result_list;
my %hs_prefix=();
my %hs_taxonomy = ();
foreach my $t ("species","genus","family","order","class","phylum"){
		$hs_taxonomy{$t} = 1;
}
my $options = GetOptions(
		"params=s" => \$module_params,
		"cpu=i" => \$cpu,
);
if(!defined($module_params)){
		print "# Error: There is no parameters.\n";
		my $src = basename($0);
		print "\tUsage: $src -params <module params> -cpu <number of threads>\n\n";
		exit;
}
if(!defined($cpu)){ $cpu=1; }
$module_params = abs_path("$module_params");
my $out_dir = "";
my ($file1, $file2) = ("", "");
my $data_type = "";
chdir("$clark_path");
open(FP, "$module_params");
while(<FP>){
	chomp;
	if($_ =~ /^RANK=(\S+)/){
		$taxonomy_rank = lc($1);
	}
	if($_ =~ /^DBNAME=(\S+)/){
		my $db_dir = $1;
		$link_file = "$db_path/$db_dir/taxonomy_data/$taxonomy_rank.link";
		$db_path .= "/$db_dir/CLARK";
		my $db_address = "$db_path";
		if($db_dir ne "tama"){ `./set_targets.sh $db_path custom --$taxonomy_rank`; }
		else{
				my $target_index = "";
				if($taxonomy_rank eq "species"){
						$db_address .= "/custom_0";
						`cat $db_path/taxonomy/species_targets.txt > $db_path/targets.txt`;
				}
				elsif($taxonomy_rank eq "genus"){
						$db_address .= "/custom_1";
						`cat $db_path/taxonomy/genus_targets.txt > $db_path/targets.txt`;
				}
				elsif($taxonomy_rank eq "family"){
						$db_address .= "/custom_2";
						`cat $db_path/taxonomy/family_targets.txt > $db_path/targets.txt`;
				}
				elsif($taxonomy_rank eq "order"){
						$db_address .= "/custom_3";
						`cat $db_path/taxonomy/order_targets.txt > $db_path/targets.txt`;
				}
				elsif($taxonomy_rank eq "class"){
						$db_address .= "/custom_4";
						`cat $db_path/taxonomy/class_targets.txt > $db_path/targets.txt`;
				}
				elsif($taxonomy_rank eq "phylum"){
						$db_address .= "/custom_5";
						`cat $db_path/taxonomy/phylum_targets.txt > $db_path/targets.txt`;
				}
				`echo $db_path > ./.DBDirectory`;
				`echo $db_address > .dbAddress`;
				`echo -T $db_path/targets.txt > .settings`;
				`echo -D $db_address/ >> .settings`;
		}
	}
	if($_ =~ /^>(\S+)/){ 
		$out_dir = abs_path("$1/CLARK");
		`mkdir -p $out_dir`;
	}
	if($_ =~ /^SINGLE=(\S+)/){
		if(-f $1){
			print STDERR "\t[CMD] ./classify_metagenome.sh -k $clark_k -O $1 -R $out_dir/S.result -n $cpu -m 0\n";
			`./classify_metagenome.sh -k $clark_k -O $1 -R $out_dir/S.result -n $cpu -m 0`;
			$data_type = "S";
		}
	}
	if($_ =~ /^PAIRED1=(\S+)/){
		if(-f $1){ $file1 = $1; }
	}
	if($_ =~ /^PAIRED2=(\S+)/){
		if(-f $file1 && -f $1){
			$file2 = $1;
			print STDERR "\t[CMD] ./classify_metagenome.sh -k $clark_k -P $file1 $file2 -R $out_dir/P.result -n $cpu -m 0\n";
			`./classify_metagenome.sh -k $clark_k -P $file1 $file2 -R $out_dir/P.result -n $cpu -m 0`;
			$data_type .= "P";
		}
	}
}
close(FP);
if($data_type eq "S"){ `mv $out_dir/S.result.csv $out_dir/clark_result.csv`; }
elsif($data_type eq "P"){ `mv $out_dir/P.result.csv $out_dir/clark_result.csv`; }
elsif($data_type eq "SP"){
	`cat $out_dir/S.result.csv $out_dir/P.result.csv > $out_dir/clark_result.csv`;
	`rm $out_dir/S.result.csv $out_dir/P.result.csv`;
}
print STDERR "[CMD] $Bin/clark_to_meta-input.pl $out_dir/clark_result.csv $link_file $out_dir/metainput\n";
`$Bin/clark_to_meta-input.pl $out_dir/clark_result.csv $link_file $out_dir/metainput`;
