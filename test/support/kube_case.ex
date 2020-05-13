defmodule ReviewAppOperator.KubeCase do
  use ExUnit.CaseTemplate
  import Mox

  using do
    quote do
      import ReviewAppOperator.KubeCase
    end
  end

  def expect_k8s(mock, action, times \\ 1) when action in [:create, :patch, :delete] do
    expect(mock, action, times, fn resource -> {:ok, resource} end)
  end

  def expect_get_secret(mock, times \\ 1) do
    data = %{"POSTGRES_PASSWORD" => "cGFzc3dvcmQK"}
    expect(mock, :get, times, fn resource -> {:ok, Map.put(resource, "data", data)} end)
  end

  def expect_get_job(mock, :succeeded) do
    status = %{"succeeded" => 1}
    expect(mock, :get, fn resource -> {:ok, Map.put(resource, "status", status)} end)
  end

  def expect_get_job(mock, :failed) do
    response = fn resource ->
      resource
      |> Map.put("status", %{"failed" => 4})
      |> Map.put("spec", %{"backoffLimit" => 3})
    end

    expect(mock, :get, &{:ok, response.(&1)})
  end
end
