#https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started
# https://aperogeek.fr/kubernetes-deployment-with-terraform/

resource "kubernetes_namespace" "challenge" {
  metadata {
    name = var.namespaceifany
  }
}

resource "kubernetes_deployment" "challenge" {
  metadata {
    name      = "decoya-assignment"
    namespace = kubernetes_namespace.challenge.metadata.0.name
  }

  spec {
    replicas = var.numofreplicas
    selector {
      match_labels = {
        app = "DecoyaAssignment"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "DecoyaAssignment"
        }
      }
      spec {
        container {
          image = var.imagename
          name  = "decoya-assignment-container"
          port {
            container_port = 8080
          }
          volume_mount {
            name       = "share-vol"
            mount_path = "/var/www/html/config"
          }

          image_pull_policy = "Always" 

          liveness_probe {
            tcp_socket { #http_get 
              port = 8080
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 2
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
resource "kubernetes_service" "challenge" {
  metadata {
    name      = "decoya-assignment-svc"
    namespace = kubernetes_namespace.challenge.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.challenge.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 8080
    }
  }
}


#Ingress

#https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress
# resource "kubernetes_ingress" "example" {
#   wait_for_load_balancer = true
#   metadata {
#     name = "decoya-assignment-ing"
#     namespace = "${kubernetes_namespace.challenge.metadata.0.name}"

#     # annotations = {
#     #   "kubernetes.io/ingress.class" = "nginx"
#     # }
#   }
#   spec {
#     rule {
#       http {
#         path {
#           path = "/"
#           backend {
#             service_name = kubernetes_service.challenge.metadata.0.name
#             service_port = 80
#           }
#         }
#       }
#     }
#   }
# }

#https://stackoverflow.com/questions/70497809/terraform-fails-to-create-ingress-could-not-find-the-requested-resource-ingress

resource "kubernetes_ingress_v1" "challenge" {
  metadata {
    name = "decoya-assignment-ing"
    namespace = kubernetes_namespace.challenge.metadata.0.name
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/"
          backend {
            service {
              name = kubernetes_service.challenge.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}