use Mix.Config

config :logger,
  level: :warn

config :review_app_operator, :k8s_client, ReviewAppOperator.MockKubeClient

config :review_app_operator,
  tls_secret_name: "star-review-local-tls",
  tls_secret_namespace: "default"
