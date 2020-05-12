defmodule ReviewAppOperator.Controller.V1.ReviewAppTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias ReviewAppOperator.Controller.V1.ReviewApp
  alias ReviewAppOperator.MockKubeClient
  import Mox

  describe "add/1" do
    test "returns :ok" do
      MockKubeClient
      |> expect_get_secret()
      |> expect_k8s(:create, 4)
      |> expect_k8s(:patch)

      event = TestReviewApp.manifest()
      result = ReviewApp.add(event)
      assert result == :ok
    end
  end

  describe "modify/1" do
    test "returns :ok" do
      event = TestReviewApp.manifest()
      result = ReviewApp.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      MockKubeClient
      |> expect_get_secret()
      |> expect_k8s(:delete, 4)

      event = TestReviewApp.manifest()
      result = ReviewApp.delete(event)
      assert result == :ok
    end
  end

  describe "reconcile/1" do
    test "returns :ok when nothing to do" do
      event = TestReviewApp.manifest()
      result = ReviewApp.reconcile(event)
      assert result == :ok
    end

    test "handles build completion" do
      MockKubeClient
      |> expect_get_job(:succeeded)
      |> expect_k8s(:patch)

      event =
        TestReviewApp.manifest()
        |> put_in(["status", "buildStatus"], "building")
        |> put_in(["status", "buildJobName"], "buildJob-123")

      result = ReviewApp.reconcile(event)
      assert result == :ok
    end

    test "handles build failure" do
      MockKubeClient
      |> expect_get_job(:failed)
      |> expect_k8s(:patch)

      event =
        TestReviewApp.manifest()
        |> put_in(["status", "buildStatus"], "building")
        |> put_in(["status", "buildJobName"], "buildJob-123")

      result = ReviewApp.reconcile(event)
      assert result == :ok
    end
  end

  defp expect_k8s(mock, action, times \\ 1) when action in [:create, :patch, :delete] do
    expect(mock, action, times, fn resource -> {:ok, resource} end)
  end

  defp expect_get_secret(mock, times \\ 1) do
    data = %{"POSTGRES_PASSWORD" => "cGFzc3dvcmQK"}
    expect(mock, :get, times, fn resource -> {:ok, Map.put(resource, "data", data)} end)
  end

  defp expect_get_job(mock, :succeeded) do
    status = %{"succeeded" => 1}
    expect(mock, :get, fn resource -> {:ok, Map.put(resource, "status", status)} end)
  end

  defp expect_get_job(mock, :failed) do
    response = fn resource ->
      resource
      |> Map.put("status", %{"failed" => 4})
      |> Map.put("spec", %{"backoffLimit" => 3})
    end

    expect(mock, :get, &{:ok, response.(&1)})
  end
end
