#ec2 instances
resource "aws_instance" "public_ec2" {
    ami = "ami-071226ecf16aa7d96"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [ aws_security_group.public_sg.id ]
    associate_public_ip_address = true
    key_name = "ec2key"

    tags = {
        Name = "public-ec2"
    }
}

resource "aws_instance" "private_ec2" {
    ami = "ami-071226ecf16aa7d96"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private.id
    associate_public_ip_address = false
    vpc_security_group_ids = [aws_security_group.private_sg.id]
    key_name = "ec2key"

    tags = {
        Name = "private-ec2"
    }
}
