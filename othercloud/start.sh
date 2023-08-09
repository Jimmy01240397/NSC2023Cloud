ip route del default
ip -6 route del default
chown -R frr.frr /etc/frr
service frr start
service nginx start
echo 'managed-keys {' > /etc/bind/bind.keys
keydata="$(cat /var/www/keys/ds | sed 's/IN DS/static-ds/g')"
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

cd /bindmanager
python3 webapi.py

while :
do
    rndc flush
    sleep 1
done
