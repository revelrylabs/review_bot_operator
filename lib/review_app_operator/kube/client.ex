defmodule ReviewAppOperator.Kube.Client do
  @moduledoc """
  Client for Kubernetes operation, wrapping the K8s.Client
  """
  @behaviour ReviewAppOperator.Kube.ClientBehavior

  require Logger

  @impl ReviewAppOperator.Kube.ClientBehavior
  def create(resource), do: apply_operation(resource, &K8s.Client.create/1)

  @impl ReviewAppOperator.Kube.ClientBehavior
  def get(resource), do: apply_operation(resource, &K8s.Client.get/1)

  @impl ReviewAppOperator.Kube.ClientBehavior
  def patch(resource), do: apply_operation(resource, &K8s.Client.patch/1)

  @impl ReviewAppOperator.Kube.ClientBehavior
  def delete(resource), do: apply_operation(resource, &K8s.Client.delete/1)

  defp apply_operation(resource, client_function) do
    resource
    |> client_function.()
    |> log_operation()
    |> K8s.Client.run(Bonny.Config.cluster_name())
  end

  defp log_operation(%K8s.Operation{} = operation) do
    operation
    |> redact_secrets()
    |> inspect()
    |> Logger.info()

    operation
  end

  defp redact_secrets(%{data: %{"kind" => "Secret", "data" => _data}} = operation) do
    put_in(operation, [:data, "data"], "[REDACTED]")
  end

  defp redact_secrets(operation), do: operation
end
