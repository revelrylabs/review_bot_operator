use Mix.Config

config :logger,
  level: :warn

config :review_app_operator, :k8s_client, ReviewAppOperator.MockKubeClient
