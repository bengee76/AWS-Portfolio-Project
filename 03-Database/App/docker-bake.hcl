group "default" {
  targets = ["proxy", "app"]
}

target "proxy" {
  context = "./nginx"
  dockerfile = "Dockerfile"
  tags = ["proxy:latest"]
}

target "app" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["app:latest"]
}