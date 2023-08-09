FROM debian:latest
RUN apt-get update && apt-get -y upgrade 
RUN apt-get install -y lsb-release procps curl wget git gnupg2 iputils-ping mtr dnsutils vim bind9 nginx python3 python3-venv  python3-dev python3-pip ansible
RUN curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
ENV FRRVER="frr-stable"
RUN echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | tee -a /etc/apt/sources.list.d/frr.list
RUN apt update && apt install -y frr frr-pythontools
COPY version version
RUN git clone https://github.com/Jimmy01240397/Bind9Manager /bindmanager
COPY bind/apiconfig.yaml /bindmanager/config.yaml
RUN pip3 install -r /bindmanager/requirements.txt --break-system-packages

RUN mkdir /var/www/keys
COPY nginx/sitesconf/* /etc/nginx/sites-enabled/
RUN mkdir /var/log/bind && chown bind:bind /var/log/bind
COPY bind/config/* /etc/bind/
COPY bind/zone/* /var/cache/bind/
RUN dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE . > /tmp/kskname
RUN dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 .
RUN cp /var/cache/bind/$(cat /tmp/kskname).key /var/www/keys/dnskey
RUN dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/www/keys/ds
RUN chown -R bind:bind /var/cache/bind/
