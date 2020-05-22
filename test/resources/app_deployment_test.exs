defmodule ReviewAppOperator.Resource.AppDeploymentTest do
  use ExUnit.Case
  doctest ReviewAppOperator.Resource.AppDeployment

  test "constructs the deployment manifest" do
    app = TestReviewApp.manifest()
    deployment = ReviewAppOperator.Resource.AppDeployment.from_review_app(app)

    assert %{"containers" => [container], "initContainers" => [initContainer]} =
             get_in(deployment, ["spec", "template", "spec"])

    assert container["env"] == initContainer["env"]
    assert container["envFrom"] == initContainer["envFrom"]
    assert container["image"] == initContainer["image"]

    assert %{"value" => "value number one"} =
             Enum.find(container["env"], fn %{"name" => name} -> name == "ENV_ONE" end)

    assert initContainer["command"] == ["./bin/app_template"]
    assert initContainer["args"] == ["eval", "AppTemplate.ReleaseTasks.migrate()"]
  end
end
