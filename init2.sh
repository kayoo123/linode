
## freedns
mkdir -p /DATA/scripts
cat > /DATA/scripts/update_DNS.sh << "EOF"
#!/bin/sh
#FreeDNS updater script
# 02 * * * * root /DATA/scripts/update_DNS.sh

UPDATEURL="http://freedns.afraid.org/dynamic/update.php?cXQ5a3VpcTdUejR4QnpOVHZhTFJ0cnc1OjIwMjg5MTc5"
DOMAIN="jeremi.fr.to"

registered=$(nslookup $DOMAIN|tail -n2|grep A|sed s/[^0-9.]//g)
current=$(wget -q -O - http://checkip.dyndns.org|sed s/[^0-9.]//g)

[ "$current" != "$registered" ] && {
        wget -q -O /dev/null $UPDATEURL
        echo "DNS updated on: $(date)"
}
EOF
sudo chmod +x /DATA/scripts/update_DNS.sh
echo '02 * * * * root /DATA/scripts/update_DNS.sh' > /etc/cron.d/freedns
sudo service cron restart

## docker 
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

## docker-compose 
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

