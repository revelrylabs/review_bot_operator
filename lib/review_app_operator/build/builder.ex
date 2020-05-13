defmodule ReviewAppOperator.Build.Builder do
  alias ReviewAppOperator.Resource.{ReviewApp, BuildJob}
  alias ReviewAppOperator.Kube
  require Logger

  def build_image(review_app) do
    delete_job(review_app)
    updated_app = update_status(review_app)

    {:ok, _job} =
      review_app
      |> BuildJob.from_review_app()
      |> Kube.client().create()

    Kube.client().patch(updated_app)

    :ok
  end

  def job_status(%{"status" => %{"buildJobName" => job_name}}) do
    {:ok, job} =
      job_name
      |> BuildJob.selector()
      |> Kube.client().get()

    BuildJob.status(job)
  end

  def delete_job(%{"status" => %{"buildJobName" => job_name}}) do
    case job_name
         |> BuildJob.selector()
         |> Kube.client().get() do
      {:ok, job} ->
        Kube.client().delete(job)

      _ ->
        Logger.info("Job #{job_name} not found. Skipping delete")
        :not_found
    end
  end

  def delete_job(_), do: nil

  defp update_status(%{"spec" => %{"commitHash" => hash}} = review_app) do
    app_status = ReviewApp.get_status(review_app, "appStatus", "building")
    start_time = DateTime.to_unix(DateTime.utc_now())
    image = BuildJob.image_tag(review_app)
    job_name = BuildJob.job_name(review_app)

    review_app
    |> ReviewApp.set_status("appStatus", app_status)
    |> ReviewApp.set_status("buildStatus", "building")
    |> ReviewApp.set_status("buildStartedAt", start_time)
    |> ReviewApp.set_status("buildJobName", job_name)
    |> ReviewApp.set_status("buildCommit", hash)
    |> ReviewApp.set_status("image", image)
  end
end
