#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd 'abs_path';
use lib "$Bin";
use Check::Modules;

my ($check, $tool_install, $uninstall, $db_set, $example_down);
my ($spc, $gen, $fam, $ord, $cla, $phy);
GetOptions(
	"--check" => \$check,
	"--install" => \$tool_install,
	"--uninstall" => \$uninstall,
	"--db" => \$db_set,
	"--species|s" => \$spc,
	"--genus|g" => \$gen,
	"--family|f" => \$fam,
	"--order|o" => \$ord,
	"--class|c" => \$cla,
	"--phylum|p" => \$phy,
	"--example" => \$example_down,
);
if(!defined($check) && !defined($tool_install) && !defined($uninstall) && !defined($db_set) && !defined($example_down)){
	print STDERR "Please check the input option\n";
	HELP();
}
if(defined($check)){
	print STDERR "** Check the requirements..\n";
	if(!check_modules()){}
	else{ print STDERR "All perl modules exists!!\n";}
}
elsif(defined($tool_install)){
	print STDERR "** Install all tools of TAMA package..\n";
	`$Bin/src/install_tools.sh`;
}
elsif(defined($uninstall)){
	print STDERR "** Uninstall all tools of TAMA package..\n";
	`$Bin/src/uninstall_tools.sh`;
}
elsif(defined($db_set)){
	print STDERR "** Download common databases..\n";
	`mkdir -p $Bin/DB/tama/`;
	print STDERR "\t* file check: metadata ..\n";
	if(-e "$Bin/DB/tama/taxonomy_data/.metadata"){
		print STDERR "\t  -> Yes, (skipped)\n";
	}
	else{
		print STDERR "\t  -> No\n\t  [1] download metadata..\n";
		`curl -o $Bin/DB/taxonomy_data.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/DB/taxonomy_data.tar.gz`;
		print STDERR "\t  [2] unzipping..\n";
		`tar xfz $Bin/DB/taxonomy_data.tar.gz -C $Bin/DB/tama/`;
		`rm -f $Bin/DB/taxonomy_data.tar.gz`;
		`touch $Bin/DB/tama/taxonomy_data/.metadata`;
	}
	print STDERR "\t* file check: centrifuge database ..\n";
	if(-e "$Bin/DB/tama/centrifuge/.centrifugedb"){
		print STDERR "\t  -> Yes, (skipped)\n";
	}
	else{
		print STDERR "\t  -> No\n\t  [1] download centrifuge database..\n";
		`curl -o $Bin/DB/tama/centrifuge.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/DB/tama/centrifuge.tar.gz`;
		print STDERR "\t  [2] unzipping..\n";
		`tar xfz $Bin/DB/tama/centrifuge.tar.gz -C $Bin/DB/tama/`;
		`rm -f $Bin/DB/tama/centrifuge.tar.gz`;
		`touch $Bin/DB/tama/centrifuge/.centrifugedb`;
	}
	print STDERR "\t* file check: CLARK data files..\n";
	if(-e "$Bin/DB/tama/CLARK/.clarkdatafile"){
		print STDERR "\t  -> Yes, (skipped)\n";
	}
	else{
		print STDERR "\t  -> No\n\t  [1] download CLARK data files..\n";
		`curl -o $Bin/DB/tama/CLARK.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/DB/tama/CLARK.tar.gz`;
		print STDERR "\t  [2] unzipping..\n";
		`tar xfz $Bin/DB/tama/CLARK.tar.gz -C $Bin/DB/tama/`;
		`rm -f $Bin/DB/tama/CLARK.tar.gz`;
		`touch $Bin/DB/tama/CLARK/.clarkdatafile`;
	}
	print STDERR "\t* file check: kraken database..\n";
	if(-e "$Bin/DB/tama/kraken/.krakendb"){
		print STDERR "\t  -> Yes, (skipped)\n";
	}
	else{
		print STDERR "\t  -> No\n\t  [1] download kraken database..\n";
		`curl -o $Bin/DB/tama/kraken.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/DB/tama/kraken.tar.gz`;
		print STDERR "\t  [2] unzipping..\n";
		`tar xfz $Bin/DB/tama/kraken.tar.gz -C $Bin/DB/tama/`;
		`rm -f $Bin/DB/tama/kraken.tar.gz`;
		`touch $Bin/DB/tama/kraken/.krakendb`;
	}

	if(!defined($spc) && !defined($gen) && !defined($fam) && !defined($ord) && !defined($cla) && !defined($phy)){
		print STDERR "\t* file check: clark species database..\n";
		if(-e "$Bin/DB/tama/CLARK/custom_0/.speciesdb"){
			print STDERR "\t  -> Yes, (skipped)\n";
		}
		else{
			print STDERR "\t  -> No\n\t  [1] download CLARK species db..\n";
			`curl -o $Bin/DB/tama/CLARK/species.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/species.tar.gz`;
			print STDERR "\t  [2] unzipping..\n";
			`tar xfz $Bin/DB/tama/CLARK/species.tar.gz -C $Bin/DB/tama/CLARK/`;
			`rm -f $Bin/DB/tama/CLARK/species.tar.gz`;
			`touch $Bin/DB/tama/CLARK/custom_0/.speciesdb`;
		}
	}
	else{
		if(defined($spc)){
			print STDERR "\t* file check: clark species database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_0/.speciesdb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK species db..\n";
				`curl -o $Bin/DB/tama/CLARK/species.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/species.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/species.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/species.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_0/.speciesdb`;
			}
		}
		if(defined($gen)){
			print STDERR "\t* file check: clark genus database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_1/.genusdb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK genus db..\n";
				`curl -o $Bin/DB/tama/CLARK/genus.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/genus.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/genus.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/genus.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_1/.genusdb`;
			}
		}
		if(defined($fam)){
			print STDERR "\t* file check: clark family database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_2/.familydb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK family db..\n";
				`curl -o $Bin/DB/tama/CLARK/family.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/family.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/family.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/family.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_2/.familydb`;
			}
		}
		if(defined($ord)){
			print STDERR "\t* file check: clark order database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_3/.orderdb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK order db..\n";
				`curl -o $Bin/DB/tama/CLARK/order.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/order.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/order.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/order.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_3/.orderdb`;
			}
		}
		if(defined($cla)){
			print STDERR "\t* file check: clark class database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_4/.classdb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK class db..\n";
				`curl -o $Bin/DB/tama/CLARK/class.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/class.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/class.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/class.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_4/.classdb`;
			}
		}
		if(defined($phy)){
			print STDERR "\t* file check: clark phylum database..\n";
			if(-e "$Bin/DB/tama/CLARK/custom_5/.phylumdb"){
				print STDERR "\t  -> Yes, (skipped)\n";
			}
			else{
				print STDERR "\t  -> No\n\t  [1] download CLARK phylum db..\n";
				`curl -o $Bin/DB/tama/CLARK/phylum.tar.gz http://bioinfo.konkuk.ac.kr/TAMA/CLARK_DBs/phylum.tar.gz`;
				print STDERR "\t  [2] unzipping..\n";
				`tar xfz $Bin/DB/tama/CLARK/phylum.tar.gz -C $Bin/DB/tama/CLARK/`;
				`rm -f $Bin/DB/tama/CLARK/phylum.tar.gz`;
				`touch $Bin/DB/tama/CLARK/custom_5/.phylumdb`;
			}
		}
	}
	print STDERR "** Done.\n";
}
elsif(defined($example_down)){
	print STDERR "** Prepare the example datasets..\n";
	`tar xfz $Bin/examples.tar.gz`;
	`perl $Bin/src/set_customDB_example.pl`;
}


sub HELP{
	my $src = basename($0);
	print STDERR "Usage: ./$src [option]\n";
	print STDERR "--check\n\tCheck the requirements\n";
	print STDERR "--install\n\tInstall the TAMA package\n";
	print STDERR "--db <--taxonomic rank>\n\tDownload the CLARK, Kraken, and Centrifuge database\n\tYou can download any of taxonomic rank database with --taxonomic rank option (--species, --genus, --family, --order, --class, --phylum)\n\t(default: species)\n";
	print STDERR "--example\n\tPrepare the example dataset\n";
	exit();
}
