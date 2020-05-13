defmodule ReviewAppOperator.Kube.ClientBehavior do
  @callback create(map) :: {:ok, map} | {:error, map}

  @callback get(map) :: {:ok, map} | {:error, map}

  @callback patch(map) :: {:ok, map} | {:error, map}

  @callback delete(map) :: {:ok, map} | {:error, map}
end
