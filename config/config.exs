use Mix.Config

config :bonny,
  controllers: [
    ReviewAppOperator.Controller.V1.ReviewApp
  ],
  group: "reviewtron.k8s.revelry.co",
  operator_name: "review-app-operator",
  service_account_name: "review-app-operator",
  labels: %{
    review_app: "true"
  },
  resources: %{
    limits: %{cpu: "200m", memory: "200Mi"},
    requests: %{cpu: "200m", memory: "200Mi"}
  }

config :review_app_operator,
  build_image: "gcr.io/kaniko-project/executor:latest",
  build_unpack_image: "harbor.revelry-prod.revelry.net/library/kaniko-unpack:latest",
  build_pull_secrets: ["harbor-credentials"]

import_config "#{Mix.env()}.exs"
