# See also:
# * https://openvpn.net/index.php/open-source/documentation/howto.html 
# * http://habrahabr.ru/post/188474/

apt-get install -y openvpn
cd /etc/openvpn
cp -r /usr/share/easy-rsa .
cd easy-rsa
. ./vars
./clean-all
./build-ca # enter common name "server"
./build-key-server server # enter common name "server"
# build-key <client-name>
./build-dh
zcat /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > server.conf
# edit server.conf:
# push "redirect-gateway def1"
# ca /etc/openvpn/easy-rsa/keys/ca.crt
# cert /etc/openvpn/easy-rsa/keys/server.crt
# key /etc/openvpn/easy-rsa/keys/server.key
# dh /etc/openvpn/easy-rsa/keys/dh2048.pem
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
#echo "-A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE" > /etc/rc.local
#iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
update-rc.d openvpn defaults


# Client config
# cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/
# Copy ca.crt, <client-name>.crt and <client-name>.key from remote server to
# /etc/openvpn/keys directory
# edit client.conf:
# remote <server-hostname> 1194
# ca keys/ca.crt
# cert keys/<client-name>.crt
# key keys/<client-name>.key
# update-rc.d openvpn defaults
