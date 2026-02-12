############################################
# Generate DB Password
############################################

resource "random_password" "db" {
  length  = 16
  special = true
}

############################################
# Store DB Credentials in Secrets Manager
############################################

resource "aws_secretsmanager_secret" "db" {
  name = "rds-db-credentials-${var.environment}-${random_id.this.hex}"


  tags = {
    Name        = "rds-db-credentials-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "appuser"
    password = random_password.db.result
  })
}

############################################
# Security Group for RDS
############################################

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow PostgreSQL access from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rds-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

############################################
# RDS Module (PostgreSQL 15)
############################################

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.5.0"

  identifier = "app-db-${var.environment}"

  engine         = "postgres"
  engine_version = "15"
  family         = "postgres15"

  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name = "appdb"

  username = "appuser"
  password = random_password.db.result

  port = 5432

  ##########################################
  # Networking
  ##########################################

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  ##########################################
  # Security & Reliability
  ##########################################

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  ##########################################
  # Tags
  ##########################################

  tags = {
    Name        = "app-rds"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
