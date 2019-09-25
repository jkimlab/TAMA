FROM ubuntu:16.04
MAINTAINER Jongin <jongin333@gmail.com>

RUN apt-get update && apt-get install -y \
		perl \
		python \
		openjdk-8-jdk \
		git \
		cpanminus \
		gcc \
		g++ \
		make \
		zip \
		curl \
		vim

RUN cpanm Sort::Key::Natural

RUN git clone https://github.com/jkimlab/TAMA \
		&& cd TAMA \
		&& ./setup.pl --install
