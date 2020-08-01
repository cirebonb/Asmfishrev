
macro search RootNode, PvNode
	; in:
	;  rbp:	address	of Pos struct in thread	struct
	;  rbx:	address	of State
	;  ecx:	alpha
	;  edx:	beta
	;  r8d:	depth
	;  r9l:	cutNode	 must be 0 or -1 (=FFh)
	; out:
	;  eax:	score
  if RootNode =	1 & PvNode = 0
    err	'bad params to search'
  end if
if RootNode =	0
	if PvNode = 0
		varbounder	equ	r14
		varbounderd	equ	r14d
		varbounderl	equ	r14l
	else
		varbounder	equ	r10
		varbounderd	equ	r10d
		varbounderl	equ	r10l
	end if
else
	varbounder	equ	r13
	varbounderd	equ	r13d
	varbounderl	equ	r13l
end if

  virtual at rsp
	.cutNode	rb	0
	.beta			rd 1	;act as .beta in PvNode, .cutNode otherwise {-1 for true}
	.success		rd 1
	.reductionOffset	rd 1
	.pvHitReduction		rd 1
	.quietsSearched		rd 64
	.capturesSearched	rd 32
    if PvNode =	1
      .pv		rd MAX_PLY + 1
    end	if
    .lend		rb 0
  end virtual
.localsize = (.lend-rsp+15) and -16
.localstacksize = (.lend-.beta+15) and -16
if	PvNode = 0
	localStackCutNode	equ .localstacksize
end if
.posKey	equ (rbx+State.key+6)
.ltte	equ (rbx+State.ltte)

	       push   rsi rdi r12 r13 r14 r15
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

if RootNode =	0
		mov	r12d, ecx
	if PvNode = 1
		mov	r13d, edx
	else
		lea	r13d, [r12+1]
	end if
		mov	esi, r8d		; .depth
	if PvNode = 0
		mov	byte[.cutNode], r9l
	end if
end if
	; callsCnt counts down as in master
	; resetCnt, if nonzero,	contains the count to which callsCnt should be reset
		mov	rax, qword[rbp-Thread.rootPos+Thread.callsCnt]
		mov	edx, eax
		shr	rax,32
		 jz	.dontreset
		mov	edx, eax
		mov	dword[rbp-Thread.rootPos+Thread.resetCnt], 0
	.dontreset:
		dec	edx
		mov	dword[rbp-Thread.rootPos+Thread.callsCnt], edx
		jns	.dontchecktime
	       call	CheckTime		; CheckTime sets resetCalls for	all threads
	.dontchecktime:

if RootNode =	0
	; Step 3. mate distance	pruning
	if	PvNode = 0
		movzx	eax, byte[rbx+State.ply]
	else
		movzx	edi, byte[rbx+State.ply]
		mov	eax, edi
	end if
		sub	eax, VALUE_MATE		;ply-Mate
	if	PvNode = 0
		xor	rcx, rcx
	end if
		cmp	r12d, eax
	      cmovl	r12d, eax
	if	PvNode = 0
	      cmovg	rcx, rax
	end if
		not	eax			;Mate-ply
		cmp	r13d, eax
	      cmovg	r13d, eax
		mov	eax, r12d
		cmp	eax, r13d
		jge	.Return
	if	PvNode = 0
		inc	eax
		cmp	rcx, qword[rbx+State.checkersBB]	;when r12d = -VALUE_MATE+ply is not check then return r12d+1
		je	.Return
	end if

	if PvNode = 1
		movzx	eax, byte[rbp-Thread.rootPos+Thread.selDepth]
		cmp	eax, edi
		cmovb	eax, edi
		mov	byte[rbp-Thread.rootPos+Thread.selDepth], al
	end if
end if
;
		cmp	byte[signals.stop], 0
		jne	.Return
;
	; Step 4. transposition	table look up
if RootNode =	1
		xor	r15, r15
else
.Begin:
end if
		call	MainHash_Probe.Main
if RootNode =	0
.AfterHashProbe:
		mov	rdi, rcx
		sar	rdi, 48
		cmp	edi, VALUE_NONE
		je	.DontReturnTTValue
		lea	r8d, [rdi+VALUE_MATE_IN_MAX_PLY]
		cmp	r8d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ValueFromTT		; no esi, edx, ecx
.ValueFromTTRet:
	if PvNode = 0
		movsx   eax, ch			; depthTT
		cmp	eax, esi		; .depth
		 jl	.DontReturnTTValue
		cmp	edi, r12d
		setg	dl
		inc	edx
		test	dl, cl
		jnz	.beforeReturnTTValue
	end if
end if
.DontReturnTTValue:

	; Step 1. initialize node
		xor	eax, eax
	if PvNode = 1
		mov	dword[.beta], r13d
	end if
		mov	dword[rbx+1*sizeof.State+State.excludedMove], eax
		mov	dword[rbx+2*sizeof.State+State.history], eax
		mov	qword[rbx+2*sizeof.State+State.killers], rax
if RootNode =	0
	if PvNode = 0
		test	r15l, JUMP_IMM_3
		jnz	.moves_loopex
	else if USE_GAMECYCLE = 1
		cmp	r12d, eax
		jge	.1done
		cmp	r13d, eax
		jle	.1done
		movzx	r10d, word[rbx+State.movelead0]
		cmp	ax, r10w
		cmovl	r12d, eax
		jne	.1done
		mov	eax, dword[rbx+State.rule50]
		cmp	ah, 3
		jae	.has_game_cycle
	.1done:
	end if

	if USE_SYZYGY
		; Step 4a. Tablebase probe
		cmp	sil, byte[.ltte+MainHashEntry.depth]
		jle	.CheckTablebaseReturn
		movzx	eax, byte[rbx+State.rule50]
		or	al, byte[rbx+State.castlingRights]
		jnz	.CheckTablebaseReturn
		cmp	eax, dword[Tablebase_Cardinality]
		je	.CheckTablebaseReturn
		jmp	.CheckTablebase
	 calign	  8
.CheckTablebaseReturn:
	end if
end if	;RootNode =	0
		; step 5. evaluate the position statically
		xor	rcx, rcx
		cmp	rcx, qword[rbx+State.checkersBB]
		je	@1f
		mov	word[.ltte+MainHashEntry.eval_], VALUE_NONE
		jmp	.moves_loopex
	@1:
		movsx	eax, word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		jne	@2f
		call	Evaluate
	@2:
if RootNode =	1
		test	r15l, JUMP_IMM_6
		jnz	@3f
else
		mov	r14d, eax
		test	r15l, JUMP_IMM_6
		jnz	.improvingEval
end if		
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[.posKey]
      MainHash_Save	.ltte, r8, r9w, 0, BOUND_NONE,	DEPTH_NONE, 0

if RootNode =	1
	@3:
		cmp	word[.ltte+MainHashEntry.eval_], 0
		setge	dl
		mov	byte[rbx+State.improving],	dl
else
	if	QueenThreats = 100	; order number 5
		cmp	r14w, 0x7CFF
		je	.YesMateThreat
	end if
		jmp	.StaticValueDone
.improvingEval:
		cmp	edi, VALUE_NONE
		je	.StaticValueDone
		cmp	edi, r14d
		setg	cl
		inc	ecx
		test	cl, byte[.ltte+MainHashEntry.genBound]
		cmovnz	r14d, edi
.StaticValueDone:
		; r12 = .alpha r13 = .beta r14 = .evalu;  rsi = .depth
		; Step 6. Razoring (skipped when in check)
		
	if PvNode = 0
		cmp	esi, 2*ONE_PLY
		jge	.6skip
		lea	edx, [r14+600]
		cmp	edx, r12d
		jle	.6gotoQsearch
.6skip:
	end if
		movsx	ecx, word[.ltte-2*sizeof.State+MainHashEntry.eval_]
		cmp	word[.ltte+MainHashEntry.eval_], cx
		setge	dl
		cmp	ecx, VALUE_NONE
		sete	cl
		or	dl, cl
		; Step 7. Futility pruning:	child node (skipped when in check)
		cmp	esi, 7*ONE_PLY
		jge	._7skip
		cmp	r14d, VALUE_KNOWN_WIN
		jge	._7skip
	if	1	;do not wanna miss tactical things
		if PvNode = 1
			cmp	r13d, -VALUE_KNOWN_WIN			; .beta
			jle	@1f
		else
			cmp	r12d, -VALUE_KNOWN_WIN			; .alpha
			jle	@1f
		end if
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]
		movzx	eax, byte[rbx+State.capturedPiece]
		sar	ecx, 14
		or	al, cl						;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	cx, 3
		and	al, ch				; if MOVE_NULL result NZ
		jz	@1f
		cmp	byte[.ltte+MainHashEntry.depth], -5
		jle	._7skip
		@1:
	end if
		movzx	ecx, dl				; byte[rbx+State.improving]
		neg	ecx
		and	ecx, 50
		sub	ecx, 175
		imul	ecx, esi
		mov	eax, r14d
		add	ecx, eax
	if PvNode = 1
		cmp	ecx, r13d			; .beta
		jge	.Return
	else
		cmp	ecx, r12d			; .alpha
		jg	.Return
	end if
._7skip:
		mov	byte[rbx+State.improving],	dl   ; should be 0 or 1	; +State.improving
	if PvNode = 0
	; setting after nullmove
		lea	rax,[.8skip]
		test	r15l, JUMP_IMM_2
		jnz	.SetAttackOnNull

	    ; Step 8. Null move	search with verification search	(is omitted in PV nodes)
		test	byte[rbx+State.pvhit], JUMP_IMM_8
		jnz	.moves_loopex
		cmp	r14d, r12d
		jle	.8skip
	if 0
		cmp	dword[rbx-1*sizeof.State+State.history], 23200
		jge	.8skip
	end if
		mov	ecx, dword[rbp+Pos.sideToMove]
		cmp	word[rbx+State.npMaterial+2*rcx], 0
		je	.8skip
		movsx	edx, word[.ltte+MainHashEntry.eval_]
		cmp	dx, VALUE_MATE_THREAT
		je	.8skip
		imul	eax, esi, 36
	if	1
		lea	eax, [rax+rdx-1-225]
		cmp	eax, r12d
		jl	.8skip
	else
		add	eax, edx
		lea	edx, [r12+1+225]
		cmp	eax, edx
		jl	.8skip
	end if
		movzx	edx, byte[rbx+State.ply]
		mov	r13d, edx
		and	dl, 1
		movzx	edi, byte[rbp-Thread.rootPos+Thread.nmp_ply+rdx]
		cmp	r13d, edi
		jae	.Move_DoNull
.8skip:	
	; Step 9. ProbCut (skipped when	in check)
		cmp	esi, 5*ONE_PLY
		jl	.9skip
		lea	eax, [r12+VALUE_MATE_IN_MAX_PLY]
		cmp	eax, 2*(VALUE_MATE_IN_MAX_PLY-1)
		ja	.9skip
		lea	rax, [MovePick_PROBCUTINIT]
		jmp	.9caller
.9moveloop:
	GetNextMove .9caller
		jz	.9skip		; uses flags
		call	Move_Do__ProbCut
		jz	.9skipverify
		xor	r8d, r8d
		mov	ecx, edi
		call	r14
		cmp	eax, edi
		jg	.9skipverify
		mov	ecx, edi
		lea	r8d, [rsi-4*ONE_PLY]
		mov	r9d, r13d
		sar	r9d, 8		;!.cutNode
		call	Search_NonPv
.9skipverify:
		mov	r14d, eax
	       call	Move_Undo
		cmp	r14d, edi
		 jg	.9moveloop
	if	SaveProbResult = 1
		jmp	.SaveProbCutResult
	else
		mov	eax, r14d
		neg	eax
		jmp	.Return	;never save result
	end if
		calign 8
.9skip:
	end if ;PvNode = 0

.IID_Search:
    ; Step 10. Internal iterative deepening (skipped when in check)
		cmp	esi, 8*ONE_PLY
		jl	.moves_loopex
		cmp	word[.ltte+MainHashEntry.move], 0
		jne	.moves_loopex
		test	byte[rbx+State.pvhit], JUMP_IMM_8
		jnz	.moves_loopex
	if PvNode = 0
		movsx	r9d, byte[.cutNode]
		mov	r15l, JUMP_IMM_3
		push	.moves_loopex rsi rdi r12	;r13 r14 r15 
		sub	rsp, .localsize + 8*3		;8*3 is for reg r13 r14 & r15
		mov	byte[.cutNode], r9l
		lea	esi, [3*rsi-8*ONE_PLY]
		shr	esi, 2
;		cmp	sil, byte [.ltte+MainHashEntry.depth]
;		jg	.Scen2
		jmp	.Begin		;there is TT cut off
		;jmp	.Scen2		;neglect TT cut off
	else
		mov	edx, dword[.beta]
		push	.moves_loopex
	end if
	if PvNode = 0
		calign 8
.BYPASS:
		push	rsi rdi r12 r13 r14 r15
		sub	rsp, .localsize
		sar	esi, 1				; .depth
		mov	r12d, ecx
.Scen2:
		xor	eax, eax
		mov	byte[.cutNode], r9l
		mov	dword[rbx+2*sizeof.State+State.history], eax
		mov	qword[rbx+2*sizeof.State+State.killers], rax
	else
		push	rsi rdi r12 ;r13 r14 r15
		sub	rsp, .localsize + 8*3
		lea	esi, [3*rsi-8*ONE_PLY]
		shr	esi, 2				; .depth
		mov	dword[.beta], edx
	end if
end if	;RootNode =	0
		jmp	.moves_loopex
		calign 8
.moves_loopex:

.CMH  equ (rbx-1*sizeof.State+State.counterMoves)
.FMH  equ (rbx-2*sizeof.State+State.counterMoves)
.FMH2 equ (rbx-4*sizeof.State+State.counterMoves)
    ; initialize move pick
if RootNode =	1
		imul	edi, dword[rbp-Thread.rootPos+Thread.PVIdx], sizeof.RootMove
		add	rdi, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	edi, dword[rdi+RootMove.pv]
else
		movzx	edi, word[.ltte+MainHashEntry.move]
		lea	r14, [MovePick_CAPTURES_GEN]
		lea	r13, [MovePick_ALL_EVASIONS]
	if PvNode = 0
		cmp	dword[rbx+State.excludedMove], edi
		je	.NoTTMove
	else
		test	edi, edi
		jz	.NoTTMove
	end if
		mov	ecx, edi
		call	Move_IsPseudoLegal
		cmovz	edi, eax
		jz	.NoTTMove
end if
		lea	r14, [MovePick_MAIN_SEARCH]
		lea	r13, [MovePick_EVASIONS]
	.NoTTMove:
		mov	rdx, qword[rbx+State.checkersBB]
	       test	rdx, rdx
	     cmovnz	r14, r13
		mov	r13, qword[rbx+State.killers]

		movzx	eax, byte[rbx+State.improving]
		mov	edx, 63
		mov	ecx, esi		; .depth
		cmp	esi, edx
	      cmova	ecx, edx
		lea	eax, [8*rax]
		lea	eax, [8*rax+rcx]
		shl	eax, 6
		lea	eax, [Reductions + rax + 2*64*64*PvNode]
		mov	qword[.reductionOffset], rax	;+.pvHitReduction
if RootNode = 0 | UpdateAtRoot = 1
		mov	eax, dword[rbx-1*sizeof.State+State.currentMove]
	if PvNode = 0
		cmp	eax, 1
		jl	.no_counter
	end if
		and	eax, edx		;63
		movzx	r11d, byte[rbp+Pos.board+rax]
		shl	r11d, 6
		add	eax, r11d
		mov	r10, qword[rbp+Pos.counterMoves]
		mov	r11d, dword[r10+4*rax]
		shl	r11, 32
		shl	rax, 48
		or	r11, rax
		or	rdi, r11		; rdi = .ttMove + .countermove
	if PvNode = 0
.no_counter:
	end if
end if
if RootNode = 0
		xor	ecx, ecx
		mov	r15, qword[.ltte+MainHashEntry.genBound]
		or	r15l, byte[rbx+State.pvhit]
	if PvNode = 0
		movzx	eax, r15l
		shr	eax, 1
		and	al, 2
	else
		movzx	r10d, byte[rbx-1*sizeof.State+State.moveCount]
		cmp	r10d, 1						;a reasearch
		mov	eax, 2
		cmove	ecx, eax
	end if
		mov	r11, r15
		sar	r11, 3*16
		cmp	r11d, VALUE_MATED_IN_MAX_PLY
		cmovle	eax, ecx
		mov	dword[.pvHitReduction], eax
	if PvNode = 1
		test	edi, edi
		jz	.skipsingular
	else
		cmp	dword[rbx+State.excludedMove], edi
		je	.skipsingular
	end if
		mov	byte[rbx+State.singularNode],	0	;0x4
else	;RootNode = 1
		test	edi, edi
		jz	.skipsingular
		mov	r9d, edi
		and	r9d, edx		; edx = 63	; r9d = to
end if
		mov	ecx, edi
		shr	ecx, 14
	      movzx	eax, byte[rbp+Pos.board+r9]	; piece to

		or	al, cl	;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	cx, 3
		and	al, ch

		setnz	al				; convert to bit 1 or 0
		mov	byte[rbx+State.ttcap], al
if RootNode = 0
;		xor	eax, eax	;	test	r15l, JUMP_IMM_8 ;jnz	.addExtSingular	;explode
		mov	ecx, r15d
		cmp	esi, 8*ONE_PLY				; esi	=.depth
	      setge	al
	       test	cl, BOUND_LOWER
	      setnz	cl
		and	al, cl
		movsx	ecx, ch					; ecx = MainHashEntry.depth
		add	ecx, 3*ONE_PLY
		cmp	ecx, esi				; esi = .depth
	      setge	cl
		and	al, cl
		jz	.skipsingular
		xor	eax, eax
		lea	r10d, [r11+VALUE_KNOWN_WIN]
		cmp	r10d, 2*(VALUE_KNOWN_WIN-1)
		ja	.cancelSingular
		test	r15l, JUMP_IMM_8
		jnz	.addExtSingular
		mov	r15, r11
		mov	ecx, edi
		call	Move_IsLegal
		jz	.resetMovePick

		xor	rax, rax
		sub	r15, rsi
		sub	r15, rsi			; edx = .rbeta
		cmp	r15, rax
		jg	.skipdetect
		mov	edx, dword[rbx+State.movelead1]
		cmp	ax, dx
		je	@1f
	if	PvNode = 0
		lea	r10d, [r12+1]
		cmp	eax, r10d
		jg	.Return
	else
		cmp	eax, dword[.beta]
		jg	.Return
	end if
		jmp	.cancelSingular
@1:
		shr	edx, 16
		cmp	cx, dx
		je	.skipdetect
		cmp	ax, dx
		jl	.cancelSingular
	if USE_GAMECYCLE = 1
		jg	.skipdetect
		cmp	r12d, eax
		jl	.skipdetect
		mov	eax, dword[rbx+State.rule50]
		cmp	ah, 3
		jb	.skipdetect
		call	has_game_cycle_spesial
		jz	.cancelSingular
	end if
.skipdetect:
	if	PvNode = 0
		movsx	r9d, byte[.cutNode]
	else
		xor	r9, r9
	end if
		mov	dword[rbx+State.excludedMove], ecx
		lea	ecx, [r15-1]
	       call	Search_NonPv.BYPASS
		xor	ecx, ecx
		mov	dword[rbx+State.excludedMove], ecx
		cmp	eax, r15d
		jl	.gapSingular
	if	PvNode = 0
		lea	ecx, [r12+1]
		cmp	eax, VALUE_MATE_IN_MAX_PLY
		cmovge	ecx, eax
		cmp	r15d, ecx
		cmovg	eax, r15d
		jg	.Return
	else
		cmp	r15d, dword[.beta]
		jg	.Return
	end if
		mov	al, 0
if	0
		cmp	eax, VALUE_MATED_IN_MAX_PLY
		mov	al, 0
		jl	.cancelSingular
		mov	edx, edi
		mov	ecx, edi
		and	edx, 63
		movzx	edx, byte[rbp+Pos.board+rdx]
		shr	ecx, 14
		or	dl, cl		;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	cx, 3
		and	dl, ch
		setnz	dl
		mov	byte[rbx+State.ttcap], dl
end if
		jmp	.cancelSingular
	.gapSingular:
		cmp	eax, r12d
		mov	al, 0
		jge	.addExtSingular
		cmp	eax, -VALUE_KNOWN_WIN	;VALUE_MATED_IN_MAX_PLY
		jg	.addExtSingular
		cmp	word[.ltte+MainHashEntry.eval_], VALUE_MATE_THREAT
		je	.addExtSingular
		or	al, 0x4		;break dont add any depth........!!!
	.addExtSingular:
		or	al, 0x1
	.cancelSingular:
		or	al, 0x2
		mov	byte[rbx+State.singularNode], al	;	al	; diffgap = 4 singular =2 YesExtend = 1
end if

  .skipsingular:

		; Init before search
		; esi = .depth r14 = State.stage
		xor	r11, r11
		mov	rcx, 0x082FF0000				; (-VALUE_INFINITE shl 16)
if	RootNode = 0
	if	Countermoves_based_pruning_Model = 1
		cmp	esi, 16
		jge	@1f
		mov	rdx, qword[rbx-1*sizeof.State+State.moveCount]
		cmp	dl, 1		;State.moveCount=1?
		sete	al
		sar	rdx, 32		;State.history>0?
		setns	ah
		setnz	dl
		and	ah, dl
		or	al, ah
		add	al, 3
		mov	byte[rbx+State.depthpruned], al
;======		
if	GetExtentionCheckFromHash = 1
		cmp	esi, 8
		setle	al
		mov	dx, word[rbx-1*sizeof.State+State.moveCount]	;1. this->node first priority...
		or	dh, byte[rbx-1*sizeof.State+State.givesCheck]	;2. this->node not in_check...
		cmp	dx, 1
		cmovne	eax, r11d
		mov	byte[rbx+State.bound6], al
end if
;======
		movzx	eax, byte[rbx+State.improving]
		shl	eax, 4
		mov	ch, byte[FutilityMoveCounts+rax+rsi]		; store in next code
	@1:
	end if
end if
		mov	qword[rbx+State.moveCountPruning], rcx		; (word).moveCountPruning+ .bestvalue + .bestmove
		mov	qword[rbx+State.ttMove], rdi			; .ttMove + .countermove
		mov	qword[rbx+State.mpKillers], r13
		mov	dword[rbx+State.moveCount], r11d
  if PvNode = 1
		lea	rdx, [.pv]
		mov	qword[rbx+1*sizeof.State+State.pv], rdx
		mov	dword[rdx], r11d
  end if

		mov	rax, r14
		jmp	.Pickcaller
;=================================
    ; Step 11. Loop through moves
if RootNode = 0
		calign	  8
.PrunedLoop:
		mov	byte[rbx+State.pruned], -1
		jmp	.MovePickLoop
end if
	 calign	  8
.MovePickLoop:
    GetNextMove .Pickcaller
		jz	.EndCycle
if RootNode = 1
		; at the root search only moves in the move	list
		imul	eax, dword[rbp-Thread.rootPos+Thread.PVIdx], sizeof.RootMove
		add	rax, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
    @1:
		cmp	rax, rdx
		jae	.MovePickLoop
		cmp	ecx, dword[rax+RootMove.pv]
		lea	rax, [rax+sizeof.RootMove]
		jne	@1b
	if	NotReducedatRoot = 1
		sub	rax, (sizeof.RootMove-RootMove.everPv)
		mov	qword[rbx+State.pv], rax
	end if
	if USE_CURRMOVE = 1 & VERBOSE < 2
		cmp	byte[options.displayInfoMove],	0
		je	.PrintCurrentMoveRet
		cmp	dword[rbp-Thread.rootPos+Thread.idx], 0
		jne	.PrintCurrentMoveRet
		mov	rax, qword[time.lastPrint]
		cmp	eax, CURRMOVE_MIN_TIME
		jge	.PrintCurrentMove
.PrintCurrentMoveRet:
	end if
end if
		call	Move_GivesCheck
		; r9d = to & r8d = from
		mov	edi, eax
		movsx	r13d, word[rbx+State.moveCountPruning]
		movzx	r14d, byte[rbp+Pos.board+r8]	; r14d = from piece
		movzx	r15d, byte[rbp+Pos.board+r9]	; r15d = to piece
		mov	edx, r15d
		mov	ah, dl
		mov	edx, ecx
		shr	edx, 14

		or	ah, dl		;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	dx, 3
		and	ah, dh

		shl	r13d, 16
		or	r13w, ax
		mov	dword[rbx+State.givesCheck], r13d	; .givesCheck+.captureOrPromotion+.moveCountPruning+...... newdepth later

	; Step 13. Extensions
if RootNode = 0
		cmp	ecx, dword[rbx+State.ttMove]
		jne	.12else
		movzx	eax, byte[rbx+State.singularNode]
		test	al, 2
		jnz	.12result
.12else:
	if	0
		cmp	byte[rbx+State.moveCount],0
		jne	.12else0
		cmp	dword[.ltte+MainHashEntry.eval_], 0x7D027D02
		jne	.12else0
		mov	edi, 1
		jmp	.12done
.12else0:
	end if
end if
		test	edi, edi
		jz	.12done
		SeeSignTestQSearch	.12extend_oneply
.12result:
		mov	edi, eax
.12extend_oneply:
		and	edi, 1		; .extension = 1
.12done:
	; edi = .extension
		lea	edi, [rdi+rsi-1]		; .newDepth
		shl	r13d, 8
		or	r13l, dil			; r13l	= .newDepth

		movzx	eax, byte[rbx+State.moveCount]	; .moveCount
		mov	edx, 63
		cmp	eax, edx
		cmova	eax, edx
		add	eax, dword[.reductionOffset]
		movsx	r15d, byte[rax]			; r15d = .reduction

if RootNode = 0
	; Step 14. Pruning at shallow depth
		cmp	esi, 16*ONE_PLY	; .depth
		jge	.13done
		cmp	word[rbx+State.bestvalue], VALUE_MATED_IN_MAX_PLY
		jle	.13done
		mov	r10d, r14d
		shr	r10d, 3					; Pos.sideToMove
		cmp	word[rbx+State.npMaterial+2*r10], 0
		je	.13done
		test	r13d, 0x0ffff00				; .givesCheck+.captureOrPromotion = 0 ?
		jnz	.13else
		mov	r11l, r14l
		and	r11l, 7
		cmp	r11l, Pawn
		jne	.13do
		neg	r10d
		and	r10d, 7 shl 3
		xor	r10d, r8d
		cmp	r10d, SQ_A5
		jae	.13else
.13do:
    ; Move count based pruning
		test	r13d, r13d	;0xff000000				; .moveCountPruning = 0 ?
		js	.PrunedLoop	;.MovePickLoop	;jnz
		mov	al, byte[rbx+State.moveCountPruning+1]
		sub	al, byte[rbx+State.moveCount]
		sar	al, 7
		or	byte[rbx+State.moveCountPruning], al
		jnz	.PrunedLoop	;.MovePickLoop
		sub	edi, r15d		; edi = lmrDepth = .newDepth - .reduction
	if Countermoves_based_pruning_Model = 0
		cmp	edi, 3*ONE_PLY
		jge	.13DontSkip2
	else if Countermoves_based_pruning_Model = 1
		cmp	dil, byte[rbx+State.depthpruned]
		jge	.13DontSkip2
	end if
    ; Countermoves based pruning
		mov	rax, qword[.CMH]
		mov	rdx, qword[.FMH]
		lea	r10, [8*r14]
		lea	r10, [8*r10+r9]
		mov	eax, dword[rax+4*r10]
	if CounterMovePruneThreshold <> 0     ; code assumes
		err
	end if
		and	eax, dword[rdx+4*r10]
		js	.PrunedLoop	;.MovePickLoop
.13DontSkip2:
    ; Futility pruning:	parent node
		cmp	edi, 7*ONE_PLY
if	No_Depth_Restriction = 0
		 jg	.13done
		 je	.13check_see
else
		 jge	.13check_see
end if
		xor	eax, eax
	       test	edi, edi
	      cmovs	edi, eax
		movsx	eax, word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		je	.13check_see	; .inCheck ? yes
		imul	edx, edi, 200
		lea	eax, [eax+edx+256]
		cmp	eax, r12d
		jle	.PrunedLoop	;.MovePickLoop
.13check_see:
    ; Prune moves with negative	SEE at low depths
		imul	edx, edi,	-29	;-35
		imul	edx, edi
		jmp	.13done0
		calign   8
.13else:
if	No_Depth_Restriction = 0
		cmp	esi, 7*ONE_PLY	; .depth
		jge	.13done
end if
		cmp	sil, r13l	; .extension = 0 ? ~ .depth == .newdepth ?
		je	.13done		; jne	.13done
		imul	edx, esi, -PawnValueEg
.13done0:
		call	SeeTestGe.HaveFromTo
		test	eax, eax
		jz	.PrunedLoop	;.MovePickLoop
.13done:

    ; Check for legality just before making the move
		call	Move_IsLegal
		jz	.MovePickLoop
end if	;(RootNode = 0)
		add	byte[rbx+State.moveCount], 1

    ; Step 14. Make the move
		call	Move_Do__Search
		jz	.17entry

		shl	r14d, 6		; r14d = from piece shl 6
		add	r14d, r9d
		; r14 = moved_piece_to_sq	= index	of [moved_piece][to_sq(move)]
		mov	eax, r14d
		shl	eax, 2+4+6
		add	rax, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx-1*sizeof.State+State.counterMoves], rax
		mov	edi, r15d		; r15d = .reduction	save to edi
		xor	r15, r15
    ; Step 15. Reduced depth search (LMR)
	if	NotReducedatRoot = 1 & RootNode = 1
		cmp	byte[rbx-1*sizeof.State+State.moveCount], 1
		jbe	.DoFullPvSearch
		mov	rdx, qword[rbx-1*sizeof.State+State.pv]
		cmp	byte[rdx], 1
		ja	.15skip
	else
		cmp	byte[rbx-1*sizeof.State+State.moveCount], 1
		if PvNode = 1
			jbe	.DoFullPvSearch
		else
			jbe	.15skip
		end if
	end if
		cmp	esi, 3*ONE_PLY
		jl	.15skip
	if RootNode = 0
		test	r13d, 0x0ff0000		; .captureOrPromotion = 0 ?
		jz	.15NotCaptureOrPromotion
		test	r13d, r13d		; (r13 & 0xff000000) .moveCountPruning = 0 ?
		jns	.15skip
	else
		test	r13d, 0x0ff0000		; .captureOrPromotion = 0 ? at Root .moveCountPruning = 0!
		jnz	.15skip
	end if
.15NotCaptureOrPromotion:
    ; r13l = newdepth
    ; r14d = moved_piece_to_sq
    ; r15d = 0
    ; ecx = moveCount

    ; Decrease reduction if opponent's move count is high
	if RootNode = 0
		mov	eax, 15
		cmp	al, byte[rbx - 2*sizeof.State + State.moveCount]
		sbb	edi, dword[.pvHitReduction]
		test	r13d, 0x0ff0000		; .captureOrPromotion = 0 ?
		jnz	.15ReadyToSearch
	else
		sub	edi, 2			; .pvHitReduction
	end if
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]	; .move
    ; Increase reduction if ttMove is a	capture
	if RootNode = 0
		mov	eax, dword[rbx-1*sizeof.State+State.ttcap]
		test	eax, 0x401
		jz	.15itsOk
		mov	r10d, 1
	else
		movzx	r10d, byte[rbx-1*sizeof.State+State.ttcap]
		test	r10d, r10d
		jz	.15itsOk
	end if
		cmp	sil, r13l		; .givesCheck = 0 ?
		jne	.15AddReduce
		mov	edx, dword[rbx-1*sizeof.State+State.ttMove]
		shr	edx, 6
		and	edx, 63
		cmp	edx, r8d
		jne	.15itsOk
.15AddReduce:
		add	edi, r10d
.15itsOk:
    ; Increase reduction for cut nodes
  if PvNode = 0
		cmp	byte[.cutNode],  r15l		; PvNode = 1 ---> .cutNode=0
		je	.15testA
		add	edi, 2*ONE_PLY
		jmp	.15skipA
.15testA:
  end if
		;move is not capture or promotion
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.15skipA
if	0
		cmp	qword[rbx-1*sizeof.State+State.checkersBB], r15
		je	.15lanjut
		mov	eax, r14d
		and	eax, 7 shl 6
		cmp	eax, King  shl 6
		je	.15add2ply
end if
.15lanjut:
		mov	eax, r9d
		mov	r9d, r8d
		mov	r8d, eax
		xor	edx, edx
		call	SeeTestGe.HaveFromTo
		test	eax, eax
		jnz	.15skipA
.15add2ply:
		sub	edi, 2*ONE_PLY
.15skipA:
		and	ecx, (64*64)-1
		mov	eax, r14d		; from piece (shl 6 + tosq)
		shr	eax, 6+3
		mov	r9, qword[.CMH-1*sizeof.State]
		mov	r10, qword[.FMH-1*sizeof.State]
		mov	r11, qword[.FMH2-1*sizeof.State]
		mov	rax, qword[rbp+Pos.history+8*rax]
		mov	eax, dword[rax+4*rcx]
		add	eax, dword[r9+4*r14]	; r14 = .moved_piece_to_sq
		add	eax, dword[r10+4*r14]
		add	eax, dword[r11+4*r14]
		sub	eax, 4000
		mov	dword[rbx-1*sizeof.State+State.history], eax
   ; Decrease/increase reduction by comparing opponent's stat score
		mov	ecx, dword[rbx-2*sizeof.State+State.history]
		mov	edx, ecx
		xor	edx, eax
		and	ecx, edx
		shr	ecx, 31
		sub	edi, ecx
		and	edx, eax
		shr	edx, 31
		add	edi, edx

		cdq
		mov	ecx, 20000
		idiv	ecx
		sub	edi, eax
.15ReadyToSearch:
		cmovs	edi, r15d
	if RootNode = 0 & GetExtentionCheckFromHash = 1
		test	edi, edi
		jz	.NotFound
		cmp	sil, r13l
		sete	al
		and	al, byte[rbx-1*sizeof.State+State.bound6]
		jnz	.gethash
.NotFound:		
	end if
		mov	eax, 1
		movsx	r8d, r13l		; .newDepth
		sub	r8d, edi
		cmp	r8d, eax
		cmovl	r8d, eax
		mov	edi, r8d
		lea	ecx, [r12+1]
		neg	ecx
		 or	r9d, -1
		call	Search_NonPv
		neg	eax
		cmp	eax, r12d		; .alpha
		jle	.17entry

		cmp	dil, r13l		; r13l .newDepth
  if PvNode = 1
		jge	.beforeDoFullPvSearch
  else
		jge	.17entry
  end if
		jmp	.15skip
	     calign   8
.15skip:
    ; Step 16. full depth search   this is for when step 15 is skipped
		xor	r9, r9
		mov	eax, r13d
		movsx	r8d, al			; .newDepth
		movsx	eax, ah			; .givesCheck
		inc	eax
		cmp	r8d, r9d
		cmovl	r8d, r9d
		lea	ecx, [rax+2]
		cmovg	eax, ecx
  if PvNode = 0
		movsx	r9d, byte[.cutNode]
  end if
		not	r9d
		lea	ecx, [r12+1]
		neg	ecx
		
		mov	rax, qword[TableQsearch_NonPv+rax*8]
		call	rax
		neg	eax
  if PvNode = 1
		cmp	eax, r12d
		jle	.17entry

.beforeDoFullPvSearch:
	if RootNode	= 0
		cmp	eax, dword[.beta]
		jge	.17entry
	end if
.DoFullPvSearch:
		xor	r9, r9
 		mov	dword[.pv], r9d
		mov	eax, r13d
		movsx	r8d, al			; .newDepth
		movsx	eax, ah			; .givesCheck
		inc	eax
		cmp	r8d, r9d
		cmovl	r8d, r9d
		lea	ecx, [rax+2]
		cmovg	eax, ecx
		or	byte[rbx+State.pvhit], 4	;cl
		mov	rax, qword[TableQsearch_Pv+rax*8]
		mov	ecx, dword[.beta]
		mov	edx, r12d
		neg	edx
		neg	ecx
		call	rax
		neg	eax
  end if	;PvNode = 1
    ; Step 17. Undo move
.17entry:
		mov	edi, eax
		call	Move_Undo
		;out	ecx = move
    ; Step 18. Check for new best move
		cmp	byte[signals.stop], 0
		jne	.Return

  if RootNode =	1
		;mov	eax, dword[.beta]
		Display 2, "info string move %m1 score=%i7 alpha=%i12 .beta=%i0%n"

		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		sub	rdx, sizeof.RootMove
.FindRootMove:
		add	rdx, sizeof.RootMove
	     Assert   b, rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender], 'cant find root move'
		cmp	ecx, dword[rdx+RootMove.pv+4*0]
		jne	.FindRootMove
		mov	r9d, 1
		mov	r10d,	-VALUE_INFINITE
		cmp	r9l, byte[rbx+State.moveCount]
		 je	.FoundRootMove1
		cmp	edi, r12d
		jle	.FoundRootMoveDone
	    _vmovsd	xmm0,	qword[rbp-Thread.rootPos+Thread.bestMoveChanges]
	    _vaddsd	xmm0,	xmm0, qword[constd._1p0]
	    _vmovsd	qword[rbp-Thread.rootPos+Thread.bestMoveChanges],	xmm0
.FoundRootMove1:
		mov	r10d,	edi
		lea	r8, [.pv-4]
		movzx	eax, byte[rbp-Thread.rootPos+Thread.selDepth]
		mov	byte[rdx+RootMove.selDepth],	al
		jmp	@2f
    @1:
		mov	dword[rdx+RootMove.pv+4*r9],	eax
		inc	r9
    @2:
		mov	eax, dword[r8+4*r9]
	       test	eax, eax
		jnz	@1b
		mov	dword[rdx+RootMove.pvSize], r9d
if	NotReducedatRoot = 1
		inc	r9
end if
.FoundRootMoveDone:
		mov	dword[rdx+RootMove.score], r10d
if	NotReducedatRoot = 1
		mov	byte[rdx+RootMove.everPv],	r9l
end if
  else
		if	TRACE = 1	;drawish.epd line 6 38 moves
			Testingmoves
		end if
  end if
    ; check for new best move
		cmp	di, word[rbx+State.bestvalue]
		jle	.18NoNewBestValue
		mov	word[rbx+State.bestvalue], di
		cmp	edi, r12d
		jle	.18NoNewAlpha
		mov	word[rbx+State.bestmove], cx
  if PvNode = 0
		; failhigh
		jmp	.MovePickDone
  else
		cmp	edi, dword[.beta]
		jge	.MovePickDone
	  if RootNode = 0
		lea	r9, [.pv-4]
		mov	r8, qword[rbx+State.pv]
		mov	dword[r8], ecx
		mov	edx, 1
    @1:
		mov	eax, dword[r9+rdx*4]
		mov	dword[r8+rdx*4], eax
		inc	edx
		test	eax, eax
		jnz	@1b
	  end if
		mov	r12d, edi
		jmp	.MovePickLoop
  end if
	     calign   8
.18NoNewAlpha:
.18NoNewBestValue:
		; ecx = move
		test	r13d, 0xff0000			; .captureOrPromotion = 0?
		jnz	@1f
		movzx	eax, byte[rbx+State.quietCount]
		cmp	eax, 64
		jae	.MovePickLoop
		inc	eax
		mov	dword[.quietsSearched+4*rax-4],	ecx
		mov	byte[rbx+State.quietCount], al
		jmp	.MovePickLoop
    @1:
		movzx	eax, byte[rbx+State.captureCount]
		cmp	eax, 32
		jae	.MovePickLoop
		inc	eax
		mov	dword[.capturesSearched+4*rax-4], ecx
		mov	byte[rbx+State.captureCount],	al
		jmp	.MovePickLoop
	     calign   8
.EndCycle:
    ; Step 20. Check for mate and stalemate
		xor	edx, edx
		mov	eax, dword[rbx+State.moveCount]
		movsx	edi, word[rbx+State.bestvalue]
if RootNode =	0
		test	eax, eax
	if PvNode = 0
		js	.20CheckBonus
	else
		js	.EndCycle0
	end if
		cmp	al, 1
	if PvNode = 0
		ja	.20CheckBonus
	else
		ja	.EndCycle0
	end if
		or	byte[rbx+State.pvhit], JUMP_IMM_8
end if
		cmp	al, dl
	if PvNode = 0
		jne	.20CheckBonus
		cmp	dword[rbx+State.excludedMove], edx
		cmovne	edi, r12d	; .alpha
		jne	.ReturnBestValue
	else
		jne	.EndCycle0	; .MovePickDone
	end if
if RootNode =	1
		mov	edi, -VALUE_MATE
		cmp	rdx, qword[rbx+State.checkersBB]
		cmove	edi, edx
		mov	varbounderd, BOUND_EXACT		;ups
		mov	eax, edx
else
		cmp	rdx, qword[rbx+State.checkersBB]
		je	.drawdetect
		mov	eax, edx
		mov	edx, -VALUE_MATE
		movzx	edi, byte[rbx+State.ply]
		add	edi, edx
		mov	dword[.ltte-1*sizeof.State+MainHashEntry.eval_], 0x7cff7cff	;(((VALUE_MATE-1) shl 16) or (VALUE_MATE-1))
		mov	varbounderd, BOUND_EXACT		;ups
		jmp	.direct_save	;.20TTStoreSave
	     calign   8
.drawdetect:
		mov	varbounderd, BOUND_EXACT		;ups
		mov	edi, edx
		mov	eax, edx
		
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]
	if PvNode = 0
		cmp	ecx, 1
		jl	.direct_save	;.20TTStoreSave
	end if
		mov	word[rbx-1*sizeof.State+State.movelead0], cx
end if
		jmp	.direct_save	;.20TTStoreSave
	     calign   8
if PvNode = 1
.EndCycle0:
		movzx	ecx, word[rbx+State.bestmove]
		test	ecx, ecx
	if RootNode =	0 | UpdateAtRoot = 1
		jz	.20CheckBonus
	else
		jz	.20TTStore
	end if

		mov	eax, ecx

		mov	edx, eax
		and	edx, 63
		movzx	edx, byte[rbp+Pos.board+rdx]
		shr	eax, 14
		or	dl, al		;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	ax, 3
		and	dl, ah
		mov	r13d, edx
		shl	r13d, 16

end if
.MovePickDone:
; r15d = offset of [piece_on(prevSq),prevSq]
; ecx = move
; esi = depth
		mov	eax, esi
		imul	eax, eax
		lea	r10d, [rax+2*rsi-2]
		test	r13d, 0xff0000			; .captureOrPromotion = 0?
		jnz	.20Quiet_UpdateCaptureStats
		Updatemove	ecx, word[rbx+State.countermove+2], PvNode, RootNode
		cmp	esi, 17
		jg	.20TTStore
if 1
		mov	r15d, r10d
		je	@1f
		lea	r15d, [r10+2*(rsi+1)+1]		;bonus for (rsi+1)
		if PvNode = 1
			mov	eax, dword[.beta]
			add	eax, BonusMargin
			cmp	edi, eax
			cmovl	r15d, r10d
		else
			lea	eax, [r12+4*rsi]
			cmp	dword[rbx+State.excludedMove],0
			cmove	eax, r12d
			add	eax, BonusMargin+1
			cmp	edi, eax
			cmovle	r15d, r10d
		end if
	@1:
		UpdateStats	ecx, .quietsSearched, byte[rbx+State.quietCount], r11d, r15d, RootNode
else
		UpdateStats	ecx, .quietsSearched, byte[rbx+State.quietCount], r11d, r10d, RootNode
end if
		xor	ecx, ecx
.20Quiet_UpdateCaptureStats:
		cmp	esi, 17
		jge	.20TTStore
		mov	rax, qword[rbx+State.checkersBB]
		test	rax, rax
		jnz	.20Quiet_UpdateStatsDone
		lea	r15d, [r10+2*(rsi+1)+1]
		UpdateCaptureStats	ecx, .capturesSearched, byte[rbx+State.captureCount],	r11d, r15d
.20Quiet_UpdateStatsDone:
if RootNode =	0 | UpdateAtRoot = 1
		cmp	word[rbx-1*sizeof.State+State.quietCount], 0	;only 1st Quiet
		ja	.20TTStore
		cmp	byte[rbx+State.capturedPiece], 0
		jne	.20TTStore
		lea	r10d, [r10+2*(rsi+1)+1]
    ; r10d = penalty
		imul	r11d,	r10d, -32
		jmp	.20TTBeforeStore
	     calign   8
.20CheckBonus:
    ; Bonus for prior countermove that caused the fail low
		cmp	esi, 17
		jg	.20TTStore
		if PvNode = 0
			lea	edx, [rsi-3*ONE_PLY]
			or	edx, dword[rbx-1*sizeof.State+State.currentMove]
			js	.20TTStore
		end if
		cmp	byte[rbx+State.capturedPiece], 0
		jne	.20TTStore
		mov	eax, esi
		imul	eax, eax
		lea	r10d, [rax+2*rsi-2]
		imul	r11d,	r10d, 32
.20TTBeforeStore:
		test	byte[rbx-1*sizeof.State+State.pvhit], JUMP_IMM_8
		jnz	.20TTStore
		movzx	r15d, word[rbx+State.countermove+2]
		UpdateCmStats	(rbx-1*sizeof.State),	r15, r11d, r10d, r8
end if
.20TTStore:
    ; edi = bestValue
if PvNode = 0
		cmp	dword[rbx+State.excludedMove],0
		jne	.IsMateThreat
end if
.20TTStoreSave:
		movzx	eax, word[rbx+State.bestmove]
.20TTStoreSave2:
		mov	edx, edi
		lea	ecx, [rdx+VALUE_MATE_IN_MAX_PLY]
		cmp	ecx, 2*VALUE_MATE_IN_MAX_PLY
		jae	.20ValueToTT
.20ValueToTTRet:
  if PvNode = 0
		xor	varbounderd, varbounderd
		cmp	edi, r12d	;dword[.beta]
		setg	varbounderl
		inc	varbounderd
  else
		mov	ecx, BOUND_LOWER
		cmp	eax, 1
		sbb	varbounderd, varbounderd
		lea	varbounderd, [(BOUND_EXACT-BOUND_UPPER)*varbounder+BOUND_EXACT]
		cmp	edi, dword[.beta]
		cmovge	varbounderd, ecx
  end if
.direct_save:
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[.posKey]
	; sil = .depth
	MainHash_Save   .ltte, r8, r9w, edx, varbounderl, sil, eax



.ReturnBestValue:
.Return_edi_Value:
		mov	eax, edi
.Return:
Display	2, "Search returning %i0%n"
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
if RootNode =	0
	     calign   8
.ValueFromTT:
		movzx	r8d, byte[rbx+State.ply]
	if PvNode = 0
		cmp	edi, VALUE_MATE-1
		je	.ValueFromTTmod
	end if
		mov	r9d, edi
		sar	r9d, 31
		xor	r8d, r9d
		add	edi, r9d
		sub	edi, r8d
		jmp	.ValueFromTTRet
	if PvNode = 0 | (RootNode = 0 & QueenThreats = 100)
if PvNode = 0
		calign	8
.IsMateThreat:
		cmp	edi, VALUE_MATE_IN_MAX_PLY
		jl	.ReturnBestValue	;was jl
		cmp	word[rbx+State.ltte+MainHashEntry.eval_], 0x7cff
		je	.MateThreatinOne
.YesMateThreat2:
		;add	esi, esi
		movzx	eax, word[rbx+State.bestmove]
		movsx	edx, byte[.ltte+MainHashEntry.depth]
		cmp	edx, esi
		cmovg	esi, edx			;adjustable depth
		mov	dword[rsp+.localsize+4*8], eax	;report bestmove
		jmp	.20TTStoreSave2
		calign	8
.MateThreatinOne:
		cmp	dword[rbx-1*sizeof.State+State.currentMove], 1
		jge	.YesMateThreat2
		mov	word[rbx-1*sizeof.State+State.ltte+MainHashEntry.eval_], VALUE_MATE_THREAT
		jmp	.YesMateThreat2

end if
		calign   8
.YesMateThreat:
		;Maximum Threat...
		movzx	ecx, word[.ltte+MainHashEntry.move]
		if	PvNode = 0
			jmp	.FollowVFT
			calign   8
.ValueFromTTmod:
			;update depth?
			movsx	edx, ch

			sub	edi, r8d
			shr	ecx, 16

			cmp	edx, esi
			jge	.FollowVFT1
			mov	r8, qword[rbx+State.tte]
		end if
.FollowVFT:
		mov	byte[r8+MainHashEntry.depth], sil
.FollowVFT1:
		;
		cmp	esi, 17
		if	PvNode = 0
			jge	.ReturnTTValue
		else
			jge	.FollowVFT2
		end if
		if	PvNode = 0
			lea	eax, [r12+BonusMargin+1]
		else
			lea	eax, [r13+BonusMargin]
		end if
			cmp	edi, eax
			lea	eax, [rsi+1]
			cmovge	esi, eax
		if	PvNode = 0
			jmp	.ReturnTTValue
		else
.FollowVFT2:
			lea	r12d, [r13-1]
			add	rsp, (.localstacksize-localStackCutNode)
			jmp	Search_NonPv.ReturnTTValue
		end if
	end if
end if
  if PvNode = 0
	     calign   8
.beforeReturnTTValue:
		mov	eax, ecx
		shr	ecx, 16			; used for also .ReturnTTValue
		jz	.Return_edi_Value
		and	al, 3
		cmp	al, 1
		je	.Return_edi_Value
		jmp	.ReturnTTValue
	     calign   8
.ReturnTTValue:
; If ttMove is quiet, update move sorting heuristics on TT hit
; edi = ttValue
; esi = depth
; eax = ttdepth
		mov	eax, ecx
		mov	edx, eax
		and	edx, 63
		shr	eax, 14
		mov	dl, byte[rbp+Pos.board+rdx]

		or	dl, al	;_CaptureOrPromotion_or + _CaptureOrPromotion_and
		sub	ax, 3
		and	dl, ah

	; dl = capture or promotion
		mov	eax, esi			; .depth
		imul	eax, eax
		lea	r10d,	[rax+2*rsi-2]
	; r10d = bonus
	; ttMove is quiet; update move sorting heuristics on TT hit
		cmp	edi, r12d
		jle	.ReturnTTValue_Penalty
		movzx	eax, byte[rbx-1*sizeof.State+State.currentMove]
		and	al, 63
		movzx	r15d, byte[rbp+Pos.board+rax]
		shl	r15d, 6
		add	r15d, eax
	; r15d = offset of [piece_on(prevSq),prevSq]
		test	dl, dl
		jnz	.ReturnTTValue_UpdateCaptureStats
		Updatemove	ecx, r15, 0, 0
		cmp	esi, 17
		jg	.Return_edi_Value
		UpdateStats	ecx,	0, 0, r11d, r10d, 0
.ReturnTTValue_UpdateCaptureStats:
;Extra penalty for a quiet TT move in previous ply when it gets refuted
	; r10d = penalty
		cmp	esi, 17
		jge	.Return_edi_Value
		cmp	word[rbx-1*sizeof.State+State.quietCount], 0
		ja	.Return_edi_Value
		cmp	byte[rbx+State.capturedPiece], 0
		jne	.Return_edi_Value
		test	byte[rbx-1*sizeof.State+State.pvhit], JUMP_IMM_8
		jnz	.Return_edi_Value
		lea	r10d,	[r10+2*(rsi+1)+1]
		imul	r11d,	r10d, -32
	UpdateCmStats	(rbx-1*sizeof.State),	r15, r11d, r10d, r8
		jmp	.Return_edi_Value
	     calign   8
.ReturnTTValue_Penalty:
		cmp	esi, 17
		jg	.Return_edi_Value
		test	dl, dl
		jnz	.Return_edi_Value
		test	byte[rbx+State.pvhit], JUMP_IMM_8
		jnz	.Return_edi_Value

	; r8 = offset in history table
		imul	r11d,	r10d, -32
	; Penalty for a quiet ttMove that fails low
		and	ecx, (64*64)-1
		mov	r9d, ecx
		mov	r8d, dword[rbp+Pos.sideToMove]
		mov	r8, qword[rbp+Pos.history+8*r8]
		lea	r8, [r8+4*rcx]
	apply_bonus	r8, r11d,	r10d, 324
		mov	eax, r9d
		shr	eax, 6
		and	r9d, 63
	      movzx	eax, byte[rbp+Pos.board+rax]
		shl	eax, 6
		add	r9d, eax
    ; r9 = offset in cm table
	UpdateCmStats	(rbx-0*sizeof.State),	r9, r11d, r10d,	r8
		jmp	.Return_edi_Value

;============================================================= additionPROBCUT  
	if PvNode = 0 & SaveProbResult = 1
		calign 8
.SaveProbCutResult:
		mov	eax, r14d
		neg	eax
		mov	rcx, qword[.ltte+MainHashEntry.genBound]
		cmp	eax, VALUE_MATE_IN_MAX_PLY
		jge	.ProbCutSave	;was jge
		lea	edx, [r12+1]
		cmp	eax, edx
		cmovl	edx, eax
		cmp	ch, DEPTH_QS_NO_CHECKS
		cmovg	eax, edx
		jg	.Return
		test	ecx, 0xffff0000
		cmovnz	eax, edx
		jnz	.Return
		sub	esi, 4
		mov	edi, eax
		mov	eax, dword[rbx+State.currentMove]
		cmp	edi, r12d
		jg	.20TTStoreSave2
;		Display	0, "info string ... [.ply=%i9][.value=%i7]=[.CvtprobVal=%i2] [.probVal=%i0]%n"
		add	esi, 4
		mov	varbounderd, BOUND_EXACT		;ups
		jmp	.direct_save
		calign 8
.ProbCutSave:	;belum ketemu cara ngesave effective
		mov	rdi, rcx
		sar	rdi, 32+16
		cmp	edi, 0x7CFF
		je	@1f
		movzx	r9d, byte[rbx+State.ply]
		sub	edi, r9d
		cmp	edi, eax
		jge	.Return	;was je
		Display	2, "info string ... [.ply=%i9][.value=%i7]=[.CvtprobVal=%i2] [.probVal=%i0]%n"
	@1:
		mov	edi, eax
		movsx	edx, ch				;.depth
		cmp	edx, esi
		cmovg	esi, edx
		mov	eax, dword[rbx+State.currentMove]
		jmp	.20TTStoreSave2
		calign 8
	end if
  end if
	 calign   8
.20ValueToTT:
		movzx	edx, byte[rbx+State.ply]
		mov	ecx, edi
		sar	ecx, 31
		xor	edx, ecx
		sub	edx, ecx
		add	edx, edi
		jmp	.20ValueToTTRet
		calign	8
  if RootNode = 0
if	GetExtentionCheckFromHash	= 1
		calign	8
.gethash:
		mov	rcx, qword[rbx+State.key]
		mov	rax, qword[mainHash.mask]
		and	rax, rcx
		shr	rcx, 48
		add	rax, qword[mainHash.table]
		mov	rdx, qword[rax+8*3]
		test	dx, dx
		jz	.NotFound
		cmp	dx, cx
		je	.FoundRefresh
		shr	rdx, 16
		add	rax, 8
		test	dx, dx
		jz	.NotFound
		cmp	dx, cx
		je	.FoundRefresh
		shr	rdx, 16
		add	rax, 8
		test	dx, dx
		jz	.NotFound
		cmp	dx, cx
		jne	.NotFound
.FoundRefresh:
		mov	rcx, qword[rax]
		and	rcx, 0xFFFFFFFFFFFFFF87
		or	cl, byte[mainHash.date]
		mov	rdx, rcx
		and	dl, 4+JUMP_IMM_8
		mov	byte[rax+MainHashEntry.genBound], cl
		mov	qword[rbx+State.tte], rax
		mov	qword[rbx+State.ltte], rcx
		mov	byte[rbx+State.pvhit], dl

		sar	rdx, 48
		lea	eax, [rdx+VALUE_KNOWN_WIN]
		cmp	eax, 2*(VALUE_KNOWN_WIN-1)
		ja	.NotFound
		test	cl, JUMP_IMM_8
		jnz	.singelreply
		test	ecx,0xffff0000
		jz	.NotFound
		test	cl, BOUND_LOWER
		jz	.NotFound
.fresh:
		xor	edi, edi
		jmp	.NotFound
.singelreply:
;reg r10 free
		cmp	esi, 8*ONE_PLY
	      sete	al
	       test	cl, BOUND_LOWER
	      setnz	cl
		and	al, cl
		movsx	ecx, ch					; ecx = MainHashEntry.depth
		add	ecx, 3*ONE_PLY
		cmp	ecx, esi				; esi = .depth
	      setge	cl
		and	al, cl
		jnz	.NotFound

		neg	edx
		sub	edx, 750
		cmp	edx, r12d
		jg	.NotFound
	@1:
		xor	edi, edi
		jmp	.NotFound
end if

	 calign   8
.resetMovePick:
		lea	r14, [MovePick_CAPTURES_GEN]
		lea	rcx, [MovePick_ALL_EVASIONS]
		cmp	rax, qword[rbx+State.checkersBB]
		cmovne	r14, rcx
		mov	byte[rbx+State.ttcap], al
	if PvNode = 0
		mov	byte[rbx+State.pvhit], al
	else
		mov	byte[rbx+State.pvhit], 4
	end if
		mov	word[.ltte+MainHashEntry.move], ax
		mov	rax, 0xffffffff00000000
		and	rdi, rax
		jmp	.skipsingular
    if USE_SYZYGY
	     calign   8
.CheckTablebase:
Display	2,"Info String second phase before DoTbProbe %i0%n"
	; get a	count of the piece for tb
		mov	rax, qword[rbx+State.Occupied]
		mov	ecx, dword[Tablebase_Cardinality]
		_popcnt	rax, rax,	r8
		cmp	eax, ecx
		jg	.CheckTablebaseReturn
		cmp	esi, dword[Tablebase_ProbeDepth]	; esi .depth
		jge	.DoTbProbe
		cmp	eax, ecx
		jge	.CheckTablebaseReturn
.DoTbProbe:
Display	2,"DoTbProbe %p%n"
		push	r15
		lea	r15, [.success]
		call	Tablebase_Probe_WDL
		pop	r15
		mov	edx, dword[.success]
		test	edx, edx
		jz	.CheckTablebaseReturn
Display	2,"Tablebase_Probe_WDL returned	%i0%n"
		mov	r8d, -VALUE_MATE + MAX_PLY
		movsx	ecx, byte[Tablebase_UseRule50]
		movzx	r9d, byte[rbx+State.ply]
		lea	edx, [2*rax]
		and	edx, ecx
		mov	edi, edx
		add	r9d, r8d
		cmp	eax, ecx
		cmovl	edx, r8d
		cmovl	edi, r9d
		neg	ecx
		mov	r8d, VALUE_MATE - MAX_PLY
		neg	r9d
		cmp	eax, ecx
		cmovg	edx, r8d
		cmovg	edi, r9d
    ; edi = value
    ; edx = value_to_tt(value, ss->ply)
		inc	qword[rbp-Thread.rootPos+Thread.tbHits]
		mov	r9d, dword[.posKey]
		mov	r8, qword[rbx+State.tte]
		mov	eax, MAX_PLY - 1
		add	esi, 6		; esi = .depth
		cmp	esi, eax
	      cmovg	esi, eax

;      		mov	word[.ltte+MainHashEntry.eval_], 0x7D02
		xor	eax, eax
      MainHash_Save   .ltte, r8, r9w, edx, BOUND_EXACT,	sil, eax
	
		mov	eax, edi
		jmp	.Return
    end if
  end if
  if USE_CURRMOVE = 1 &	VERBOSE	< 2 & RootNode = 1
	 calign   8
.PrintCurrentMove:
		mov	dword[rbx+State.currentMove],	ecx		; save .move
		movzx	edx, byte[rbx+State.moveCount]
		add	edx, dword[rbp-Thread.rootPos+Thread.PVIdx]
		inc	edx						; added after legal
		push	rdx rdx rcx rsi					; esi = .depth ecx = .move
		lea	rdi, [Output]
		lea	rcx, [sz_format_currmove]
		mov	rdx, rsp
		xor	r8, r8
		call	PrintFancy
		add	rsp, 8*4
		call	WriteLine_Output
		mov	ecx, dword[rbx+State.currentMove]		; load .move
		jmp	.PrintCurrentMoveRet
  end if
if RootNode = 0 & PvNode = 0
	     calign   8
.6gotoQsearch:
		xor	esi, esi
		movzx	r12d, r12w	;and	r12d, 0xffff		; .alpha + .bestMove
		mov	rcx, qword[rbx+State.ltte]
		add	rsp, (localStackCutNode-localsizestackqsearch)
		mov	qword[rsp+0], rsi	;.ttDepth+.depth
		or	r15l, JUMP_IMM_6
		jmp	QSearch_NonPv_NoCheck.AfterHashProbe
	     calign   8
.SetAttackOnNull:
                mov	rcx, qword[rbx-1*sizeof.State+State.pawnKey]
                mov	r10, qword[rbx-1*sizeof.State+State.psq] 	; copy psq and npMaterial
		mov	r11, qword[rbx-1*sizeof.State+State.checkSq]	; QxR
		mov	r8, qword[rbx-1*sizeof.State+State.checkSq+8]	; QxB
		mov	r9, qword[rbx-1*sizeof.State+State.Occupied]	; r9 = all pieces
		mov	edx, dword[rbx-1*sizeof.State+State.materialIdx]
                mov	qword[rbx+State.pawnKey], rcx
		mov	qword[rbx+State.psq], r10
		mov	qword[rbx+State.checkSq], r11		;QxR
		mov	qword[rbx+State.checkSq+8], r8		;QxB
		mov	qword[rbx+State.Occupied], r9
		mov	dword[rbx+State.materialIdx], edx
		
		movzx   r10d, byte[rbx-1*sizeof.State+State.ourKsq]
                mov	ecx, dword[rbp+Pos.sideToMove]
		mov	edx, ecx
		xor	edx, 1
		shl	edx, 6+3

		mov	r11, qword[WhitePawnAttacks+rdx+8*r10]
		mov	rdx, qword[KnightAttacks+8*r10]
		mov	qword[rbx+State.checkSq+8*Pawn], r11
		mov	qword[rbx+State.checkSq+8*Knight], rdx
      BishopAttacks	r11, r10, r9, r8
	RookAttacks	rdx, r10, r9, r8
		mov	qword[rbx+State.checkSq+8*Bishop], r11
		mov	qword[rbx+State.checkSq+8*Rook], rdx
		 or	r11, rdx
		mov	qword[rbx+State.checkSq+8*Queen], r11
		mov	byte[rbx+State.ksq], r10l

		mov	r10, qword[rbp+Pos.typeBB+8*rcx]		; r10 = our pieces
		mov	r11, qword[rbx-1*sizeof.State+State.pinnersForKing+8*0]
		mov	rdx, qword[rbx-1*sizeof.State+State.pinnersForKing+8*1]
		mov	r8, qword[rbx-1*sizeof.State+State.blockersForKing+8*0]
		mov	r9, qword[rbx-1*sizeof.State+State.blockersForKing+8*1]
		mov	qword[rbx+State.pinnersForKing+8*0], r11
		mov	qword[rbx+State.pinnersForKing+8*1], rdx
		mov	qword[rbx+State.blockersForKing+8*0], r8
		mov	qword[rbx+State.blockersForKing+8*1], r9

		and	r8, r10
		and	r9, r10
		mov	r10, r9
		test	ecx, ecx
		cmovnz	r10, r8
		cmovnz	r8, r9

		mov	ecx, CmhDeadOffset
		add	rcx, qword[rbp+Pos.counterMoveHistory]
                mov	rdx, qword[rbx-2*sizeof.State+State.endMoves]
                mov	qword[rbx-1*sizeof.State+State.endMoves], rdx
		mov	qword[rbx-1*sizeof.State+State.counterMoves], rcx

		mov	qword[rbx+State.dcCandidates], r10
		mov	qword[rbx+State.pinned], r8
		mov	word[rbx+State.movelead0], -1
		jmp	rax
;in	r9d	= .cutNode
;	r13d	= .ply
;	edi	= .Thread.nmp_ply
;	esi	= .depth
             calign   16
.Move_DoNull:
		lea	eax, [r14-1]			; r14d = .evalu
		sub	eax, r12d			; eax = .evalu - .beta
		mov	ecx, PawnValueMg
		xor	edx, edx
	       idiv	ecx
		mov	ecx, 3
		cmp	eax, ecx
	      cmovg	eax, ecx
	       imul	ecx, esi, 67
		add	ecx, 823
		sar	ecx, 8
		add	ecx, eax

	     Assert   ge, ecx, 0, 'assertion ecx >= 0 failed in	Search'

		mov	r14d, esi
		sub	r14d, ecx			; r14d = depth-R
	; copy the other important info
		xor	eax, eax
		mov	edx, dword[rbx+State.rule50]
		mov	dh, al
		add	edx, 0x010001			; + ply; + 50moves
		cmp	byte[signals.stop], al
		jne	.Return		;Move_DoNull.exitSearch
		cmp	edx, (MAX_PLY-1) shl 16
		ja	.NullAbortSearch_PlySmaller
		cmp	dl, 100
		jae	.NullAbortSearch_PlySmaller

		movzx	ecx, word[rbx+State.epSquare]	; only copy epsq n castling
		movzx   r9d, byte[rbx+State.ksq]
		mov	r8, qword[rbx+State.key]
		xor	r8, qword[Zobrist_side]
		test	ecx, 63
		jnz	.epsq
.epsq_ret:
		mov	dword[rbx+sizeof.State+State.epSquare], ecx	; .castlingRights+capturedPiece+ksq
		mov	qword[rbx+sizeof.State+State.rule50], rdx
		mov	dword[rbx+State.currentMove], MOVE_NULL
		mov	qword[rbx+1*sizeof.State+State.checkSq+8*King], rax
		mov	qword[rbx+1*sizeof.State+State.checkersBB], rax
		mov	dword[rbx+State.moveCount], 0xffff00

		mov	qword[rbx+1*sizeof.State+State.tte],rax
                mov	qword[rbx+1*sizeof.State+State.key], r8
		mov	qword[rbx+1*sizeof.State+State.ourKsq], r9	;incl .pvhit

		and	r8, qword[mainHash.mask]			;shl	r8, 5
		add	r8, qword[mainHash.table]
		prefetchnta	[r8]

	; mate distance	pruning
		mov	r8d, r12d
		neg	r8d
		lea	ecx, [r8-1]
if 1
		lea	edx, [(r13+1)-VALUE_MATE]
		cmp	ecx, edx
	      cmovl	ecx, edx
		not	edx
		cmp	r8d, edx
	      cmovg	r8d, edx
		mov	eax, ecx
		neg	eax		; result
		cmp	ecx, r8d
		jge	.NullAbortSearch_PlySmaller
		xor	eax, eax
end if
		xor	dword[rbp+Pos.sideToMove], 1
		add	rbx, sizeof.State		; point of change

		mov	r15l, JUMP_IMM_2
		movsx	r9d, byte[.cutNode]
		not	r9d
		mov	r8d, r14d			; .depth-R
		cmp	r8d, eax			; ONE_PLY
		cmovl	r8d, eax
		setg	al				; setge
		mov	rax, qword[TableQsearch_NonPv+8+rax*8]
		call	rax
		neg	eax

		xor	dword[rbp+Pos.sideToMove], 1
		sub	rbx, sizeof.State
if	1
		lea	edx, [rax+VALUE_MATE-2]
		sub	edx, r13d
		jnz	.NullAbortSearch_PlySmaller
		mov	word[rbx+State.ltte+MainHashEntry.eval_], VALUE_MATE_THREAT
end if
.NullAbortSearch_PlySmaller:
		lea	ecx, [r12+1]
		cmp	eax, ecx
		jl	.8skip
		cmp	eax, VALUE_MATE_IN_MAX_PLY
		cmovge	eax, ecx
		test	dil, dil			; Thread.nmp_ply = 0?
		jnz	.Return
		cmp	esi, 12*ONE_PLY
		jge	.8check
		lea	ecx, [r12+VALUE_KNOWN_WIN]
		cmp	ecx, 2*(VALUE_KNOWN_WIN-1)
		jbe	.Return
.8check:
		mov	edi, eax			; eax = nullValue
		mov	r8d, r14d
		mov	ecx, 4
		lea	eax, [3*r8d]		;if r8 =0 eax=0 if r8 =-1 eax=-3
		test	eax, eax		;if eax <=0 search in Qsearch not in SearchPvNode
		cmovs	eax, ecx
		sar	eax, 2
		add	eax, r13d			; r13d	= .ply
		and	r13d, 1
		mov	byte[rbp-Thread.rootPos+Thread.nmp_ply+r13], al
		;
		xor	eax, eax
		xor	r15, r15
		mov	r9d, eax
		cmp	r8d, eax
		cmovl	r8d, eax
		setg	al
		mov	ecx, r12d
		mov	rax, qword[TableQsearch_NonPv+8+rax*8]
		call	rax

		mov	byte[rbp-Thread.rootPos+Thread.nmp_ply+r13], 0
		cmp	eax, r12d
		jle	.8skip
		mov	eax, edi
		jmp	.Return
	calign   8
.epsq:
		mov	r10d, ecx
		mov	cl, 0x40
		and	r10d, 7
		xor	r8, qword[Zobrist_Ep+8*r10]
		jmp	.epsq_ret
end if
;r1bq1rk1/pppp1ppp/3n1b2/4R3/3P4/8/PPP2PPP/RNBQ1BK1 w - - 1 10 problem
if USE_GAMECYCLE = 1 & RootNode = 0 & PvNode = 1
	 calign	  8
.has_game_cycle:
		mov	r8d, eax
		shr	r8d, 16		;.ply
		neg	r8d
		movzx	eax, ah		;.pliesFromNull
		add	r8d, eax	;.pliesFromNull
		lea	r9d, [rax-3]
		mov	rdx, qword[rbx+State.key]
		lea	r11, [rbx-3*sizeof.State+State.key]
	.hgcs_loopcheck:
		mov	r10, rdx
		xor	r10, qword[r11]
		mov	eax, r10d
		and	eax, 0x1fff	;H1
		cmp	r10, qword[cuckoo+rax*8]
		je	.hgcs_yescyclefound
		mov	eax, r10d
		shr	eax, 16
		and	eax, 0x1fff	;H2
		cmp	r10, qword[cuckoo+rax*8]
		je	.hgcs_yescyclefound
	.hgcs_nocyclefound:
		sub	r11, 2*sizeof.State
		sub	r9d, 2
		jns	.hgcs_loopcheck
.hgcs_not_found:
		mov	word[rbx+State.movelead0], -1
		jmp	Search_Pv.1done	;1draw	;ret
	calign 8
	.hgcs_yescyclefound:
		movzx	r10, word[cuckooMove+rax*2]
		mov	rax, qword[rbx+State.Occupied]
		test	rax, qword[BetweenBB+r10*8]
		jnz	.hgcs_nocyclefound
		cmp	r8d, r9d
		jl	.hgcs_found

		mov	eax, r10d
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax],ah
		jne	.Yespiece
		mov	eax, r10d
		shr	eax, 6
		and	eax, 63
	.Yespiece:
		movzx	eax, byte[rbp+Pos.board+rax]
		shr	eax, 3
		cmp	eax, dword[rbp+Pos.sideToMove]
		jne	.hgcs_nocyclefound

		cmp	byte[r11-State.key+State.onerep],0
		je	.hgcs_not_found
if	0
		;all move drawish
		mov	r10w, 0x7fff
		jmp	.test0
end if
.hgcs_found:
		mov	eax, r10d
		shr	eax, 6
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax],ah
		jne	.test0
		and	r10d, 63
		shl	r10d, 6
		or	r10d, eax
	.test0:
		mov	word[rbx+State.movelead0], r10w
		xor	eax, eax
		mov	r12d, eax
		jmp	Search_Pv.1done	;1draw	;ret
end if
restore	varbounder
restore varbounderd
restore varbounderl

end macro
