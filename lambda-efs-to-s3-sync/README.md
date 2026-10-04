# Lambda: EFS -> S3 sync

## What it does
The bridge between staging and archive: on a schedule, reads whatever rotated log files are sitting on the EFS access point, uploads each to S3, and only deletes it from EFS after the upload succeeds.

## Behaviour
- **Lambda mounts EFS directly** (`file_system_config`): the function reads log files as plain local files at `/mnt/logs` — no NFS client code, no separate copy step, Lambda handles the EFS connection itself via the access point.
- **VPC-attached**: because it talks to EFS (a VPC resource), the function runs inside the VPC (`vpc_config`) rather than Lambda's default non-VPC networking — this is also why it needs `AWSLambdaVPCAccessExecutionRole` instead of just the basic execution role.
- **Delete-after-confirm, not delete-then-upload**: `fs.unlinkSync` only runs after the S3 write resolves successfully — a failed upload leaves the file on EFS to be retried on the next scheduled run, rather than silently losing it.
- **Hourly schedule, not realtime**: logs don't need to land in S3 the instant they're rotated — an hourly batch keeps the Lambda's per-invocation cost and EFS read volume low compared to triggering on every single file write.
- **Narrow IAM policy**: the function's only S3 permission is `PutObject` on this specific bucket — it can't read, list, or delete anything in S3, only write new archive objects.

## Why it's needed
EC2 and EFS solve "don't lose logs when an instance is replaced"; this is the step that actually gets them to where long-term retention/lifecycle policy applies (see `../s3-archive`). Doing it as a scheduled Lambda rather than a cron job on a dedicated EC2 instance means there's no always-on server whose only job is occasionally copying files.
