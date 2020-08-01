	     calign   16
Move_IsPseudoLegal:
	; in: rbp address of Pos
	;     rbx address of State
	;     ecx move
	; out: rax = 0 if move is not pseudo legal
	;      rax !=0 if move is pseudo legal      could be anything nonzero
	;
	;  we need to make sure the move is legal for the special types
	;    promotion
	;    castling
	;    epcapture
	;  so we also require checkinfo to be set

;ProfileInc Move_IsPseudoLegal

		push   rsi rdi r12 r13 r14 r15

	; r8d = from
	; r9d = to
		mov	r8d, ecx
		shr	r8d, 6
		and	r8d, 63
		mov	r9d, ecx
		and	r9d, 63

;ProfileInc moveUnpack
	; eax = FROM PIECE
		movzx	eax, byte[rbp+Pos.board+r8]
		mov	esi, dword[rbp+Pos.sideToMove]
	; r14 = bitboard of our pieces
	; r15 = bitboard of all pieces
		mov	r14, qword[rbp+Pos.typeBB+8*rsi]
	; make sure that our piece is on from square
		bt	r14, r8
		jnc	.ReturnFalse
	; r13 = checkers
	; r12 = -1 if checkers!=0
	;     =  0 if checkers==0
		mov	r15, qword[rbx+State.Occupied]
		mov	r12, qword[rbx+State.checkersBB]
		mov	r13, r12
		neg	r12
		sbb	r12, r12
		and	eax, 7
	; ecx = MOVE_TYPE
	; rdi = bitboard of to square r9d
	; r10 = -(MOVE_TYPE==0) & rdi
	; eax = move
		cmp	ecx, 1 shl 12	;1
		sbb	r10, r10
		xor	edi, edi
		bts	rdi, r9
		and	r10, rdi
		jz	.Special
	; make sure that we don't capture our own piece
		bt	r14, r9
		jc	.ReturnFalse
		mov	eax, dword[.JmpTable+4*rax]
		jmp	rax
	     calign   8
    .NoPiece:
    .ReturnFalse:
		xor	eax, eax
		pop	r15 r14 r13 r12 rdi rsi
		ret
;flagok
             calign   8
.JmpTable:
		dd .NoPiece
		dd .NoPiece
		dd .Pawn
		dd .Knight
		dd .Bishop
		dd .Rook
		dd .Queen
		dd .King

	     calign   8
.Knight:
		mov   rax, qword[KnightAttacks+8*r8]
		and   rax, r10
	       test   rax, r12
		jnz   .Checkers
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign   8
.Bishop:
      BishopAttacks   rax, r8, r15, rdx
		and   rax, r10
	       test   rax, r12
		jnz   .Checkers
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign   8
.Rook:
	RookAttacks   rax, r8, r15, rdx
		and   rax, r10
	       test   rax, r12
		jnz   .Checkers
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign   8
.Queen:
	QueenAttacks	rax, r8, r15, r11, rdx	;rcx
		and   rax, r10
	       test   rax, r12
		jnz   .Checkers
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign   8
.Checkers:
	; if more than one checker, must move king
		lea   rdx, [r13-1]
	       test   rdx, r13
		jnz   .ReturnFalse
	; if moving P|R|B|Q and in check, filter some moves out
		movzx	edx, byte[rbx+State.ourKsq]
             _tzcnt   rax, r13
		shl   eax, 6+3
		mov   rax, qword[BetweenBB+rax+8*rdx]
		 or   rax, r13
	; move must be a blocking evasion or a capture of the checking piece
		and   rax, rdi
;flagok
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign  8
.Pawn:
		mov   eax, r8d
		xor   eax, r9d
		cmp   eax, 16
		 je   .DoublePawn
		mov   r11d, esi
		shl   r11d, 6+3
		xor   eax, eax
		xor   esi, 1
		lea   edx, [2*rsi-1]
		lea   edx, [r8+8*rdx]
		bts   rax, rdx
	      _andn   rax, r15, rax
		mov   rdx, [rbp+Pos.typeBB+8*rsi]
		and   rdx, qword[PawnAttacks+r11+8*r8]
		 or   rax, rdx
		mov   rdx, 0x00FFFFFFFFFFFF00
		and   rax, rdx

		and   rax, r10
	       test   rax, r12
		jnz   .Checkers
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret


	     calign   8
 .DoublePawn:
	; make sure that two squares are clear
		lea   eax, [r8+r9]
		shr   eax, 1
		mov   rdx, rdi
		bts   rdx, rax
	       test   rdx, r15
		jnz   .DPawnReturnFalse
	; make sure that from is on home
		mov   eax, r8d
		shr   eax, 3
		lea   edx, [1+5*rsi]
		cmp   eax, edx
		jne   .DPawnReturnFalse
	       test   r12, r12
		jnz   .Checkers
		 or   eax, -1
		pop   r15 r14 r13 r12 rdi rsi		;flagok
		ret
    .DPawnReturnFalse:
		xor   eax, eax				;flagok
		pop   r15 r14 r13 r12 rdi rsi
		ret
.popexit:
		test	rax,rax	;===================
		pop   r15 r14 r13 r12 rdi rsi
		ret


	     calign  8
.King:
		mov   rax, qword[KingAttacks+8*r8]
		and   rax, r10
	       test   rax, r12	;r12 bool check rax=sq
		jz	.popexit
		shl	esi, 6+3
; .KingCheckers:
	; r14 = their pieces
	; r15 = pieces ^ our king
	      _andn   r14, r14, r15
		btr   r15, r8

		mov   rax, qword[KingAttacks+8*r9]
		and   rax, qword[rbp+Pos.typeBB+8*King]

		mov   rdx, qword[KnightAttacks+8*r9]
		and   rdx, qword[rbp+Pos.typeBB+8*Knight]
		 or   rax, rdx

		mov   rdx, qword[PawnAttacks+rsi+8*r9]
		and   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		 or   rax, rdx

	RookAttacks   rdx, r9, r15, r10
		and	rdx, qword[rbx+State.checkSq]	; QxR
		 or	rax, rdx

      BishopAttacks   rdx, r9, r15, r10
		and	rdx, qword[rbx+State.checkSq+8]	; QxB
		 or	rax, rdx

		and	rax, r14
		cmp	rax, 1
		sbb	eax, eax
		pop   r15 r14 r13 r12 rdi rsi	;flagok
		ret


	     calign   8
.Special:
		cmp	ecx, MOVE_TYPE_EPCAP shl	12
		jae	.EpCapture
.Promotion:

		cmp   eax, Pawn
		jne   .ReturnFalse
		 bt   r14, r9
		 jc   .ReturnFalse

		mov   r11d, esi
		shl   r11d, 6+3

;		lea   ecx, [rsi-1]
		xor   esi, 1
;		and   ecx, 56
;		mov   edx, 0x0FF
;		shl   rdx, cl

		mov	rdx, 0x0FF00000000000000
		mov	eax, 0x0FF
		cmp	esi, 1
		cmovne	rdx, rax

		xor	eax, eax

		lea	r14d, [2*rsi-1]
		lea	r14d, [r8+8*r14]
		bts	rax, r14
	      _andn	rax, r15, rax
		mov	r14, [rbp+Pos.typeBB+8*rsi]
		and	r14, qword[PawnAttacks+r11+8*r8]
		 or	rax, r14
		and	rax, rdx
		and	rax, rdi
		 jz	.ReturnFalse
	       test	rax, r12
		jnz	.PromotionCheckers

	; we are not in check so make sure pawn is not pinned

.PromotionCheckPinned:
		mov   rdx, qword[rbx+State.pinned]
		 bt   rdx, r8
		jnc   @f

		xor   esi, 1
		imul	edx, r8d, 1 shl 9
		mov   rax, qword[rbp+Pos.typeBB+8*King]
		and   rax, qword[rbp+Pos.typeBB+8*rsi]
		and   rax, qword[LineBB+rdx+8*r9]
		pop   r15 r14 r13 r12 rdi rsi
		ret	;flagok
@@:
		 or   eax, -1	;flagok
		pop   r15 r14 r13 r12 rdi rsi
		ret


.PromotionCheckers:
	; position inCheck!
	; if moving P|R|B|Q and in check, filter some moves out
	; if more than one checker, must move king
		lea	rdx, [r13-1]
		test	rdx, r13
		jnz	.ReturnFalse

		_tzcnt	rax, r13
		shl	eax, 6+3
		movzx	edx, byte[rbx+State.ourKsq]
		mov	rax, qword[BetweenBB+rax+8*rdx]
		or	rax, r13

	; move must be a blocking evasion or a capture of the checking piece
		test	rax, rdi
		jz	.ReturnFalse
		jmp	.PromotionCheckPinned


	     calign   8
.EpCapture:
		mov	edx, ecx
		shr	edx, 12
		cmp	edx, MOVE_TYPE_EPCAP
		jne	.Castle

	; make sure destination is empty
		 bt   r15, r9
		 jc   .ReturnFalse

	; make sure that it is our pawn moving
		cmp   eax, Pawn
		jne   .ReturnFalse

	; make sure to is epsquare
		cmp   r9l, byte[rbx+State.epSquare]
		jne   .ReturnFalse

	; make sure from->to is a pawn attack
		mov   r11d, esi
		shl   r11d, 6+3
		mov   rax, qword[PawnAttacks+r11+8*r8]
		 bt   rax, r9
		jnc   .ReturnFalse

	; make sure capsq=r10=r9+pawnpush is their pawn
		lea   r10d, [2*rsi-1]
		lea   r10d, [r9+8*r10]
		xor   esi, 1
		lea   eax, [Pawn+8*rsi]
		cmp   al, byte[rbp+Pos.board+r10]
		jne   .ReturnFalse

	; rdi = ksq = square<KING>(us)
		movzx	edi, byte[rbx+State.ourKsq]

	; r15 = occupied = (pieces() ^ from ^ capsq) | to
		btr   r15, r8
		btr   r15, r10
		bts   r15, r9

	; r14 = their pieces
		mov   r14, qword[rbp+Pos.typeBB+8*rsi]

	; check for rook attacks
	RookAttacks   rax, rdi, r15, rdx
		and	rax, qword[rbx+State.checkSq]	; QxR
		test	rax, r14
		jnz   .ReturnFalse

	; check for bishop attacks
      BishopAttacks   rax, rdi, r15, rdx
		and	rax, qword[rbx+State.checkSq+8]	; QxB
	       test   rax, r14
		jnz   .ReturnFalse

		 or   eax, -1				;flagok
		pop   r15 r14 r13 r12 rdi rsi
		ret

	     calign   8				;below flagok
.Castle:
	; in eax = move, clobered reg rdx, rax, rcx
	; CastlingJmp expects
	;     r13  their pieces
	;     r14  all pieces
		cmp   edx, MOVE_TYPE_CASTLE
		jne   .CastleReturnFalse
	       test   r12, r12
		jnz   .CastleReturnFalse
	      _andn   r13, r14, r15
		mov   r14, r15
	       test   esi, esi
		jnz   .CastleBlack
.CastleWhite:
		cmp   ecx, dword[rbp-Thread.rootPos+Thread.castling_movgen+4*0]
		 je   .CastleCheck_WhiteOO
		cmp   ecx, dword[rbp-Thread.rootPos+Thread.castling_movgen+4*1]
		 je   .CastleCheck_WhiteOOO
.CastleReturnFalse:
		xor   eax, eax
		pop   r15 r14 r13 r12 rdi rsi
		ret
.CastleBlack:
		cmp   ecx, dword[rbp-Thread.rootPos+Thread.castling_movgen+4*2]
		 je   .CastleCheck_BlackOO
		cmp   ecx, dword[rbp-Thread.rootPos+Thread.castling_movgen+4*3]
		jne   .CastleReturnFalse
		jmp   .CastleCheck_BlackOOO



  .CastleCheck_WhiteOO:
	      movzx   eax, byte[rbx+State.castlingRights]
		mov   rdx, qword[rbp-Thread.rootPos+Thread.castling_path+8*0]
		and   rdx, r15
		and   eax, 1 shl 0
		xor   eax, 1 shl 0
		 or   rax, rdx
		jnz   .CastleReturnFalse
	       call   CastleOOLegal_White
		pop   r15 r14 r13 r12 rdi rsi
		ret

  .CastleCheck_BlackOO:
	      movzx   eax, byte[rbx+State.castlingRights]
		mov   rdx, qword[rbp-Thread.rootPos+Thread.castling_path+8*2]
		and   rdx, r15
		and   eax, 1 shl 2
		xor   eax, 1 shl 2
		 or   rax, rdx
		jnz   .CastleReturnFalse
	       call   CastleOOLegal_Black
		pop   r15 r14 r13 r12 rdi rsi
		ret


  .CastleCheck_WhiteOOO:
	      movzx   eax, byte[rbx+State.castlingRights]
		mov   rdx, qword[rbp-Thread.rootPos+Thread.castling_path+8*1]
		and   rdx, r15
		and   eax, 1 shl 1
		xor   eax, 1 shl 1
		 or   rax, rdx
		jnz   .CastleReturnFalse
	       call   CastleOOOLegal_White
		pop   r15 r14 r13 r12 rdi rsi
		ret

  .CastleCheck_BlackOOO:
	      movzx   eax, byte[rbx+State.castlingRights]
		mov   rdx, qword[rbp-Thread.rootPos+Thread.castling_path+8*3]
		and   rdx, r15
		and   eax, 1 shl 3
		xor   eax, 1 shl 3
		 or   rax, rdx
		jnz   .CastleReturnFalse
	       call   CastleOOOLegal_Black
		pop   r15 r14 r13 r12 rdi rsi
		ret
