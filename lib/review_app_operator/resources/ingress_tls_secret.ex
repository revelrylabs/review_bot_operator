defmodule ReviewAppOperator.Resource.IngressTlsSecret do
  alias ReviewAppOperator.Kube
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{ReviewApp, Secret}

  def from_review_app(review_app) do
    case original_secret() do
      %{"kind" => "Secret"} = secret ->
        manifest(%{
          name: Resource.valid_label(review_app, "ingress-tls"),
          ns: ReviewApp.namespace(review_app),
          original: secret
        })

      _ ->
        nil
    end
  end

  defp manifest(%{name: name, ns: ns, original: original}) do
    %{
      original
      | "metadata" => %{"name" => name, "namespace" => ns},
        "status" => %{}
    }
  end

  # TODO: Just like in DB Copy Secret, might be good to cache
  defp original_secret() do
    name = Application.get_env(:review_app_operator, :tls_secret_name)
    ns = Application.get_env(:review_app_operator, :tls_secret_namespace)

    if name && ns do
      {:ok, secret} = Kube.client().get(Secret.selector(name, ns))
      secret
    else
      nil
    end
  end
end
