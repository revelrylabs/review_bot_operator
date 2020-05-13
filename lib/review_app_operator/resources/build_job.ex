defmodule ReviewAppOperator.Resource.BuildJob do
  @moduledoc """
  Code for creating a Job to build an image for a review app
  """

  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp

  def job_name(review_app) do
    Resource.valid_label(review_app, ReviewApp.abbreviated_hash(review_app))
  end

  def image_tag(review_app) do
    image_base = "#{Resource.default_name(review_app)}:#{ReviewApp.abbreviated_hash(review_app)}"

    full_tag(image_base)
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

  def from_review_app(review_app) do
    manifest(%{
      build_image: build_image(),
      context_name: context_name(review_app),
      image_tag: image_tag(review_app),
      labels: Resource.default_labels(review_app),
      name: job_name(review_app),
      ns: build_namespace(),
      pull_secrets: pull_secrets(),
      tarball_bucket: tarball_bucket(),
      unpack_image: unpack_image()
    })
  end

  defp manifest(%{
         build_image: build_image,
         context_name: context_name,
         image_tag: image_tag,
         labels: labels,
         name: name,
         ns: ns,
         pull_secrets: pull_secrets,
         tarball_bucket: tarball_bucket,
         unpack_image: unpack_image
       }) do
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
                "image" => build_image,
                "args" => [
                  "--dockerfile=Dockerfile",
                  "--context=/var/unpack/#{context_name}",
                  "--destination=#{image_tag}"
                ],
                "volumeMounts" => [
                  %{"name" => "kaniko-aws", "mountPath" => "/root/.aws"},
                  %{"name" => "kaniko-docker", "mountPath" => "/kaniko/.docker"},
                  %{"name" => "unpack", "mountPath" => "/var/unpack"}
                ]
              }
            ],
            "initContainers" => [
              %{
                "name" => "unpack",
                "image" => unpack_image,
                "command" => ["unpack"],
                "args" => [
                  tarball_bucket,
                  context_name
                ],
                "volumeMounts" => [
                  %{"name" => "kaniko-aws", "mountPath" => "/root/.aws"},
                  %{"name" => "unpack", "mountPath" => "/var/unpack"}
                ]
              }
            ],
            "imagePullSecrets" => pull_secrets,
            "restartPolicy" => "Never",
            "volumes" => [
              %{
                "name" => "kaniko-aws",
                "secret" => %{"secretName" => "kaniko-aws"}
              },
              %{
                "name" => "kaniko-docker",
                "secret" => %{"secretName" => "kaniko-docker"}
              },
              %{
                "name" => "unpack",
                "emptyDir" => %{}
              }
            ]
          }
        }
      }
    }
  end

  defp build_namespace() do
    Application.get_env(:review_app_operator, :build_namespace, "default")
  end

  defp full_tag(base_tag) do
    case Application.get_env(:review_app_operator, :docker_root, "") do
      "" -> base_tag
      root -> "#{root}/#{base_tag}"
    end
  end

  defp build_image() do
    Application.get_env(:review_app_operator, :build_image)
  end

  defp unpack_image() do
    Application.get_env(:review_app_operator, :build_unpack_image)
  end

  defp pull_secrets() do
    Application.get_env(:review_app_operator, :build_pull_secrets, [])
  end

  defp context_name(%{"spec" => %{"repo" => repo, "repoOwner" => owner, "commitHash" => hash}}) do
    Enum.join(
      [
        owner,
        repo,
        String.slice(hash, 0..7)
      ],
      "-"
    )
  end

  defp tarball_bucket() do
    Application.get_env(:review_app_operator, :tarball_bucket, "")
  end
end
