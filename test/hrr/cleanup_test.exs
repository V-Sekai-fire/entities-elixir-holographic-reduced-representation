# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule HRR.CleanupTest do
  use ExUnit.Case, async: true

  @dim 1024

  describe "codebook/2" do
    test "holds one vector per unique word" do
      book = HRR.Cleanup.codebook(~w(red green blue red), @dim)

      assert map_size(book) == 3
      assert Nx.shape(book["red"]) == {@dim}
    end

    test "an empty word list gives an empty codebook" do
      assert HRR.Cleanup.codebook([], @dim) == %{}
    end
  end

  describe "nearest/2" do
    setup do
      %{book: HRR.Cleanup.codebook(~w(red green blue), @dim)}
    end

    test "an exact atom snaps to itself", %{book: book} do
      assert {"green", score} = HRR.Cleanup.nearest(HRR.encode_atom("green", @dim), book)
      assert_in_delta score, 1.0, 1.0e-12
    end

    test "recovers a filler after an unbind", %{book: book} do
      role = HRR.encode_atom("role:colour", @dim)
      trace = HRR.bind(role, HRR.encode_atom("blue", @dim))

      assert {"blue", score} = trace |> HRR.unbind(role) |> HRR.Cleanup.nearest(book)
      assert score > 0.99
    end

    test "an empty codebook gives nil" do
      assert HRR.Cleanup.nearest(HRR.encode_atom("red", @dim), %{}) == nil
    end
  end

  describe "rank/3" do
    test "returns the best matches first" do
      book = HRR.Cleanup.codebook(~w(red green blue), @dim)

      assert [{"red", best} | rest] = HRR.Cleanup.rank(HRR.encode_atom("red", @dim), book, 3)
      assert length(rest) == 2
      assert Enum.all?(rest, fn {_word, score} -> score < best end)
    end

    test "honours the count" do
      book = HRR.Cleanup.codebook(~w(red green blue yellow), @dim)

      assert length(HRR.Cleanup.rank(HRR.encode_atom("red", @dim), book, 2)) == 2
    end
  end

  describe "nearest_above/3" do
    setup do
      %{book: HRR.Cleanup.codebook(~w(red green blue), @dim)}
    end

    test "returns a hit that clears the threshold", %{book: book} do
      assert {"red", _} = HRR.Cleanup.nearest_above(HRR.encode_atom("red", @dim), book, 0.9)
    end

    test "rejects a stranger", %{book: book} do
      assert HRR.Cleanup.nearest_above(HRR.encode_atom("orange", @dim), book, 0.9) == nil
    end
  end
end
