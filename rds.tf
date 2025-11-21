resource "aws_db_instance" "db" {
  identifier              = "mydb"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = "sakshith"
  password                = random_password.rds_password.result
  db_subnet_group_name    = aws_db_subnet_group.sakshith_01_db_subnet.name
  vpc_security_group_ids  = [aws_security_group.sakshith_01_db_sg.id]
  skip_final_snapshot     = true
  publicly_accessible = true
  multi_az                = false

  tags = {
    Name = "sakshith-rds-instance"
  }
}


resource "aws_db_subnet_group" "sakshith_01_db_subnet" {
  name       = "sakshith-01-db-subnet-group"
  subnet_ids = aws_subnet.sakshith_01_subnet[*].id

  tags = {
    Name = "sakshith-01-db-subnet-group"
  }
}



# Generate a strong random password for RDS
resource "random_password" "rds_password" {
  length  = 16
  special = true
}


# RDS Security Group
resource "aws_security_group" "sakshith_01_db_sg" {
  name        = "sakshith_01-db-sg"
  description = "Allow MySQL access for RDS"
  vpc_id      = aws_vpc.sakshith_01_vpc.id

  ingress {
    description = "Allow MySQL traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ For testing only; restrict later to your app subnet or EC2 SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sakshith_01-db-sg"
  }
}
output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}

output "rds_password" {
  value     = aws_db_instance.db.password
  sensitive = true
}