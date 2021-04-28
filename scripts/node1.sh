#!/bin/bash

sudo -s
cat << EOF > /etc/vault.d/vault.hcl
ui = true
disable_mlock = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "node1"

  retry_join {
    leader_api_addr = "http://192.168.50.152:8200"
  }
  retry_join {
    leader_api_addr = "http://192.168.50.153:8200"
  }
}

cluster_addr = "http://192.168.50.151:8201"
api_addr = "http://192.168.50.151:8200"

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = true
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}
EOF

## start / restart vault service
sudo systemctl restart vault

sleep 10

# init and store envars 

vault operator init -key-shares=1 -key-threshold=1 > /opt/vagrant/vault-init
# Extract unseal key and root token
export UNSEAL=$(grep 'Unseal' /opt/vagrant/vault-init | awk '{ print $NF }' )
export VAULT_TOKEN=$(grep 'Root Token' /opt/vagrant/vault-init | awk '{ print $NF }' )

## add envars to bash profile
sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
export UNSEAL=$(grep 'Unseal' /opt/vagrant/vault-init | awk '{ print $NF }' )
export VAULT_TOKEN=$(grep 'Root Token' /opt/vagrant/vault-init | awk '{ print $NF }' )
vault operator unseal $UNSEAL
EOF

# Unseal vault
vault operator unseal $UNSEAL
