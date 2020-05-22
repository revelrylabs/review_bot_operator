defmodule ReviewAppOperator.Resource.DbCopySecretTest do
  use ExUnit.Case
  alias ReviewAppOperator.Resource.{DbCopySecret, Secret}
  doctest ReviewAppOperator.Resource.DbCopySecret

  test "works with database_url" do
    copy_from = %{
      "database_url" => %{
        "value" =>
          "postgresql://database_username:database_password@database_host.us-east-2.rds.amazonaws.com/database_name"
      }
    }

    app = put_in(TestReviewApp.manifest(), ["spec", "config", "database", "copyFrom"], copy_from)

    script =
      app
      |> DbCopySecret.from_review_app()
      |> Secret.get_data("db-copy.sh")

    assert String.contains?(script, "SOURCE_USER=\"database_username\"")
    assert String.contains?(script, "SOURCE_PASSWORD=\"database_password\"")
    assert String.contains?(script, "SOURCE_HOST=\"database_host.us-east-2.rds.amazonaws.com\"")
    assert String.contains?(script, "SOURCE_DATABASE=\"database_name\"")
  end
end
