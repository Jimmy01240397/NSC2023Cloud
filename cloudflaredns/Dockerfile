FROM debian:latest
RUN apt-get update && apt-get -y upgrade 
RUN apt-get install -y lsb-release procps curl wget gnupg2 iputils-ping mtr dnsutils bind9 vim
RUN mkdir /var/log/bind && chown bind:bind /var/log/bind
COPY bind/config/* /etc/bind/
COPY bind/zone/* /var/cache/bind/

RUN dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE 0.1.1.in-addr.arpa. > /tmp/kskname
RUN dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 0.1.1.in-addr.arpa.
RUN dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/cache/bind/0.1.1.in-addr.arpa.ds

RUN dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE 1.1.1.in-addr.arpa. > /tmp/kskname
RUN dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 1.1.1.in-addr.arpa.
RUN dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/cache/bind/1.1.1.in-addr.arpa.ds

RUN dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE 0.0.7.4.0.0.7.4.6.0.6.2.ip6.arpa > /tmp/kskname
RUN dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 0.0.7.4.0.0.7.4.6.0.6.2.ip6.arpa.
RUN dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/cache/bind/0.0.7.4.0.0.7.4.6.0.6.2.ip6.arpa.ds

RUN chown -R bind:bind /var/cache/bind/
