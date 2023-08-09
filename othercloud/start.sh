ip route del default
ip -6 route del default
chown -R frr.frr /etc/frr
service frr start
service nginx start
echo 'trust-anchors {' > /etc/bind/bind.keys
keydata="$(cat /var/www/keys/dnskey | grep DNSKEY | sed 's/IN DNSKEY/initial-key/g')"
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
service named start
sleep infinity
