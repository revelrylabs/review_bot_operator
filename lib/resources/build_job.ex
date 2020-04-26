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
  def from_review_app(_reviewapp) do
    manifest()
  end

  def manifest() do
    %{
      "apiVersion" => "batch/v1",
      "kind" => "Job",
      "metadata" => %{},
      "spec" => %{}
    }
  end

  defp full_tag(base_tag) do
    case Application.get_env(:review_app_operator, :docker_root, "") do
      "" -> base_tag
      root -> "#{root}/#{base_tag}"
    end
  end
end
