resource "aws_iam_instance_profile" "control_plane" {
  name  = "control_plane"
  role = "${aws_iam_role.control_plane.name}"
}

resource "aws_iam_instance_profile" "nodes" {
  name  = "nodes"
  role = "${aws_iam_role.nodes.name}"
}

resource "aws_iam_role" "control_plane" {
  name               = "control_plane"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_ec2.json}"
}

resource "aws_iam_role" "nodes" {
  name               = "nodes"
  path               = "/system/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_ec2.json}"
}

data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_policy" "control_plane_ec2" {
  name   = "control_plane_ec2"
  policy = "${data.aws_iam_policy_document.control_plane_ec2.json}"
}

resource "aws_iam_policy" "nodes_ec2" {
  name   = "nodes_ec2"
  policy = "${data.aws_iam_policy_document.nodes_ec2.json}"
}

data "aws_iam_policy_document" "control_plane_ec2" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:*",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_iam_policy_document" "nodes_ec2" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:Describe*",
      "ec2:ModifyInstanceAttribute",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
   ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]

    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy_attachment" "control_plane_ec2_attachment" {
  name       = "control_plane_ec2_attachment"
  roles      = ["${aws_iam_role.control_plane.name}"]
  policy_arn = "${aws_iam_policy.control_plane_ec2.arn}"
}

resource "aws_iam_policy_attachment" "nodes_ec2_attachment" {
  name       = "nodes_ec2_attachment"
  roles      = ["${aws_iam_role.nodes.name}"]
  policy_arn = "${aws_iam_policy.nodes_ec2.arn}"
}
