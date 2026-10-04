# Example: EFS filesystem used as a staging area between EC2 log sources and
# the S3 archive.

resource "aws_efs_file_system" "logs" {
  creation_token  = "log-backup-efs"
  encrypted       = true
  throughput_mode = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "log-backup-efs"
  }
}

resource "aws_efs_mount_target" "logs" {
  for_each        = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.logs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name   = "log-backup-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }
}

# Scopes both EC2 writers and the sync Lambda to a single /logs directory
# inside the filesystem, rather than giving either root access to the whole
# filesystem.
resource "aws_efs_access_point" "logs" {
  file_system_id = aws_efs_file_system.logs.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/logs"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "750"
    }
  }
}
