#gateways
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "inetrnet-gw"
    }
}

resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id

    tags = {
        Name = "nat-gw"
    }
}


#route tables
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "public-route-table"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "private-route-table"
    }
}


#associate route table with subnet
resource "aws_route_table_association" "public" {
    route_table_id = aws_route_table.public.id
    subnet_id = aws_subnet.public.id
}

resource "aws_route_table_association" "private" {
    route_table_id = aws_route_table.private.id
    subnet_id = aws_subnet.private.id
}
