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
		je	.NullAbortSearch_PlySmaller	;.found
		sub	r11, 2*sizeof.State
		cmp	r11, r10
		jae	.CheckNext
;		jmp	.skiptest
;.found:
;		mov	rax, qword[rbx+r11+1*sizeof.State+State.tte]
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

		mov	r15l, JUMP_IMM_3+JUMP_IMM_2
		mov	dl, r15l
		mov	ecx, dword[rbx-2*sizeof.State+State.staticEval]
		mov	eax, dword[rbx-1*sizeof.State+State.staticEval]
		neg	eax
		add	eax, 2*Eval_Tempo
		cmp	eax, ecx
		setge	dh
		cmp	ecx, VALUE_NONE			; incheck?
		sete	cl
		or	dh, cl
		mov	word[rbx+State.flags], dx	; +State.improving
		mov	dword[rbx+State.staticEval], eax
		mov	qword[rbx+State.dcCandidates], r10
		mov	qword[rbx+State.pinned], r8
		;
		mov	ecx, CmhDeadOffset
		add	rcx, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx-1*sizeof.State+State.counterMoves], rcx
		mov	dword[rbx-1*sizeof.State+State.currentMove], MOVE_NULL	;

		not	r9d				; r9d = .cutNode
		mov	r8d, r14d			; .depth-R
;		mov	edx, r12d
;		neg	edx
;		lea	ecx, [rdx-1]
		lea	ecx, [r12+1]
		neg	ecx
		lea	edx, [rcx+1]
		xor	eax, eax
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
		mov	r8d, r14d
		mov	edi, eax			; eax = nullValue
		mov	ecx, 4
		lea	eax, [3*r8d]
		test	eax, eax
		cmovs	eax, ecx
		shr	eax, 2
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
		cmp	byte[signals.stop],0
		ret
	calign   8
.exitSearch1:
		xor	ecx, ecx			; .Return eax = value
		ret

;	calign	  8
;.NullAbortSearch_PlySmaller:	;DRAW
;		Display	0, "info string draw on Null found %i2%n"
;		xor	eax, eax
;		ret					; .Return eax = value
	calign   8
.epsq:
                mov   r10d, ecx
                add   ecx, 0x40
                and   r10d, 7
                xor   r8, qword[Zobrist_Ep+8*r10]
                jmp   .epsq_ret
