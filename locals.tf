locals {
  public_subnets = {
    public_subnet_1 = {
      cidr_block        = "192.168.0.0/19"
      availability_zone = "us-east-1a"
    }
    public_subnet_2 = {
      cidr_block        = "192.168.32.0/19"
      availability_zone = "us-east-1b"
    }
    public_subnet_3 = {
      cidr_block        = "192.168.64.0/19"
      availability_zone = "us-east-1c"
    }
  }
}

locals {
  private_subnets = {
    private_subnet_1 = {
      cidr_block        = "192.168.96.0/19"
      availability_zone = "us-east-1d"
    }
    private_subnet_2 = {
      cidr_block        = "192.168.128.0/19"
      availability_zone = "us-east-1e"
    }
    private_subnet_3 = {
      cidr_block        = "192.168.160.0/19"
      availability_zone = "us-east-1f"
    }
  }
}
locals {
  # SSH is handled separately and restricted to var.ssh_allowed_cidr.
  web_ingress_ports = {
    http  = 80
    https = 443
  }
}
