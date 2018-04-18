resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow only ssh"
  vpc_id      = "${aws_vpc.platform.id}"

  // allow traffic for TCP 22
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ssh"
  }
}

resource "aws_security_group" "LBPorts" {
  name        = "LBPorts"
  description = "Allow load balancers to hit high ports"
  vpc_id      = "${aws_vpc.platform.id}"

  // allow traffic for TCP 22
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  tags {
    Name = "LBPorts"
  }
}

resource "aws_security_group" "icmp" {
  name        = "icmp"
  description = "Allow ping bettween instances"
  vpc_id      = "${aws_vpc.platform.id}"

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = []
    self            = true
  }

  egress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = []
    cidr_blocks     = ["${var.vpc_cidr_block}"]
  }

  tags {
    Name = "icmp"
  }
}

resource "aws_security_group" "egress" {
  name        = "egress"
  description = "egress Traffic"
  vpc_id      = "${aws_vpc.platform.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "egress"
  }
}

resource "aws_security_group" "kube" {
  name        = "kube"
  description = "give access to everything for now"
  vpc_id      = "${aws_vpc.platform.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_block}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${lookup(var.private_subnet_blocks, count.index)}"]
  }

  tags {
    Name                                 = "kube"
    "kubernetes.io/cluster/${var.stage}" = "${var.stage}"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "allow-https-to-kubeapi"
  description = "give access to 6443 port"
  vpc_id      = "${aws_vpc.platform.id}"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "allow-https"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "kube-api"
  description = "give access to kube api server"
  vpc_id      = "${aws_vpc.platform.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
