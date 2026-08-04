# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule HRR.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/weftspun/hrr"

  def project do
    [
      app: :hrr,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Holographic Reduced Representations with phase encoding, over Nx. " <>
          "Bind, unbind, bundle, and clean up fixed width distributed vectors. " <>
          "Extracted from holographic-item-memory.",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url}
      ],
      docs: [main: "HRR", source_url: @source_url],
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nx, "~> 0.7"},
      {:jason, "~> 1.4", only: :test},
      {:stream_data, "~> 1.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
