#!/bin/bash

sudo apt-get install -y pptpd iptables

# pptpd configure
cat >>/etc/pptpd.conf<<EOF
localip 172.26.218.18
remoteip 192.168.100.1-100
EOF

# dns configure
cat >>/etc/ppp/pptpd-options<<EOF
ms-dns 223.5.5.5
ms-dns 8.8.8.8
EOF

# username and password configure
cat >>/etc/ppp/chap-secrets<<EOF
aliyun  pptpd   123456  *
EOF

# ip forword configure
cat >>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward=1
EOF
sudo sysctl -p


sudo iptables -A INPUT -p gre -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 1723 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 47 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -s 192.168.100.1/24 -o eth0 -j MASQUERADE

sudo iptables-save
sudo ufw allow 1723/tcp

/etc/init.d/pptpd restart