; Generate all legal moves.
;attention: original on major version
	     calign   16
Gen_Legal:
	; in: rbp address of position
	;     rbx address of state
	; io: rdi address to write moves

		push	rsi r12 r13 r14 r15
		mov	rsi, rdi
		mov	rax, qword[rbx+State.checkersBB]
	; generate moves
		test	rax, rax
		jnz	.InCheck
.NotInCheck:
		call	Gen_NonEvasions
		jmp	.GenDone
.InCheck:
		call	Gen_Evasions
.GenDone:
		mov	r15, qword[rbx+State.pinned]
		mov	r13d, dword[rbp+Pos.sideToMove]
		mov	r12, qword[rbp+Pos.typeBB+8*King]
		and	r12, qword[rbp+Pos.typeBB+8*r13]
             _tzcnt	r14, r12
	; r15  = pinned pieces
	; r14d = our king square
	; r13d = side
	; r12 = our king bitboard

		shl	r14d, 6
		cmp	rsi, rdi
		 je	.FilterDone
		mov	eax, dword[rsi]
		mov	ecx, eax			;move
		test	r15, r15
		jnz	.FilterYesPinned
.FilterNoPinned:
		add	rsi, sizeof.ExtMove
		and	ecx, 0x0FC0    ; ecx shr 6 = source square
		cmp	ecx, r14d
		 je	.KingMove
		cmp	eax, MOVE_TYPE_EPCAP shl 12
		jae	.EpCapture
		mov	eax, dword[rsi]
		mov	ecx, eax	 ; move is legal at this point
		cmp	rsi, rdi
		jne	.FilterNoPinned
.FilterDone:
		pop	r15 r14 r13 r12 rsi
		ret


	     calign  8
.KingMove:
	; pseudo legal castling moves are always legal  ep captures have already been caught
		cmp	eax, MOVE_TYPE_CASTLE shl 12
		jae	.FilterLegalChoose

	; if they have an attacker to king's destination square, then move is illegal
		and	eax, 63	; eax = destination square
		mov	ecx, r13d
		shl	ecx, 6+3

		xor	r13d, 1
		mov	r10, qword[rbp+Pos.typeBB+8*r13]
		xor	r13d, 1
	; pawn
		mov	rcx, qword[PawnAttacks+rcx+8*rax]
		and	rcx, qword[rbp+Pos.typeBB+8*Pawn]
		test	rcx, r10
		jnz	.FilterIllegalChoose
	; king
		mov	rcx, qword[KingAttacks+8*rax]
		and	rcx, qword[rbp+Pos.typeBB+8*King]
		test	rcx, r10
		jnz	.FilterIllegalChoose
	; knight
		mov	rcx, qword[KnightAttacks+8*rax]
		and	rcx, qword[rbp+Pos.typeBB+8*Knight]
		test	rcx, r10
		jnz	.FilterIllegalChoose
		mov	r9, qword[rbp+Pos.typeBB+8*r13]			;has been moved
		or	r9, r10						;has been moved
.bishop_n_rook_attack:

	; bishop + queen
		BishopAttacks   rdx, rax, r9, rcx
		and	rdx, qword[rbx+State.checkSq+8]	; QxB
		test	rdx, r10
		jnz	.FilterIllegalChoose
	; rook + queen
		RookAttacks   rdx, rax, r9, rcx
		and	rdx, qword[rbx+State.checkSq]	; QxR
		test	rdx, r10
		jnz	.FilterIllegalChoose
		jmp	.FilterLegalChoose
	     calign   8, .FilterLegalChoose
.FilterIllegalChoose:
		sub	rdi, sizeof.ExtMove
		sub	rsi, sizeof.ExtMove
		mov	eax, dword [rdi]
		mov	dword [rsi], eax
.FilterLegalChoose:
		cmp	rsi, rdi
		je	.FilterDone
		mov	eax, dword[rsi]
		mov	ecx, eax	 ; move is legal at this point
		test	r15, r15
		jnz	.FilterYesPinned
		jmp	.FilterNoPinned
	     calign   8, .FilterYesPinned
.FilterYesPinnedLegal:
		cmp	rsi, rdi
		je	.FilterDone
		mov	eax, dword[rsi]
		mov	ecx, eax	 ; move is legal at this point
.FilterYesPinned:
		add	rsi, sizeof.ExtMove
		and	ecx, 0x0FC0    ; ecx shr 6 = source square
		cmp	ecx, r14d
		je	.KingMove
		cmp	eax, MOVE_TYPE_EPCAP shl 12
		jae	.EpCapture
		shr	ecx, 6
		bt	r15, rcx
		jnc	.FilterYesPinnedLegal
		and	eax, 0x0FFF	;(64*64)-1
		test	r12, qword[LineBB+8*rax]
		jnz	.FilterYesPinnedLegal
.FilterYesPinnedIllegal:		;unnecessary
		sub	rdi, sizeof.ExtMove
		sub	rsi, sizeof.ExtMove
		mov	eax, dword[rdi]
		mov	dword[rsi], eax
		jmp	.FilterYesPinnedLegal
	     calign  8
.EpCapture:
	; for ep captures, just make the move and test if our king is attacked
		xor	r13d, 1
		mov	r10, qword[rbp+Pos.typeBB+8*r13]
		xor	r13d, 1
		mov	r9, qword[rbp+Pos.typeBB+8*r13]

	; all pieces
		or	r9, r10
	; remove source square
		shr	ecx, 6
		btr	r9, rcx
	; add destination square (ep square)
		and	eax, 63
		bts	r9, rax
	; remove captured pawn
		lea	ecx, [2*r13-1]
		lea	ecx, [rax+8*rcx]
		btr	r9, rcx

		mov	eax, r14d
		shr	eax, 6
		jmp	.bishop_n_rook_attack
