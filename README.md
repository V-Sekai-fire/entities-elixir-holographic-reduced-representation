# entities-elixir-holographic-reduced-representation

Holographic reduced representations with phase encoding for Elixir over Nx, with Lean 4 proofs of the phase algebra.

## What it is for

It binds, unbinds, bundles and cleans up fixed-width phase vectors, so a whole record collapses into one vector that can still be taken apart. Atoms come from hashing, so the same word gives the same vector on every machine with no seed. RFD 1021 owns the design.

## Building and running

A Mix project depends on it with:

```elixir
{:hrr, github: "V-Sekai-fire/entities-elixir-holographic-reduced-representation"}
```

To build and test it here:

```sh
mix deps.get
mix test
```

The proofs build with `lake build` from the `formal` directory.

## Licence

MIT. See [LICENSE](LICENSE).
