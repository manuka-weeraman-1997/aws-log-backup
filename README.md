# AWS Log Backup

A log backup pipeline moving data through three storage tiers, each chosen for a different reason, ending in a cost-managed S3 archive.

```
EC2 (produces + rotates logs)
  |  logrotate copies rotated files
  v
EFS (durable shared staging, survives instance replacement)
  |  scheduled Lambda uploads, then deletes once confirmed
  v
S3 (long-term archive, automatic lifecycle: Standard -> IA -> Glacier -> Deep Archive -> expire)
```

| Component | What it is | Why it's here |
|---|---|---|
| [`ec2-log-source/`](ec2-log-source) | EC2 instance + logrotate | Where logs actually originate |
| [`efs-staging/`](efs-staging) | EFS filesystem + access point | Durable staging that outlives any one instance |
| [`lambda-efs-to-s3-sync/`](lambda-efs-to-s3-sync) | Scheduled Lambda | Moves rotated logs from EFS into the S3 archive |
| [`s3-archive/`](s3-archive) | S3 bucket + lifecycle configuration | Long-term, cost-tiered retention with automatic expiration |

See [`aws-infrastructure`](https://github.com/manuka-weeraman-1997/aws-infrastructure) for the general-purpose compute/streaming/load-balancing patterns this builds on.

Author: Manuka Weeraman — Platform Engineer
