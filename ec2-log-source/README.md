# EC2: log source

## What it does
Runs the application and produces logs. On its own it isn't a backup system — it's the stage-0 producer that the rest of the pipeline (EFS, then S3) exists to protect.

## Behaviour
- **Logrotate, not a live stream**: logs rotate locally on a daily cycle; it's the *rotated, compressed* file that gets copied to EFS (`postrotate`), not a live tail of the active log — this avoids copying a file that's still being actively written to.
- **IAM instance profile, no static credentials**: the instance authenticates to EFS (and AWS APIs generally) via its attached role (`AmazonElasticFileSystemClientReadWriteAccess`) — no access keys stored on the box.
- **Mounts via an access point, not the raw filesystem root**: `accesspoint=${efs_access_point_id}` scopes this instance to the `/logs` path with a fixed POSIX identity, matching what `../efs-staging` defines — the instance can't write outside that directory even if compromised.
- **TLS-encrypted NFS**: the `tls` mount option encrypts traffic between the instance and EFS, since log data is moving over the network.

## Why it's needed
This is simply where logs originate. The interesting design decisions — durability, retention, cost — all live downstream in EFS and S3; this component's only job is to get rotated log files off ephemeral instance storage and onto the shared staging filesystem reliably.
