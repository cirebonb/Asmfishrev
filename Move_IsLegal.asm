	     calign   16
Move_IsLegal:
	; in: rbp  address of Pos
	;     rbx  address of State - pinned member must be filled in
	;     ecx  move - assumed to pass IsMovePseudoLegal test
	;	r8 from square
	;	r9 to square
	; out: eax =  0 if move is not legal
	;      eax = -1 if move is legal

		movzx	r11d, byte[rbx+State.ourKsq]	; r11 = our king bitboard

	; pseudo legal castling moves are always legal
	; ep captures require special attention
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.Special

	; if we are moving king, have to check destination square
		cmp	r8d, r11d
		je	.KingMove

	; if piece is not pinned, then move is legal
		mov	rax, qword[rbx+State.pinned]
		bt	rax, r8
		jc	.CheckPinned
		or	eax, -1	;0x10001
		ret
	     calign   8
.CheckPinned:
	; if something is pinned, its movement should becaligned with our king
		mov	eax, ecx
		and	eax, (64*64)-1
		mov	rax, qword[LineBB+8*rax]
		bt	rax, r11
		sbb	eax, eax
		ret
	     calign   8
.KingMove:
	; if they have an attacker to king's destination square, then move is illegal

		mov	eax, dword[rbp+Pos.sideToMove]
		mov	r10d, eax
		xor	r10d, 1
		mov	r10, qword[rbp+Pos.typeBB+8*r10]
	; pawn
		shl	eax, 6+3
		mov	rax, qword[PawnAttacks+rax+8*r9]
		and	rax, qword[rbp+Pos.typeBB+8*Pawn]
	       test	rax, r10
		jnz	.Illegal
	; king
		mov	rax, qword[KingAttacks+8*r9]
		and	rax, qword[rbp+Pos.typeBB+8*King]
	       test	rax, r10
		jnz	.Illegal
	; knight
		mov	rax, qword[KnightAttacks+8*r9]
		and	rax, qword[rbp+Pos.typeBB+8*Knight]
	       test	rax, r10
		jnz	.Illegal

		mov	rdx, qword[rbx+State.Occupied]	; all pieces

	; bishop + queen
		BishopAttacks	rax, r9, rdx, r11
		and	rax, qword[rbx+State.checkSq+8]	; QxB
		test	rax, r10
		jnz	.Illegal
	; rook + queen
		RookAttacksClob	rax, r9, rdx
		and	rax, qword[rbx+State.checkSq]	; QxR
		test	rax, r10
		jnz	.Illegal

.Legal:
		or   eax, -1
		ret


	     calign   8
.Illegal:
		xor   eax, eax
		ret


	     calign   8
.Special:
	; pseudo legal castling moves are always legal
		cmp   ecx, MOVE_TYPE_CASTLE shl 12
		jae   .Legal

;.EpCapture:
		push	r13
	; for ep captures, just make the move and test if our king is attacked
		mov	r10d, dword[rbp+Pos.sideToMove]
		mov	rdx, qword[rbx+State.Occupied]	; all pieces
	; remove source square
		btr	rdx, r8	; from square
	; add destination square (ep square)
		bts	rdx, r9	; to square
	; remove captured pawn
		lea	eax, [2*r10-1]
		lea	eax, [r9+8*rax]
		btr	rdx, rax
	; check for rook attacks
		xor	r10d, 1
		mov	r10, qword[rbp+Pos.typeBB+8*r10]
;		movzx	r11d, byte[rbx+State.ourKsq]

		RookAttacks	rax, r11, rdx, r13
		and	rax, qword[rbx+State.checkSq]	; QxR
		and	rax, r10
		jnz	.Illegal0
	; check for bishop attacks
		BishopAttacksClob	r11, r11, rdx
		and	r11, qword[rbx+State.checkSq+8]	; QxB
		and	r11, r10
		jnz	.Illegal0
		or	eax, -1
		pop	r13
		ret
	     calign   8
.Illegal0:
		xor   eax, eax
;.Illegal1:
		pop   r13
		ret