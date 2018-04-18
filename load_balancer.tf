resource "aws_elb" "kube_api" {
  name = "terraform-elb"

  subnets         = ["${aws_subnet.public.0.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.control_plane.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400


  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:6443"
    interval            = 30
  }
}

resource "aws_route53_record" "kube_api" {
    zone_id = "${var.route53_zone_id}"
    name    = "${var.route53_elb_cname}"
    type    = "CNAME"
    ttl     = "300"
    records = ["${aws_elb.kube_api.dns_name}"]

}

output "elb_address" {
  value = "${aws_elb.kube_api.dns_name}"
}