; x = bitboard of pseudo legal moves for a piece on sq with occ pieces occluding its movement on the board
; addition x & sq can be one register
macro RookAttacksOffset x, sq, occ, t
  if CPU_HAS_BMI2
	       pext   t, occ, qword[RookAttacksPEXT+8*(sq)]
		mov   x#d, dword[RookAttacksMOFF+4*(sq)]
  else
		mov   t, qword[RookAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[RookAttacksIMUL+8*(sq)]
		shr   t, 64-12
		mov   x#d, dword[RookAttacksMOFF+4*(sq)]
  end if
end macro
macro BishopAttacksOffset x, sq, occ, t
  if CPU_HAS_BMI2
	       pext   t, occ, qword[BishopAttacksPEXT+8*(sq)]
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  else
		mov   t, qword[BishopAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[BishopAttacksIMUL+8*(sq)]
		shr   t, 64-9
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  end if
end macro

macro RookAttacks x, sq, occ, t
		RookAttacksOffset x, sq, occ, t
		mov   x, qword[x+8*t]
end macro

macro BishopAttacks x, sq, occ, t
		BishopAttacksOffset x, sq, occ, t
		mov   x, qword[x+8*(t)]
end macro

macro QueenAttacks x, sq, occ, t, s
  if CPU_HAS_BMI2
	       pext   t, occ, qword[BishopAttacksPEXT+8*(sq)]
		mov   x#d, dword[BishopAttacksMOFF+4*sq]
		mov   x, qword[x+8*(t)]
	       pext   t, occ, qword[RookAttacksPEXT+8*(sq)]
		mov   s#d, dword[RookAttacksMOFF+4*sq]
		 or   x, qword[s+8*(t)]
  else
		mov   t, qword[BishopAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[BishopAttacksIMUL+8*(sq)]
		shr   t, 64-9
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
		mov   x, qword[x+8*(t)]

		mov   t, qword[RookAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[RookAttacksIMUL+8*(sq)]
		shr   t, 64-12
		mov   s#d, dword[RookAttacksMOFF+4*(sq)]
		 or   x, qword[s+8*(t)]
  end if
end macro
macro QueenAttacksMinReg x, sq, occ, t
  if CPU_HAS_BMI2
	       pext   t, occ, qword[BishopAttacksPEXT+8*(sq)]
		mov   x#d, dword[BishopAttacksMOFF+4*sq]
		mov   x, qword[x+8*(t)]
	       pext   t, occ, qword[RookAttacksPEXT+8*(sq)]
		mov   occ#d, dword[RookAttacksMOFF+4*sq]
		 or   x, qword[occ+8*(t)]
  else
		mov   t, qword[BishopAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[BishopAttacksIMUL+8*(sq)]
		shr   t, 64-9
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
		mov   x, qword[x+8*(t)]

		mov   t, qword[RookAttacksPEXT+8*(sq)]
		and   t, occ
	       imul   t, qword[RookAttacksIMUL+8*(sq)]
		shr   t, 64-12
		mov   occ#d, dword[RookAttacksMOFF+4*(sq)]
		 or   x, qword[occ+8*(t)]
  end if
end macro

macro RookAttacksClob x, sq, occ
  if CPU_HAS_BMI2
	       pext   occ, occ, qword[RookAttacksPEXT+8*(sq)]
		mov   x#d, dword[RookAttacksMOFF+4*(sq)]
  else
		and   occ, qword[RookAttacksPEXT+8*(sq)]
	       imul   occ, qword[RookAttacksIMUL+8*(sq)]
		shr   occ, 64-12
		mov   x#d, dword[RookAttacksMOFF+4*(sq)]
  end if
		mov   x, qword[x+8*(occ)]
end macro
macro BishopAttacksClob x, sq, occ
  if CPU_HAS_BMI2
	       pext   occ, occ, qword[BishopAttacksPEXT+8*(sq)]
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  else
		and   occ, qword[BishopAttacksPEXT+8*(sq)]
	       imul   occ, qword[BishopAttacksIMUL+8*(sq)]
		shr   occ, 64-9
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  end if
		mov   x, qword[x+8*(occ)]
end macro
macro BishopAttacksClobc x, sq, occ
  if CPU_HAS_BMI2
	       pext   occ, occ, qword[BishopAttacksPEXT+8*(sq)]
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  else
		and   occ, qword[BishopAttacksPEXT+8*(sq)]
	       imul   occ, qword[BishopAttacksIMUL+8*(sq)]
		shr   occ, 64-9
		mov   x#d, dword[BishopAttacksMOFF+4*(sq)]
  end if
		mov   occ, qword[x+8*(occ)]
end macro


macro RookAttacksTest x, sq, occ, t, targetreg
; x = bitboard of pseudo legal moves for a piece on sq with occ pieces occluding its movement on the board
		RookAttacksOffset x, sq, occ, t
		test   qword[x+8*t], targetreg
end macro
macro BishopAttacksTest x, sq, occ, t, targetreg
		BishopAttacksOffset x, sq, occ, t
		test   qword[x+8*t], targetreg
end macro
;x & t same reg
macro RookAttacksm x, sq, occ
  if CPU_HAS_BMI2
	       pext   x, occ, qword[RookAttacksPEXT+8*(sq)]
  else
		mov   x, qword[RookAttacksPEXT+8*(sq)]
		and   x, occ
	       imul   x, qword[RookAttacksIMUL+8*(sq)]
		shr   x, 64-12
  end if
		lea	x,[8*x]
		add	x#d, dword[RookAttacksMOFF+4*(sq)]
		mov	x, qword[x]
end macro
macro BishopAttacksm x, sq, occ
  if CPU_HAS_BMI2
	       pext   x, occ, qword[BishopAttacksPEXT+8*(sq)]
  else
		mov   x, qword[BishopAttacksPEXT+8*(sq)]
		and   x, occ
	       imul   x, qword[BishopAttacksIMUL+8*(sq)]
		shr   x, 64-9
  end if
		lea	x,[8*x]
		add	x#d, dword[BishopAttacksMOFF+4*(sq)]
		mov	x, qword[x]
end macro
