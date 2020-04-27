defmodule ReviewAppOperator.Resource.BuildJob do
  @moduledoc """
  Code for creating a Job to build an image for a review app
  """

  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp

  def job_name(%{"spec" => %{"repo" => repo, "pr" => pr}} = reviewapp) do
    Resource.valid_label(repo, pr, ReviewApp.abbreviated_hash(reviewapp))
  end

  def image_tag(reviewapp) do
    image_base = "#{Resource.default_name(reviewapp)}:#{ReviewApp.abbreviated_hash(reviewapp)}"

    full_tag(image_base)
  end

  # TODO: flesh this out
  def from_review_app(reviewapp) do
    manifest(%{
      name: job_name(reviewapp),
      ns: build_namespace(),
      labels: Resource.default_labels(reviewapp)
    })
  end

  # TODO: Put the real job info in here. This just tests by sleeping
  # FOR DEV: Is there a way to override the images using an env flag
  #   but have everything else be the same... so we can sub in a sleep container / command
  #   w/o having to change the manifest at all?
  def manifest(%{name: name, ns: ns, labels: labels}) do
    %{
      "apiVersion" => "batch/v1",
      "kind" => "Job",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels
      },
      "spec" => %{
        "backoffLimit" => 3,
        "template" => %{
          "metadata" => %{
            "generateName" => name
          },
          "spec" => %{
            "containers" => [
              %{
                "name" => "kaniko",
                "image" => "busybox",
                "command" => ["sleep", "45"]
              }
            ],
            "initContainers" => [],
            "restartPolicy" => "Never"
          }
        }
      }
    }
  end

  def selector(name) do
    %{
      "apiVersion" => "batch/v1",
      "kind" => "Job",
      "metadata" => %{
        "name" => name,
        "namespace" => build_namespace()
      }
    }
  end

  def status(%{"status" => %{"succeeded" => 1}}), do: :success

  def status(%{
        "spec" => %{"backoffLimit" => limit},
        "status" => %{"failed" => failed}
      })
      when failed > limit do
    :failure
  end

  def status(_), do: :running

  def build_namespace() do
    Application.get_env(:review_app_operator, :build_namespace, "default")
  end

  defp full_tag(base_tag) do
    case Application.get_env(:review_app_operator, :docker_root, "") do
      "" -> base_tag
      root -> "#{root}/#{base_tag}"
    end
  end
end
