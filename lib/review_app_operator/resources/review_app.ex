defmodule ReviewAppOperator.Resource.ReviewApp do
  @moduledoc """
  Functions for working with the review app resource
  """

  # TODO: better have a type for this!

  def namespace(review_app), do: get_from_config(review_app, "namespace")
  def port(review_app), do: get_from_config(review_app, "applicationPort")

  def abbreviated_hash(%{"spec" => %{"commitHash" => full_hash}}) do
    String.slice(full_hash, 0..10)
  end

  def get_from_config(review_app, key) do
    get_in(review_app, ["spec", "config", key])
  end

  def get_status(review_app, key), do: get_status(review_app, key, nil)

  def get_status(review_app, key, default) do
    case get_in(review_app, ["status", key]) do
      nil -> default
      value -> value
    end
  end

  def set_status(review_app, key, value) do
    put_in(review_app, ["status", key], value)
  end
end
