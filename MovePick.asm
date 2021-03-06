;r12 free
	     calign   8
MovePick_MAIN_SEARCH:
		lea	rax, [MovePick_CAPTURES_GEN]
		mov	rcx, qword[rbx-1*sizeof.State+State.endMoves]
		mov	qword[rbx+State.endMoves], rcx			;*******
		mov	qword[rbx+State.stage], rax
		mov	ecx, dword[rbx+State.ttMove]
		test	ecx, ecx
		ret

	     calign   16, MovePick_GOOD_CAPTURES
MovePick_CAPTURES_GEN:
		or	r15, -1
		call	Gen_Captures
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
		mov	qword[rbx+State.endBadCaptures], r14
		mov	qword[rbx+State.endMoves], rdi			;*******
      ScoreCaptures	r14, r13, rdi, WhileDone1
		mov	r15, rdi
		lea	rax, [MovePick_GOOD_CAPTURES]
		mov	qword[rbx+State.stage], rax
		jmp	@1f

MovePick_GOOD_CAPTURES:
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:		
		cmp	r14, r15
		je	WhileDone1
	   PickBest	r14, r13, r15
		cmp	ecx, dword[rbx+State.ttMove]
		je	@1b
		imul	edx, dword[r14 - sizeof.ExtMove + ExtMove.value], -55
                lea	eax, [edx + 1023]
		test	edx, edx
		cmovs	edx, eax
		sar	edx, 10
		call	SeeTestGe
		test	eax, eax
		jz	.Negative
		mov	qword[rbx+State.cur], r14			;*******0
		ret		;	flags !zero
	.Negative:
		mov	rax, qword[rbx+State.endBadCaptures]
		mov	dword[rax+ExtMove.move], ecx
		add	rax, sizeof.ExtMove
		mov	qword[rbx+State.endBadCaptures], rax
		jmp	@1b
		calign	16, MovePick_QUIETS
    WhileDone1:
		mov	ecx, dword[rbx+State.mpKillers+4*0]
		test	ecx, ecx
		jz	MovePick_KILLERS2	;changed
		cmp	ecx, dword[rbx+State.ttMove]
		je	MovePick_KILLERS
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.special
		mov	eax, ecx
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax], 0
		jnz	MovePick_KILLERS
    .check:
		call	Move_IsPseudoLegal
;		test	rax, rax
		jz	MovePick_KILLERS
		lea	rax, [MovePick_KILLERS]
		mov	qword[rbx+State.stage], rax
		ret	;	flags !zero
.special:
		cmp	ecx, MOVE_TYPE_CASTLE shl 12
		jae	.check
MovePick_KILLERS:
		mov	ecx, dword[rbx+State.mpKillers+4*1]
		test	ecx, ecx
		jz	MovePick_KILLERS2
		cmp	ecx, dword[rbx+State.ttMove]
		je	MovePick_KILLERS2
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.special
		mov	eax, ecx
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax], 0
		jnz	MovePick_KILLERS2
    .check:
		call	Move_IsPseudoLegal
;		test	rax, rax
		jz	MovePick_KILLERS2
		lea	rax, [MovePick_KILLERS2]
		mov	qword[rbx+State.stage], rax
		ret	;	flags !zero
.special:
		cmp	ecx, MOVE_TYPE_CASTLE shl 12
		jae	.check
MovePick_KILLERS2:
		movzx	ecx, word[rbx+State.countermove]
		test	ecx, ecx
		jz	MovePick_QUIET_GEN
		cmp	ecx, dword[rbx+State.ttMove]
		je	MovePick_QUIET_GEN
		cmp	ecx, dword[rbx+State.mpKillers+4*0]
		je	MovePick_QUIET_GEN
		cmp	ecx, dword[rbx+State.mpKillers+4*1]
		je	MovePick_QUIET_GEN
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.special
		mov	eax, ecx
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax], 0
		jnz	MovePick_QUIET_GEN
    .check:
		call	Move_IsPseudoLegal
;		test	rax, rax
		jz	MovePick_QUIET_GEN
		lea	rax, [MovePick_QUIET_GEN]
		mov	qword[rbx+State.stage], rax
		mov	word[rbx+State.countermove], cx
		ret	;	flags !zero
.special:
		cmp	ecx, MOVE_TYPE_CASTLE shl 12
		jae	.check

MovePick_QUIET_GEN:
		cmp	byte[rbx+State.moveCountPruning],0	;test	esi, esi
		jnz	Before_MovePick_BAD_CAPTURES
		mov	rdi, qword[rbx+State.endBadCaptures]
		mov	r14, rdi
		call	Gen_Quiets
	ScoreQuiets	r14, r13, rdi, Before_MovePick_BAD_CAPTURES
        ; partial insertion sort
		mov	r15, rdi
		lea	r10, [r14+sizeof.ExtMove]
		cmp	r10, r15
		je	.SortDone
		imul	edx, esi, -4000		;dword[rbx+State.depth], -4000
		mov	r8, r10
.SortLoop:
		mov	edi, dword[r8+ExtMove.value]
		cmp	edi, edx
		jl	.SortLoopSkip
		mov	r9, qword[r8+ExtMove.move]
		mov	rax, qword[r10]
		mov	qword[r8], rax
		mov	rcx, r10
		cmp	r10, r14
		je	.SortInnerDone
.SortInner:
		cmp	edi, dword[rcx-sizeof.ExtMove+ExtMove.value]	;[rax+ExtMove.value]
		jle	.SortInnerDone
		mov	r11, qword[rcx-sizeof.ExtMove]		;[rax]
		mov	qword[rcx], r11
		sub	rcx, sizeof.ExtMove
		;lea	rcx, [rcx-sizeof.ExtMove]
		;mov	rcx, rax
		;cmp	rax, r14
		cmp	rcx, r14
		jne	.SortInner
.SortInnerDone:
		add	r10, sizeof.ExtMove
		mov	qword[rcx], r9
.SortLoopSkip:
		add	r8, sizeof.ExtMove
		cmp	r8, r15
		jb	.SortLoop
.SortDone:
		lea	rax, [MovePick_QUIETS]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15			;*******
		jmp	@1f

MovePick_QUIETS:
		cmp	byte[rbx+State.moveCountPruning],0 
		jnz	.WhileDone
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:
		cmp	r14, r15
		je	.WhileDone
		mov	ecx, dword[r14 + ExtMove.move]
		add	r14, sizeof.ExtMove
		cmp	ecx, dword[rbx + State.ttMove]
		je	@1b
		cmp	ecx, dword[rbx + State.mpKillers + 4*0]
		je	@1b
		cmp	ecx, dword[rbx + State.mpKillers + 4*1]
		je	@1b
		cmp	cx, word[rbx + State.countermove]
		je	@1b
		mov	qword[rbx+State.cur], r14			;*******0
		ret	;	flags !zero
		calign	16, MovePick_BAD_CAPTURES
    .WhileDone:
    Before_MovePick_BAD_CAPTURES:
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
		lea	rax, [MovePick_BAD_CAPTURES]
		mov	qword[rbx+State.stage], rax
		jmp	@1f

MovePick_BAD_CAPTURES:
		mov	r14, qword[rbx+State.cur]
	@1:
		cmp	r14, qword[rbx+State.endBadCaptures]
		je	.IfDone
		mov	ecx, dword[r14]
		add	r14, sizeof.ExtMove
		mov	qword[rbx+State.cur], r14			;*******0
		;	flags !zero
    .IfDone:
		ret
		calign	8
MovePick_EVASIONS:
		mov	rcx, qword[rbx-1*sizeof.State+State.endMoves]
		lea	rax, [MovePick_ALL_EVASIONS]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], rcx			;*******
		mov	ecx, dword[rbx+State.ttMove]
		test	ecx, ecx
		ret

		calign	8
MovePick_QSEARCH_WITHOUT_CHECKS:
		mov	rcx, qword[rbx-1*sizeof.State+State.endMoves]
		lea	rax, [MovePick_QCAPTURES_NO_CHECKS_GEN]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], rcx			;*******
		mov	ecx, dword[rbx+State.ttMove]
		test	ecx, ecx
	_MATE:
		ret
		calign	8
MovePick_ALL_EVASIONS:
		mov	rdi, qword[rbx-1*sizeof.State+State.endMoves]
	       call	Gen_Evasions
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
      ScoreEvasions	r14, r13, rdi, _MATE		; rdi clobered
		mov	r15, rdi
		mov	rax, rdi
		sub	rax, r14
		shr	rax, 5
		cmp	eax, 1
		jne	@1f
		or	byte[rbx+State.pvhit], JUMP_IMM_8
		@1:
		lea	rax, [MovePick_REMAINING]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15			;*******
		mov	qword[rbx+State.cur], r14
		jmp	MovePick_REMAINING

	     calign   16, MovePick_REMAINING
MovePick_QCAPTURES_NO_CHECKS_GEN:
		mov	rcx, qword[rbx + State.endBadCaptures]			; .depthQs + .recaptureSquare
		or	r15, -1
		cmp	cx, DEPTH_QS_RECAPTURES
		jg	.RecaptureInclude
		shr	rcx, 32
		mov	r15d, 1
		shl	r15, cl
.RecaptureInclude:
	       call	Gen_Captures
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
	ScoreCaptures	r14, r13, rdi, WhileDone2
		mov	r15, rdi
		lea	rax, [MovePick_REMAINING]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15			;*******
		jmp	@1f

MovePick_REMAINING:
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:
		cmp	r14, r15
		je	WhileDone2
	   PickBest	r14, r13, r15
		cmp	ecx, dword[rbx+State.ttMove]
		 je	@1b
		mov	qword[rbx+State.cur], r14			;*******0
		;	flags !zero
    WhileDone2:
		ret
		calign	8
MovePick_QSEARCH_WITH_CHECKS:
		mov	rcx, qword[rbx-1*sizeof.State+State.endMoves]
		lea	rax, [MovePick_QCAPTURES_CHECKS_GEN]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], rcx			;*******
		mov	ecx, dword[rbx+State.ttMove]
		test	ecx, ecx
		ret
		calign	8, MovePick_QCAPTURES_CHECKS
MovePick_QCAPTURES_CHECKS_GEN:
		or	r15, -1
		call	Gen_Captures
		mov	r15, rdi
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
	ScoreCaptures	r14, r13, rdi, WhileDone3
		lea	rax, [MovePick_QCAPTURES_CHECKS]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15			;*******
		jmp	@1f

MovePick_QCAPTURES_CHECKS:
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:
		cmp	r14, r15
		jae	WhileDone3
	   PickBest	r14, r13, r15
		cmp	ecx, dword[rbx+State.ttMove]
		je	@1b
		;	flags !zero
		mov	qword[rbx+State.cur], r14			;*******0
		ret
		calign	16, MovePick_CHECKS
    WhileDone3:
		mov	rdi, qword[rbx-1*sizeof.State+State.endMoves]	;reset offset StartMoves
		call	Gen_QuietChecks	;r13 r14 r15 cloberred
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]	;reset offset StartMoves
		mov	r15, rdi
		lea	rax, [MovePick_CHECKS]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15			;*******
		jmp	@1f
MovePick_CHECKS:
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:
		cmp	r14, r15
		je	.IfDone
		mov	ecx, dword[r14]
		add	r14, sizeof.ExtMove
		cmp	ecx, dword[rbx+State.ttMove]
		je	@1b
		;	flags !zero
		mov	qword[rbx+State.cur], r14			;*******0
    .IfDone:
		ret
	     calign   16
MovePick_PROBCUTINIT:
		; initialize movepick
		; r12 = .alpha
		movzx	eax, byte[rbx+State.improving]	;1
		neg	eax				;2
		and	eax, -48
		;lea	edi, [r12+1+216+rax]
		lea	edi, [r12+1+216]
		add	edi, eax
	if	0
		mov	eax, VALUE_INFINITE		;absurd ;)
	else
		movzx	eax, byte[rbx+State.ply]
		neg	eax
		add	eax, VALUE_MATE-1
	end if
		cmp	edi, eax
		cmovg	edi, eax
		neg	edi
		mov	dword[rbx+State.mpKillers], edi		; .rbeta
		xor	eax, eax
		neg	edi
		movsx	edx, word[rbx+State.ltte+MainHashEntry.eval_]
		sub	edi, edx
		cmp	edi, QueenValueMg
		jg	.cancelProbcut		;in case in nullmove found mated
		mov	dword[rbx+State.mpKillers+4], edi		; .threshold
		mov	dword[rbx+State.moveCount], 0xffff00
		movzx	ecx, word[rbx+State.ltte+MainHashEntry.move]	;.ttMove
		test	ecx, ecx
		jz	.9NoTTMove		;Zero = 1
		cmp	ecx, MOVE_TYPE_CASTLE shl 12
		jae	.9NoTTMove
		cmp	ecx, (MOVE_TYPE_PROM+3) shl 12	;MOVE_TYPE_EPCAP shl 12
		jae	@1f
		mov	edx, ecx
		and	edx, 63			;to
		cmp	al, byte[rbp+Pos.board+rdx]
		jz	.9NoTTMove		;Zero = 1
	@1:
		call	Move_IsPseudoLegal	;esi safe
;		test	rax, rax
		jz	.9NoTTMove		;Zero = 1
		mov	edx, edi		; .threshold
		call	SeeTestGe.HaveFromTo
		test	eax, eax
		jz	.9NoTTMove		;Zero = 1
		mov	eax, ecx
.9NoTTMove:
	; r13d	= .cutNode	transform to probCutCountMax
	movsx	edx, byte[rsp+1*8]	;.cutNode
	mov	r13d, edx
	not	r13d
	and	dl, 2
	add	dl, 2
	mov	r13l, dl
		mov	dword[rbx+State.ttMove], eax
		test	eax, eax
		jz	MovePick_PROBCUT_GEN
		call	Move_IsLegal
		jz	MovePick_PROBCUT_GEN	;uses flags
		mov	edi, dword[rbx+State.mpKillers]		; .rbeta
		mov	r15, qword[rbx-1*sizeof.State+State.endMoves]
		lea	rax, [MovePick_PROBCUT_GEN]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15
	dec	r13l
		;	ecx	= State.ttMove;	flags !zero
		ret
		calign	8
.cancelProbcut:
		xor	eax, eax
		ret
		calign   8
MovePick_PROBCUT_GEN:
		mov	edi, dword[rbp+Pos.sideToMove]
		xor	edi, 1
		mov	r15, qword[rbx+State.Occupied]
		xor	r15, qword[rbp+Pos.typeBB+8*King]
		mov	r10, qword[rbp+Pos.typeBB+8*rdi]
		mov	edx, dword[rbx+State.mpKillers+4]						; .threshold
		cmp	edx, PawnValueMg
		jl	@2f
		mov	rax, qword[rbp+Pos.typeBB+8*Pawn]
		xor	r15, rax
		cmp	edx, KnightValueMg
		jl	@2f
		xor	r15, qword[rbp+Pos.typeBB+8*Knight]
		cmp	edx, BishopValueMg
		jl	@2f
		xor	r15, qword[rbp+Pos.typeBB+8*Bishop]
		cmp	edx, RookValueMg
		jl	@2f
		xor	r15, qword[rbp+Pos.typeBB+8*Rook]
	@2:
		and	r15, r10
		jnz	MovePick_PROBCUT_GENback
		ret
		calign   8
MovePick_PROBCUT_GENback:
	push	r13
	       call	Gen_Captures			;esi secure
	pop	r13
		mov	r15, rdi
		mov	r14, qword[rbx-1*sizeof.State+State.endMoves]
	ScoreCaptures	r14, r11, rdi, WhileDone4
		mov	edi, dword[rbx+State.mpKillers]		; .rbeta
		lea	rax, [MovePick_PROBCUT]
		mov	qword[rbx+State.stage], rax
		mov	qword[rbx+State.endMoves], r15
		jmp	@1f	;MovePick_PROBCUT_2
	WhileDone4:
		ret
		calign   8
MovePick_PROBCUT:
	dec	r13l
		jz	WhileDone4
		mov	r14, qword[rbx+State.cur]
		mov	r15, qword[rbx+State.endMoves]
	@1:
		cmp	r14, r15
		je	WhileDone4
	   PickBest   r14, r11, r15
		cmp	ecx, dword[rbx+State.ttMove]
		je	@1b
		mov	edx, dword[rbx+State.mpKillers+4]						; .threshold
		call	SeeTestGe
		test	eax, eax
		jz	@1b
		call	Move_IsLegal
		jz	@1b
		mov	qword[rbx+State.cur], r14			;*******0
		;	flags !zero
		ret
