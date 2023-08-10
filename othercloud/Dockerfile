FROM debian:latest
RUN apt-get update && apt-get -y upgrade 
RUN apt-get install -y lsb-release procps unzip curl wget git gnupg2 iputils-ping mtr dnsutils vim bind9 bind9utils nginx python3 python3-venv  python3-dev python3-pip ansible
RUN curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
ENV FRRVER="frr-stable"
RUN echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | tee -a /etc/apt/sources.list.d/frr.list
RUN apt update && apt install -y frr frr-pythontools
RUN git clone https://github.com/OpenVPN/easy-rsa && \
    mv easy-rsa/easyrsa3 /usr/local/share/easy-rsa && \
    ln -s ../share/easy-rsa/easyrsa /usr/local/bin/easyrsa

RUN git clone https://github.com/Jimmy01240397/Bind9Manager /bindmanager
COPY bind/apiconfig.yaml /bindmanager/config.yaml
RUN pip3 install -r /bindmanager/requirements.txt --break-system-packages

RUN mkdir /var/log/bind && chown bind:bind /var/log/bind
