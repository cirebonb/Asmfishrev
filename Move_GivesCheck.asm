
	     calign   8	;, Move_GivesCheck.HaveFromTo
Move_GivesCheck:	;ecx stand
	; in:  rbp  address of Pos
	;      rbx  address of State - check info must be filled in
	;      ecx  move assumed to be psuedo legal
	; out: eax =  0 if does not give check
	;      eax = -1 if does give check
	;	ecx not clobered

;ProfileInc Move_GivesCheck

		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to
;.HaveFromTo:
		movzx	r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
		and	r10d, 7
		mov	r11, qword[rbx+State.dcCandidates]
		mov	rax, qword[rbx+State.checkSq+8*r10]
		bt	rax, r9
		jc	.RetCheck

		bt	r11, r8
		jc	.DiscoveredCheck

		cmp	ecx, MOVE_TYPE_PROM shl 12
		jae	.Special
.Ret0:
		xor	rax, rax
		ret
.DiscoveredCheck:
		movzx	edx, byte[rbx+State.ksq]		;was edi
		mov	eax, ecx
		and	eax, 64*64-1
		mov	rax, qword[LineBB+8*rax]
		bt	rax, rdx				;was edi
		jc	.DiscoveredCheckRet
.RetCheck:
		or	rax, -1
		ret
.DiscoveredCheckRet:
		cmp	ecx, MOVE_TYPE_PROM shl 12
		jb	.Ret0
.Special:
		movzx	r11d, byte[rbx+State.ksq]
		mov	rdx, qword[rbx+State.Occupied]
		btr	rdx, r8
		bts	rdx, r9

		mov	eax, ecx
		shr	eax, 12	; eax = move type
		mov	eax, dword[.JmpTable+4*(rax-MOVE_TYPE_PROM)]
		jmp	rax


	     calign   8
.JmpTable:   dd .PromKnight,.PromBishop,.PromRook,.PromQueen
	     dd .EpCapture,0,0,0
	     dd .Castling,0,0,0


	     calign   8
.Castling:
 ;  esi starts as
 ;  esi=0 if we are white
 ;  esi=1 if we are black
 ;  we are supposed to get into esi the following number
 ;  esi=0 if white and O-O
 ;  esi=1 if white and O-O-O
 ;  esi=2 if black and O-O
 ;  esi=3 if black and O-O-O
 ;  r9d contains to square   (square of rook)
 ;  r8d contains from square (square of king)
 ;
 ;  since we assume that only one of the four possible castling moves have been passed in,
 ;  this can be corrected by comparing the rook square to the king square
		mov   eax, dword[rbp+Pos.sideToMove]
		cmp   r9d, r8d
		adc   eax, eax

	      movzx   r10d, byte[rbp-Thread.rootPos+Thread.castling_rfrom+rax]
	      movzx   eax, byte[rbp-Thread.rootPos+Thread.castling_rto+rax]
		btr   rdx, r10
		bts   rdx, rax
		bts   rdx, r9  ; set king again if nec
		RookAttacksClob	rax, rax, rdx
;	RookAttacks   rax, rax, rdx, r10
		 bt   rax, r11
		sbb   rax, rax
		ret


	     calign   8
.EpCapture:
		push	rsi
		mov	esi, dword[rbp+Pos.sideToMove]
		lea	eax, [2*rsi-1]
		lea	eax, [r9+8*rax]
		btr	rdx, rax
	BishopAttacks	rax, r11, rdx, r10
	RookAttacksClob	r11, r11, rdx
		and	rax, qword[rbx+State.checkSq+8]	;B + Q
		and	r11, qword[rbx+State.checkSq]	;R + Q
		or	rax, r11
		and	rax, qword[rbp+Pos.typeBB+8*rsi]
		neg	rax
		sbb	rax, rax
		pop	rsi
		ret

	     calign   8
.PromQueen:
;		QueenAttacks	rax, r9, rdx, r10, r11
		;rdx clobered
		QueenAttacksMinReg	rax, r9, rdx, r10
		bt	rax, r11
		sbb	rax, rax
		ret
	     calign   8
.PromBishop:
		BishopAttacksClob	rax, r9, rdx
;      BishopAttacks   rax, r9, rdx, r10
		 bt   rax, r11
		sbb   rax, rax
		ret

	     calign   8
.PromRook:
		RookAttacksClob		rax, r9, rdx
;	RookAttacks   rax, r9, rdx, r10
		 bt   rax, r11
		sbb   rax, rax
		ret

	     calign   8
.PromKnight:
		mov   rax, qword[KnightAttacks+8*r9]
		 bt   rax, r11
		sbb   rax, rax
		ret

