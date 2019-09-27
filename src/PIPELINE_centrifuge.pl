#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';

my $centrifuge_path = abs_path("$Bin/../tools/centrifuge-1.0.3-beta/");
my $db_path = abs_path("$Bin/../DB");
my $src = abs_path("$Bin/");
my $taxonomy_path = abs_path("$Bin/../DB/taxonomy_data");

##INPUT
my $module_params;
my $cpu;
my $project;
my $rank;
my $db_name;
my $db_seq;
my $in_single;
my $in_paired1;
my $in_paired2;
my %hs_inputs = ();

my $options = GetOptions (
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

print STDERR "\n\tModule parameter check...\n";
open FPARAM,"$module_params";
while(<FPARAM>)
{
	chomp;
	next if /^#/;
	if($_ =~ /^PROJECTPATH=/)
	{
		my @t = split(/=/,$_);
		if(!defined($t[1]))
		{
			print "# ERROR: Please set project path.\n";
			exit;
		}
		$project = $t[1];
#`mkdir -p $project/centrifuge.test`;
	}
	elsif($_ =~ /^RANK=/)
	{
		my @t = split(/=/,$_);
		if(!defined($t[1]))
		{
			$rank = "species";
		}
		else
		{
			$rank = $t[1];
		}
	}
	elsif($_ =~ /^DBNAME=/)
	{
		my @t = split(/=/,$_);
		if(!defined($t[1]))
		{
			print "# ERROR: Please set DATABASE.\n";
			exit;
		}
		$db_name = $t[1];
		`mkdir -p $db_path/$db_name/centrifuge`;
	}
	elsif($_ =~ /^>(\S+)/)
	{
		my $prefix_path = abs_path($1);
		my $prefix = basename($1);
		`mkdir -p $prefix_path/centrifuge`;
		$in_single = <FPARAM>; chomp($in_single);
		$in_paired1 = <FPARAM>; chomp($in_paired1);
		$in_paired2 = <FPARAM>; chomp($in_paired2);
		my @t = split(/=/,$in_single);
		if(defined($t[1]))
		{
			$hs_inputs{$prefix_path}{"single"} = $t[1];
		}
		my @p1 = split(/=/,$in_paired1);
		my @p2 = split(/=/,$in_paired2);
		if(!defined($p1[1]) && defined($p2[1]))
		{
        	print "# Error: There is no forward read file.\n";
            exit;
        }
        elsif(defined($p1[1]) && !defined($p2[1]))
		{
            print "#Error: There is no reverse read file.\n";
            exit;
        }
        elsif(defined($p1[1]) && defined($p2[1]))
		{
			$hs_inputs{$prefix_path}{"paired"} = "$p1[1]\t$p2[1]";
       	}
	}
}
close FPARAM;

my $stype = 0;
my $ptype = 0;
my $DB_file = "$db_path/$db_name/centrifuge/database.1.cf";
if(-e "$DB_file")
{
	foreach my $path(sort keys  %hs_inputs)
	{
		chdir("$path/centrifuge");
		my $cur = `pwd -P`;
		print "Current path: $cur";
		foreach my $type(sort {$b cmp $a} keys %{$hs_inputs{$path}})
		{
			print "$type\n";
			if($type eq "single")
			{
				print "Read type: $type\n";
				print "$centrifuge_path/centrifuge -x $db_path/$db_name/centrifuge/database -k 100000 -p $cpu -U $hs_inputs{$path}{$type} --report-file $type\_report -S $type\_classification 2> $type.log\n\n";
				`$centrifuge_path/centrifuge -x $db_path/$db_name/centrifuge/database -k 100000 -p $cpu -U $hs_inputs{$path}{$type} --report-file $type\_report -S $type\_classification 2> $type.log`;
				`$Bin/centrifuge_to_meta-input_single.pl $type\_classification $Bin/../DB/$db_name/taxonomy_data/$rank.link $hs_inputs{$path}{$type} > metainput.single`;
				$stype = 1;
			}
			if($type eq "paired")
			{
				print "Read type: $type\n";
				my @pair = split(/\s+/,$hs_inputs{$path}{$type});
				print "$centrifuge_path/centrifuge -x $db_path/$db_name/centrifuge/database -k 100000 -p $cpu -1 $pair[0] -2 $pair[1] --report-file $type\_report -S $type\_classification 2> $type.log\n\n";;
				`$centrifuge_path/centrifuge -x $db_path/$db_name/centrifuge/database -k 100000 -p $cpu -1 $pair[0] -2 $pair[1] --report-file $type\_report -S $type\_classification 2> $type.log`;
				`$Bin/centrifuge_to_meta-input_paired.pl $type\_classification $Bin/../DB/$db_name/taxonomy_data/$rank.link $pair[0] $pair[1] > metainput.paired`;
				$ptype = 1;
			}
		}
		if($stype == 1 && $ptype == 1)
		{
			`cat metainput.single metainput.paired > metainput`;
		}
		elsif($stype == 1 && $ptype == 0)
		{
			`mv metainput.single metainput`;
		}
		elsif($stype == 0 && $ptype == 1)
		{
			`mv metainput.paired metainput`;
		}
		$stype = 0; $ptype = 0;
	}
}
else{
	print STDERR "Please check the centrifuge database\n";
	exit();
}
