resource "aws_db_subnet_group" "db_subnets" {
  name = "db-subnets-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public-2.id]
}

resource "aws_db_instance" "app_db" {
  allocated_storage = 10
  db_name = "appDatabase"
  engine = "postgres"
  engine_version = "17.2"
  instance_class = "db.t3.micro"
  username = "hardwak"
  password = "HardWak123!"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  skip_final_snapshot = true
}

