# hrr

Holographic Reduced Representations with phase encoding, over [Nx](https://github.com/elixir-nx/nx).

A vector symbolic architecture. Structure lives in the algebra, not in an
index, so a whole record collapses into one fixed-width vector that you
can still take apart.

Each concept is a vector of phase angles in `[0, 2π)`, held as an f64 `Nx`
tensor.

| Operation | Meaning |
| --- | --- |
| `bind/2` | Circular convolution, as element-wise phase addition. Ties a role to a filler. The result is quasi-orthogonal to both inputs. |
| `unbind/2` | Circular correlation, as phase subtraction. Recovers the filler. |
| `bundle/1` | Superposition, as the circular mean. Merges vectors into one similar to each input. Holds about `√dim` items. |
| `similarity/2` | Phase cosine similarity, in `[-1, 1]`. |

`HRR.Cleanup` adds a codebook and nearest-symbol lookup, because an unbind
returns the filler plus superposition noise.

## Install

```elixir
def deps do
  [
    {:hrr, github: "weftspun/elixir-holographic-reduced-representation"}
  ]
end
```

## Use

```elixir
dim = 1024

role = HRR.encode_atom("role:colour", dim)
trace = HRR.bind(role, HRR.encode_atom("red", dim))

# bind and unbind are exact on the phase grid.
HRR.similarity(HRR.unbind(trace, role), HRR.encode_atom("red", dim))
#=> 1.0

# A record is a bundle of role-filler pairs.
record =
  HRR.bundle([
    HRR.bind(HRR.encode_atom("role:colour", dim), HRR.encode_atom("red", dim)),
    HRR.bind(HRR.encode_atom("role:size", dim), HRR.encode_atom("large", dim))
  ])

book = HRR.Cleanup.codebook(~w(red large small blue), dim)

record
|> HRR.unbind(HRR.encode_atom("role:colour", dim))
|> HRR.Cleanup.nearest(book)
#=> {"red", 0.71}
```

Store a vector with `HRR.to_binary/1` and read it back with
`HRR.from_binary/1`. At the default dimension of 4096 a vector takes 32
kilobytes, so pick a smaller dimension when rows are many.

## Capacity

`HRR.snr_estimate/2` reports `√(dim / n_items)`. Retrieval starts to fail
below about 2.0, which is `n_items > dim / 4`.

```elixir
HRR.snr_estimate(1024, 64)
#=> 4.0
```

## Determinism

`encode_atom/2` hashes `"word:0"`, `"word:1"`, and so on with SHA-256,
reads the digests as little-endian uint16 values, and scales them to
`[0, 2π)`. The same word gives the same vector on every machine, every
process, and every language version. No seed and no state.

That property lets a store keep the words and rebuild the vectors, rather
than keep the vectors.

`test/fixtures/hrr_golden.json` certifies parity with the Python
`holographic.py` reference to within 1.0e-12.

## Proofs

`formal/` holds a Lean 4 model of the algebra on the integer grid the
atoms come from. `encode_atom/2` scales uint16 values by `2π/65536`, so
one component lives on `ℤ/65536`, and bind and unbind are addition and
subtraction there.

| Theorem | Says |
| --- | --- |
| `unbind_bind` | `unbind (bind a b) b = a`. Retrieval is exact. |
| `unbind_bind_left` | The same through the other operand. |
| `bind_comm` | Binding commutes, as circular convolution does. |
| `bind_assoc` | Binding associates, so a nested bind needs no brackets. |
| `bind_lt_grid`, `unbind_lt_grid` | Results stay on the grid. |

```
cd formal
lake build       # check the proofs
lake exe hrr-model
```

The proofs need a plain Lean 4 toolchain and nothing else. They close
by `omega`, `Nat.add_comm`, and the `Nat` mod lemmas, and they depend
on no axiom beyond `propext` and `Quot.sound`.

The model covers the algebra, not the arithmetic that runs it. The
Elixir code holds these phases as f64 values, so it adds
representation noise on top of what the proofs certify. The facts are
per component, so a one component model loses no generality over a
1024 or 4096 dimensional vector.

## Background

Plate 1995, *Holographic Reduced Representations*. Gayler 2004,
*Vector Symbolic Architectures answer Jackendoff's challenges*.

Extracted from `holographic-item-memory` (later
`weftspun/residual-fsq-recommender`), where this was `Holo.Core.HRR`.
The algebra and the atom generation are unchanged.

## Test

```
mix test
```

## Licence

MIT. See [LICENSE](LICENSE).
