#!/bin/bash
set -e

echo "[INFO] Generating /etc/ceph/ceph.conf..."
sudo microceph.ceph config generate-minimal-conf > /etc/ceph/ceph.conf

echo "[INFO] Writing /etc/ceph/ceph.client.admin.keyring..."
sudo tee /etc/ceph/ceph.client.admin.keyring > /dev/null <<EOF
[client.admin]
key = AQDfQQVpK+W/ABAAIaMblIB2nItPq9Np9EqSMQ==
caps mds = "allow *"
caps mgr = "allow *"
caps mon = "allow *"
caps osd = "allow *"
EOF

echo "[INFO] Setting permissions..."
sudo chmod 600 /etc/ceph/ceph.client.admin.keyring

echo "[INFO] Creating /usr/local/bin/mount-cephfs.sh..."
sudo tee /usr/local/bin/mount-cephfs.sh > /dev/null <<'EOF'
#!/bin/bash
echo "[INFO] Mounting CephFS to /data/shared..."

mount -t ceph 10.10.20.51:6789,10.10.20.52:6789,10.10.20.53:6789:/ /data/shared \
  -o name=admin,secret=AQDfQQVpK+W/ABAAIaMblIB2nItPq9Np9EqSMQ==,conf=/etc/ceph/ceph.conf

exit $?
EOF

sudo chmod +x /usr/local/bin/mount-cephfs.sh

echo "[INFO] Creating systemd service: /etc/systemd/system/mount-cephfs.service..."
sudo tee /etc/systemd/system/mount-cephfs.service > /dev/null <<EOF
[Unit]
Description=Mount CephFS at /data/shared using script
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/mount-cephfs.sh
RemainAfterExit=true
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

echo "[INFO] Reloading systemd, enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable --now mount-cephfs.service

echo "[DONE] CephFS is configured and mounted."
sudo df -h
