#!/bin/bash

echo "[+] Flushing existing iptables rules..."
iptables -F
iptables -X

echo "[+] Setting default policies..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "[+] Allowing loopback and established connections..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

echo "[+] Allowing public HTTP/HTTPS access..."
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# IPs allowed for SSH, 12667, 9842, and 3306
WHITELIST=(
  35.210.137.169
  35.210.98.72
  34.38.42.113
  95.217.111.212
  95.217.79.45
  162.55.1.181
  49.12.174.55
  88.99.95.148
  159.69.142.232
  88.99.249.122
  95.216.38.185
  142.132.143.152
  167.172.63.104
  127.0.0.1
  95.216.68.12
)

# Cloudflare IP Ranges (now allowed on all restricted ports)
CLOUDFLARE_RANGES=(
  173.245.48.0/20
  103.21.244.0/22
  103.22.200.0/22
  103.31.4.0/22
  141.101.64.0/18
  108.162.192.0/18
  190.93.240.0/20
  188.114.96.0/20
  197.234.240.0/22
  198.41.128.0/17
  162.158.0.0/15
  104.16.0.0/13
  104.24.0.0/14
  172.64.0.0/13
  131.0.72.0/22
)

echo "[+] Adding rules for whitelisted IPs..."
for ip in "${WHITELIST[@]}"; do
  for port in 22 12667 9842 3306; do
    iptables -A INPUT -p tcp --dport $port -s $ip -j ACCEPT
  done
done

echo "[+] Adding Cloudflare ranges for all allowed ports..."
for ip in "${CLOUDFLARE_RANGES[@]}"; do
  for port in 22 12667 9842 3306; do
    iptables -A INPUT -p tcp --dport $port -s $ip -j ACCEPT
  done
done

echo "[+] Installing iptables-persistent and saving rules..."
apt-get update && apt-get install -y iptables-persistent
netfilter-persistent save

echo "[✓] Firewall rules successfully applied and saved."
