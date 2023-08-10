ip route del default
ip -6 route del default
chown -R frr.frr /etc/frr
service frr start


if ! [ -f /var/cache/bind/kskname. ]
then
    dnssec-keygen -a RSASHA256 -f KSK -K /var/cache/bind -b 2048 -n ZONE . > /var/cache/bind/kskname.
    dnssec-keygen -a RSASHA256 -K /var/cache/bind -b 2048 .
fi
chown -R bind:bind /var/cache/bind/

mkdir /var/www/keys
ln -s /var/cache/bind/$(cat /tmp/kskname).key /var/www/keys/dnskey
dnssec-dsfromkey /var/cache/bind/$(cat /tmp/kskname).key > /var/www/keys/ds

if ! [ -f /etc/bind/rndc.key ]
then
    rndc-confgen | sed -n '2,5p' > /etc/bind/rndc.key
fi

echo 'managed-keys {' > /etc/bind/bind.ds
keydata="$(cat /var/www/keys/ds | sed 's/IN DS/static-ds/g')"
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
service named start

while :
do
    rndc flush
    sleep 1
done &

while ! curl --connect-timeout 1 -s ca.meow.com
do
    true
done

#RUN mkdir /etc/nginx/certs

easyrsa init-pki
if ! [ -f /etc/nginx/certs/dns.meow.com.key ]
then
    easyrsa --san=DNS:dns.meow.com --batch gen-req dns.meow.com nopass
    curl ca.meow.com/sign/ca -F 'req=@pki/reqs/dns.meow.com.req'
    wget ca.meow.com/downloadcert/dns.meow.com -O certificate.zip
    unzip certificate.zip 
    mv fullchain.crt /etc/nginx/certs/dns.meow.com.crt
    cp pki/private/dns.meow.com.key /etc/nginx/certs/dns.meow.com.key
fi

service nginx start

cd /bindmanager
python3 webapi.py
