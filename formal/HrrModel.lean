/-
SPDX-License-Identifier: MIT
Copyright (c) 2026 K. S. Ernest (iFire) Lee

Formal model of the HRR phase algebra.

`HRR.encode_atom/2` reads SHA-256 digests as little-endian uint16
values and scales them by `2π/65536`. One component of a phase vector
therefore lives on `ℤ/65536`, and `bind` and `unbind` are addition and
subtraction on that grid.

This file certifies the two facts the library rests on:

  * `unbind_bind` — retrieval is exact, so `unbind (bind a b) b = a`.
  * `bind_comm` — binding commutes, matching circular convolution.

Scope. The model is the integer grid the atoms come from. The Elixir
code holds those phases as f64 values, so it adds representation noise
on top of what is proved here. The algebra is exact; the float
implementation is exact to within f64 rounding.

The facts are per component, so a one component model loses no
generality over a 1024 or 4096 dimensional vector.

History. Restored from `formal/RecommenderModel.lean` in
`weftspun/residual-fsq-recommender`, which removed it in commit
7303244 once the HRR code left that repository. The cleanup recall
proofs in that file are not restored: they modelled a recommender that
no longer exists.
-/

namespace HrrModel

/-- Atom phases are `uint16 · 2π/65536`, so one component lives on `ℤ/65536`. -/
def grid : Nat := 65536

/-- `bind` = element-wise phase addition (mod the grid). -/
def bindG (a b : Nat) : Nat := (a + b) % grid

/-- `unbind` = element-wise phase subtraction (mod the grid). -/
def unbindG (m k : Nat) : Nat := (m + grid - k % grid) % grid

/-- Retrieval is exact on the grid: `unbind (bind a b) b = a`. The float
    implementation of `HRR` only adds f64 representation noise on top. -/
theorem unbind_bind (a b : Nat) (ha : a < grid) (hb : b < grid) :
    unbindG (bindG a b) b = a := by
  unfold unbindG bindG grid at *
  rw [Nat.mod_eq_of_lt hb]
  omega

/-- Binding is commutative, matching circular convolution. -/
theorem bind_comm (a b : Nat) : bindG a b = bindG b a := by
  unfold bindG
  rw [Nat.add_comm]

/-- Binding is associative, so a nested bind needs no bracketing. -/
theorem bind_assoc (a b c : Nat) : bindG (bindG a b) c = bindG a (bindG b c) := by
  unfold bindG
  rw [Nat.mod_add_mod, Nat.add_mod_mod, Nat.add_assoc]

/-- A bound value stays on the grid. -/
theorem bind_lt_grid (a b : Nat) : bindG a b < grid := by
  unfold bindG grid
  omega

/-- An unbound value stays on the grid. -/
theorem unbind_lt_grid (m k : Nat) : unbindG m k < grid := by
  unfold unbindG grid
  omega

/-- Unbinding with the other operand recovers the first, because binding
    commutes. -/
theorem unbind_bind_left (a b : Nat) (ha : a < grid) (hb : b < grid) :
    unbindG (bindG a b) a = b := by
  rw [bind_comm]
  exact unbind_bind b a hb ha

end HrrModel

open HrrModel in
/-- Executable check, so `lake exe hrr-model` fails loudly if the model and
    the Elixir implementation drift apart. -/
def main : IO Unit := do
  let pairs : List (Nat × Nat) := [(0, 0), (1, 65535), (11, 60000), (4096, 123), (32768, 32768)]
  for (a, b) in pairs do
    if unbindG (bindG a b) b != a then
      throw <| IO.userError s!"unbind_bind failed at ({a}, {b})"
    if bindG a b != bindG b a then
      throw <| IO.userError s!"bind_comm failed at ({a}, {b})"
  IO.println "phase algebra certified (unbind_bind, bind_comm, bind_assoc)"
