variable "namespaceifany" {
    description = "Namspace to create for resources"
    default = "decoya-assignment"
}

variable "numofreplicas" {
  description = "number of pods to deploy"
  default = 1
}

variable "imagename" {
  description = "image container to buid with"
  default = "vladbronfman/decoya-assignment:latest" 
}