defmodule ReviewAppOperator.Resource.AppService do
  @moduledoc """
  Code for building a service resource for a review app
  """

  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp

  @doc """
  ### Examples
      iex> app = TestReviewApp.manifest()
      ...> service = ReviewAppOperator.Resource.AppService.from_review_app(app)
      ...> assert %{"kind" => "Service", "metadata" => metadata, "spec" => spec} = service
      ...> assert %{"namespace" => "app-template", "labels" => labels} = metadata
      ...> assert labels["reviewtron.k8s.revelry.co/build"] == get_in(app, ["spec", "pr"])
      ...> assert get_in(spec, ["selector", "reviewApp"]) == "revelry-phoenix-app-template-678"
  """
  def from_review_app(reviewapp) do
    manifest(%{
      name: Resource.default_name(reviewapp),
      ns: ReviewApp.namespace(reviewapp),
      labels: Resource.default_labels(reviewapp),
      port: ReviewApp.port(reviewapp)
    })
  end

  def manifest(%{name: name, ns: ns, labels: labels, port: port}) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels
      },
      "spec" => %{
        "ports" => [%{"port" => 80, "protocol" => "TCP", "targetPort" => port}],
        "selector" => %{"reviewApp" => name}
      }
    }
  end
end
