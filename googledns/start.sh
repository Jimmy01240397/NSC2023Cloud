#!/bin/bash
ip route del default
ip -6 route del default
ip route add default via $1 dev eth0
ip -6 route add default via $2 dev eth0

while ! curl --connect-timeout 1 -s --resolve 'keys:80:198.41.0.4' keys
do
    true
done

curl --connect-timeout 1 -s --resolve 'keys:80:198.41.0.4' keys/dnskey > /usr/share/dns/root.key
curl --connect-timeout 1 -s --resolve 'keys:80:198.41.0.4' keys/ds > /usr/share/dns/root.ds

if ! [ -f /etc/bind/rndc.key ]
then
    rndc-confgen | sed -n '2,5p' > /etc/bind/rndc.key
fi

echo 'managed-keys {' > /etc/bind/bind.ds
#cat /usr/share/dns/root.ds | sed 's/IN DS/static-key/g' | sed 's/$/;/' >> /etc/bind/bind.keys
keydata="$(cat /usr/share/dns/root.ds | sed 's/IN DS/static-ds/g')"
for a in $(seq 1 1 $(echo "$keydata" | awk '{print NF}'))
do
    if [ $a -eq 6 ]
    then
        printf '"' >> /etc/bind/bind.ds
    fi
    printf "$(echo "$keydata" | awk "{print \$$a}")" >> /etc/bind/bind.ds
    if [ $a -eq $(echo "$keydata" | awk '{print NF}') ]
    then
        printf '";' >> /etc/bind/bind.ds
    fi
    if [ $a -ge 6 ]
    then
        echo >> /etc/bind/bind.ds
    else
        printf ' ' >> /etc/bind/bind.ds
    fi
done
echo '};' >> /etc/bind/bind.ds

cat /etc/bind/bind.ds >> /etc/bind/named.conf.docker

if ! [ -f /var/cache/bind/8.8.8.in-addr.arpa.ds ]
then
    dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE 8.8.8.in-addr.arpa. > /tmp/kskname
    dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 8.8.8.in-addr.arpa.
    dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/cache/bind/8.8.8.in-addr.arpa.ds
fi
if ! [ -f /var/cache/bind/0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa.ds ]
then
    dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE 0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa > /tmp/kskname
    dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa.
    dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/cache/bind/0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa.ds
fi
chown -R bind:bind /var/cache/bind/

service named start

while ! curl -k --connect-timeout 1 -s https://dns.meow.com
do
    true
done

curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"ns.google.com", "type":"A", "data":"8.8.8.8", "username":"g0ol3", "password":"m30w"}'
curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"ns.google.com", "type":"AAAA", "data":"2001:4860:4860::8888", "username":"g0ol3", "password":"m30w"}'

curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"8.8.8.in-addr.arpa", "type":"NS", "data":"ns.google.com", "username":"g0ol3", "password":"m30w"}'
curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"8.8.8.in-addr.arpa", "type":"DS", "data":"'"$(cat /var/cache/bind/8.8.8.in-addr.arpa.ds | awk '{for (i=4; i<=7; i++) printf "%s ", $i; print ""}')"'", "username":"g0ol3", "password":"m30w"}'

curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa", "type":"NS", "data":"ns.google.com", "username":"g0ol3", "password":"m30w"}'
curl -k -H 'Content-Type: application/json' https://dns.meow.com/addrecord -X POST -d '{"name":"0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa", "type":"DS", "data":"'"$(cat /var/cache/bind/0.6.8.4.0.6.8.4.1.0.0.2.ip6.arpa.ds | awk '{for (i=4; i<=7; i++) printf "%s ", $i; print ""}')"'", "username":"g0ol3", "password":"m30w"}'

while :
do
    rndc flush
    sleep 1
done
