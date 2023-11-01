#!/bin/bash
sudo apt-get update
sudo apt-get install wireguard iptables -y

# Configure the kernel to allow IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -p

# Generate the private and public keys for the server
wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey

# Replace the private key in the wg0.conf file
PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)
NETWORK_INTERFACE=$(ip route | grep default | awk '{print $5}')

# Create the wg0.conf file
sudo tee /etc/wireguard/wg0.conf << EOF
[interface]
Address = 10.1.0.1/24
ListenPort = 51820
SaveConfig = true
PrivateKey = $PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADEv
EOF

sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0



