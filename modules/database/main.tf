resource "aws_db_instance" "app_database" {
  allocated_storage = var.allocated_storage
  instance_class    = var.db_instance_class
  engine            = "mysql"
  engine_version    = var.db_engine_version
  db_name           = var.db_name
  username          = var.db_user
  password          = var.db_pasword
  db_subnet_group_name = var.db_subnet_group_name
  #The name of the RDS instance
  identifier        = var.identifier
  #Determines whether a final DB snapshot is created before the DB instance is deleted
  skip_final_snapshot = var.db_skip_snapshot
  vpc_security_group_ids = [var.rds_sg]

  tags = {
    Name = "app_db"
  }
}