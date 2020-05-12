defmodule ReviewAppOperator.Resource do
  @moduledoc """
  Utilities for working with resources

  # TODO: docspecs on the label and name functions
  # TODO: we'll need to use Mox for the k8s client
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

  def default_labels(%{"spec" => %{"pr" => pr, "repo" => repo}}) do
    group = Bonny.Config.group()

    %{
      "#{group}/app" => valid_label(repo),
      "#{group}/build" => valid_label(pr)
    }
  end

  def default_name(%{"spec" => %{"pr" => pr, "repo" => repo}}) do
    valid_label(repo, pr)
  end

  def valid_label(name), do: kube_safe_name(name, 0)

  def valid_label(%{"spec" => %{"pr" => _pr, "repo" => _repo}} = review_app, postfix)
      when is_binary(postfix) do
    valid_label(review_app, postfix, 0)
  end

  def valid_label(name, pr), do: valid_label(name, pr, 0)

  def valid_label(%{"spec" => %{"pr" => pr, "repo" => repo}}, postfix, headroom)
      when is_binary(postfix) and is_integer(headroom) do
    valid_label(repo, pr, postfix, headroom)
  end

  def valid_label(name, pr, headroom) when is_integer(headroom) do
    Enum.join(
      [
        kube_safe_name(name, String.length(pr) + headroom),
        valid_label(pr)
      ],
      "-"
    )
  end

  def valid_label(name, pr, postfix) when is_binary(postfix) do
    valid_label(name, pr, postfix, 0)
  end

  def valid_label(name, pr, postfix, headroom) do
    Enum.join(
      [
        valid_label(name, pr, headroom + String.length(postfix)),
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
