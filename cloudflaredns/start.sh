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

echo 'managed-keys {' > /etc/bind/bind.keys
#cat /usr/share/dns/root.ds | sed 's/IN DS/static-key/g' | sed 's/$/;/' >> /etc/bind/bind.keys
keydata="$(cat /usr/share/dns/root.ds | sed 's/IN DS/static-ds/g')"
for a in $(seq 1 1 $(echo "$keydata" | awk '{print NF}'))
do
    if [ $a -eq 6 ]
    then
        printf '"' >> /etc/bind/bind.keys
    fi
    printf "$(echo "$keydata" | awk "{print \$$a}")" >> /etc/bind/bind.keys
    if [ $a -eq $(echo "$keydata" | awk '{print NF}') ]
    then
        printf '";' >> /etc/bind/bind.keys
    fi
    if [ $a -ge 6 ]
    then
        echo >> /etc/bind/bind.keys
    else
        printf ' ' >> /etc/bind/bind.keys
    fi
done
echo '};' >> /etc/bind/bind.keys

cat /etc/bind/bind.keys >> /etc/bind/named.conf.options

service named start

sleep infinity
