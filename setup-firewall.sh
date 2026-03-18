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

#echo "[+] Allowing public HTTP/HTTPS access..."
#iptables -A INPUT -p tcp --dport 80 -j ACCEPT
#iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# IPs allowed for SSH, 12667, 9842, and 3306
WHITELIST=(
  64.226.113.132
)

# Cloudflare IP Ranges (allowed on all restricted ports)
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
  for port in 22 12667 9842 3306 80 443 10050  3390 10051; do
    iptables -A INPUT -p tcp --dport $port -s $ip -j ACCEPT
  done
done

echo "[+] Adding Cloudflare ranges for all allowed ports..."
for ip in "${CLOUDFLARE_RANGES[@]}"; do
  for port in 22 12667 9842 3306 80 443 10050 3390 10051; do
    iptables -A INPUT -p tcp --dport $port -s $ip -j ACCEPT
  done
done

echo "[+] Adding explicit DROP for all other TCP traffic on sensitive ports..."
for port in 22 12667 9842 3306 80 3390 443; do
  iptables -A INPUT -p tcp --dport $port -j DROP
done

echo "[+] Installing iptables-persistent and saving rules..."
apt-get update && apt-get install -y iptables-persistent
netfilter-persistent save

echo "[✓] Firewall rules successfully applied and saved."
