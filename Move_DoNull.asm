;in	r9d	= .cutNode
;	r13d	= .ply
;	edi	= .Thread.nmp_ply
;	esi	= .depth
             calign   16
Move_DoNull:
		lea	eax, [r14-1]			; r14d = .evalu
		sub	eax, r12d			; eax = .evalu - .beta
		mov	ecx, PawnValueMg
		xor	edx, edx
	       idiv	ecx
		mov	ecx, 3
		cmp	eax, ecx
	      cmovg	eax, ecx
	       imul	ecx, esi, 67	;dword[.depth], 67
		add	ecx, 823
		sar	ecx, 8
		add	eax, ecx

	     Assert   ge, eax, 0, 'assertion eax >= 0 failed in	Search'

		mov	r14d, esi
		sub	r14d, eax			; r14d = depth-R
        ; copy the other important info
		xor	eax, eax
		mov	edx, dword[rbx+State.rule50]
		mov	dh, al
		add	edx, 0x010001	; + ply; + 50moves
		cmp	byte[signals.stop], al
		jne	.exitSearch
		cmp	edx, (MAX_PLY-1) shl 16
		ja	.NullAbortSearch_PlySmaller
		cmp	dl, 100
		jae	.NullAbortSearch_PlySmaller

		movzx	ecx, word[rbx+State.epSquare]	; only copy epsq n castling
		mov	r8, qword[rbx+State.key]
		xor	r8, qword[Zobrist_side]
		test	ecx, 63
		jnz	.epsq
.epsq_ret:
		mov	dword[rbx+sizeof.State+State.epSquare], ecx	; .castlingRights+capturedPiece+ksq
		mov	dword[rbx+sizeof.State+State.rule50], edx
		mov	dword[rbx+2*sizeof.State+State.history], eax
		mov	qword[rbx+1*sizeof.State+State.checkSq+8*King], rax
		mov	qword[rbx+1*sizeof.State+State.checkersBB], rax
		mov	dword[rbx+State.moveCount], eax

if 0
		movzx	ecx, byte[rbx+State.pliesFromNull]
		inc	ecx
		movzx	edx, dl
		cmp	edx, ecx
		cmovg	edx, ecx
		cmp	edx, 4
		jb	.skiptest
		imul	r10, rdx, -sizeof.State
		mov	r11, -4*sizeof.State	; r9 = i
.CheckNext:
		cmp	r8, qword[rbx+r11+1*sizeof.State+State.key]
		je	.found
;		je	.NullAbortSearch_PlySmaller
		sub	r11, 2*sizeof.State
		cmp	r11, r10
		jae	.CheckNext
		jmp	.skiptest
.found:
		mov	rax, qword[rbx+r11+1*sizeof.State+State.ltte]
		mov	qword[rbx+1*sizeof.State+State.ltte], rax
		mov	rax, qword[rbx+r11+1*sizeof.State+State.tte]
;		Display	0, "info string draw on Null found %i2%n"
.skiptest:
end if
		mov	qword[rbx+1*sizeof.State+State.tte],rax
		
		; Move_Do_null
		add	rbx, sizeof.State			; point of change
	; null move doesn't use a move picker
                mov	rcx, qword[rbx-1*sizeof.State+State.pawnKey]
                mov	rdx, qword[rbx-1*sizeof.State+State.materialKey]
                mov	r10, qword[rbx-1*sizeof.State+State.psq] 	; copy psq and npMaterial
		mov	r11, qword[rbx-1*sizeof.State+State.checkSq]	; QxR
		mov	rax, qword[rbx-1*sizeof.State+State.checkSq+8]	; QxB
		mov	r15, qword[rbx-1*sizeof.State+State.Occupied]	; r15 = all pieces
		mov	qword[rbx+State.Occupied], r15
		mov	qword[rbx+State.checkSq+8], rax		;QxB
		mov	qword[rbx+State.checkSq], r11		;QxR
		mov	qword[rbx+State.psq], r10
                mov	qword[rbx+State.pawnKey], rcx
                mov	qword[rbx+State.materialKey], rdx
                mov	qword[rbx+State.key], r8
		
;		mov	dword[rbx+1*sizeof.State+State.excludedMove], eax
;		mov	qword[rbx+2*sizeof.State+State.killers], rax

                and	r8, qword[mainHash.mask]
                shl	r8, 5
                add	r8, qword[mainHash.table]
        prefetchnta	[r8]

;		movzx	eax, word[rbx-1*sizeof.State+State.ksq]
;		movzx	edx, ah
;		mov	r11d, edx
;		mov	dh, al
;		mov	qword[rbx+State.Ksq], rdx
		movzx   eax, byte[rbx-1*sizeof.State+State.ksq]
		movzx   r11d, byte[rbx-1*sizeof.State+State.ourKsq]
                mov	ecx, dword[rbp+Pos.sideToMove]
		mov	edx, ecx
		shl	edx, 6+3
		xor	ecx, 1
                mov	dword[rbp+Pos.sideToMove], ecx
		mov	byte[rbx+State.ksq], r11l
		mov	qword[rbx+State.ourKsq], rax

		mov	rax, qword[WhitePawnAttacks+rdx+8*r11]
		mov	rdx, qword[KnightAttacks+8*r11]
		mov	qword[rbx+State.checkSq+8*Pawn], rax
		mov	qword[rbx+State.checkSq+8*Knight], rdx
      BishopAttacks	rax, r11, r15, r8
	RookAttacks	rdx, r11, r15, r8
		mov	qword[rbx+State.checkSq+8*Bishop], rax
		mov	qword[rbx+State.checkSq+8*Rook], rdx
		 or	rax, rdx
		mov	qword[rbx+State.checkSq+8*Queen], rax
;allready have checkinfo on previous
;_vmovups   xmm0, dqword[rbx-1*sizeof.State+State.pinnersForKing+8*0]
;_vmovups   xmm1, dqword[rbx-1*sizeof.State+State.blockersForKing+8*0]
;_vmovups   xmm2, dqword[rbx-1*sizeof.State+State.QxR]
;_vmovups   dqword[rbx+State.pinnersForKing+8*0], xmm0
;_vmovups   dqword[rbx+State.blockersForKing+8*0], xmm1 
;_vmovups   dqword[rbx+State.QxR], xmm2 
		mov	r10, qword[rbp+Pos.typeBB+8*rcx]		; r10 = our pieces
		mov	rax, qword[rbx-1*sizeof.State+State.pinnersForKing+8*0]
		mov	rdx, qword[rbx-1*sizeof.State+State.pinnersForKing+8*1]
		mov	r8, qword[rbx-1*sizeof.State+State.blockersForKing+8*0]
		mov	r15, qword[rbx-1*sizeof.State+State.blockersForKing+8*1]
                mov	r11, qword[rbx-2*sizeof.State+State.endMoves]
                mov	qword[rbx-1*sizeof.State+State.endMoves], r11
		mov	qword[rbx+State.pinnersForKing+8*0], rax
		mov	qword[rbx+State.pinnersForKing+8*1], rdx
		mov	qword[rbx+State.blockersForKing+8*0], r8
		mov	qword[rbx+State.blockersForKing+8*1], r15


		and	r8, r10
		and	r15, r10
		mov	r10, r15
		test	ecx, ecx
		cmovnz	r10, r8
		cmovnz	r8, r15

		mov	r15l, JUMP_IMM_2+JUMP_IMM_4
		mov	dx, JUMP_IMM_2
		mov	ecx, dword[rbx-2*sizeof.State+State.staticEval]
		mov	r11d, dword[rbx-1*sizeof.State+State.staticEval]
		neg	r11d
		add	r11d, 2*Eval_Tempo
		xor	eax, eax

;		cmp	r14d, eax
;		jle	.notnecessary
		not	r9d				; r9d = .cutNode
		cmp	r11d, ecx
		setge	dh
		cmp	ecx, VALUE_NONE			; incheck?
		sete	cl
		or	dh, cl
		mov	ecx, CmhDeadOffset
		add	rcx, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx-1*sizeof.State+State.counterMoves], rcx
		mov	dword[rbx-1*sizeof.State+State.currentMove], MOVE_NULL	;
;	.notnecessary:
		;
		mov	word[rbx+State.flags], dx	; +State.improving
		mov	dword[rbx+State.staticEval], r11d
		mov	qword[rbx+State.dcCandidates], r10
		mov	qword[rbx+State.pinned], r8
		;

		mov	r8d, r14d			; .depth-R
		lea	ecx, [r12+1]
		neg	ecx
		lea	edx, [rcx+1]
		cmp	r8d, eax			; ONE_PLY
		cmovl	r8d, eax
		setg	al				; setge
		mov	rax, [TableQsearch_NonPv+8+rax*8]
		call	rax
		neg	eax
		xor	dword[rbp+Pos.sideToMove], 1	; undo null move
		sub	rbx, sizeof.State		;
.NullAbortSearch_PlySmaller:
		lea	ecx, [r12+1]
		cmp	eax, ecx
		jl	.ReturnFunction
		test	dil, dil			; Thread.nmp_ply = 0? Recursive verification is not allowed
		jnz	.exitSearch
		cmp	eax, VALUE_MATE_IN_MAX_PLY
		cmovge	eax, ecx
		lea	ecx, [r12+VALUE_KNOWN_WIN]	;[r13+VALUE_KNOWN_WIN-1]
		cmp	ecx, 2*(VALUE_KNOWN_WIN-1)
		ja	.8check
		cmp	esi, 12*ONE_PLY
		jge	.8check
		; .Return eax = value
.exitSearch:
		xor	ecx, ecx			; FLag Zero is Set -> dont clobber eax
.ReturnFunction:
		ret
.8check:
		mov	edi, eax			; eax = nullValue
		cmp	r12d, 0
		jge	.skipdetect
		movzx	ecx, word[rbx+State.ltte+MainHashEntry.move]
		cmp	ecx, 0
		jne	.skipdetect2
		mov   r8d, ecx
		shr   r8d, 6
		and   r8d, 63	; r8d = from
		mov   r9d, ecx
		and   r9d, 63	; r9d = to
		call	detectRepetition
		mov	eax, edi		; edi = nullValue
		jz	.exitSearch1
.skipdetect2:
 if USE_GAMECYCLE = 1
		movzx	ecx, byte[rbx+State.pliesFromNull]
		cmp	ecx, 3
		jb	.skipdetect
		call	has_game_cycle
		mov	eax, edi		; edi = nullValue
		jz	.exitSearch1
 end if
.skipdetect:

		mov	r8d, r14d
		mov	ecx, 4
		lea	eax, [3*r8d]
		test	eax, eax
		cmovs	eax, ecx
		sar	eax, 2
		add	eax, r13d			; r13d	= .ply
		and	r13d, 1
		mov	byte[rbp-Thread.rootPos+Thread.nmp_ply+r13], al
		;
		mov	r15l, JUMP_IMM_3		; direct to movepick
		xor	eax, eax
		mov	r9d, eax			; r9d = .cutNode = 0
		cmp	r8d, eax	;ONE_PLY
		cmovl	r8d, eax
		setg	al		;setge
		mov	rax,[TableQsearch_NonPv+8+rax*8]
;		
		mov	ecx, r12d
		lea	edx, [rcx+1]
		call	rax
		; restore original Thread.nmp_ply
		mov	byte[rbp-Thread.rootPos+Thread.nmp_ply+r13], 0
		;
		cmp	eax, r12d		; .beta
		mov	eax, edi		; edi = nullValue
		jg	.exitSearch1		;jge
		; if Zero Flags = 1 -> .Return eax = value
		cmp	byte[signals.stop],-1	;  bug fix ;) 
		ret
	calign   8
.exitSearch1:
		xor	ecx, ecx			; .Return eax = value
		ret
	calign   8
.epsq:
                mov   r10d, ecx
                add   ecx, 0x40
                and   r10d, 7
                xor   r8, qword[Zobrist_Ep+8*r10]
                jmp   .epsq_ret
if 1
	     calign   16
detectRepetition:
	; in	: r8 & r9
		cmp	ecx, MOVE_TYPE_PROM shl 12
		jae	.NO_DRAW
	; get update rule50 and pliesFromNull
		movzx	eax, byte[rbp+Pos.board+r9]	; eax = TO PIECE
		and	eax, 7
		jnz	.NO_DRAW
		movzx	r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
;		cmp	byte[IsPawnMasks+r10],0xff	or
		mov	eax, r10d
		and	eax, 7
		cmp	eax, Pawn
		je	.NO_DRAW
		mov	edx, dword[rbx+State.rule50]
		add	edx, 0x010101
		cmp	edx, (MAX_PLY-1) shl 16
		ja	.YES_DRAW
		cmp	dl, 100
		jae	.YES_DRAW
		mov	eax, edx
		shr	eax, 8
		cmp	dl, al
		cmova	edx, eax
		cmp	dl, 4
		jb	.TPDReturn
	; build key
		mov	r11, qword[Zobrist_side]
		xor	r11, qword[rbx+State.key]
	; castling rights
		movzx	eax, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r8]
		or	al, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r9]
		and	al, byte[rbx+State.castlingRights]
		jnz	.Rights
.RightsRet:
	; ep square hash allready filtered out
		shl	r10d, 6+3
		xor	r11, qword[Zobrist_Pieces+r10+8*r8]
		xor	r11, qword[Zobrist_Pieces+r10+8*r9]
		movzx	edx, dl
		imul	r10, rdx, -sizeof.State	; r10 = end
		mov	rdx, -4*sizeof.State
.DetectNext:
		cmp	r11, qword[rbx+rdx+sizeof.State+State.key]
		 je	.YES_DRAW
		sub	rdx, 2*sizeof.State
		cmp	rdx, r10
		jge	.DetectNext
		;no draw
;		;now detect draw move?
;		mov	eax, dword[rbx-3*sizeof.State+State.currentMove]
;		cmp	eax, MOVE_TYPE_PROM shl 12
;		jae	.NO_DRAW
;		test	eax, eax
;		jz	.NO_DRAW
;		mov	r10d, eax
;		and	eax,63
;		shl	eax, 6
;		shr	r10d, 6
;		or	eax, r10d
;		cmp	eax, dword[rbx-1*sizeof.State+State.currentMove]
;		jne	.NO_DRAW
;		mov	eax, dword[rbx-2*sizeof.State+State.currentMove]
;		cmp	eax, MOVE_NULL
;		je	.NO_DRAW
;		mov	al, byte[rbx-3*sizeof.State+State.castlingRights]
;		cmp	al, byte[rbx+State.castlingRights]
;		je	.YES_DRAW
.NO_DRAW:
		xor	eax, eax
		inc	eax
		ret
	 calign	  8
.YES_DRAW:
		xor	eax, eax	;eax = VALUE_DRAW
.TPDReturn:
		ret
	     calign	8
.Rights:
		xor	r11, qword[Zobrist_Castling+8*rax]
		jmp	.RightsRet
end if

if USE_GAMECYCLE = 1
	 calign	  16
has_game_cycle:
;in	ecx = pliesFromNull
;out	eax = result 0 or cl

		mov	r8,qword[rbx+State.key]
		lea	r9,[rbx-sizeof.State]
		mov	r11d, 3
	.loopcheck:
		sub	r9, 2*sizeof.State
		mov	r10, r8
		xor	r10, qword[r9+State.key]
		mov	eax, r10d
		and	eax, 0x1fff	;H1
		cmp	r10, qword[cuckoo+rax*8]
		je	.yescyclefound
		mov	eax, r10d
		shr	eax, 16
		and	eax, 0x1fff	;H2
		cmp	r10, qword[cuckoo+rax*8]
		jne	.nocyclefound
	.yescyclefound:
		movzx	rax, word[cuckooMove+rax*2]
		mov	rax, qword[BetweenBB+rax*8]
		test	rax, qword[rbx+State.Occupied]
		jz	.testprint
	.nocyclefound:
		add	r11d, 2
		cmp	r11d, ecx
		jbe	.loopcheck
		or	eax,-1
		ret
	.testprint:
		xor	eax,eax
		ret
end if
