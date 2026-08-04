# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule HRR.Cleanup do
  @moduledoc """
  Cleanup memory: snap a noisy phase vector back to a known symbol.

  `HRR.unbind/2` returns the bound filler plus superposition noise. The
  noise grows with the number of items in a bundle, so a raw result is
  rarely equal to the atom that went in. A cleanup memory holds every
  symbol the caller expects and returns the nearest one.

  ## Example

      book = HRR.Cleanup.codebook(~w(red green blue), 1024)

      trace = HRR.bind(HRR.encode_atom("role:colour", 1024), HRR.encode_atom("red", 1024))

      trace
      |> HRR.unbind(HRR.encode_atom("role:colour", 1024))
      |> HRR.Cleanup.nearest(book)
      #=> {"red", 1.0}
  """

  @type codebook :: %{String.t() => Nx.Tensor.t()}

  @doc """
  Builds a codebook of atom vectors from a list of words.

  Duplicate words collapse, because `encode_atom/2` is deterministic.
  """
  @spec codebook([String.t()], pos_integer()) :: codebook()
  def codebook(words, dim \\ HRR.default_dim()) do
    words
    |> Enum.uniq()
    |> Map.new(&{&1, HRR.encode_atom(&1, dim)})
  end

  @doc """
  The closest symbol to `probe`.

  Returns `{word, similarity}`, or `nil` when the codebook is empty.
  """
  @spec nearest(Nx.Tensor.t(), codebook()) :: {String.t(), float()} | nil
  def nearest(_probe, codebook) when map_size(codebook) == 0, do: nil

  def nearest(probe, codebook) do
    codebook
    |> Enum.map(fn {word, vector} -> {word, HRR.similarity(probe, vector)} end)
    |> Enum.max_by(&elem(&1, 1))
  end

  @doc """
  The `n` closest symbols to `probe`, best first.

  Use this when the caller must see the runners up, such as a search
  result list.
  """
  @spec rank(Nx.Tensor.t(), codebook(), pos_integer()) :: [{String.t(), float()}]
  def rank(probe, codebook, n \\ 5) do
    codebook
    |> Enum.map(fn {word, vector} -> {word, HRR.similarity(probe, vector)} end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.take(n)
  end

  @doc """
  The closest symbol, or `nil` when no symbol clears `threshold`.

  A bundle that holds too many items returns noise. The threshold lets
  the caller reject that result instead of taking a wrong symbol.
  """
  @spec nearest_above(Nx.Tensor.t(), codebook(), float()) :: {String.t(), float()} | nil
  def nearest_above(probe, codebook, threshold) do
    case nearest(probe, codebook) do
      {_word, score} = hit when score >= threshold -> hit
      _ -> nil
    end
  end
end
