# See also:
# * https://openvpn.net/index.php/open-source/documentation/howto.html 
# * http://habrahabr.ru/post/188474/

# START
apt-get install -y openvpn easy-rsa
cd /etc/openvpn
cp -r /usr/share/easy-rsa .
cd /etc/openvpn/easy-rsa
. ./vars
./clean-all
./build-ca
./build-key-server PROJECT_server
./build-key PROJECT_client
./build-dh
cd /etc/openvpn
zcat /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > server.conf
# edit server.conf:
# push "redirect-gateway def1"
# ca /etc/openvpn/easy-rsa/keys/ca.crt
# cert /etc/openvpn/easy-rsa/keys/PROJECT_server.crt
# key /etc/openvpn/easy-rsa/keys/PROJECT_server.key
# dh /etc/openvpn/easy-rsa/keys/dh2048.pem
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1
if ! grep MASQUERADE /etc/rc.local; then
    echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE" > /etc/rc.local
fi
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
update-rc.d openvpn defaults
# CURRENT_POSITION
# FINISH


# Client config
# cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/
# Copy:
# * ca.crt
# * PROJECT_client.crt
# * PROJECT_client.key
# from PROJECT server to
# /etc/openvpn/keys/PROJECT directory
# edit client.conf:
# remote <server-hostname> 1194
# ca /etc/openvpn/keys/PROJECT/ca.crt
# cert /etc/openvpn/keys/PROJECT/<client-name>.crt
# key /etc/openvpn/keys/PROJECT/<client-name>.key
# update-rc.d openvpn defaults
