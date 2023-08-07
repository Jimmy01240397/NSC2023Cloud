FROM debian:latest
RUN apt-get update && apt-get -y upgrade 
RUN apt-get install -y curl wget
RUN curl -s https://deb.frrouting.org/frr/keys.asc | sudo apt-key add -
ENV FRRVER="frr-stable"
RUN echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | sudo tee -a /etc/apt/sources.list.d/frr.list
RUN apt update && apt install -y frr frr-pythontools
