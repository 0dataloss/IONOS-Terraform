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
  name        = "Kubernetes Demo Platform"
  location    = "gb/lhr"
  description = "VDC managed by Terraform - do not edit manually"
}

///////////////////////////////////////////////////////////
// K8S Control Plane Instance
///////////////////////////////////////////////////////////

resource "ionoscloud_k8s_cluster" "Kubernetes_Control_Plane" {
  name        = "K8Scluster_Control_Plane"
  k8s_version = "1.21.4"
  maintenance_window {
    day_of_the_week = "Sunday"
    time            = "02:30:00Z"
  }
}

///////////////////////////////////////////////////////////
// K8S Node-Pool
///////////////////////////////////////////////////////////
# K8S Pool setup
resource "ionoscloud_k8s_node_pool" "Kubernetes_Node_Pool" {
  name        = "Node_Pool"
  k8s_version = "1.21.4"
  maintenance_window {
    day_of_the_week = "Sunday"
    time            = "03:30:00Z"
  }
  datacenter_id     = ionoscloud_datacenter.Customer_DC.id
  k8s_cluster_id    = ionoscloud_k8s_cluster.Kubernetes_Control_Plane.id
  cpu_family        = "INTEL_SKYLAKE"
  availability_zone = "AUTO"
  storage_type      = "HDD"
  node_count        = 2
  cores_count       = 2
  ram_size          = 2048
  storage_size      = 10
}
