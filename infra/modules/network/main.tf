# A private-only VPC. There is deliberately no internet gateway and no NAT
# gateway: App Runner's VPC connector routes *all* app egress through here, so
# adding a managed NAT gateway would add ~$33/month for a demo that does not
# call anything outbound. RDS and ElastiCache live in these subnets; App
# Runner reaches the public internet on the ingress side only.
#
# When a demo needs outbound HTTPS (the model API in the coding-assistant
# demo), add a t4g.nano NAT instance in a public subnet (~$3/month) rather than
# a NAT gateway, or move that call to a Lambda outside the VPC.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.name}-private-${count.index + 1}" }
}

# No routes beyond the VPC's implicit local route.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name}-private" }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Attached to the App Runner VPC connector's ENIs.
resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "App Runner VPC connector ENIs"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name}-app" }
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Allow the app to reach the database and cache"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "PostgreSQL, reachable only from the app"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name}-database" }
}

resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL from the app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "cache" {
  name        = "${var.name}-cache"
  description = "Valkey, reachable only from the app"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name}-cache" }
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_app" {
  security_group_id            = aws_security_group.cache.id
  description                  = "Valkey from the app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}
