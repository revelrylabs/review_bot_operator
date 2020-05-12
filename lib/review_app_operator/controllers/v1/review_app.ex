defmodule ReviewAppOperator.Controller.V1.ReviewApp do
  @moduledoc """
  Resource declaration and event handlers for ReviewApp Custom Resources (v1)
  """
  use Bonny.Controller
  require Logger
  alias ReviewAppOperator.Build.Builder
  alias ReviewAppOperator.Kube
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.ReviewApp

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
    },
    %{
      name: "Status",
      type: "string",
      description: "The status of the review app",
      JSONPath: ".status.appStatus"
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
  def add(%{} = review_app) do
    log_event(:add, review_app)

    Builder.build_image(review_app)
    Resource.create_all(review_app)
    :ok
  end

  @doc """
  Handles a `MODIFIED` event
  """
  @spec modify(map()) :: :ok | :error
  @impl Bonny.Controller
  def modify(%{} = review_app) do
    log_event(:modify, review_app)
    # TODO: Compare commit hashes and rebuild if necessary
    :ok
  end

  @doc """
  Handles a `DELETED` event
  """
  @spec delete(map()) :: :ok | :error
  @impl Bonny.Controller
  def delete(%{} = review_app) do
    log_event(:delete, review_app)
    Builder.delete_job(review_app)
    Resource.delete_all(review_app)
    :ok
  end

  @doc """
  Called periodically for each existing CustomResource to allow for reconciliation.
  """
  @spec reconcile(map()) :: :ok | :error
  @impl Bonny.Controller
  def reconcile(%{"status" => %{"buildStatus" => "building"}} = review_app) do
    log_event(:reconcile, review_app)

    case Builder.job_status(review_app) do
      :success -> handle_build_success(review_app)
      :failure -> handle_build_failure(review_app)
      :running -> nil
    end

    :ok
  end

  def reconcile(%{} = review_app) do
    log_event(:reconcile, review_app)
    :ok
  end

  defp log_event(type, resource),
    do: Logger.info("#{type}: #{inspect(resource)}")

  defp handle_build_success(review_app) do
    _updated_app =
      review_app
      |> ReviewApp.set_status("buildStatus", "success")
      |> ReviewApp.set_status("appStatus", "deployed")
      |> Kube.client().patch()

    # TODO: something like this
    # updated_app
    # |> Deployment.from_review_app()
    # |> Kube.client().patch()
  end

  defp handle_build_failure(review_app) do
    review_app
    |> ReviewApp.set_status("buildStatus", "error")
    |> ReviewApp.set_status("appStatus", "error")
    |> Kube.client().patch()
  end
end
