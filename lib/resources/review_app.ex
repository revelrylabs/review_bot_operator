defmodule ReviewAppOperator.Resources.ReviewApp do
  def namespace(reviewapp), do: get_from_config(reviewapp, "namespace")
  def port(reviewapp), do: get_from_config(reviewapp, "applicationPort")

  def get_from_config(reviewapp, key) do
    get_in(reviewapp, ["spec", "config", key])
  end
end
