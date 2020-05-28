defmodule ReviewAppOperator.Resource.AppIngress do
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{IngressTlsSecret, ReviewApp, AppService}

  @moduledoc """
  The ingress resource to expose the review app on its internet hostname
  """
  def from_review_app(review_app) do
    manifest(%{
      hostname: hostname(review_app),
      labels: Resource.default_labels(review_app),
      name: Resource.default_name(review_app),
      ns: ReviewApp.namespace(review_app),
      service_name: AppService.name(review_app),
      tls: tls_setup(review_app)
    })
  end

  def manifest(%{
        hostname: hostname,
        labels: labels,
        name: name,
        ns: ns,
        service_name: service_name,
        tls: tls
      }) do
    %{
      "apiVersion" => "networking.k8s.io/v1beta1",
      "kind" => "Ingress",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels,
        "annotations" => %{
          "kubernetes.io/ingress.class" => "nginx"
        }
      },
      "spec" => %{
        "rules" => [
          %{
            "host" => hostname,
            "http" => %{
              "paths" => [
                %{
                  "backend" => %{
                    "serviceName" => service_name,
                    "servicePort" => 80
                  },
                  "path" => "/"
                }
              ]
            }
          }
        ],
        "tls" => tls
      }
    }
  end

  defp hostname(review_app) do
    name = Resource.default_name(review_app)
    domain = Application.get_env(:review_app_operator, :app_domain, "")
    "#{name}.#{domain}"
  end

  defp tls_setup(review_app) do
    case IngressTlsSecret.from_review_app(review_app) do
      %{"metadata" => %{"name" => name}} ->
        [
          %{
            "hosts" => [hostname(review_app)],
            "secretName" => name
          }
        ]

      _ ->
        []
    end
  end
end
