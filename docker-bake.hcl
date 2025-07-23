group "default" {
  targets = ["frontend", "backend"]
}
variable "env" {
  default = "staging"
}
target "frontend" {
  context = "./App/frontend"
  dockerfile = "Dockerfile"
  tags = ["cookie-${env}/frontend:latest"]
}

target "backend" {
  context = "./App/backend"
  dockerfile = "Dockerfile"
  tags = ["cookie-${env}/backend:latest"]
}