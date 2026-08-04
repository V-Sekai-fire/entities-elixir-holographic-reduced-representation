/-
SPDX-License-Identifier: MIT
Copyright (c) 2026 K. S. Ernest (iFire) Lee

Limited-precision rationals, and what binary64 does to them.

`HrrModel` proves the algebra on `ℤ/65536`. This file answers the next
question: does the float64 code realise that algebra, or only
approximate it?

A phase is a rational with a power-of-two denominator. Component `k` of
an atom stands for the fraction

    k / 2^16      (a turn, so a full circle is 1)

That is a limited-precision rational: numerator `k`, denominator fixed
at `2^prec`. A binary float holds `m * 2^e` exactly whenever the
significand `m` stays below `2^53`, so the question is whether the
algebra ever needs a numerator wider than that.

It does not, and by a wide margin. `bind` adds two numerators below
`2^p`, so the exact sum needs `p + 1` bits. Every theorem below is
stated for an arbitrary precision `p` and needs only `p + 1 ≤ 53`, so
the 16 bits this library uses leave 36 bits of headroom.

Scope. Lean's `Float` is a native opaque type with no formal
semantics, so no proof here mentions it. These theorems bound the
significand, and the binary64 exactness criterion does the rest. The
criterion is standard: a value `m * 2^e` with `m < 2^53` and `e` in
range is representable with no rounding.

Radians, not turns. The Elixir code stores `k * 2π/65536` radians
rather than `k / 65536` turns. `2π/65536` is irrational, so a radian
phase is not a limited-precision rational and the exactness below does
not reach it. The measured cost is about one unit in the last place:
a bind and unbind round trip over 4096 components moves a phase by at
most `2.2e-15`, which is `2.3e-11` of one grid step. See the README.
-/
import HrrModel


namespace PhaseRat

/-- Significand width of binary64. A value `m * 2^e` with `m < 2^53`
    is exactly representable. -/
def sigBits : Nat := 53

/-- The phase grid at precision `p`: denominators are `2^p`. -/
def Grid (p : Nat) : Nat := 2 ^ p

/-- `bind` on numerators at precision `p`. -/
def BindG (p a b : Nat) : Nat := (a + b) % Grid p

/-- `unbind` on numerators at precision `p`. -/
def UnbindG (p m k : Nat) : Nat := (m + Grid p - k % Grid p) % Grid p

/-- A numerator that binary64 holds with no rounding. -/
def Exact (m : Nat) : Prop := m < 2 ^ sigBits

theorem grid_pos (p : Nat) : 0 < Grid p :=
  Nat.two_pow_pos p

/-- Two numerators at precision `p` sum below `2 ^ (p + 1)`. This is the
    whole argument: one carry bit, never more. -/
theorem sum_lt (p a b : Nat) (ha : a < Grid p) (hb : b < Grid p) :
    a + b < 2 ^ (p + 1) := by
  have h : (2 : Nat) ^ (p + 1) = 2 ^ p * 2 := Nat.pow_succ 2 p
  unfold Grid at ha hb
  omega

/-- A precision that leaves room for the carry bit keeps every value
    inside the binary64 significand. -/
theorem pow_le_sig (p : Nat) (hp : p + 1 ≤ sigBits) : 2 ^ (p + 1) ≤ 2 ^ sigBits :=
  Nat.pow_le_pow_right (by decide) hp

/-- The exact sum of two phases is exact in binary64, so the addition
    inside `bind` does not round. -/
theorem bind_sum_exact (p a b : Nat) (hp : p + 1 ≤ sigBits)
    (ha : a < Grid p) (hb : b < Grid p) : Exact (a + b) :=
  Nat.lt_of_lt_of_le (sum_lt p a b ha hb) (pow_le_sig p hp)

/-- The reduced result is exact too, being smaller still. -/
theorem bind_exact (p a b : Nat) (hp : p + 1 ≤ sigBits) : Exact (BindG p a b) := by
  have hlt : BindG p a b < Grid p := Nat.mod_lt _ (grid_pos p)
  have hs := pow_le_sig p hp
  have h2 : (2 : Nat) ^ (p + 1) = 2 ^ p * 2 := Nat.pow_succ 2 p
  unfold Exact Grid at *
  omega

/-- The intermediate `m + grid - k % grid` inside `unbind` is exact, so
    the subtraction does not round either. -/
theorem unbind_sum_exact (p m k : Nat) (hp : p + 1 ≤ sigBits) (hm : m < Grid p) :
    Exact (m + Grid p - k % Grid p) := by
  have hk : k % Grid p < Grid p := Nat.mod_lt _ (grid_pos p)
  have hs := pow_le_sig p hp
  have h2 : (2 : Nat) ^ (p + 1) = 2 ^ p * 2 := Nat.pow_succ 2 p
  unfold Exact Grid at *
  omega

/-- The reduced result of `unbind` is exact. -/
theorem unbind_exact (p m k : Nat) (hp : p + 1 ≤ sigBits) :
    Exact (UnbindG p m k) := by
  have hlt : UnbindG p m k < Grid p := Nat.mod_lt _ (grid_pos p)
  have hs := pow_le_sig p hp
  have h2 : (2 : Nat) ^ (p + 1) = 2 ^ p * 2 := Nat.pow_succ 2 p
  unfold Exact Grid at *
  omega

/-! ## This library

`HRR.encode_atom` reads uint16 values, so `p = 16`. -/

/-- The precision the atoms use. -/
def prec : Nat := 16

/-- `HrrModel.grid` is the grid at precision 16. -/
theorem grid_prec : Grid prec = 65536 := by decide

/-- The carry bit fits, with 36 bits to spare. -/
theorem prec_fits : prec + 1 ≤ sigBits := by decide

/-- Room to raise the precision before binary64 starts to round. -/
theorem headroom : sigBits - (prec + 1) = 36 := by decide

/-- At this precision every bind is exact in binary64. -/
theorem bind_exact_here (a b : Nat) : Exact (BindG prec a b) :=
  bind_exact prec a b prec_fits

/-- At this precision every unbind is exact in binary64. -/
theorem unbind_exact_here (m k : Nat) : Exact (UnbindG prec m k) :=
  unbind_exact prec m k prec_fits

/-! ## The bridge to `HrrModel`

Without these, this file could bound the significand of a different
algebra from the one `HrrModel` proves correct. They say the two
models are the same model. -/

/-- The grid at precision 16 is the grid `HrrModel` works on. -/
theorem grid_agrees : Grid prec = HrrModel.grid := by decide

/-- `bind` here is `bind` there. -/
theorem bind_agrees (a b : Nat) : BindG prec a b = HrrModel.bindG a b := by
  unfold BindG HrrModel.bindG Grid prec HrrModel.grid
  rfl

/-- `unbind` here is `unbind` there. -/
theorem unbind_agrees (m k : Nat) : UnbindG prec m k = HrrModel.unbindG m k := by
  unfold UnbindG HrrModel.unbindG Grid prec HrrModel.grid
  rfl

/-- The two results together: retrieval is exact on the grid, and every
    value it touches is exact in binary64. -/
theorem unbind_bind_exact (a b : Nat) (ha : a < HrrModel.grid) (hb : b < HrrModel.grid) :
    HrrModel.unbindG (HrrModel.bindG a b) b = a ∧ Exact (HrrModel.bindG a b) := by
  refine ⟨HrrModel.unbind_bind a b ha hb, ?_⟩
  rw [← bind_agrees]
  exact bind_exact_here a b

end PhaseRat
