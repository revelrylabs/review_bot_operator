defmodule ReviewAppOperator.Resource.ReviewApp do
  @moduledoc """
  Functions for working with the review app resource
  """

  # TODO: better have a type for this!

  def namespace(reviewapp), do: get_from_config(reviewapp, "namespace")
  def port(reviewapp), do: get_from_config(reviewapp, "applicationPort")

  def abbreviated_hash(%{"spec" => %{"commitHash" => full_hash}}) do
    String.slice(full_hash, 0..10)
  end

  def get_from_config(reviewapp, key) do
    get_in(reviewapp, ["spec", "config", key])
  end

  def get_status(reviewapp, key), do: get_status(reviewapp, key, nil)

  def get_status(reviewapp, key, default) do
    case get_in(reviewapp, ["status", key]) do
      nil -> default
      value -> value
    end
  end

  def set_status(reviewapp, key, value) do
    put_in(reviewapp, ["status", key], value)
  end
end
