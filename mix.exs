defmodule CodeHealth.MixProject do
  use Mix.Project

  def project do
    [
      app: :code_health,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp escript do
    [
      main_module: CodeHealth.CLI,
      name: "code-health"
    ]
  end

  defp deps do
    [
      {:ex_openai, "~> 1.8"},
      {:jason, "~> 1.4"}
    ]
  end
end
