#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd 'abs_path';

## Required
my $in_tools_name;
my $in_classi_out;
my $in_fscore;
my $in_meta_score_cutoff;
my $out_file;
my $help;

## Variables
my @arr_classi_out = ();
my @arr_tools_name = ();
my @arr_fscore = ();
my $total_fscore = 0;
my %hs_metascore = ();
my %hs_assigned_tool = ();

## Main Funtion
GETOPTS();
PREPROCESSING();
MAKEOUTPUT();

## Functions
sub MAKEOUTPUT{
		print STDERR "# Make output file.\n";
		open(FOUT, ">$out_file");
		my @arr_read = sort keys(%hs_metascore);
		foreach my $read (@arr_read){
			my @arr_taxa = sort {$a<=>$b} keys(%{$hs_metascore{$read}});
			my $ignored = shift(@arr_taxa);
			if($ignored != 0){ die "wrong\n"; }
			if($#arr_taxa == -1){
					print FOUT "$read\tNA\t0\n";
			}
			else{
					my $max_score = 0;
					my $final_taxa = "";
					for(my $n = 0; $n <= $#arr_taxa; $n++){
							my $cur_score = $hs_metascore{$read}{$arr_taxa[$n]};
							if($cur_score > $max_score){
									$final_taxa = $arr_taxa[$n];
									$max_score = $cur_score;
							}
							elsif($cur_score == $max_score){
									if($final_taxa eq ""){ $final_taxa = "$arr_taxa[$n]"; }
									else{ $final_taxa .= ",$arr_taxa[$n]"; }
							}
					}
					$max_score = sprintf("%.5f",$max_score);
					if($max_score < $in_meta_score_cutoff){
							print FOUT "$read\tNA\t$max_score\n";

					}
					else{
							print FOUT "$read\t$final_taxa\t$max_score\n";
					}
			}
		}
		print STDERR "Finished. \n\n";
}
sub PREPROCESSING{
		print STDERR "# Storing the scores for each taxonomy.\n";
		foreach my $fs (@arr_fscore){ $total_fscore += $fs; }
		for(my $i = 0; $i <= $#arr_tools_name; $i++){
				my $cur_tool = $arr_tools_name[$i];
				my $cur_metainput = $arr_classi_out[$i];
				my $cur_fscore = $arr_fscore[$i];
				print STDERR "\t*Current tool: $cur_tool\n\tF-score: $cur_fscore\n";
				if($cur_metainput =~ /.gz$/){ open(FINPUT, "gunzip -c $cur_metainput|"); }
				else{ open(FINPUT, "$cur_metainput"); }
				while(<FINPUT>){
						chomp;
						my ($read_id, $taxa_id, $score) = split(/\t/,$_);
						$hs_metascore{$read_id}{0} = -1;
						if($taxa_id =~ /NA/){ next; }
						if($taxa_id =~ /,/){
								my @arr_taxa = split(/,/,$taxa_id);
								foreach my $t (@arr_taxa){
										$hs_metascore{$read_id}{$t} += (($score/($#arr_taxa+1))*$cur_fscore)/$total_fscore;
										$hs_assigned_tool{$read_id}{$t} .= "$cur_tool ";
								}
						}
						else{
								$hs_metascore{$read_id}{$taxa_id} += ($score*$cur_fscore)/$total_fscore;
						}
				}
				close(FINPUT);
				print STDERR "\t$cur_tool is done.\n";
		}
}

sub GETOPTS{ # Get options
		my $status = GetOptions(
						"l=s" => \$in_tools_name,
						"i=s" => \$in_classi_out,
						"f=s" => \$in_fscore,
						"t=f" => \$in_meta_score_cutoff,
						"o=s" => \$out_file,
						"h|help" => \$help,
						);
		if($status != 1 || !defined($in_tools_name) || !defined($in_classi_out) || !defined($in_fscore) || !defined($out_file) || $help){ PRINTHELP(); }
		@arr_classi_out = split(/,/,$in_classi_out);
		@arr_tools_name = split(/,/,$in_tools_name);
		@arr_fscore = split(/,/,$in_fscore);
		if($#arr_classi_out != $#arr_tools_name){
				print STDERR "The number of classification tools does not match the number of files with meta-analysis input\n\n";
				PRINTHELP();
		}
		if(!defined($in_meta_score_cutoff)){ $in_meta_score_cutoff = 0; }
		my $src = basename($0);
		$src = abs_path($src);
		print STDERR "# running options:\n\tScript: $src\n\tCutoff: $in_meta_score_cutoff\n";
		for(my $i = 0; $i <= $#arr_tools_name; $i++){
				print STDERR "\t$arr_tools_name[$i]: $arr_classi_out[$i], $arr_fscore[$i]\n";
		}
}

sub PRINTHELP{
		my $src = basename($0);
		print "Usage: $src -i <meta-input1,meta-input2,...> -l <label1,label2,...> -t <cutoff> -o <output file>\n";
		print "\t-i <string> file with read_id assigned_taxa_id normalized_score.\n";
		print "\t-l <string> label of each file.\n";
		print "\t-f <decimal> F-score of each tool.\n";
		print "\t-t <decimal> threshold of meta-analysis. If the meta-score is less than this, the read is not assigned to any taxonomy. (default = 0).\n";
		print "\t-o <string> output file name.\n";
		exit;
}

