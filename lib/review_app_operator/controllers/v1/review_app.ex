defmodule ReviewAppOperator.Controller.V1.ReviewApp do
  @moduledoc """
  Resource declaration and event handlers for ReviewApp Custom Resources (v1)
  """
  use Bonny.Controller
  require Logger
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp
  alias ReviewAppOperator.Build.Builder

  @scope :cluster

  @names %{
    plural: "reviewapps",
    singular: "reviewapp",
    kind: "ReviewApp",
    shortNames: []
  }

  @additional_printer_columns [
    %{
      name: "repo",
      type: "string",
      description: "The name of the source code repo",
      JSONPath: ".spec.repo"
    },
    %{
      name: "branch",
      type: "string",
      description: "The branch this review app is based on",
      JSONPath: ".spec.branch"
    },
    %{
      name: "PR",
      type: "string",
      description: "The pull request identifier for this branch",
      JSONPath: ".spec.pr"
    }
  ]

  # TODO: get the real permissions from revelry-prod
  @rule {"revelry.co", ["reviewapps"], ["*"]}
  @rule {"apps", ["deployments"], ["*"]}
  @rule {"", ["services"], ["*"]}

  @doc """
  Handles an `ADDED` event
  """
  @spec add(map()) :: :ok | :error
  @impl Bonny.Controller
  def add(%{} = reviewapp) do
    log_event(:add, reviewapp)

    Builder.build_image(reviewapp)
    Resource.create_all(reviewapp)
    :ok
  end

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(%{} = reviewapp) do
    log_event(:modify, reviewapp)
    # TODO: Compare commit hashes and rebuild if necessary
    :ok
  end

  @doc """
  Handles a `DELETED` event
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(%{} = reviewapp) do
    log_event(:delete, reviewapp)
    Builder.delete_job(reviewapp)
    Resource.delete_all(reviewapp)
    :ok
  end

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(%{"status" => %{"buildStatus" => "building"}} = reviewapp) do
    log_event(:reconcile, reviewapp)

    case Builder.job_status(reviewapp) do
      :success -> handle_build_success(reviewapp)
      :failure -> handle_build_failure(reviewapp)
      :running -> nil
    end

    :ok
  end

  def reconcile(%{} = reviewapp) do
    log_event(:reconcile, reviewapp)
    :ok
  end

  defp log_event(type, resource),
    do: Logger.info("#{type}: #{inspect(resource)}")

  defp handle_build_success(reviewapp) do
    _updated_app =
      reviewapp
      |> ReviewApp.set_status("buildStatus", "success")
      |> ReviewApp.set_status("appStatus", "deployed")
      |> Resource.patch()

    # TODO: something like this
    # updated_app
    # |> Deployment.from_review_app()
    # |> Resource.patch()
  end

  defp handle_build_failure(reviewapp) do
    reviewapp
    |> ReviewApp.set_status("buildStatus", "error")
    |> ReviewApp.set_status("appStatus", "error")
    |> Resource.patch()
  end
end
