defmodule ReviewAppOperator.Resource.AppDatabase do
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{DbCopySecret, ReviewApp}

  def from_review_app(
        %{"spec" => %{"config" => %{"database" => %{"backend" => "kubedb"} = database}}} =
          review_app
      ) do
    %{
      engine: Map.get(database, "engine", "Postgres"),
      version: Map.get(database, "version", "10.6"),
      name: Resource.valid_label(review_app, "db", 5),
      ns: ReviewApp.namespace(review_app),
      labels: Resource.default_labels(review_app)
    }
    |> manifest()
    |> add_copy_secret(review_app)
  end

  def from_review_app(_), do: nil

  defp manifest(%{
         engine: engine,
         name: name,
         ns: ns,
         labels: labels,
         version: version
       }) do
    %{
      "apiVersion" => "kubedb.com/v1alpha1",
      "kind" => engine,
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels
      },
      "spec" => %{
        "version" => version,
        "storageType" => "Durable",
        "storage" => %{
          "accessModes" => ["ReadWriteOnce"],
          "resources" => %{
            "requests" => %{
              "storage" => "1Gi"
            }
          }
        },
        "terminationPolicy" => "WipeOut"
      }
    }
  end

  defp add_copy_secret(manifest, review_app) do
    case DbCopySecret.secret_name(review_app) do
      name when is_binary(name) ->
        put_in(manifest, ["spec", "init"], %{
          "scriptSource" => %{
            "secret" => %{
              "secretName" => name,
              "defaultMode" => 511
            }
          }
        })

      _ ->
        manifest
    end
  end
end
