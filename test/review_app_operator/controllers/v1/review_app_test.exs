defmodule ReviewAppOperator.Controller.V1.ReviewAppTest do
  @moduledoc false
  use ReviewAppOperator.KubeCase, async: false
  alias ReviewAppOperator.Controller.V1.ReviewApp
  alias ReviewAppOperator.MockKubeClient

  describe "add/1" do
    test "returns :ok" do
      MockKubeClient
      |> expect_get_secret()
      |> expect_k8s(:create, 5)
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
      |> expect_k8s(:delete, 5)

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
end
