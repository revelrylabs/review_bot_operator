defmodule TestReviewApp do
  def manifest() do
    %{
      "apiVersion" => "reviewtron.k8s.revelry.co/v1",
      "kind" => "ReviewApp",
      "metadata" => %{
        "clusterName" => "",
        "creationTimestamp" => "2020-04-25T14:57:36Z",
        "name" => "test",
        "namespace" => "",
        "resourceVersion" => "50425",
        "selfLink" => "/apis/reviewtron.k8s.revelry.co/v1/test",
        "uid" => "19f2cdfc-8705-11ea-a41e-080027cf9354"
      },
      "spec" => %{
        "branch" => "test-review-operator",
        "commitHash" => "c8c9aa334a76677aa0be4ec0ebb08484367f952d",
        "config" => %{
          "applicationPort" => 5000,
          "database" => %{
            "backend" => "kubedb",
            "copyFrom" => %{
              "database" => %{"value" => "postgres"},
              "host" => %{"value" => "database-resource"},
              "password" => %{
                "secretRef" => %{
                  "key" => "POSTGRES_PASSWORD",
                  "name" => "database-resource-auth"
                }
              },
              "user" => %{
                "secretRef" => %{
                  "key" => "POSTGRES_USER",
                  "name" => "database-resource-auth"
                }
              }
            },
            "version" => "10.6"
          },
          "env" => %{
            "configMaps" => ["configMapOne", "configMapTwo"],
            "secrets" => ["secretOne", "secretTwo"],
            "values" => [
              %{"name" => "ENV_ONE", "value" => "value number one"},
              %{"name" => "ENV_TWO", "value" => 1}
            ]
          },
          "ignoreBranches" => ["/dependabot.*/", "ignore-me"],
          "migrate" => %{
            "args" => ["eval", "AppTemplate.ReleaseTasks.migrate()"],
            "command" => ["./bin/app_template"]
          },
          "namespace" => "app-template",
          "registrySecretName" => "harbor"
        },
        "pr" => "678",
        "repoOwner" => "revelrylabs",
        "repo" => "revelry_phoenix_app_template",
        "tarballUrl" => "https://s3.aws.com/bucket/repo_source.tar.gz"
      },
      "status" => %{}
    }
  end
end
