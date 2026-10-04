#!/bin/bash
# Mount the shared EFS staging filesystem (via its access point) and
# configure logrotate to copy rotated logs there instead of just deleting them.
mkdir -p /mnt/efs-logs
mount -t efs -o tls,accesspoint=${efs_access_point_id} ${efs_id}:/ /mnt/efs-logs

cat > /etc/logrotate.d/app <<'EOF'
/var/log/app/*.log {
    daily
    rotate 1
    compress
    missingok
    postrotate
        cp /var/log/app/*.log.1.gz /mnt/efs-logs/ 2>/dev/null || true
    endscript
}
EOF
