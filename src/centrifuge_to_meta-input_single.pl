#!/usr/bin/perl

use strict;
use warnings;

my $in_results = shift;
my $in_spc_link = shift;
my $in_read_1 = shift;

my %hs_spc_link = ();
open F,"$in_spc_link";
while(<F>)
{
	chomp;
	my @t = split(/\s+/);
	$hs_spc_link{$t[0]} = $t[2];
}

my %read_header = ();
if($in_read_1 =~ /.gz$/){ open(F3, "gunzip -c $in_read_1|"); }
else{ open(F3, "$in_read_1"); }
while(<F3>)
{
	chomp;
	my $t = substr($_,1);
	my $l2 = <F3>;
	my $len = length($l2) - 1;
	my $score = ($len - 15) * ($len - 15);
	my $l3 = <F3>;
	my $l4 = <F3>;
	if($_ =~ /\s+/)
	{
		my @rid = split(/\s+/,$t);
		$read_header{$rid[0]} = $score;
	}
	else
	{
		my @rid = split(/\//,$t);
		$read_header{$rid[0]} = $score;
	}
}
close F3;

my %tid = ();
my %score = ();
my $spc_tid = "";
my $norm_score = 0;
if($in_results =~ /.gz$/){ open(F2, "gunzip -c $in_results|"); }
else{ open(F2, "$in_results"); }
open F2,"$in_results";
while(<F2>)
{
	chomp;
	next if /^readID/;
	my @t = split(/\s+/);
	if(exists $hs_spc_link{$t[2]} && ($t[2] =~ /\d+/))
	{
#print "RID - $t[0] , score - $t[3] , max - $read_header{$t[0]}\n";
		$spc_tid = $hs_spc_link{$t[2]};
		$norm_score = ($t[3]-1)/($read_header{$t[0]}-1);
		$tid{$t[0]}{$spc_tid}++;
		$score{$t[0]} = "$norm_score";
	}
}
close F2;

foreach my $rheader (sort keys %read_header)
{
	if(exists $tid{$rheader})
	{
		print "$rheader\t";
		foreach my $tids (keys %{$tid{$rheader}})
		{
			print "$tids," x $tid{$rheader}{$tids};
		}
		print "\t$score{$rheader}\n";
	}
	else
	{
		print "$rheader\tNA\t0\n";
	}
}

