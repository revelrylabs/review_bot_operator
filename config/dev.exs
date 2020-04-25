use Mix.Config

config :k8s,
  clusters: %{
    minikube: %{
      conn: "~/.kube/config"
    }
  }

config :bonny,
  cluster_name: :minikube
