terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# aws configure
# aws configure set aws_session_token

# ssh -i C:\Users\ymher\Downloads\ec2key.pem ec2-user@ip
# aws ec2-instance-connect ssh --instance-id ...

# scp -i ec2key.pem ec2key.pem ec2-user@ip:~
# chmod 400 ec2key.pem

# curl ifconfig.me 

# nslookup ssm.us-east-1.amazonaws.com
# sudo yum install -y telnet
# telnet address_in_lookup 443
