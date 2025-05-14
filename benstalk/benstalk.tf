data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "eb-instance-profile"
  role = data.aws_iam_role.lab_role.name
}

resource "aws_elastic_beanstalk_application" "app" {
  name = "cloud-chat"
}

resource "aws_s3_bucket" "app_deployment" {
  bucket_prefix = "eb-docker-deploy-"
  force_destroy = true
}

resource "aws_s3_object" "dockerrun" {
  bucket       = aws_s3_bucket.app_deployment.id
  key          = "Dockerrun.aws.json"
  content      = file("${path.module}/Dockerrun.aws.json")
  content_type = "application/json"
}

resource "aws_elastic_beanstalk_application_version" "latest" {
  name        = "app-version-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.app_deployment.id
  key         = aws_s3_object.dockerrun.key
  depends_on  = [aws_s3_object.dockerrun]
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "app-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.1 running ECS"
  version_label       = aws_elastic_beanstalk_application_version.latest.name

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.main.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.public.id},${aws_subnet.public-2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public.id},${aws_subnet.public-2.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.app_sg.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.large"
  }
}

output "beanstalk_url" {
  value = aws_elastic_beanstalk_environment.env.cname
}
