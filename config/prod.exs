use Mix.Config

config :k8s,
  clusters: %{
    # use the pod's service account in prod
    default: %{}
  }

config :bonny,
  cluster_name: :default

# TODO: move to env vars
config :review_app_operator,
  docker_root: "harbor.revelry-prod.revelry.net",
  build_namespace: "review-build",
  tarball_bucket: "tarball_bucket",
  app_domain: "revelry-prod.revelry.net"
