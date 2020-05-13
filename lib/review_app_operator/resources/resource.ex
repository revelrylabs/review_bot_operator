defmodule ReviewAppOperator.Resource do
  @moduledoc """
  Utilities for working with resources
  """
  alias ReviewAppOperator.Kube
  alias ReviewAppOperator.Resource.{AppService, AppDatabase, DbCopySecret}

  @max_k8s_name_length 63

  def create_all(review_app) do
    all_modules()
    |> Enum.map(&apply(&1, :from_review_app, [review_app]))
    |> Enum.filter(& &1)
    |> Enum.map(&Kube.client().create(&1))
  end

  def delete_all(review_app) do
    all_modules()
    |> Enum.map(&apply(&1, :from_review_app, [review_app]))
    |> Enum.filter(& &1)
    |> Enum.map(&Kube.client().delete(&1))
  end

  @doc """
  Generate the default set of labels for resources related to this review app

  ### Examples

      iex> Resource.default_labels(TestReviewApp.manifest())
      %{
        "reviewtron.k8s.revelry.co/app" => "revelry-phoenix-app-template",
        "reviewtron.k8s.revelry.co/build" => "678",
      }
  """
  def default_labels(%{"spec" => %{"pr" => pr, "repo" => repo}}) do
    group = Bonny.Config.group()

    %{
      "#{group}/app" => valid_label(repo),
      "#{group}/build" => valid_label(pr)
    }
  end

  @doc """
  Generate the base name for resources related to this review app. This name
  will generally be used unless we have multiple resources of the same Kind
  or need specificity for other reasons.

  ### Examples

      iex> Resource.default_name(TestReviewApp.manifest())
      "revelry-phoenix-app-template-678"
  """
  def default_name(%{"spec" => %{"pr" => pr, "repo" => repo}}) do
    valid_label(repo, pr)
  end

  @doc """
  Make a kubernetes-safe name from the input by replacing invalid characters
  and trimming the length to 63

  ### Examples

      iex> Resource.valid_label("review_app")
      "review-app"

      iex> Resource.valid_label(String.duplicate("abc efg", 10))
      String.duplicate("abc-efg", 9)
  """
  def valid_label(name), do: kube_safe_name(name, 0)

  @doc """
  Make a valid name for a reasource using the given suffix
  OR
  Make a valid name for a aresource from the given name and PR number

  ### Examples

      iex> Resource.valid_label(TestReviewApp.manifest(), "hello")
      "revelry-phoenix-app-template-678--hello"

      iex> Resource.valid_label("app_name", "123")
      "app-name-123"
  """
  def valid_label(%{"spec" => %{"pr" => _pr, "repo" => _repo}} = review_app, postfix)
      when is_binary(postfix) do
    valid_label(review_app, postfix, 0)
  end

  def valid_label(name, pr), do: valid_label(name, pr, 0)

  @doc """
  Make a valid name from the review app, postfix, and leaving a certain amount of headroom
  OR
  Make a valid name from the name, pr number, and requested amount of headroom

  ### Examples

      iex> label = Resource.valid_label(TestReviewApp.manifest(), "hello", 30)
      ...> String.length(label)
      63 - 30

      iex> Resource.valid_label("review_app_hello_there", "123", 43)
      "review-app-hello-123"
  """
  def valid_label(%{"spec" => %{"pr" => pr, "repo" => repo}}, postfix, headroom)
      when is_binary(postfix) and is_integer(headroom) do
    valid_label(repo, pr, postfix, headroom)
  end

  def valid_label(name, pr, headroom) when is_integer(headroom) do
    Enum.join(
      [
        kube_safe_name(name, String.length(pr) + headroom + 1),
        valid_label(pr)
      ],
      "-"
    )
  end

  def valid_label(name, pr, postfix) when is_binary(postfix) do
    valid_label(name, pr, postfix, 0)
  end

  @doc """
  Make a valid name from the name, pr number, postfix, and requested amount of headroom

  ### Examples

      iex> Resource.valid_label("review_app_hello_there", "123", "postfix", 30)
      "review-app-hello-the-123--postfix"
  """
  def valid_label(name, pr, postfix, headroom) do
    Enum.join(
      [
        valid_label(name, pr, headroom + String.length(postfix) + 2),
        valid_label(postfix)
      ],
      "--"
    )
  end

  defp all_modules do
    [AppService, DbCopySecret, AppDatabase]
  end

  defp kube_safe_name(base_name, headroom) do
    base_name
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^-a-z0-9]+/, "-", global: true)
    |> String.slice(0, @max_k8s_name_length - headroom)
  end
end
