/*
resource "aws_launch_configuration" "control_plane" {
  name_prefix   = "control-plane-"
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.large"

  security_groups = ["${aws_security_group.ssh.id}",
    "${aws_security_group.icmp.id}",
    "${aws_security_group.egress.id}",
    "${aws_security_group.kube.id}",
  ]

  iam_instance_profile = "${aws_iam_instance_profile.control_plane.name}"
  key_name             = "${aws_key_pair.kube.key_name}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  associate_public_ip_address = true

  user_data = "${data.template_cloudinit_config.control_plane.rendered}"
}

resource "aws_autoscaling_group" "control_plane" {
  name                 = "control-plane"
  launch_configuration = "${aws_launch_configuration.control_plane.name}"

  desired_capacity     = "${var.control_plane_num}"
  min_size             = "${var.control_plane_num}"
  max_size             = "${var.control_plane_num + 1}"
  termination_policies = ["OldestInstance"]
  health_check_type    = "EC2"

  vpc_zone_identifier = ["${aws_subnet.public.*.id}"]

  lifecycle {
    create_before_destroy = true
  }

  wait_for_capacity_timeout = "15m"

  tag {
    key                 = "Name"
    value               = "control-plane"
    propagate_at_launch = true
  }
}
*/

resource "aws_instance" "control_plane" {
  ami = "${data.aws_ami.ubuntu.id}"

  instance_type = "t2.large"

  subnet_id = "${aws_subnet.public.0.id}"

  vpc_security_group_ids = ["${aws_security_group.ssh.id}",
    "${aws_security_group.icmp.id}",
    "${aws_security_group.egress.id}",
    "${aws_security_group.kube.id}",
    "${aws_security_group.allow_https.id}",
  ]

  source_dest_check = false

  iam_instance_profile = "${aws_iam_instance_profile.control_plane.name}"
  key_name             = "${aws_key_pair.kube.key_name}"

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  /* TODO storage for etcd
    ebs_block_device {
      device_name           = "/dev/xvdb"
      volume_type           = "gp2"
      volume_size           = 20
      delete_on_termination = false
    } 
    */

  tags {
    Name = "control-plane"
    "kubernetes.io/cluster/jpw" = "jpw" 
  }
  associate_public_ip_address = true
  user_data = "${data.template_cloudinit_config.control_plane.rendered}"

  connection {
        user = "ubuntu"
        private_key = "${file("/Users/jamesweber/.ssh/id_rsa")}"
    }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p $HOME/.kube",
      "until ls /etc/kubernetes/admin.conf; do sleep 3; done",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "cat $HOME/.kube/config"
    ]
  }
  
  # provisioner "local-exec" {
  #   command = "scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null ubuntu@${aws_instance.control_plane.public_ip}:/home/ubuntu/.kube/config/ ~/kube-config.tf"
  #   command = "sed -i '' 's/10.1.*:6443/k8s.supercomputerrobot.com/g' /Users/jamesweber/kube-config.tf"
  # }

}

data "template_file" "control_plane" {
  template = "${file("${path.root}/control_plane.tpl")}"

  vars {
    k8s_token = "${var.k8s_token}",
    elb_dnsname = "${var.route53_elb_cname}",
  }
}

data "template_cloudinit_config" "control_plane" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.control_plane.rendered}"
  }
}

output "control_plane.public_ip" {
  value = "${aws_instance.control_plane.public_ip}"
}