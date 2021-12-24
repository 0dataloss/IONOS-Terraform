terraform {
  required_providers {
    ionoscloud = {
      source = "ionos-cloud/ionoscloud"
      version = "= 6.0.0-beta.14"
    }
  }
}
provider "ionoscloud" {
  username = var.IONOS_user
  password = var.IONOS_password
}

///////////////////////////////////////////////////////////
// Virtual Data Center
///////////////////////////////////////////////////////////

resource "ionoscloud_datacenter" "Customer_DC" {
  name        = "Magento_Scalable_Hosting_Platform"
  location    = "gb/lhr"
  description = "VDC managed by Terraform - do not edit manually"
}

///////////////////////////////////////////////////////////
// Network LAN
///////////////////////////////////////////////////////////

resource "ionoscloud_lan" "public_lan" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  public        = true
  name          = "publicLAN"
}

///////////////////////////////////////////////////////////
// Network PRIVATE LB2WEB
///////////////////////////////////////////////////////////

resource "ionoscloud_lan" "LB2WEB_lan" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  public        = false
  name          = "LB2WEB_lan"
}

///////////////////////////////////////////////////////////
// Network PRIVATE WEB2DB
///////////////////////////////////////////////////////////

resource "ionoscloud_lan" "WEB2DB_lan" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  public        = false
  name          = "WEB2DB_lan"
}

///////////////////////////////////////////////////////////
// Network PRIVATE DB2DB
///////////////////////////////////////////////////////////

resource "ionoscloud_lan" "DB2DB_lan" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  public        = false
  name          = "DB2DB_lan"
}

///////////////////////////////////////////////////////////
// Webservers
///////////////////////////////////////////////////////////

resource "ionoscloud_server" "webserver01" {
  name              = "webserver01"
  datacenter_id     = ionoscloud_datacenter.Customer_DC.id
  cores             = 2
  ram               = 4096
  cpu_family        = "INTEL_SKYLAKE"
  availability_zone = "ZONE_1"
  image_name        = "cd05e12b-526d-11ec-bfd0-46b2a98527cd"
  ssh_key_path      = [ "${var.ssh_pub_key}" ]
  #  image_password    = var.console_password
  volume {
    name              = "webserver01"
    size              = 20
    disk_type         = "HDD"
    availability_zone = "ZONE_2"
  }
  nic {
    name = "Public_NIC"
    lan  = ionoscloud_lan.public_lan.id
    dhcp = true
    firewall_active = true
  }
}

resource "ionoscloud_server" "webserver02" {
  name              = "webserver02"
  datacenter_id     = ionoscloud_datacenter.Customer_DC.id
  cores             = 2
  ram               = 4096
  cpu_family        = "INTEL_SKYLAKE"
  availability_zone = "ZONE_2"
  image_name        = "cd05e12b-526d-11ec-bfd0-46b2a98527cd"
  ssh_key_path      = [ "${var.ssh_pub_key}" ]
  #  image_password    = var.console_password
  volume {
    name              = "webserver02"
    size              = 20
    disk_type         = "HDD"
    availability_zone = "ZONE_3"
  }
  nic {
    name = "Public_NIC"
    lan  = ionoscloud_lan.public_lan.id
    dhcp = true
    firewall_active = true
  }
}
/////////////////////////////////////////
// webserver Firewalls
//////////////////////////////////////////
resource "ionoscloud_firewall" "webserver_public" {
  datacenter_id    = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id        = "${ionoscloud_server.webserver01.id}"
  nic_id           = "${ionoscloud_server.webserver01.primary_nic}"
  protocol         = "TCP"
  port_range_start = 22
  port_range_end   = 22
  source_ip        = var.origin_IP01
}

resource "ionoscloud_firewall" "webserver02_public" {
  datacenter_id    = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id        = "${ionoscloud_server.webserver02.id}"
  nic_id           = "${ionoscloud_server.webserver02.primary_nic}"
  protocol         = "TCP"
  port_range_start = 22
  port_range_end   = 22
  source_ip        = var.origin_IP01
}

///////////////////////////////////////////////////////////
// webserver NicS
///////////////////////////////////////////////////////////

resource "ionoscloud_nic" "webserver01_2lb_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.webserver01.id
  lan           = ionoscloud_lan.LB2WEB_lan.id
  name          = "PrivateWEB2LB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "webserver02_2lb_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.webserver02.id
  lan           = ionoscloud_lan.LB2WEB_lan.id
  name          = "PrivateWEB2LB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "webserver01_2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.webserver01.id
  lan           = ionoscloud_lan.WEB2DB_lan.id
  name          = "PrivateWEB2DB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "webserver02_2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.webserver02.id
  lan           = ionoscloud_lan.WEB2DB_lan.id
  name          = "PrivateWEB2DB_NIC"
  dhcp          = true
}

/////////////////////////////////////////
// Database Servers
//////////////////////////////////////////
resource "ionoscloud_server" "database01" {
  name              = "database01"
  datacenter_id     = ionoscloud_datacenter.Customer_DC.id
  cores             = 2
  ram               = 4096
  cpu_family        = "INTEL_SKYLAKE"
  availability_zone = "ZONE_1"
  image_name        = "cd05e12b-526d-11ec-bfd0-46b2a98527cd"
  ssh_key_path      = [ "${var.ssh_pub_key}" ]
  #  image_password    = var.console_password
  volume {
    name              = "database01"
    size              = 20
    disk_type         = "HDD"
    availability_zone = "ZONE_1"
  }
  nic {
    name = "Public_NIC"
    lan  = ionoscloud_lan.public_lan.id
    dhcp = true
    firewall_active = true
  }
}
resource "ionoscloud_volume" "database01_storage" {
  datacenter_id = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id     = "${ionoscloud_server.database01.id}"
  name          = "database01_storage"
  licence_type    = "LINUX"
  size          = 100
  disk_type     = "SSD"
  availability_zone = "ZONE_2"
}

resource "ionoscloud_server" "database02" {
  name              = "database02"
  datacenter_id     = ionoscloud_datacenter.Customer_DC.id
  cores             = 2
  ram               = 4096
  cpu_family        = "INTEL_SKYLAKE"
  availability_zone = "ZONE_2"
  image_name        = "cd05e12b-526d-11ec-bfd0-46b2a98527cd"
  ssh_key_path      = [ "${var.ssh_pub_key}" ]
  #  image_password    = var.console_password
  volume {
    name              = "database02"
    size              = 20
    disk_type         = "HDD"
    availability_zone = "ZONE_2"
  }
  nic {
    name = "Public_NIC"
    lan  = ionoscloud_lan.public_lan.id
    dhcp = true
    firewall_active = true
  }
}
resource "ionoscloud_volume" "database02_storage" {
  datacenter_id = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id     = "${ionoscloud_server.database02.id}"
  name          = "database02_storage"
  licence_type    = "LINUX"
  size          = 100
  disk_type     = "SSD"
  availability_zone = "ZONE_3"
}
/////////////////////////////////////////
// Database Firewall
//////////////////////////////////////////
resource "ionoscloud_firewall" "database01_public" {
  datacenter_id    = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id        = "${ionoscloud_server.database01.id}"
  nic_id           = "${ionoscloud_server.database01.primary_nic}"
  protocol         = "TCP"
  port_range_start = 22
  port_range_end   = 22
  source_ip        = var.origin_IP01
}
resource "ionoscloud_firewall" "database02_public" {
  datacenter_id    = "${ionoscloud_datacenter.Customer_DC.id}"
  server_id        = "${ionoscloud_server.database02.id}"
  nic_id           = "${ionoscloud_server.database02.primary_nic}"
  protocol         = "TCP"
  port_range_start = 22
  port_range_end   = 22
  source_ip        = var.origin_IP01
}

///////////////////////////////////////////////////////////
// Database NicS
///////////////////////////////////////////////////////////

resource "ionoscloud_nic" "database01_web2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.database01.id
  lan           = ionoscloud_lan.WEB2DB_lan.id
  name          = "PrivateWEB2DB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "database02_web2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.database02.id
  lan           = ionoscloud_lan.WEB2DB_lan.id
  name          = "PrivateWEB2DB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "database01_db2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.database01.id
  lan           = ionoscloud_lan.DB2DB_lan.id
  name          = "PrivateDB2DB_NIC"
  dhcp          = true
}
resource "ionoscloud_nic" "database02_db2db_nic" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  server_id     = ionoscloud_server.database02.id
  lan           = ionoscloud_lan.DB2DB_lan.id
  name          = "PrivateDB2DB_NIC"
  dhcp          = true
}
///////////////////////////////////////////////////////////
// Network Load Balancer
///////////////////////////////////////////////////////////
resource "ionoscloud_ipblock" "NLBIP" {
  location = "${ionoscloud_datacenter.Customer_DC.location}"
  name     = "WebLB"
  size     = 1
}
resource "ionoscloud_networkloadbalancer" "WebLB" {
  datacenter_id = ionoscloud_datacenter.Customer_DC.id
  name          = "WebLB"
  listener_lan  = ionoscloud_lan.public_lan.id
  target_lan    = ionoscloud_lan.LB2WEB_lan.id
  ips           =["${ionoscloud_ipblock.NLBIP.ips[0]}"]
}
resource "ionoscloud_networkloadbalancer_forwardingrule" "httpsrule" {
 datacenter_id = ionoscloud_datacenter.Customer_DC.id
 networkloadbalancer_id = ionoscloud_networkloadbalancer.WebLB.id
 name = "HTTPS"
 algorithm = "SOURCE_IP"
 protocol = "TCP"
 listener_ip = "${ionoscloud_ipblock.NLBIP.ips[0]}"
 listener_port = "443"
 targets {
   ip = "${ionoscloud_server.webserver02.nic[0].ips[0]}"
   port = "443"
   weight = "1"
   health_check {
     check = true
     check_interval = 1000
   }
 }
 targets {
   ip = "${ionoscloud_server.webserver01.nic[0].ips[0]}"
   port = "443"
   weight = "1"
   health_check {
     check = true
     check_interval = 1000
    }
 }
}
