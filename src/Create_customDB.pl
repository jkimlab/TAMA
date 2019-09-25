#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use FindBin qw($Bin);

my $in_ref_list;
my $in_names;
my $in_nodes;
my $target_rank = "species";
my $in_cpu = 1;
my $out_dir;
my $help;

####### Input parameters
my $options = GetOptions(
				"ref=s" => \$in_ref_list,
				"names=s" => \$in_names,
				"nodes=s" => \$in_nodes,
				"p|cpu=i" => \$in_cpu,
				"rank=s" => \$target_rank,
				"o|out=s" => \$out_dir,
				"h|help" => \$help,
);
if(defined($help)){ PRINT_HELP(); }
if(!defined($in_ref_list) || !defined($in_names) || !defined($in_nodes)){ PRINT_HELP(); }
####### Paths
my $clark_path = "$Bin/../tools/CLARKSCV1.2.6";
my $kraken_path = "$Bin/../tools/kraken";
my $centrifuge_path = "$Bin/../tools/centrifuge-1.0.3-beta";
my $example_path = "$Bin/../examples/sample1.1.fq.gz";
if(!-f $example_path){
		$example_path = "$Bin/../examples/sample1.1.fq";
		if(!-f $example_path){
				print STDERR "<!> Please prepare the example datasets using the setup.pl script.\n";
				exit();
		}
}
`mkdir -p $Bin/../DB/$out_dir`;
$out_dir = abs_path("$Bin/../DB/$out_dir");
open(FLOG, ">$out_dir/custom_db_maker.log.txt");
print STDERR "Output directory: $out_dir\n";
print FLOG "Output directory: $out_dir\n";
$in_nodes = abs_path("$in_nodes");
$in_names = abs_path("$in_names");
####### Preprocessing
## 1. Loading sequence files
print STDERR "Preprocessing...\n";
print FLOG "Preprocessing...\n";
print STDERR "\t[1] Constructing data structure ..\n";
print FLOG "\t[1] Constructing data structure ..\n";
`mkdir -p $out_dir/CLARK/Custom $out_dir/tmp $out_dir/centrifuge $out_dir/kraken/taxonomy $out_dir/taxonomy_data`;
`cp $in_names $in_nodes $out_dir/taxonomy_data`;
my %hs_ref = ();
if($in_ref_list =~ /.gz$/){ open(FLIST, "gunzip -c $in_ref_list |"); }
else{ open(FLIST, "$in_ref_list"); }
while(<FLIST>){
		chomp;
		my ($file_path, $taxid) = split(/\t/,$_);
		if(!exists($hs_ref{$taxid})){
				$hs_ref{$taxid} = $file_path;
		}
		else{ $hs_ref{$taxid} .= "\t$file_path"; }
}
close(FLIST);
print STDERR "\t[2] Making taxonomy rank link file ..\n";
print FLOG "\t[2] Making taxonomy rank link file ..\n";
foreach my $rank ("species", "genus", "family", "order", "class", "phylum"){
		print STDERR "\t    -$rank.link ..\n";
		print FLOG "\t    -$rank.link ..\n";
		`$Bin/link_maker.pl $in_nodes $rank $out_dir/taxonomy_data/$rank.link`;
}
my %hs_spc_link = ();
open(FLINK, "$out_dir/taxonomy_data/species.link");
while(<FLINK>){
		chomp;
		my @t = split(/\s+/,$_);
		$hs_spc_link{$t[0]} = $t[2];
}
close(FLINK);
print STDERR "\t[3] Creating and reformatting input data ..\n";
print FLOG "\t[3] Creating and reformatting input data ..\n";
my $seq_num = 0;
my %hs_db_input = ();
my %hs_genome_size = ();
my %hs_file_num = ();
open(FKRAIDMAP, ">$out_dir/kraken/taxonomy/seqid2taxid.map");
open(FCENTIDMAP, ">$out_dir/centrifuge/seqid2taxid.map");
foreach my $tid (keys(%hs_ref)){
		my $cur_spc_id = $hs_spc_link{$tid};
		if(!exists($hs_genome_size{$cur_spc_id})){
				$hs_genome_size{$cur_spc_id} = 0;
				$hs_file_num{$cur_spc_id} = 0;
		}
		my @seq_size = ();
		my @files = split(/\t/,$hs_ref{$tid});
		my $file_num = 0;
		print STDERR "@files\n";
		foreach my $file_path (@files){
				$file_num++;
				$hs_file_num{$cur_spc_id} += 1;
				my $file_name = basename($file_path);
				print FLOG "\t... $file_name ($tid)\n";
				$hs_db_input{"$out_dir/CLARK/Custom/$tid.$file_num.fa"} = $tid;
				open(FNEWFA, ">$out_dir/CLARK/Custom/$tid.$file_num.fa");
				if($file_path =~ /.gz$/){ open(FFA, "gunzip -c $file_path|"); }
				else{ open(FFA, "$file_path"); }
				while(<FFA>){
						chomp;
						if($_ =~ /^>(.+)/){
								$seq_num++;
								print FNEWFA ">sequence$seq_num|kraken:taxid|$tid $1\n";
								print FKRAIDMAP "sequence$seq_num|kraken:taxid|$tid\t$tid\n";
								print FCENTIDMAP "sequence$seq_num|kraken:taxid\t$tid\n";
						}
						else{
								print FNEWFA "$_\n";
								$hs_genome_size{$cur_spc_id} += length($_);
						}
				}
				close(FFA);
				close(FNEWFA);
		}
}
close(FKRAIDMAP);
close(FCENTIDMAP);
print STDERR "\t[4] Calculating average genome size ..\n";
open(FSIZE, ">$out_dir/taxonomy_data/tax.avg.sizes");
foreach my $spc_id (sort {$a<=>$b} keys(%hs_genome_size)){
		my $avg_size = int($hs_genome_size{$spc_id} / $hs_file_num{$spc_id});
		print FSIZE "$spc_id\t$avg_size\n";
}
close(FSIZE);

## 2. Loading node information
print STDERR "Reading NCBI taxonomy tree information...\n";
print FLOG "Reading NCBI taxonomy tree information...\n";
my %hs_nodes = ();
my %hs_rank = ();
if($in_nodes =~ /.gz$/){ open(FNODE, "gunzip -c $in_nodes|"); }
else{ open(FNODE, "$in_nodes"); }
while(<FNODE>){
		chomp;
		my @t = split(/\t/,$_);
		$hs_nodes{$t[0]} = $t[2];
		$hs_rank{$t[0]} = $t[4];
}
close(FNODE);
print STDERR "Done.\n";
print FLOG "Done.\n";
####### Making CLARK db
print STDERR "Creating CLARK DB\n\t$out_dir/CLARK\n";
print FLOG "Creating CLARK DB\n\t$out_dir/CLARK\n";
`mkdir -p $out_dir/CLARK/taxonomy`;
`touch $out_dir/CLARK/.taxondata`;
my @files = keys(%hs_db_input);
open(FCT, ">$out_dir/CLARK/.custom.fileToTaxIDs");
open(FCA, ">$out_dir/CLARK/.custom.fileToAccssnTaxID");
for(my $i = 0; $i <= $#files; $i++){
		my $cur_file = abs_path($files[$i]);
		my ($s, $g, $f, $o, $c, $p) = ("-1", "-1", "-1", "-1", "-1", "-1");
		my $cur_taxid = $hs_db_input{$files[$i]};
		while(1){
				my $upper_taxid = $hs_nodes{$cur_taxid};
				my $upper_rank = $hs_rank{$cur_taxid};
				if($upper_taxid eq "1"){ last; }
				if($upper_rank eq "species"){ $s = $upper_taxid; }
				elsif($upper_rank eq "genus"){ $g = $upper_taxid; }
				elsif($upper_rank eq "family"){ $f = $upper_taxid; }
				elsif($upper_rank eq "order"){ $o = $upper_taxid; }
				elsif($upper_rank eq "class"){ $c = $upper_taxid; }
				elsif($upper_rank eq "phylum"){ $p = $upper_taxid; }
				$cur_taxid = $upper_taxid;
		}
		print FCT "$cur_file\t$hs_db_input{$files[$i]}\t$s\t$g\t$f\t$o\t$c\t$p\n";
		print FCA "$cur_file\tsequence\t$hs_db_input{$files[$i]}\n";
}
close(FCT);
close(FCA);
chdir($clark_path);
`./set_targets.sh $out_dir/CLARK custom --$target_rank`;
`./classify_metagenome.sh -k 31 -O /mss2/projects/META2/taxonomy_classification/TAMA_examples/sample1.1.fq -R $out_dir/tmp/CLARK_testout -n $in_cpu -m 0`;
####### Making kraken db
`cat $out_dir/CLARK/Custom/*.fa > $out_dir/tmp/custom_ref.fa`;
`rm -rf $out_dir/CLARK/Custom`;
print STDERR "Done.\n";
print FLOG "Done.\n";
print STDERR "Creating Kraken DB\n\t$out_dir/kraken\n";
print FLOG "Creating Kraken DB\n\t$out_dir/kraken\n";
if($in_nodes =~ /.gz$/){ `gunzip -c $in_nodes > $out_dir/kraken/taxonomy/nodes.dmp`; }
else{ `cp $in_nodes $out_dir/kraken/taxonomy/nodes.dmp`; }
if($in_names =~ /.gz$/){ `gunzip -c $in_names > $out_dir/kraken/taxonomy/names.dmp`; }
else{ `cp $in_names $out_dir/kraken/taxonomy/names.dmp`; }
`$kraken_path/kraken-build --add-to-library $out_dir/tmp/custom_ref.fa --db $out_dir/kraken`;
`$kraken_path/kraken-build --build --db $out_dir/kraken --kmer-len 31 --threads $in_cpu`;
`$kraken_path/kraken --db $out_dir/kraken /mss2/projects/META2/taxonomy_classification/TAMA_examples/sample1.1.fq --threads $in_cpu > $out_dir/tmp/kraken_testout`;
print STDERR "Done.\n";
print FLOG "Done.\n";
####### Making centrifuge db
print STDERR "Creating Centrifuge DB\n\t$out_dir/centrifuge\n";
print FLOG "Creating Centrifuge DB\n\t$out_dir/centrifuge\n";
`$centrifuge_path/centrifuge-build -p $in_cpu --conversion-table $out_dir/centrifuge/seqid2taxid.map --taxonomy-tree $out_dir/kraken/taxonomy/nodes.dmp --name-table $out_dir/kraken/taxonomy/names.dmp $out_dir/tmp/custom_ref.fa $out_dir/centrifuge/database >& $out_dir/centrifuge/centrifuge-build.log`;
`$centrifuge_path/centrifuge -x $out_dir/centrifuge/database -k 100000 -p $in_cpu -U /mss2/projects/META2/taxonomy_classification/TAMA_examples/sample1.1.fq --report-file $out_dir/tmp/centrifuge_testout_report -S $out_dir/tmp/centrifuge_testout_classification >& $out_dir/tmp/centrifuge_testout.log`;
print STDERR "All finished !\n";
print FLOG "All finished !\n";
close(FLOG);
####### HELP !
sub PRINT_HELP{
		my $src = basename($0);
		my $tama_dir = abs_path("$Bin/../");
		print STDERR "Usage: ./$src -ref <reference list> -names <names.dmp> -nodes <nodes.dmp> -o <output directory>\n";
		print STDERR "-ref       <reference list>\n  This file must have paths of reference genome sequence file and their taxon ID in two separated column with '\\t'.\n";
		print STDERR "-names     <names.dmp>\n  Enter the NCBI names.dmp file has the information of scientific names.\n";
		print STDERR "-nodes     <nodes.dmp>\n  Enter the NCBI nodes.dmp file has the information of taxonomy tree.\n";
		print STDERR "-o | -out  <output directory name>  A directory with this name will be created into \'$tama_dir/DB\'\n";
		print STDERR "-p | -cpu  <num of threads>\n";
		print STDERR "-rank      <target taxonomic rank>\n  Select one from species(default), genus, family, order, class, and phylum.\n";
		print STDERR "-h | -help Print this page.\n";
		exit();
}

