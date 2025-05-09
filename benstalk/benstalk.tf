data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

locals {
  dockerrun_aws_json = jsonencode({
    AWSEBDockerrunVersion = "3",
    containerDefinitions = [
      {
        name = "backend-container",
        image = "hardwak/cloud-backend:latest",
        portMappings = [
          {
            hostPort = 8081,
            containerPort = 8081
          }
        ],
        environment = [
          {
            name = "CORS_ALLOWED_ORIGINS",
            value = "http://${aws_elastic_beanstalk_environment.env.cname}:5173"
          }
        ]
      },
      {
        name = "frontend-container",
        image = "hardwak/cloud_frontend:latest",
        portMappings = [
          {
            hostPort = 5173,
            containerPort = 5173
          }
        ],
        environment = [
          {
            name = "PUBLIC_API_BASE_URL",
            value = "http://${aws_elastic_beanstalk_environment.env.cname}:8081"
          }
        ]
      }
    ]
  })
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
  content      = local.dockerrun_aws_json
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
  solution_stack_name = "64bit Amazon Linux 2023 v4.1.1 running ECS"

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
    value     = "t3.small"
  }
}

output "beanstalk_url" {
  value = aws_elastic_beanstalk_environment.env.cname
}
