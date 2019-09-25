#!/bin/bash
cd ./tools/

#centrifuge
unzip centrifuge-1.0.3-beta-Linux_x86_64.zip
#CLARK
tar xvfz ./CLARKV1.2.6.tar.gz
cd ./CLARKSCV1.2.6
./install.sh
cd ../
#kraken
tar xvfz ./kraken.tar.gz
cd ./kraken
bash install_kraken.sh .
cd ../
#Trimmomatic
unzip ./Trimmomatic-0.39.zip
#BayesHammer
tar xvfz ./SPAdes-3.13.1-Linux.tar.gz
