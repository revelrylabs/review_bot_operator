defmodule ReviewAppOperator.Build.Builder do
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{ReviewApp, BuildJob}
  require Logger

  def build_image(reviewapp) do
    delete_job(reviewapp)
    updated_app = update_status(reviewapp)

    {:ok, _job} =
      reviewapp
      |> BuildJob.from_review_app()
      |> Resource.create()

    Resource.patch(updated_app)

    :ok
  end

  def job_status(%{"status" => %{"buildJobName" => job_name}}) do
    {:ok, job} =
      job_name
      |> BuildJob.selector()
      |> Resource.get()

    BuildJob.status(job)
  end

  def delete_job(%{"status" => %{"buildJobName" => job_name}}) do
    case job_name
         |> BuildJob.selector()
         |> Resource.get() do
      {:ok, job} ->
        Resource.delete(job)

      _ ->
        Logger.info("Job #{job_name} not found. Skipping delete")
        :not_found
    end
  end

  def delete_job(_), do: nil

  defp update_status(%{"spec" => %{"commitHash" => hash}} = reviewapp) do
    app_status = ReviewApp.get_status(reviewapp, "appStatus", "building")
    start_time = DateTime.to_unix(DateTime.utc_now())
    image = BuildJob.image_tag(reviewapp)
    job_name = BuildJob.job_name(reviewapp)

    reviewapp
    |> ReviewApp.set_status("appStatus", app_status)
    |> ReviewApp.set_status("buildStatus", "building")
    |> ReviewApp.set_status("buildStartedAt", start_time)
    |> ReviewApp.set_status("buildJobName", job_name)
    |> ReviewApp.set_status("buildCommit", hash)
    |> ReviewApp.set_status("image", image)
  end
end
