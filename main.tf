#https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}
resource "kubernetes_namespace" "test" {
  metadata {
    name = "decoya-assignment"
  }
}
resource "kubernetes_deployment" "test" {
  metadata {
    name      = "decoya-assignment"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "DecoyaAssignment"
      }
    }
    template {
      metadata {
        labels = {
          app = "DecoyaAssignment"
        }
      }
      spec {
        container {
          image = "vladbronfman/decoya-assignment:latest"
          name  = "decoya-assignment-container"
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "share-vol"
            mount_path = "/var/www/html/config"
          }
          
        }
        init_container {
          name  = "tools"
          image = "alpine:3.12"
          command = [
            "/bin/sh", "-c", "hostname -f > /data/filetoreadfrom"
          ]

          volume_mount {
            name       = "share-vol"
            mount_path = "/data"
          }

        }
        volume {
          empty_dir {}
          name = "share-vol"
        }
      }
    }
  }
}
resource "kubernetes_service" "test" {
  metadata {
    name      = "decoya-assignment-svc"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 8080
    }
  }
}