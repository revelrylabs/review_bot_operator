use Mix.Config

config :k8s,
  clusters: %{
    minikube: %{
      conn: "~/.kube/config"
    }
  }

config :bonny,
  cluster_name: :minikube

config :review_app_operator,
  docker_root: "grossvogel",
  build_image: "grossvogel/sleep45:latest",
  build_unpack_image: "grossvogel/sleep45:latest",
  build_pull_secrets: [],
  tarball_bucket: "tarball_bucket",
  app_domain: "local",
  tls_secret_name: "star-dot-local-tls",
  tls_secret_namespace: "default"
