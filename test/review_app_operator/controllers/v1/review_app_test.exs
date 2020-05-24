defmodule ReviewAppOperator.Controller.V1.ReviewAppTest do
  @moduledoc false
  use ReviewAppOperator.KubeCase, async: false
  alias ReviewAppOperator.Controller.V1.ReviewApp
  alias ReviewAppOperator.MockKubeClient

  describe "add/1" do
    test "returns :ok" do
      MockKubeClient
      |> expect_get_secret(3)
      |> expect_k8s(:create, 7)
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

    test "kicks off new build" do
      MockKubeClient
      |> expect_k8s(:create, 1)
      |> expect_k8s(:patch, 2)

      event =
        TestReviewApp.manifest()
        |> put_in(["spec", "commitHash"], "5ce6e4a15e2a09fe113aba79263104835bd676c2")
        |> put_in(["status", "buildCommit"], "c8c9aa334a76677aa0be4ec0ebb08484367f952d")

      result = ReviewApp.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      MockKubeClient
      |> expect_get_secret(4)
      |> expect_k8s(:delete, 7)

      event =
        TestReviewApp.manifest()
        |> put_in(["status", "buildJobName"], "buildJob-123")

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
      |> expect_k8s(:patch, 2)

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
