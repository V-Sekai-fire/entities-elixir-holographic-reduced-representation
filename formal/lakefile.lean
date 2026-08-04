import Lake
open Lake DSL

-- SPDX-License-Identifier: MIT
-- Formal model of the HRR phase algebra on the uint16 grid
-- (lib/hrr.ex: encode_atom / bind / unbind).
--
-- No dependencies. The proofs close by `omega` and `Nat.add_comm`,
-- so a plain Lean 4 toolchain builds this.

package «hrr-model» where

@[default_target] lean_lib HrrModel where

@[default_target] lean_lib PhaseRat where

lean_exe «hrr-model» where
  root := `HrrModel
