# EFS: log staging

## What it does
Sits between EC2 log sources and the S3 archive — EC2 instances write rotated logs here, and a scheduled Lambda (see `../lambda-efs-to-s3-sync`) reads from here and uploads to S3.

## Behaviour
- **EFS's own lifecycle policy** (`transition_to_ia`): EFS has a *separate* cost-tiering mechanism from the S3 one — files not accessed for 30 days move to EFS Infrequent Access automatically, which matters here because logs can sit in staging for a while between an instance writing them and the sync Lambda's next scheduled run.
- **Access point, not raw filesystem access**: both EC2 and the sync Lambda mount the filesystem through `aws_efs_access_point.logs`, which fixes them to `/logs` with a specific POSIX uid/gid — neither can wander outside that directory or operate as a different user, even though they're sharing one filesystem.
- **Mount target per subnet, not per instance**: EFS is accessed over NFS via a mount target in each subnet/AZ — every instance in that subnet reaches the same shared filesystem through its local mount target, rather than needing a direct connection to a single EFS endpoint.
- **Encrypted at rest**: log data often includes sensitive request/response detail — encrypted by default rather than as an opt-in.

## Why it's needed
EC2 instances are disposable (replaced on failure, scaled in/out) — if logs only lived on local instance disk, terminating an instance would delete its logs before they're archived. EFS gives every instance a shared, durable, always-available place to land logs that survives any single instance's lifecycle, decoupling "logs got written" from "logs got archived".
