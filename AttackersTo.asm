	     calign  16
AttackersTo_Side:
	; in: ecx side
	;     edx square
	; out: rax  pieces on side ecx^1 that attack square edx

		xor	ecx,1
		mov	r11, qword[rbp+Pos.typeBB+8*rcx]
		mov	r10, qword[rbx+State.Occupied]
		xor	ecx, 1
		shl	ecx, 6+3
.Set:
		mov   rax, qword[KingAttacks+8*rdx]
		and   rax, qword[rbp+Pos.typeBB+8*King]

		mov   r8, qword[KnightAttacks+8*rdx]
		and   r8, qword[rbp+Pos.typeBB+8*Knight]
		 or   rax, r8

		mov   r8, qword[WhitePawnAttacks+rcx+8*rdx]
		and   r8, qword[rbp+Pos.typeBB+8*Pawn]
		 or   rax, r8

	RookAttacks   r8, rdx, r10, r9
		and	r8, qword[rbx+State.checkSq]
		 or	rax, r8
      BishopAttacks   r8, rdx, r10, r9
		and	r8, qword[rbx+State.checkSq+8]
		 or	rax, r8
		and   rax, r11
		ret
