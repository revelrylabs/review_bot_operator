defmodule ReviewAppOperator.Resource.AppService do
  @moduledoc """
  Code for building a service resource for a review app
  """

  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp

  @spec from_review_app(map) :: %{
          optional(<<_::32, _::_*16>>) =>
            <<_::16, _::_*40>> | %{optional(<<_::32, _::_*8>>) => any}
        }
  @doc """
  ### Examples
      iex> app = TestReviewApp.manifest()
      ...> service = ReviewAppOperator.Resource.AppService.from_review_app(app)
      ...> assert %{"kind" => "Service", "metadata" => metadata, "spec" => spec} = service
      ...> assert %{"namespace" => "test-review-app", "labels" => labels} = metadata
      ...> assert labels["reviewtron.k8s.revelry.co/build"] == get_in(app, ["spec", "pr"])
      ...> assert get_in(spec, ["selector", "reviewApp"]) == "revelry-phoenix-app-template-678"
  """
  def from_review_app(review_app) do
    manifest(%{
      name: name(review_app),
      ns: ReviewApp.namespace(review_app),
      labels: Resource.default_labels(review_app),
      port: ReviewApp.port(review_app)
    })
  end

  def name(review_app), do: Resource.default_name(review_app)

  defp manifest(%{name: name, ns: ns, labels: labels, port: port}) do
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
