#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd 'abs_path';

my %hs_options = ();
my ($core_N, $out_D, $par_F, $tmp_save, $help,);
my ($db_F, %runTools,@gz_li, @prjDir, %fscore);
my $script_Loc = dirname($0);

# running options
GetOptions(
	"--param=s" => \$par_F,
	"-p:i" => \$core_N,
	"-o:s" => \$out_D,
	"-t:s" => \$tmp_save,
	"h|help" => \$help,
);
if(!defined($par_F) || ! -f $par_F || ! -e $par_F){
	print STDERR "[Error] There is no proper parameter file.\n";
	HELP();
}
if(!defined($out_D)){ $out_D = abs_path("./"); }
else{ $out_D = abs_path("$out_D"); }
if(!defined($core_N)){ $core_N = 1; }
if(defined($help)){ HELP(); }

## Paths
my $src_path = abs_path("$Bin/src");
my $tool_path = abs_path("$Bin/tools");
my $db_path = abs_path("$Bin/DB");

## Default options
$hs_options{"RANK"} = "species";
$hs_options{"META-THRESHOLD"} = 0.34;
$hs_options{"WEIGHT-centrifuge"} = 0.9600;
$hs_options{"WEIGHT-CLARK"} = 0.9374;
$hs_options{"WEIGHT-kraken"} = 0.9362;
$hs_options{"TRIMMOMATIC-RUN"} = "TRUE";
$hs_options{"BAYESHAMMER-RUN"} = "TRUE";
$hs_options{"TRIMMOMATIC-OPTION"} = "AVGQUAL:2 LEADING:3 TRAILING:3";
$hs_options{"TOOL"} = "CLARK,centrifuge,kraken";
$hs_options{"DBNAME"} = "tama";

## Check the parameters
print STDERR "[1] Parameters..\n";
my $header;
my %hs_sample = ();
open(FPA, "$par_F");
while(<FPA>){
	chomp;
	if($_ =~ /\[(\S+)\]/){
		$header = $1;
		if($header eq "Input"){
			my $cur_sample = "";
			while(1){
				my $line = <FPA>;
				chomp($line);
				if($line eq ""){ next; }
				if($line =~ /^\[/){ last; }
				if($line =~ /^>(\S+)/){
					$cur_sample = $1;
					next;
				}
				my ($option, $file) = split(/=/,$line);
				$option = substr($option, 1);
				if(!defined($file)){ next; }
				if($file eq ""){ next; }
				if(!-f $file || !-e $file){
					print STDERR "[Error] There is no proper input file.\n";
					print STDERR "     => $file\n";
					exit();
				}
				$file = abs_path("$file");
				if(!exists($hs_sample{$cur_sample}{$option})){
					$hs_sample{$cur_sample}{$option} = "$file";
				}
				elsif(exists($hs_sample{$cur_sample}{$option})){
					$hs_sample{$cur_sample}{$option} .= ",$file";
				}
			}
		}
		next;
	}
	elsif($_ eq ""){ next; }
	elsif($_ =~ /^\$(\S+)/){
		my ($option, $value) = split(/=/,$1);
		if($value eq ""){
			next;
		}
		$hs_options{$option} = $value;
	}
}
close(FPA);

print STDERR " [options]\n";
print STDERR "  OUTDIR = $out_D\n";
print STDERR "  CPU = $core_N\n";
foreach my $k ("PROJECTNAME", "DBNAME", "TOOL", "RANK", "META-THRESHOLD", "WEIGHT-CLARK", "WEIGHT-centrifuge", "WEIGHT-kraken", "TRIMMOMATIC-RUN", "TRIMMOMATIC-OPTION", "BAYESHAMMER-RUN"){
	print STDERR "  $k = $hs_options{$k}\n";
}
print STDERR " [samples]\n";
foreach my $s1 (keys(%hs_sample)){
	print STDERR "  $s1\n";
	foreach my $s2 (keys(%{$hs_sample{$s1}})){
		print STDERR "  $s2 = $hs_sample{$s1}{$s2}\n";
	}
}

## Do pipeline
foreach my $sample (sort keys(%hs_sample)){
	print STDERR "[#] Currend sample: $sample\n";
	my $cur_dir = "$out_D/$hs_options{PROJECTNAME}/$sample";
	`mkdir -p $cur_dir/tmp`;
	`rm -rf $cur_dir/tmp/*`;
	PRINT_BASIC_PARAM($cur_dir);
	print STDERR "[2] Preprocessing..\n";
	my %hs_input_type = ();
	foreach my $type ("SINGLE", "PAIRED1", "PAIRED2"){
		if(!exists($hs_sample{$sample}{$type})){
			$hs_sample{$sample}{$type} = "";
			next;
		}
		if($type eq "SINGLE"){
			$hs_input_type{"SE"} = 1;
			$hs_input_type{$type} = "SE";
			`mkdir -p $cur_dir/tmp/SE`;
		}
		else{
			$hs_input_type{"PE"} = 1;
			$hs_input_type{$type} = "PE";
			`mkdir -p $cur_dir/tmp/PE`;
		}
		my $files = $hs_sample{$sample}{$type};
		if($files =~ /,/){
			my @file = split(/,/,$files);
			foreach my $cur_seq (@file){
				if($cur_seq =~ /.gz$/){
					`gunzip -c $cur_seq >> $cur_dir/tmp/$hs_input_type{$type}/$type.fq`;
				}
				else{
					`cat $cur_seq >> $cur_dir/tmp/$hs_input_type{$type}/$type.fq`; 
				}
			}
			$hs_sample{$sample}{$type} = "$cur_dir/tmp/$hs_input_type{$type}/$type.fq";
		}
	}
	foreach my $i (keys(%hs_input_type)){
		if($i eq "SE"){
			# Trimming
			if($hs_options{"TRIMMOMATIC-RUN"} eq "true"){ 
				`mkdir -p $cur_dir/tmp/SE`;
				print STDERR "\t[CMD] java -jar $tool_path/Trimmomatic-0.39/trimmomatic-0.39.jar SE -threads $core_N $hs_sample{$sample}{'SINGLE'} $cur_dir/tmp/SE/Trimmed.S.fq $hs_options{'TRIMMOMATIC-OPTION'}\n";
				`java -jar $tool_path/Trimmomatic-0.39/trimmomatic-0.39.jar SE -threads $core_N $hs_sample{$sample}{'SINGLE'} $cur_dir/tmp/SE/Trimmed.S.fq $hs_options{'TRIMMOMATIC-OPTION'}`;
				$hs_sample{$sample}{'SINGLE'} = "$cur_dir/tmp/SE/Trimmed.S.fq";
			}
			else{ print STDERR "\tTrimming is skipped\n"; }
			# Error correction
			if($hs_options{'BAYESHAMMER-RUN'} eq "true"){
				print STDERR "\t[CMD] $tool_path/SPAdes-3.13.1-Linux/bin/spades.py -t $core_N -s $hs_sample{$sample}{'SINGLE'} --meta -o $cur_dir/tmp/SE --only-error-correction --disable-gzip-output\n";
				`$tool_path/SPAdes-3.13.1-Linux/bin/spades.py -t $core_N -s $hs_sample{$sample}{'SINGLE'} --meta -o $cur_dir/tmp/SE --only-error-correction --disable-gzip-output`;
				$hs_sample{$sample}{'SINGLE'} = "$cur_dir/tmp/SE/corrected/Trimmed.S.00.0_0.cor.fastq";
			}
			else{ print STDERR "\tError correction is skipped\n"; }
		}
		elsif($i eq "PE"){
			# Trimming
			if($hs_options{"TRIMMOMATIC-RUN"} eq "true"){ 
				`mkdir -p $cur_dir/tmp/PE`;
				print STDERR "\t[CMD] java -jar $tool_path/Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads $core_N $hs_sample{$sample}{PAIRED1} $hs_sample{$sample}{PAIRED2} $cur_dir/tmp/PE/Trimmed.P.1.fq $cur_dir/tmp/PE/unpaired.P.1.fq $cur_dir/tmp/PE/Trimmed.P.2.fq $cur_dir/tmp/PE/unpaired.P.2.fq $hs_options{'TRIMMOMATIC-OPTION'}\n";
				`java -jar $tool_path/Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads $core_N $hs_sample{$sample}{PAIRED1} $hs_sample{$sample}{PAIRED2} $cur_dir/tmp/PE/Trimmed.P.1.fq $cur_dir/tmp/PE/unpaired.P.1.fq $cur_dir/tmp/PE/Trimmed.P.2.fq $cur_dir/tmp/PE/unpaired.P.2.fq $hs_options{'TRIMMOMATIC-OPTION'}`;
				$hs_sample{$sample}{'PAIRED1'} = "$cur_dir/tmp/PE/Trimmed.P.1.fq";
				$hs_sample{$sample}{'PAIRED2'} = "$cur_dir/tmp/PE/Trimmed.P.2.fq";
			}
			else{ print STDERR "\tTrimming is skipped\n"; }
			# Error correction
			if($hs_options{'BAYESHAMMER-RUN'} eq "true"){
				print STDERR "\t[CMD] $tool_path/SPAdes-3.13.1-Linux/bin/spades.py -t $core_N -1 $hs_sample{$sample}{'PAIRED1'} -2 $hs_sample{$sample}{'PAIRED2'} --meta -o $cur_dir/tmp/PE --only-error-correction --disable-gzip-output\n";
				`$tool_path/SPAdes-3.13.1-Linux/bin/spades.py -t $core_N -1 $hs_sample{$sample}{'PAIRED1'} -2 $hs_sample{$sample}{'PAIRED2'} --meta -o $cur_dir/tmp/PE --only-error-correction --disable-gzip-output`;
				$hs_sample{$sample}{'PAIRED1'} = "$cur_dir/tmp/PE/corrected/Trimmed.P.1.00.0_0.cor.fastq";
				$hs_sample{$sample}{'PAIRED2'} = "$cur_dir/tmp/PE/corrected/Trimmed.P.2.00.0_0.cor.fastq";
			}
			else{ print STDERR "\tError correction is skipped\n"; }
		}
	}
	open(FOUT, ">>$cur_dir/module_params");
	print FOUT "SINGLE=$hs_sample{$sample}{'SINGLE'}\n";
	print FOUT "PAIRED1=$hs_sample{$sample}{'PAIRED1'}\n";
	print FOUT "PAIRED2=$hs_sample{$sample}{'PAIRED2'}\n";
	close(FOUT);
	# Taxonomy analysis
	print STDERR "[3] Taxonomy analysis..\n";
	my @tool = split(/,/,$hs_options{'TOOL'});
	foreach my $t (@tool){
		if($t eq "clark"){ $t = "CLARK"; }
		print STDERR "\t$t:\n\t[CMD] $src_path/PIPELINE_$t.pl -params $cur_dir/module_params -cpu $core_N\n";
		`$src_path/PIPELINE_$t.pl -params $cur_dir/module_params -cpu $core_N`;
	}
	print STDERR "[4] Meta-analysis..\n";
	my %hs_meta_option = ();
	foreach my $t (@tool){
		if($t eq "clark"){ $t = "CLARK"; }
		my $w = "WEIGHT-$t";
		if(!exists($hs_meta_option{'L'})){ $hs_meta_option{'L'} = "$t"; }
		else{ $hs_meta_option{'L'} .= ",$t"; }
		if(!exists($hs_meta_option{'I'})){ $hs_meta_option{'I'} = "$cur_dir/$t/metainput"; }
		else{ $hs_meta_option{'I'} .= ",$cur_dir/$t/metainput"; }
		if(!exists($hs_meta_option{'F'})){ $hs_meta_option{'F'} = "$hs_options{$w}"; }
		else{ $hs_meta_option{'F'} .= ",$hs_options{$w}"; }
	}
#	print STDERR "\t[CMD] $src_path/meta-analysis.pl -l $hs_meta_option{'L'} -i $hs_meta_option{'I'} -f $hs_meta_option{'F'} -t $hs_options{'META-THRESHOLD'} -o $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out\n";
	print STDERR "\t[CMD] $src_path/meta-analysis.pl -l $hs_meta_option{'L'} -i $hs_meta_option{'I'} -f $hs_meta_option{'F'} -t 0 -o $cur_dir/read_classi.out\n";
#	`$src_path/meta-analysis.pl -l $hs_meta_option{'L'} -i $hs_meta_option{'I'} -f $hs_meta_option{'F'} -t $hs_options{'META-THRESHOLD'} -o $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out`;
	`$src_path/meta-analysis.pl -l $hs_meta_option{'L'} -i $hs_meta_option{'I'} -f $hs_meta_option{'F'} -t 0 -o $cur_dir/read_classi.out`;
	print STDERR "[5] Abundance estimation..\n";
	print STDERR "\t[CMD] $src_path/metascore_mean_in_taxon.pl $cur_dir/read_classi.out $cur_dir/avg_metascore.txt\n";;
	`$src_path/metascore_mean_in_taxon.pl $cur_dir/read_classi.out $cur_dir/avg_metascore.txt`;
	print STDERR "\t[CMD] $src_path/filt_read_profile_with_metamean.pl $cur_dir/avg_metascore.txt $cur_dir/read_classi.out $hs_options{'META-THRESHOLD'} $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out\n";
	`$src_path/filt_read_profile_with_metamean.pl $cur_dir/avg_metascore.txt $cur_dir/read_classi.out $hs_options{'META-THRESHOLD'} $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out`;
	print STDERR "\t[CMD] $src_path/calculate_abundance.pl $cur_dir/module_params $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out 0 > $cur_dir/abundance_profile.$hs_options{'META-THRESHOLD'}.out\n";
	`$src_path/calculate_abundance.pl $cur_dir/module_params $cur_dir/read_classi.$hs_options{'META-THRESHOLD'}.out 0 > $cur_dir/abundance_profile.$hs_options{'META-THRESHOLD'}.out`;
	if(!defined($tmp_save)){
		`rm -rf $cur_dir/tmp`;
	}
	elsif($tmp_save eq "True" || $tmp_save eq "true" || $tmp_save eq "TRUE" || $tmp_save eq "T" || $tmp_save eq "t"){
		`gzip $cur_dir/tmp/*/*/*/*.* $cur_dir/tmp/*/*/*.* $cur_dir/tmp/*/*.*`;
	}
	else{ `rm -rf $cur_dir/tmp`; }
	print STDERR "\nDone. \n\n";
}




sub HELP{
    my $src = basename($0);
    print STDERR "Usage: ./$src [option] --param param.txt \n";
    print STDERR "Options:\n";
    print STDERR "\t-p\t\tThe number of threads  (default: 1)\n";
    print STDERR "\t-o\t\tPath of output directory  (default: Current directory)\n";
    print STDERR "\t-t\t\tSave temporary files (default: False)\n\t\t\tIf you want to save, type 'True'\n";
    print STDERR "\t-h|help\t\tPrint help page.\n";
    print STDERR "Input:\n";
    print STDERR "\t--param\t\t(Required) Path of paramter file\n";
    exit;
}

sub PRINT_BASIC_PARAM{
	my $c_dir = shift(@_);
	open(FOUT, ">$c_dir/module_params");
	print FOUT "#Project\nPROJECTPATH=$out_D/$hs_options{'PROJECTNAME'}\n\n";
	print FOUT "#Basic options\n";
	print FOUT "RANK=$hs_options{'RANK'}\n";
	print FOUT "META-THRESHOLD=$hs_options{'META-THRESHOLD'}\n";
	print FOUT "WEIGHT-CLARK=$hs_options{'WEIGHT-CLARK'}\n";
	print FOUT "WEIGHT-centrifuge=$hs_options{'WEIGHT-centrifuge'}\n";
	print FOUT "WEIGHT-kraken=$hs_options{'WEIGHT-kraken'}\n\n";
	print FOUT "#Database\n";
	print FOUT "DBNAME=$hs_options{'DBNAME'}\n\n";
	print FOUT "#Input\n>$c_dir\n";
	close(FOUT);
}
