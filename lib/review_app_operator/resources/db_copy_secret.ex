defmodule ReviewAppOperator.Resource.DbCopySecret do
  @moduledoc """
  Create manifest for a secret used by KubeDB to copy an existing db during initialization
  """
  alias ReviewAppOperator.Kube
  alias ReviewAppOperator.Resource
  alias ReviewAppOperator.Resource.{ReviewApp, Secret}

  def secret_name(
        %{"spec" => %{"config" => %{"database" => %{"copyFrom" => copy_from}}}} = review_app
      ) do
    case complete_config?(copy_from) do
      true ->
        Resource.valid_label(review_app, "dbCopy")

      _ ->
        nil
    end
  end

  def from_review_app(
        %{"spec" => %{"config" => %{"database" => %{"copyFrom" => copy_from}}}} = review_app
      ) do
    namespace = ReviewApp.namespace(review_app)

    case complete_config?(copy_from) do
      true ->
        Secret.generic(
          secret_name(review_app),
          namespace,
          Resource.default_labels(review_app),
          %{"db-copy.sh" => script(copy_from, namespace)}
        )

      _ ->
        nil
    end
  end

  defp complete_config?(%{"database_url" => _url}), do: true

  defp complete_config?(%{"host" => _host, "database" => _db, "user" => _user, "password" => _pw}),
    do: true

  defp complete_config?(_), do: false

  defp script(%{"database_url" => url_spec}, namespace) do
    [_full, _ql, user, password, host, _port, database] =
      Regex.run(
        ~r|^postgres(ql)?://([^:]+):([^@]+)@([^:/]+):?([^/]+)?/(.*)$|i,
        evaluate_spec(url_spec, namespace)
      )

    script(%{"host" => host, "database" => database, "user" => user, "password" => password})
  end

  defp script(copy_from, namespace) do
    copy_from
    |> Map.take(["host", "database", "user", "password"])
    |> Enum.into(%{}, fn {k, v} -> {k, evaluate_spec(v, namespace)} end)
    |> script()
  end

  defp script(%{"host" => host, "database" => database, "user" => user, "password" => password}) do
    ~s"""
    #!/bin/sh
    echo "Running DB Copy script as $(whoami) in $(pwd)"

    SOURCE_HOST="#{host}"
    SOURCE_DATABASE="#{database}"
    SOURCE_USER="#{user}"
    SOURCE_PASSWORD="#{password}"

    DEST_HOST="localhost"
    DEST_DATABASE="postgres"
    DEST_USER="${POSTGRES_USER:-postgres}"
    DEST_PASSWORD="${POSTGRES_PASSWORD}"

    echo "Copying from ${SOURCE_HOST} to ${DEST_HOST}"

    # runs as the postgres user, who can't write in very many places
    WORKDIR="/var/lib/postgresql"
    DUMP_FILE="${WORKDIR}/review-bot-dump.sql"

    echo "Dump db $SOURCE_HOST:$SOURCE_DATABASE to $DUMP_FILE"
    PGPASSWORD=$SOURCE_PASSWORD pg_dump -v -h $SOURCE_HOST -U $SOURCE_USER -d $SOURCE_DATABASE -n public -T spatial_ref_sys -F c -f $DUMP_FILE --no-owner --no-acl
    echo "Dump Complete"

    echo "Restore $DUMP_FILE to db $DEST_HOST:$DEST_DATABASE"
    PGPASSWORD=$DEST_PASSWORD pg_restore -v --no-owner -h $DEST_HOST -U $DEST_USER -d $DEST_DATABASE $DUMP_FILE
    echo "Restore Complete"

    echo "Cleaning up $DUMP_FILE"
    rm $DUMP_FILE
    """
  end

  defp evaluate_spec(%{"value" => value}, _ns), do: value

  # TODO: cache secrets, handle errors?
  defp evaluate_spec(%{"secretRef" => %{"name" => name, "key" => key}}, ns) do
    {:ok, secret} = Kube.client().get(Secret.selector(name, ns))

    Base.decode64!(get_in(secret, ["data", key]))
  end
end
