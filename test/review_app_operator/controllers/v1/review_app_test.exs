defmodule ReviewAppOperator.Controller.V1.ReviewAppTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias ReviewAppOperator.Controller.V1.ReviewApp

  describe "add/1" do
    test "returns :ok" do
      event = %{}
      result = ReviewApp.add(event)
      assert result == :ok
    end
  end

  describe "modify/1" do
    test "returns :ok" do
      event = %{}
      result = ReviewApp.modify(event)
      assert result == :ok
    end
  end

  describe "delete/1" do
    test "returns :ok" do
      event = %{}
      result = ReviewApp.delete(event)
      assert result == :ok
    end
  end

  describe "reconcile/1" do
    test "returns :ok" do
      event = %{}
      result = ReviewApp.reconcile(event)
      assert result == :ok
    end
  end
end