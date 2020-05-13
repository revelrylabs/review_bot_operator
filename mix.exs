defmodule ReviewAppOperator.MixProject do
  use Mix.Project

  def project do
    [
      app: :review_app_operator,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bonny, "~> 0.4"},
      {:mox, "~> 0.5", only: :test},
      {:excoveralls, "~> 0.11.2", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support" | elixirc_paths(:production)]

  defp elixirc_paths(_), do: ["lib"]
end
