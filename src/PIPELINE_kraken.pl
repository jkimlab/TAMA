#!/usr/bin/env perl
use warnings;
use strict;

use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';

my $kraken = "$Bin/../tools/kraken";
my $dbdir = abs_path("$Bin/../DB");

my $help;
my $threads;
my $parameter;
my $rank;
my $project;
my $database;
my $outdir;


my $options = GetOptions (
			"cpu=s" => \$threads,
			"params=s" => \$parameter,
		);

sub HELP{
	my $src = basename($0);
	print "\nUsage: $src [options] <filename(s)>\n\n";
	print "\t-cpu <integer> Number of threads (default:1)\n";
	print "\t-params <filename>\n";
	print "\t-h|help print this page\n\n";
	exit;
}


###	Help prints
if (!defined $parameter){	HELP();	}

### Options
$threads = 1 unless defined $threads;

### Parameter
my @new_seq = ();
my @outdirs = ();

my @single_r = ();
my @paired_1 = ();
my @paired_2 = ();

open PARA, "$parameter";
while (<PARA>){
	chomp;
	if ($_ =~ /^#/){	next;	}
	else {
		if ($_ =~ /=/){
			my @split = split (/=/, $_);
			if ($split[0] eq "PROJECTPATH"){
				$outdir = $split[1];
				chdir ($outdir);

				my @split_name = split (/\//, $_);
				$project = $split_name[-1];
			}
			elsif ($split[0] eq "DBNAME"){	$database = $split[1];	}
			elsif ($split[0] eq "RANK"){
				if ($split[1] ne ""){	$rank = $split[1];	}
				else {	$rank = "species";	}
			}
			elsif ($split[0] eq "SINGLE"){
				if ($_ =~ /=$/){	push (@single_r, " ");	}
				else {	push (@single_r, $split[1]);	}
			}
			elsif ($split[0] eq "PAIRED1"){
				if ($_ =~ /=$/){	push (@paired_1, " ");	}
				else {	push (@paired_1, $split[1]);	}
			}
			elsif ($split[0] eq "PAIRED2"){
				if ($_ =~ /=$/){	push (@paired_2, " ");	}
				else {	push (@paired_2, $split[1]);	}
			}
		}
		elsif ($_ =~ /^>/){
			my @split = split (/>/, $_);

			push (@outdirs, $split[1]);
		}
		elsif ($_ =~ /^\//){	push (@new_seq, $_);	}
	}
}
close PARA;


### kraken database
my $link_file = abs_path("$dbdir/$database/taxonomy_data/$rank.link");
$database = "$dbdir/$database/kraken";
$database = abs_path($database);


### kraken Classification

print "\t(kraken) Classification ...\n";
print "\t(kraken) Project: $project\n";

for (my $i=0; $i<=$#outdirs; $i++){
	my @split_name = split (/\//, $outdirs[$i]);

	`mkdir -p ./$split_name[-1]/kraken`;
	chdir ("./$split_name[-1]/kraken/");
	print "\t(kraken) $split_name[-1]";
	
	if (-e "./$split_name[-1]"){	`rm -f ./$split_name[-1]`;	}


# Classification

	if (exists $single_r[$i]){
		if ($single_r[$i]  ne " "){
			print "\tSingle";
			`$kraken/kraken --preload --db $database --threads $threads --output $split_name[-1].single --fastq-input $single_r[$i] 2> $split_name[-1].single.log`;
		}
	}
	
	if (exists $paired_1[$i] && exists $paired_2[$i]){
		if ($paired_1[$i] ne " " && $paired_2[$i] ne " "){
			print "\tPaired";
			`$kraken/kraken --preload --db $database --threads $threads --output $split_name[-1].paired --fastq-input --paired $paired_1[$i] $paired_2[$i] 2> $split_name[-1].paired.log`;
		}
	}

		if (-e "$split_name[-1]\.single"){
			`cat $split_name[-1].single > $split_name[-1]`;
		}
		if (-e "$split_name[-1]\.paired"){
			`cat $split_name[-1].paired >> $split_name[-1]`;
		}

# Making the meta-input

	print "\n\t(kraken) Taxonomic rank: $rank\n";
	`$Bin/kraken_to_meta-input.pl $split_name[-1] $link_file ./metainput`;
	
	chdir($outdir);
}


