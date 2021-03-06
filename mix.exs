defmodule Raxx.Mixfile do
  use Mix.Project

  def project do
    [
      app: :raxx,
      version: "0.17.0",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [
        warnings_as_errors: true
      ],
      description: description(),
      docs: [extras: ["README.md"], main: "readme"],
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger, :ssl, :eex]]
  end

  defp deps do
    [
      # TODO remove once sessions are in separate repo.
      {:cookie, "~> 0.1.0"},
      {:eex_html, "~> 0.1.1"},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:benchee, "~> 0.13.2", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Interface for HTTP webservers, frameworks and clients.
    """
  end

  defp package do
    [
      maintainers: ["Peter Saxton"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/crowdhailer/raxx"}
    ]
  end
end
