defmodule ReviewAppOperator.Resources do
  @moduledoc """
  Utilities for working with resources

  # TODO: This module could use some tests
  """

  @max_k8s_name_length 63

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

  def valid_label(name, pr), do: valid_label(name, pr, 0)

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

  defp kube_safe_name(base_name, headroom) do
    base_name
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^-a-z0-9]+/, "-", global: true)
    |> String.slice(0, @max_k8s_name_length - headroom)
  end
end
