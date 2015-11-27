SERVER="default"
CLIENT="default"
if [ ${SERVER} == "default" ]; then
    echo "SERVER variable needs to be configured"
    exit 1
fi
if [ ${CLIENT} == "default" ]; then
    echo "CLIENT variable needs to be configured"
    exit 1
fi
apt-get install -y openvpn easy-rsa
if [ -e /etc/openvpn ]; then
    mkdir /etc/openvpn
fi
cd /etc/openvpn
if [ -e /etc/openvpn/${SERVER}_build ]; then 
    rm -rf /etc/openvpn/${SERVER}_build
fi
cp -r /usr/share/easy-rsa ${SERVER}_build
cd /etc/openvpn/${SERVER}_build
. ./vars
./clean-all
./build-ca
./build-key-server ${SERVER}_server
./build-key ${SERVER}_${CLIENT}_client
./build-dh
cd /etc/openvpn
cat > /etc/openvpn/server.conf << EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/${SERVER}_build/keys/ca.crt
cert /etc/openvpn/${SERVER}_build/keys/${SERVER}_server.crt
key /etc/openvpn/${SERVER}_build/keys/${SERVER}_server.key
dh /etc/openvpn/${SERVER}_build/keys/dh2048.pem
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1"
keepalive 10 120
comp-lzo
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

if ! grep -q "net.ipv4.ip_forward *= *1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -w net.ipv4.ip_forward=1
if ! grep -q MASQUERADE /etc/rc.local; then
    cp /etc/rc.local ~/rc.local.backup
    cat /etc/rc.local | grep -v "exit 0" > /tmp/rc.local
    echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE" >> /tmp/rc.local
    echo "exit 0" >> /tmp/rc.local
    mv /tmp/rc.local /etc/rc.local
fi
if ! iptables-save | grep -q MASQUERADE; then
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
fi
systemctl enable openvpn
systemctl start openvpn
echo "Ensure `openvpn --config /etc/openvpn/server.conf` runs without error"
