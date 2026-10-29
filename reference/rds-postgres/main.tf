# RDS = managed relational databases (PostgreSQL, MySQL, MariaDB, SQL Server,
# Oracle). AWS handles installation, patching, backups, failover and
# monitoring; you still design the schema and tune queries.
#
#   subnet group    -> which (private) subnets the DB may live in
#   security group  -> who may connect on the DB port (only your app servers!)
#   parameter group -> engine settings (postgresql.conf)
#   instance        -> size, storage, engine version, backups, Multi-AZ
#
# Production checklist shown in comments: private subnets, Multi-AZ,
# deletion protection, final snapshot, password managed by Secrets Manager.

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "demo-db"
  subnet_ids = data.aws_subnets.default.ids # prod: PRIVATE subnets only
}

resource "aws_security_group" "db" {
  name        = "demo-db"
  description = "Postgres from inside the VPC only"
  vpc_id      = data.aws_vpc.default.id
}

# Prod: reference the APP's security group instead of a CIDR
# (referenced_security_group_id), so only app servers can connect.
resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = data.aws_vpc.default.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_db_parameter_group" "pg" {
  name   = "demo-pg17"
  family = "postgres17"

  parameter {
    name  = "log_min_duration_statement"
    value = "500" # log queries slower than 500 ms
  }
}

resource "aws_db_instance" "main" {
  identifier     = "demo-postgres"
  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.micro" # smallest current-gen; free-tier eligible

  allocated_storage     = 20
  max_allocated_storage = 100 # storage autoscaling up to 100 GB
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "shop"
  username = "app_admin"
  # RDS generates the password and keeps it in Secrets Manager (rotated for
  # you); it never appears in Terraform code or state.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.pg.name
  publicly_accessible    = false

  backup_retention_period = 7             # daily snapshots kept 7 days, point-in-time restore
  backup_window           = "03:00-04:00" # UTC
  maintenance_window      = "sun:04:30-sun:05:30"

  multi_az            = false # prod: true (standby in another AZ, automatic failover)
  deletion_protection = false # prod: true
  skip_final_snapshot = true  # prod: false + final_snapshot_identifier
  apply_immediately   = true  # dev: apply changes now instead of in the maintenance window
}
