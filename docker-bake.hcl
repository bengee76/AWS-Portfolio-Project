group "default" {
  targets = ["frontend", "backend"]
}

target "frontend" {
  context = "./App/frontend"
  dockerfile = "Dockerfile"
  tags = ["coockie/frontend:latest"]
}

target "backend" {
  context = "./App/backend"
  dockerfile = "Dockerfile"
  tags = ["coockie/backend:latest"]
}