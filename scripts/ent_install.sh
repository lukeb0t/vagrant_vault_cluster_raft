
sudo wget https://releases.hashicorp.com/vault/1.7.1+ent/vault_1.7.1+ent_linux_amd64.zip
apt-get install unzip
unzip vault_1.7.1+ent_linux_amd64.zip
sudo chown root:root vault
sudo mv vault /usr/bin/
sudo setcap cap_ipc_lock=+ep /usr/bin/vault
sudo useradd --system --home /etc/vault.d --shell /bin/false vault
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
sudo mkdir /etc/vault.d
sudo mkdir /opt/vault
sudo mkdir /opt/vault/data
sudo chown -R vault:vault /opt/vault

## configure service init file
cat <<EOF > /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

## set envars
sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
EOF
export VAULT_ADDR="http://127.0.0.1:8200" 

## enable vault service
sudo systemctl enable vault.service