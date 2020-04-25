use Mix.Config

config :k8s,
  clusters: %{
    # use the pod's service account in prod
    default: %{}
  }

config :bonny,
  cluster_name: :default
