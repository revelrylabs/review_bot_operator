defmodule ReviewAppOperator.Kube do
  @moduledoc """
  Allow toggling the k8s client for easy testing
  """
  def client() do
    Application.get_env(:review_app_operator, :k8s_client, ReviewAppOperator.Kube.Client)
  end
end
