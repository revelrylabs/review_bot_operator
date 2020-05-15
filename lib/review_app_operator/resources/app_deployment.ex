defmodule ReviewAppOperator.Resource.AppDeployment do
  @moduledoc """
  Create the deployment for standing up the review app
  """
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{AppDatabase, BuildJob, ReviewApp}

  def from_review_app(%{} = review_app) do
    image_tag = BuildJob.image_tag(review_app)
    env_refs = env_refs(review_app)
    env_static = env_static(review_app)
    init_containers = build_init_containers(review_app, image_tag, env_refs, env_static)

    manifest(%{
      env_refs: env_refs,
      env_static: env_static,
      image_tag: image_tag,
      init_containers: init_containers,
      labels: Resource.default_labels(review_app),
      name: Resource.default_name(review_app),
      ns: ReviewApp.namespace(review_app),
      port: ReviewApp.port(review_app),
      pull_secret: pull_secret(review_app),
      replica_count: replica_count(review_app)
    })
  end

  def manifest(%{
        env_refs: env_refs,
        env_static: env_static,
        image_tag: image_tag,
        init_containers: init_containers,
        labels: labels,
        name: name,
        ns: ns,
        port: port,
        pull_secret: pull_secret,
        replica_count: replica_count
      }) do
    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "labels" => labels
      },
      "spec" => %{
        "replicas" => replica_count,
        "selector" => %{
          "matchLabels" => %{"reviewApp" => name}
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{"reviewApp" => name}
          },
          "spec" => %{
            "initContainers" => init_containers,
            "containers" => [
              %{
                "image" => image_tag,
                "name" => name,
                "ports" => [
                  %{"containerPort" => port}
                ],
                "envFrom" => env_refs,
                "env" => env_static
              }
            ],
            "imagePullSecrets" => [pull_secret]
          }
        }
      }
    }
  end

  defp build_init_containers(review_app, image_tag, env_refs, env_static) do
    case migrate_config(review_app) do
      {command, args} ->
        [
          %{
            "image" => image_tag,
            "name" => "migrate",
            "command" => command,
            "args" => args,
            "envFrom" => env_refs,
            "env" => env_static
          }
        ]

      _ ->
        nil
    end
  end

  defp migrate_config(%{"spec" => %{"config" => %{"migrate" => migrate}}}) do
    command = Map.get(migrate, "command", [])
    args = Map.get(migrate, "args", [])

    if command == [] do
      nil
    else
      {command, args}
    end
  end

  defp migrate_config(_), do: nil

  defp filter_truthy(enum), do: Enum.filter(enum, & &1)

  defp extract_env_config(review_app, key, transform \\ & &1) do
    case get_in(review_app, ["spec", "config", "env", key]) do
      list when is_list(list) -> list
      _ -> []
    end
    |> Enum.map(transform)
  end

  defp env_refs(review_app) do
    from_config = extract_env_config(review_app, "values")

    values =
      [
        db_secret_ref(review_app)
      ] ++ from_config

    filter_truthy(values)
  end

  defp env_static(review_app) do
    name = Resource.default_name(review_app)
    hostname = Application.get_env(:review_app_operator, :app_domain)

    config_maps =
      extract_env_config(review_app, "configMaps", fn name ->
        %{
          "configMapRef" => %{"name" => name}
        }
      end)

    secrets =
      extract_env_config(review_app, "secrets", fn name ->
        %{
          "secretRef" => %{"name" => name}
        }
      end)

    values =
      [
        %{"name" => "APP_DOMAIN", "value" => "#{name}.#{hostname}"},
        %{"name" => "APP_NAME", "value" => "#{name}"},
        %{"name" => "CLUSTER_DISABLED", "value" => "1"},
        %{"name" => "NODE_IP", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}},
        db_host_env(review_app)
      ] ++ config_maps ++ secrets

    filter_truthy(values)
  end

  defp db_secret_ref(review_app) do
    case AppDatabase.auth_secret_name(review_app) do
      nil -> nil
      name -> %{"secretRef" => %{"name" => name}}
    end
  end

  defp db_host_env(review_app) do
    case AppDatabase.host_name(review_app) do
      nil -> nil
      host -> %{"name" => "POSTGRES_HOSTNAME", "value" => host}
    end
  end

  defp replica_count(review_app) do
    case ReviewApp.get_status(review_app, "status") do
      "deployed" -> 1
      _ -> 0
    end
  end

  defp pull_secret(%{"spec" => %{"config" => config}}) do
    %{"name" => Map.get(config, "registrySecretName", "harbor-credentials")}
  end
end
