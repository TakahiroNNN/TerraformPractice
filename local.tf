locals {
  project     = "terraform_practice"
  environment = "test"
  region      = "ap-northeast-1"
  ip_address = {
    yatabe = ["11.22.33.44/32"]
  }
  vpc = {
    name       = "yatabe-nft"
    cidr_block = "10.0.0.0/16"
    subnet = {
      public = {
        a = "10.0.0.0/24"
        a = "10.0.4.0/24"
      }
    }
  }
  security_group = {
    bastion-linux = {
      cidr_block_rule = {
        ssh = {
          from_port = 22
          to_port   = 22
          protocol  = "TCP"
          cidr_blocks = concat(
            local.ip_address.yatabe,
            []
          )
        }
      }
    }
  }
  ec2 = {
    adm0000 = {
      ami           = ""
      instance_type = "t3.medium"
      subnet = {
        zone = "a"
      }
      security_groups = [
        "bastion-linux"
      ]
      volumes = {
        root = {
          size = 20
        }
      }
    }
  }
  /*
  alb = {
    public_subnet_zones = ["a", "c"]
    security_groups     = ["api-lb", "internal"]
    certificate_arn     = "arn:aws:acm:ap-northeast-1:..."
    target_group = {
      healthcheck_path = "/login"
    }
  }
  */
}
