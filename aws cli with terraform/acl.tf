#acl for subnets
resource "aws_network_acl" "public" {
    vpc_id = aws_vpc.main.id
    subnet_ids = [ aws_subnet.public.id ]

    ingress {
        rule_no = 100
        protocol = -1
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    egress {
        rule_no = 100
        protocol = -1
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    tags = {
        Name = "public-subnet-acl"
    }
}

resource "aws_network_acl" "private" {
    vpc_id = aws_vpc.main.id
    subnet_ids = [ aws_subnet.private.id ]

    #all traffic in vpc
    ingress {
        rule_no = 100
        protocol = -1
        action = "allow"
        cidr_block = aws_vpc.main.cidr_block
        from_port = 0
        to_port = 0
    }

    #return traffic from internet
    ingress {
        rule_no = 200
        protocol = "tcp"
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 65535
    }

    #for ping
    ingress {
        rule_no = 300
        protocol = "icmp"
        action = "allow"
        cidr_block = aws_vpc.main.cidr_block
        from_port = 0
        to_port = 255
    }

    #allow all traffic to internet
    egress {
        rule_no = 100
        protocol = -1
        action = "allow"
        cidr_block = "0.0.0.0/0"
        from_port = 0
        to_port = 0
    }

    tags = {
        Name = "private-subnet-acl"
    }
}