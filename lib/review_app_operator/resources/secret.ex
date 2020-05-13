defmodule ReviewAppOperator.Resource.Secret do
  @moduledoc """
  Create an arbitrary secret
  """
  def generic(name, ns, labels, data) do
    manifest(%{name: name, ns: ns, labels: labels, data: data, type: "Opaque"})
  end

  def manifest(%{
        name: name,
        ns: ns,
        labels: labels,
        data: data,
        type: type
      }) do
    %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels
      },
      "data" => encode_data(data),
      "type" => type
    }
  end

  def selector(name, namespace) do
    %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    }
  end

  defp encode_data(data) do
    Enum.into(data, %{}, fn {k, v} -> {k, Base.encode64(v)} end)
  end
end
