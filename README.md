TAMA
-----------------
* Taxonomy Analysis pipeline for metagenome using Meta-Analysis

System requirements (tested versions)
-----------------

* Programs

        - perl (v5.22.1)
        - phython (2.7.12)
        - java (1.8.0)
        - git (2.7.4)
        - gcc, g++ (5.4.0)
        - make (GNU Make 4.1)
        - zip (3.0)
        - curl (7.47.0)
        - Sort::Key::Natural (perl library)

* Required system resources

        Based on the species rank anlaysis, using the included example dataset,
        - Disk: (approximately) 300GB 
                * CLARK: 88GB, Kraken: 188GB, Centrifuge: 9.6GB
        - Memory: (approximately) 160GB 
                * This large memory is required for running the taxonomy analysis tools,
                  especially CLARK and Kraken
        

Download and install
-----------------

* Download

        git clone https://github.com/jkimlab/TAMA.git
        cd TAMA
    
    
    (1) Install by source code

        [ Check the required perl libraries ]
        ./setup.pl --check
        
        [ Install TAMA package ]
        ./setup.pl --install

        [ Uninstall TAMA package ]
        ./setup.pl --uninstall

    (2) Install by docker (https://www.docker.com/)
    
        [Build docker image]
        docker build -t [image_name] .
        
        [Run a container]
        docker run -it [image_name] /bin/bash


* Prepare databases

        [ Download CLARK, Kraken, and Centrifuge databases ]
        * 6 taxonomic rank of database is provided for the CLARK (default: species) 
        ./setup.pl --db (or ./setup.pl --db --species)
      
        * If you want to download the database of another taxonomic rank, please add taxonomic rank options
        (example) target taxonomic rank: species, genus, phylum 
        ./setup.pl --db --species --genus --phylum
        
        [ Prepare example datasets ]
        ./setup.pl --example

* Before downloading the database, please check the required disk space 
(To download and set the databases, you need to prepare about twice as much storage space.)

| Tool       | Species | Genus | Family | Order | Class | Phylum |
| :----:     | :-----: | :---: | :----: | :---: | :---: | :----: |
| CLARK      | 88 GB   | 90 GB | 89 GB  | 90 GB | 88 GB | 91 GB  |

| Tool       |   DB   |
| :----:     | :----: |
| Kraken     | 188 GB |
| Centrifuge | 9.6 GB |


Run TAMA
-----------------

* Run TAMA with example dataset

        ./TAMA.pl -p 30 -o ./ExampleTest --param examples/params.example -t True


* Run TAMA perl script

        Usage: ./TAMA.pl [option] --param param.txt 
        Options:
        	-p		The number of threads  (default: 1)
        	-o		Path of output directory  (default: Current directory)
        	-t		Save temporary files (default: False)
        			If you want to save, type 'True'
        	-h|help		Print help page
        Input:
        	--param		(Required) Path of paramter file
        

* To run TAMA, you need to prepare params file

        ### Example of parameter file 
        # Each line has 'PARAMETERNAME' and 'VALUE', they concatenate by '='
        # PARAMETERNAME is started by '$' symbol
        # Please do not change the 'PARAMETERNAME'
        # You can use your input files or options by changing the 'VALUE' after '=' symbol

        [Project]
        # PROJECTNAME parameter is the name of your project using followed all input datasets. 
        # Multiple datasets could be included in the project and analyzed in a single run. 
        # A directory with this name will be created in the output directory.
        $PROJECTNAME=TEST

        [Basic_options]
        # TOOL parameter has to get a list of taxonomy analysis tools. 
        # You can use one and more tools for your analysis from CLARK, centrifuge, and kraken.
        # (default: CLARK,centrifuge,kraken)
        $TOOL=CLARK,centrifuge,kraken
        # RANK parameter is targeted taxonomic rank of analysis.
        # You can use one taxonomic rank from species, genus, family, order, class, and phylum.
        # (default: species) 
        $RANK=species
        # META-THRESHOLD parameter is the filtering threshold of meta-analysis. 
        # You can use a positive number between 0 and 1. 
        # If the bigger threshold is used then the more strict filtering of meta-analysis will be done. 
        # (default: 0)
        $META-THRESHOLD=
        # WEIGHT-CLARK parameter is the weight (or confidence level) of CLARK results for meta-analysis. 
        # You can use a positive number between 0 and 1. 
        # (default: 0.9374)
        $WEIGHT-CLARK=
        # WEIGHT-centrifuge parameter is the weight (or confidence level) of centrifuge results for meta-analysis.
        # You can use a positive number between 0 and 1.
        # (default: 0.9600)
        $WEIGHT-centrifuge=
        # WEIGHT-kraken parameter is the weight (or confidence level) of kraken results for meta-analysis.
        # You can use a positive number between 0 and 1. 
        # (default: 0.9362)
        $WEIGHT-kraken=

        [Database]
        # DBNAME parameter is the directory name which has CLARK, kraken, and centrifuge directory 
        # and this directory have to be in 'DB' directory of TAMA package. 
        # Each directory (CLARK, kraken, and centrifuge) should have their database files. 
        # (default: tama)
        $DBNAME=tama

        [Input]
        # You need to separate each dataset with '>' symbol. 
        # The name of each dataset should be described after '>'. 
        # The dataset could have multiple numbers of input sequence files. 
        # All the sequence files will be treated as an input to the current dataset until the next '>' symbol. 
        # The directory with this name will be created in the project directory 
        # (==> output_dir/projectname/samplename)
        >sample1
        # PAIRED1 and PAIRED2 parameter are the forward and 
        # reverse strand reads of a pair of paired-end sequencing read. 
        # If you have multiple sequence files, 
        # you should write a list of files by concatenating ',' or write them in multiple lines.
        $PAIRED1=examples/sample1.1.fq
        $PAIRED2=examples/sample1.2.fq
        $PAIRED1=
        $PAIRED2=
        # SINGLE parameter is the single-end read file. 
        # If you have multiple sequence files, 
        # you should write a list of files by concatenating ',' or write them in multiple lines.
        $SINGLE=

        >sample2
        $PAIRED1=examples/sample2.1.fq
        $PAIRED2=examples/sample2.2.fq
        $SINGLE=

        [Preprocessing]
        # TRIMMOMATIC-RUN parameter get whether to execute read trimming process or not. 
        # If you want to do the read trimming process, 
        # you should write 'true', or not you should write 'false'. 
        # (default: true)
        $TRIMMOMATIC-RUN=true
        # TRIMMOMATIC-OPTION parameter is the running options of the Trimmomatic program. 
        # (default: AVGQUAL:2 LEADING:3 TRAILING:3)
        $TRIMMOMATIC-OPTION=
        # BAYESHAMMER-RUN parameter get whether to execute read error correction process or not. 
        # If you want to do the read error correction process, 
        # you should write 'true', or not you should write 'false'. 
        # (default: true)
        $BAYESHAMMER-RUN=true
        

TAMA output
-----------------
   
* Read classification profile

        - File name: read_classi.*.out
        ('*' is the input meta-score threshold (value of META-THRESHOLD parameter))
        
        - File format: there are three columns without header line
            1. Input read sequence ID
            2. Assigned taxon ID (or IDs)
            3. Meta-score


* Relative species abundance profile

        - File name: abundance_profile.*.out
        ('*' is the input meta-score threshold (value of META-THRESHOLD parameter))
        
        - File format: there are seven columns with header line
            
        1. The first line indicates name of each column
            (1) Scientific name: the scientific name of this taxon
            (2) Taxon ID: taxon id of this genome for the input taxonomic rank
            (3) Genome size: estimated genome size of this taxon 
                (if the rank of input taxonomy is not a 'species', '-' is recorded)
            (4) Ratio: the proportion of reads assigned to this taxon 
                ([the number of reads with this taxon ID]/[total number of reads])
            (5) # of Read count: the number of reads assigned to this taxon
            (6) # of Total read: the total number of reads in this sample
            (7) Abundance: relative species abundance of this taxon
            
        2. The second line has information of 'unclassified reads'
        3. From the third line, there are results of predicted species (in the reference database) from 'classified reads'
        

Third party tools
-----------------

* Trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)
* BayesHammer (http://bioinf.spbau.ru/en/spades/bayeshammer)
* CLARK (http://clark.cs.ucr.edu)
* Kraken (https://ccb.jhu.edu/software/kraken/)
* Centrifuge (https://ccb.jhu.edu/software/centrifuge/)


Contact
-----------------
E-mail: bioinfolabkr@gmail.com

        
