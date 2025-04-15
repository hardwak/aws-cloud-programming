#endpoint for aws system manager
resource "aws_vpc_endpoint" "ssm" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.us-east-1.ssm"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true

    subnet_ids = [ aws_subnet.private.id ]
    security_group_ids = [aws_security_group.private_sg.id]
}
