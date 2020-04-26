defmodule ReviewAppOperator.Build.Builder do
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{ReviewApp, BuildJob}

  def build_image(reviewapp) do
    delete_job(reviewapp)
    updated_app = update_status(reviewapp)

    # TODO: create a Job resource

    Resource.patch(updated_app)

    :ok
  end

  def delete_job(%{"status" => %{"buildJobName" => _job_name}}) do
    # TODO: delete the thing
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
