
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

  virtual at rsp
    .quietCount		rd 1	; 1. dont_change
    .captureCount	rd 1	; 2. dont_change
    .beta		rd 1
    .success		rd 1
    .reductionOffset	rd 1
    .ttCapture		rd 1    ; dont change struct			----- start	1	for true
    .singularNode	rb 1	; 1st
    .YesExtend		rb 1	; 2nd
   			rb 1    ;
			rb 1    ; -1 for true ;dont change struct	----- end
    .cutNode		rb 1    ; -1 for true
    			rb 1
			rb 1    ; -1 for true
			rb 1
if SUFFLEMOVE = 100 
    .sufflemove		rd	1	;SUFFLEMOVE = 1 used
			rd	1
end if
    .quietsSearched	rd 64
    .capturesSearched	rd 32
    if PvNode =	1
      .pvExact		rd 1
      .pv		rd MAX_PLY + 1
    end	if
    .lend		rb 0
  end virtual
  .localsize = (.lend-rsp+15) and -16

.posKey	equ (rbx+State.key+6)
.ltte	equ (rbx+State.ltte)

	       push   rsi rdi r12 r13 r14 r15
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

		mov	r12d, ecx
		mov	r13d, edx
		mov	esi, r8d		; .depth
if PvNode = 0
		mov	byte[.cutNode], r9l
end if
	; callsCnt counts down as in master
	; resetCnt, if nonzero,	contains the count to which callsCnt should be reset
		mov	rax, qword[rbp-Thread.rootPos+Thread.callsCnt]
		mov	edx,eax
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
		movzx	edi, byte[rbx+State.ply]
	; Step 3. mate distance	pruning
		mov	eax, edi
		sub	eax, VALUE_MATE
		cmp	r12d, eax
	      cmovl	r12d, eax
		not	eax
		cmp	r13d, eax
	      cmovg	r13d, eax
		mov	eax, r12d
		cmp	eax, r13d
		jge	.Return
	if PvNode = 1
		movzx	eax, byte[rbp-Thread.rootPos+Thread.selDepth]
		cmp	eax, edi
		cmovb	eax, edi
		mov	byte[rbp-Thread.rootPos+Thread.selDepth], al
	end if
end if
;
;===========================================================================
		xor	eax, eax
		cmp	al, byte[signals.stop]
		jne	.Return
;===========================================================================
;
	; Step 4. transposition	table look up
if RootNode =	0
		or	r15l, byte[rbx+State.flags]
else
		mov	r15l, byte[rbx+State.flags]
end if
		call	MainHash_Probe
		mov	qword[.ltte], rcx
if RootNode =	1
		imul	ecx, dword[rbp-Thread.rootPos+Thread.PVIdx], sizeof.RootMove
		add	rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	ecx, dword[rcx+RootMove.pv]
else
		mov	rdi, rcx
		sar	rdi, 48
		test	edx, edx
		jz	.DontReturnTTValue
	if PvNode = 0
		movsx   eax, ch			; depth
		shr	ecx, 16
		xor	r8d, r8d
		test	r15l, JUMP_IMM_1	; exclude_search
		cmovnz	ecx, r8d
		jnz	.Zero_ttMove
	end if
		cmp	edi, VALUE_NONE
		je	.DontReturnTTValue
		lea	r8d, [rdi+VALUE_MATE_IN_MAX_PLY]
		cmp	r8d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ValueFromTT		;no esi, edx, ecx
.ValueFromTTRet:
	if PvNode = 0
		cmp	eax, esi	; .depth
		 jl	.DontReturnTTValue
		cmp	edi, r12d	; dword[.beta]
		setg	al		; setge al ;def=0=BOUND_UPPER, ge=1=BOUND_LOWER
		inc	eax
		test	al, byte[.ltte+MainHashEntry.genBound]
		jnz	.ReturnTTValue
	end if
end if
	if PvNode = 0 | RootNode = 1
.Zero_ttMove:
		mov	word[.ltte+MainHashEntry.move], cx	; .ttMove
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

if RootNode =	1
		test	r15l,JUMP_IMM_2
		jnz	.moves_loopex
else
		test	r15l,JUMP_IMM_3 or JUMP_IMM_1
		jnz	.moves_loopex
		mov	cl,r15l
		and	cl,JUMP_IMM_2+JUMP_IMM_6
		jz	.NoEval
		mov	eax, dword[rbx+State.staticEval]
		cmp	cl,JUMP_IMM_6	;JUMP_IMM_2+JUMP_IMM_6
		ja	.improvingEval
		jb	.SaveHash
.NoEval:
	if USE_SYZYGY
		; Step 4a. Tablebase probe
		movzx	eax, byte[rbx+State.rule50]
		or	al, byte[rbx+State.castlingRights]
		jnz	.CheckTablebaseReturn
		cmp	eax, dword[Tablebase_Cardinality]
		jnz	.CheckTablebase		;no esi
.CheckTablebaseReturn:
	end if
end if	;RootNode =	0
		; step 5. evaluate the position statically
		xor	ecx, ecx
		mov	dword[rbx+State.staticEval], VALUE_NONE
		cmp	rcx, qword[rbx+State.checkersBB]
		jne	.moves_loopex
if RootNode =	0
		test	edx, edx
		jnz	.StaticValueYesTTHit2
else
		test	edx, edx
		jz	@2f
		movsx	eax, word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		jne	@1f
	@2:
end if	;RootNode =	1
;=====NoTTHit:======
		call	Evaluate
	@1:
		mov	dword[rbx+State.staticEval], eax
.SaveHash:
		mov	r14d, eax
if RootNode =	1
		test	r15l, JUMP_IMM_6
		jnz	@3f
end if		
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[.posKey]
		mov	edx, VALUE_NONE
if RootNode =	1
      MainHash_Save	.quietCount, r8, r9w, edx, BOUND_NONE,	DEPTH_NONE, 0, r14w
	@3:
		mov	dl, JUMP_IMM_2
else
      MainHash_Save	.ltte, r8, r9w, edx, BOUND_NONE,	DEPTH_NONE, 0, r14w
		jmp	.StaticValueDone
;.StaticValueYesTTHit:
;		mov	eax, dword[rbx+State.staticEval]
;		jmp	@2f
.StaticValueYesTTHit2:
		movsx	eax, word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		jne	@1f
		call	Evaluate
	@1:
		mov	dword[rbx+State.staticEval], eax
;	@2:
.improvingEval:
		cmp	edi, VALUE_NONE		;if no .ttHit edi = VALUE_NONE
		je	.StaticValueDone0
		cmp	edi, eax
		setg	cl
		inc	ecx
		test	cl, byte[.ltte+MainHashEntry.genBound]
		cmovnz	eax, edi
.StaticValueDone0:
		mov	r14d,eax
.StaticValueDone:
		or	r15l, JUMP_IMM_2
		mov	dl, JUMP_IMM_2
end if	;RootNode = 0
		mov	ecx, dword[rbx-2*sizeof.State+State.staticEval]
		cmp	dword[rbx-0*sizeof.State+State.staticEval], ecx
		setge	dh
		cmp	ecx, VALUE_NONE
		sete	cl
		or	dh, cl
		mov	word[rbx+State.flags],	dx   ; should be 0 or 1	; +State.improving

if RootNode =	0
;		mov	ecx, dword[rbp+Pos.sideToMove]
;		movzx	ecx, word[rbx+State.npMaterial+2*rcx]
;		test	ecx, ecx
;		jz	.moves_loopex
;		and	r15l, not (JUMP_IMM_3+JUMP_IMM_6)
;		mov	byte[rbx+State.flags], r15l
		;r12 = .alpha r14 = .evalu;  rsi = .depth

	    ; Step 6. Razoring (skipped	when in	check)
	if PvNode = 0
		cmp	esi, 2*ONE_PLY
		jge	.6skip
;		cmp	byte[rbx+State.improving], 0
;		jne	.6skip
		lea	edx, [r14+600]
		cmp	edx, r12d
		jg	.6skip
;		mov	ecx, 590		; RazorMargin
		xor	r8d, r8d
;		cmp	esi, ONE_PLY
;		cmovle	ecx, r8d
;		mov	edi, r12d
;		sub	edi, ecx
;		mov	ecx, edi
		mov	ecx, r12d
		lea	edx, [rcx+1]
		call	QSearch_NonPv_NoCheck
		jmp	.Return
;		cmp	eax, edi		; edi	= .ralpha
;		jle	.Return
;		cmp	esi, 2*ONE_PLY
;		jl	.Return
.6skip:
	end if

	    ; Step 7. Futility pruning:	child node (skipped when in check)
		cmp	esi, 7*ONE_PLY
		jge	._7skip
		cmp	r14d, VALUE_KNOWN_WIN
		jge	._7skip
		movzx	edx, byte[rbx+State.improving]
		neg	edx
		and	edx, 50
		lea	edx, [rdx-175]
		imul	edx, esi
;		imul	edx, esi, -150	;original
		mov	eax, r14d
		add	edx, eax
	if PvNode = 1
		cmp	edx, r13d			; .beta
		jge	.Return
	else
		cmp	edx, r12d			; .alpha
		jg	.Return
	end if
._7skip:

	    ; Step 8. Null move	search with verification search	(is omitted in PV nodes)
	if PvNode = 0	; null & ProbCut
		cmp	r12d, r14d	; r12d =.alpha, r14d =.evalu
		jge	.8skip
		cmp	dword[rbx-1*sizeof.State+State.history], 23200	;22500
		jge	.8skip
		mov	ecx, dword[rbp+Pos.sideToMove]
		cmp	word[rbx+State.npMaterial+2*rcx], 0
		je	.8skip
		imul	eax, esi,	36
		add	eax, dword[rbx+State.staticEval]
		lea	edx, [r12+1+225]
		cmp	eax, edx
		jl	.8skip
		movzx	r13d, byte[rbx+State.ply]
		mov	edx, r13d
		and	dl, 1
		movzx	edi, byte[rbp-Thread.rootPos+Thread.nmp_ply+rdx]
		cmp	r13d, edi
		jb	.8skip
		movzx	r9d, byte[.cutNode]
		call	Move_DoNull
		jz	.Return
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
if MATERIALDRAW = 1
		jz	.9skipverify
end if
;pre test
		xor	r8d, r8d
		mov	ecx, edi
		lea	edx, [rcx+1]
		call	r14
		cmp	eax, edi
		jg	.9skipverify
;done
		mov	ecx, edi
		lea	edx, [rcx+1]
		lea	r8d, [rsi-4*ONE_PLY]
		movzx	r9d, byte[.cutNode]
		not	r9d
	       call	Search_NonPv
.9skipverify:
		mov	r14d, eax
	       call	Move_Undo
		cmp	r14d, edi
		 jg	.9moveloop
		mov	eax, r14d
		neg	eax
		jmp	.Return
		calign 8
.9skip:
	end if ;PvNode = 0

.IID_Search:
    ; Step 10. Internal iterative deepening (skipped when in check)

		cmp	esi, 8*ONE_PLY		; 6*ONE_PLY
		jl	.moves_loopex
		cmp	word[.ltte+MainHashEntry.move], 0	; .ttMove
		jne	.moves_loopex
	if PvNode = 0
		mov	eax, dword[rbx+State.staticEval]
		add	eax, 128
		cmp	eax, r12d
		jle	.moves_loopex
		movzx	r9d, byte[.cutNode]
		or	r15l, JUMP_IMM_3
		mov	ecx, r12d		; .alpha
		lea	edx, [rcx+1]
		lea	r8d, [3*rsi-8*ONE_PLY]
		shr	r8d, 2
		call	Search_NonPv
	else
		mov	edx, dword[.beta]
		mov	ecx, r12d		; .alpha
		mov	r15l, JUMP_IMM_3
		lea	r8d, [3*rsi-8*ONE_PLY]
		shr	r8d, 2
		call	Search_Pv
	end if
		jmp	.moves_loopex
end if	;RootNode =	0

		calign 8
.moves_loopex:

if QUEENTHREAT = 100
		mov	al,byte[rbx+State.flags]
		test	al, JUMP_IMM_4
		jnz	.QKBOXskip
		or	al, JUMP_IMM_4
		mov	byte[rbx+State.flags], al
		call	InitQueenSee
.QKBOXskip:
end if

.CMH  equ (rbx-1*sizeof.State+State.counterMoves)
.FMH  equ (rbx-2*sizeof.State+State.counterMoves)
.FMH2 equ (rbx-4*sizeof.State+State.counterMoves)
    ; initialize move pick
		xor	eax, eax
		mov	qword[.ttCapture], rax		;+.ttCapture+.singularNode+.YesExtend+...+.skipQuiets
		mov	qword[.quietCount], rax		;+.captureCount
  if PvNode = 1
		mov	al, byte[.ltte+MainHashEntry.genBound]
		and	al, BOUND_EXACT
		cmp	al, BOUND_EXACT
	       sete	al
		mov	dword[.pvExact], eax
  end if
		movzx	edi, word[.ltte+MainHashEntry.move]	;dword[.ttMove]
if RootNode =	0
		lea	r14, [MovePick_CAPTURES_GEN]
		lea	r13, [MovePick_ALL_EVASIONS]
	       test	edi, edi
		 jz	.NoTTMove
		mov	ecx, edi
	       call	Move_IsPseudoLegal
;	       test	rax, rax
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
;==========================================
		movzx	eax, byte[rbx+State.improving]
		mov	edx, 63
		mov	ecx, esi		; .depth
		cmp	esi, edx
	      cmova	ecx, edx
		lea	eax, [8*rax]
		lea	eax, [8*rax+rcx]
		shl	eax, 6
		mov	dword[.reductionOffset], eax

		mov	r10, qword[rbp+Pos.counterMoves]
		mov	eax, dword[rbx-1*sizeof.State+State.currentMove]
		and	eax, edx		;63
		movzx	r11d, byte[rbp+Pos.board+rax]
		shl	r11d, 6
		add	eax, r11d
		mov	dword[.success], eax
		mov	eax, dword[r10+4*rax]
		shl	rax, 32
		or	rdi, rax		; rdi = .ttMove + .countermove
;===========================================
		test	edi, edi
		jz	.skipsingular
if RootNode =	1
; if RootNode =	0, pass Move_IsPseudoLegal we have r9
		mov	r9d, edi
		and	r9d, edx	;edx = 63	; r9d = to
		mov	r8d, edi
		shr	r8d, 6
		and	r8d, edx

end if
		mov	ecx, edi
		shr	ecx, 14
	      movzx	eax, byte[rbp+Pos.board+r9]	; piece to
		 or	al, byte[_CaptureOrPromotion_or+rcx]
		and	al, byte[_CaptureOrPromotion_and+rcx]
		setnz	al				; convert to bit 1 or 0
		mov	dword[.ttCapture], eax
;===========================================
  if RootNode = 0
		;Allready check excludemove, remove TTmove of line 162
		cmp	esi, 8*ONE_PLY			; esi	=.depth
	      setge	al
if 0
	if PvNode = 1
		mov	ecx, VALUE_MATE_IN_ONE_PLY
		cmp	ecx, dword[.beta]
		setg	cl
		and	al, cl
	else
		cmp	r12d, VALUE_MATE_IN_ONE_PLY
		setl	cl
		and	al, cl
	end if

		movsx	ecx, word[.ltte+MainHashEntry.value_]	; .ttValue
		cmp	ecx, VALUE_MATE_IN_ONE_PLY
		setl	cl
		and	al, cl
end if
		
		movsx	ecx, word[.ltte+MainHashEntry.genBound]	; genBound+depth
	       test	cl, BOUND_LOWER
	      setnz	cl
		and	al, cl
		movsx	ecx, ch				; ecx = MainHashEntry.depth
		add	ecx, 3*ONE_PLY
		cmp	ecx, esi			; esi = .depth
	      setge	cl
		and	al, cl
		jz	.skipsingular
		mov	ecx, edi
		call	Move_IsLegal
		jz	.resetMovePick
		mov	dword[rbx+State.excludedMove], ecx
		movsx	edx, word[.ltte+MainHashEntry.value_]	; .ttValue
	if	PvNode = 0
		movzx	r9d, byte[.cutNode]
	else
		xor	r9, r9
	end if
		movzx	eax, byte[rbx+State.ply]
		sub	eax, VALUE_MATE
		;mov	eax, -VALUE_MATE
		sub	edx, esi			; esi = .depth
		sub	edx, esi
		cmp	edx, eax
	      cmovl	edx, eax
		lea	r15, [8*rdx]
		lea	r15, [8*r15+JUMP_IMM_1]
		lea	ecx, [rdx-1]
		mov	r8d, esi			; esi = .depth
		sar	r8d, 1
	       call	Search_NonPv
		sar	r15, 8
		cmp	eax, r15d
	       setl	ah

		or	al, -1
		mov	word[.singularNode],	ax	; +.YesExtend
		xor	eax, eax
		mov	dword[rbx+State.excludedMove], eax
  end if
;=======================
  .skipsingular:

if SUFFLEMOVE = 100 
;& PvNode = 0
  if RootNode = 0
		xor	edx, edx
		mov	dword[.sufflemove], edx
		cmp	r12d, edx
		jge	.skip_suff
		cmp	byte[rbx+State.pliesFromNull], 2
		jb	.skip_suff
		cmp	byte[rbx+State.rule50], 2
		jb	.skip_suff
		mov	cl, byte[rbx-2*sizeof.State+State.castlingRights]
		cmp	cl, byte[rbx+State.castlingRights]
		setne	al		;yes differ Rights
		or	dl, al
		mov	r10d, dword[rbx-1*sizeof.State+State.currentMove]
		mov	ecx, dword[rbx-2*sizeof.State+State.currentMove]
		mov	r9d, ecx
		and	r9d, 63 shl 6
		shl	r9d, 3
		and	ecx, 63
		cmp	dh, byte[rbp+Pos.board+rcx]
		setnz	al		;yes capture
		or	dl, al
		mov	r8, qword[BetweenBB+r9+8*rcx]
		and	r10d, 63
		bt	r8, r10		;yes there is piece
		setc	al
		or	dl, al
		jnz	.skip_suff
		shl	ecx, 6
		shr	r9d, 6+3
		or	ecx, r9d
		mov	dword[.sufflemove], ecx
.skip_suff:
  end if
end if
;================================
		; Init before search
		; esi = .depth r14 = State.stage
		mov	rax, 0x82FF000000000000	;(-VALUE_INFINITE ) shl 48	; .value_ = -VALUE_INFINITE + .move = 0
		mov	qword[.ltte], rax
		mov	qword[rbx+State.ttMove], rdi	; .ttMove + .countermove
		mov	qword[rbx+State.mpKillers], r13
		mov	dword[rbx+State.moveCount], eax	; 0
		mov	byte[rbx+State.skipQuiets], al
		mov	rax, r14
		jmp	.Pickcaller
;
;=================================
    
    ; Step 11. Loop through moves
	 calign	  8
.MovePickLoop:	     ; this is the head	of the loop
    GetNextMove .Pickcaller
		jz	.EndCycle	;.MovePickDone	;uses flags
if PvNode = 0
		cmp	ecx, dword[rbx+State.excludedMove]
		je	.MovePickLoop
end if
		
    ; at the root search only moves in the move	list
  if RootNode =	1
		imul	eax, dword[rbp-Thread.rootPos+Thread.PVIdx], sizeof.RootMove
		add	rax, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
    @1:
		cmp	rax, rdx
		jae	.MovePickLoop
		cmp	ecx, dword[rax+RootMove.pv]
		lea	rax, [rax+sizeof.RootMove]
		jne	@1b
  end if
		xor	eax, eax
  if PvNode = 1
		lea	rdx, [.pv]
		mov	qword[rbx+1*sizeof.State+State.pv], rdx
		mov	dword[rdx], eax
  end if

  if USE_CURRMOVE = 1 &	VERBOSE	< 2 & RootNode = 1
		cmp	byte[options.displayInfoMove],	al
		je	.PrintCurrentMoveRet
		cmp	dword[rbp-Thread.rootPos+Thread.idx], eax
		jne	.PrintCurrentMoveRet
		mov	rax, qword[time.lastPrint]
		cmp	eax, CURRMOVE_MIN_TIME
		jge	.PrintCurrentMove
.PrintCurrentMoveRet:
  end if
		call	Move_GivesCheck
		; r9d = to & r8d = from

		movzx	r14d, byte[rbp	+ Pos.board + r8]	; r14d = from piece
		movzx	r15d, byte[rbp	+ Pos.board + r9]	; r15d = to piece
		movzx	edx, byte[rbx+State.improving]
		shl	edx, 4+2
		mov	edx, dword[FutilityMoveCounts+rdx+4*rsi]
		sub	edx, dword[rbx+State.moveCount]
		sub	edx, 2					; added after legal
		lea	edi, [rsi-16*ONE_PLY]			; rsi = .depth
		and	edi, edx
		sar	edi, 31
		mov	r13d, edi				; .moveCountPruning
		not	edi
		and	edi, eax  ; edi = givesCheck && !moveCountPruning

		mov	edx, r15d
		mov	ah, dl
		mov	edx, ecx
		shr	edx, 14
		or	ah, byte[_CaptureOrPromotion_or+rdx]
		and	ah, byte[_CaptureOrPromotion_and+rdx]
		shl	r13d, 16
		or	r13w, ax
		mov	dword[rbx+State.givesCheck], r13d	; .givesCheck+.captureOrPromotion+.moveCountPruning+...... newdepth later

    ; Step 12. Extend checks
if RootNode = 0
		cmp	ecx, dword[rbx+State.ttMove]
		jne	.12else
		mov	eax, dword[.singularNode]
		test	al, al
		jz	.12else
		movzx	edi, ah		; .YesExtend
		jmp	.12done
.12else:
end if
		test	edi, edi
		jz	.12done
		SeeSignTestQSearch	.12extend_oneply
		xor	edi, edi
		test	eax, eax
		jz	.12done
.12extend_oneply:
		mov	edi, 1		; .extension = 1
.12done:

    ; Step 13. Pruning at shallow depth

	; edi = .extension
		lea	edi, [rdi+rsi-1]		; .newDepth
		shl	r13d, 8
		or	r13l, dil			; r13l	= .newDepth

		mov	eax, dword[rbx+State.moveCount]	; .moveCount
		inc	eax				; added after legal
		mov	edx, 63
		cmp	eax, edx
		cmova	eax, edx
		add	eax, dword[.reductionOffset]
		mov	r15d, dword[Reductions + 4*(rax	+ 2*64*64*PvNode)]	; r15d = .reduction

  if (RootNode = 0 & USE_MATEFINDER = 0)
cmp	esi,16*ONE_PLY	; .depth
jge	.13done
		movsx	eax, word[.ltte+MainHashEntry.value_]
		cmp	eax, VALUE_MATED_IN_MAX_PLY
		jle	.13done
		mov	r10d, r14d
		shr	r10d, 3					; Pos.sideToMove
		movzx	r11d, word[rbx+State.npMaterial+2*r10]
		test	r11d, r11d
		jz	.13done
		test	r13d, 0xffff00				; .givesCheck+.captureOrPromotion = 0 ?
		jnz	.13else
		xor	r10d, 1
		add	r11w, word[rbx+State.npMaterial+2*r10]
		cmp	r11w, 5000
		jae	.13do
		mov	r11l, r14l
		and	r11l, 7
		cmp	r11l, Pawn
		jne	.13do
		xor	r10d, 1
		neg	r10d
		and	r10d, 7 shl 3
		;imul	r10d, 56
		xor	r10d, r8d
		cmp	r10d, SQ_A5
		jae	.13else
.13do:
    ; Move count based pruning
		mov	eax, r13d
		shr	eax, 16 + 8		; .moveCountPruning == -1?
		or	byte[rbx+State.skipQuiets],al
		jnz	.MovePickLoop
		sub	edi, r15d		; edi = lmrDepth = .newDepth - .reduction
if 1
		cmp	edi, 3*ONE_PLY
		jge	.13DontSkip2
else
		mov	eax, 3
		mov	edx, 2
		cmp	dword[rbx-1*sizeof.State+State.history], r15d
		cmovle	eax, edx
		cmp	edi, eax
		jg	.13DontSkip2
end if
    ; Countermoves based pruning
		mov	rax, qword[.CMH]
		mov	rdx, qword[.FMH]
		lea	r10, [8*r14]
		lea	r10, [8*r10+r9]
		mov	eax, dword[rax+4*r10]
		mov	edx, dword[rdx+4*r10]
    if CounterMovePruneThreshold <> 0     ; code assumes
	err
    end if
		and	eax, edx
		js	.MovePickLoop
.13DontSkip2:
    ; Futility pruning:	parent node
		cmp	edi, 7*ONE_PLY
		 jg	.13done
		 je	.13check_see
		xor	eax, eax
	       test	edi, edi
	      cmovs	edi, eax
		test	r13d, 0xff00	; .givesCheck ?
		jnz	.13check_see	; yes
	       imul	eax, edi, 200
		add	eax, 256
		add	eax, dword[rbx+State.staticEval]
		cmp	eax, r12d	; dword[.alpha]
		jle	.MovePickLoop
.13check_see:
    ; Prune moves with negative	SEE at low depths
		imul	edx, edi,	-35
		imul	edx, edi
		jmp	.13done0
		calign   8
.13else:
		cmp	esi, 7*ONE_PLY	; .depth
		jge	.13done
		cmp	sil, r13l	; .extension = 0 ? ~ .depth == .newdepth ?
		je	.13done		; jne	.13done
		imul	edx, esi, -PawnValueEg
.13done0:
		call	SeeTestGe.HaveFromTo
		test	eax, eax
		jz	.MovePickLoop
.13done:
  end if	;(RootNode = 0 & USE_MATEFINDER = 0)

    ; Check for legality just before making the move
  if RootNode = 0
		call	Move_IsLegal
		jz	.MovePickLoop	; .IllegalMove	;uses eax flags
		add	dword[rbx+State.moveCount], 1
	if SUFFLEMOVE = 100 
		xor	edi, edi
		cmp	ecx, dword[.sufflemove]
		je	.MovePickLoop	; .testSuffling
	end if
  else
		add	dword[rbx+State.moveCount], 1
  end if

    ; replacing prefetch on Move_Do
    ; Step 14. Make the move
		call	Move_Do__Search
		jz	.17entry	; uses flags
		shl	r14d, 6		; r14d = from piece shl 6
		add	r14d, r9d
		; r14 = moved_piece_to_sq	= index	of [moved_piece][to_sq(move)]
		mov	eax, r14d
		shl	eax, 2+4+6
		add	rax, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx-1*sizeof.State+State.counterMoves], rax
		mov	edi, r15d		; r15d = .reduction	save to edi
		xor	r15, r15		; skipEarlyPruning = 0
    ; Step 15. Reduced depth search (LMR)
		mov	ecx, dword[rbx-1*sizeof.State+State.moveCount]
		cmp	ecx, 1			; .moveCount = 1 ?
  if PvNode = 1
		jbe	.DoFullPvSearch
  else
		jbe	.15skip
  end if
		cmp	esi, 3*ONE_PLY
		jl	.15skip
		test	r13d, 0xff0000		; .captureOrPromotion = 0 ?
		jz	.15NotCaptureOrPromotion
		test	r13d, 0xff000000	; .moveCountPruning = 0 ?
		jz	.15skip
if RootNode = 0
		cmp	dword[rbx-2*sizeof.State+State.history], r15d
		adc	rdi, r15
end if
		dec	edi	;sub	edi, 1
		cmovs	edi, r15d
;or
;		lea	eax, [rdi-1]
;		test	edi, edi
;		cmovnz	edi, eax
		jmp	.15ReadyToSearch

.15NotCaptureOrPromotion:
    ; r13l = newdepth
    ; r14d = moved_piece_to_sq
    ; r15d = 0
    ; ecx = moveCount

    ; Decrease reduction if opponent's move count is high
  if RootNode = 0
		mov	ecx, 15
		cmp	ecx, dword[rbx	- 2*sizeof.State + State.moveCount]
	  if PvNode = 1
		sbb	edi, dword[.pvExact]
	  else
		sbb	edi, r15d
	  end if
  else
		sub	edi, dword[.pvExact]
  end if
    ; Increase reduction if ttMove is a	capture
		add	edi, dword[.ttCapture]
		mov	ecx, dword[rbx-1*sizeof.State+State.currentMove]		; .move
    ; Increase reduction for cut nodes
  if PvNode = 0
		cmp	byte[.cutNode],  r15l		; PvNode = 1 ---> .cutNode=0
		jz	.15testA
		add	edi, 2*ONE_PLY
		jmp	.15skipA
.15testA:
  end if
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	.15skipA
		mov	eax, r14d
		and	eax, 7 shl 6
		cmp	eax, King  shl 6
		jne	.15lanjut
		cmp	qword[rbx-1*sizeof.State+State.checkersBB], r15
		jne	.15add2ply
		jmp	.15skipA
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
		mov	r9, qword[.CMH-1*sizeof.State]
		mov	r10, qword[.FMH-1*sizeof.State]
		mov	r11, qword[.FMH2-1*sizeof.State]
		mov	eax, r14d		; from piece (shl 6 + tosq)
		and	ax, 0x200	;shr	eax, 6+3		; Pos.sideToMove before move_do -> equal to = mov eax, dword[rbp+Pos.sideToMove]; xor eax, 1
		shl	eax, 5		;shl	eax, 12+2
		add	rax, qword[rbp+Pos.history]
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
		xor	ecx, ecx
		sub	edi, eax
		cmovs	edi, ecx
.15ReadyToSearch:
		mov	eax, 1
		mov	edx, r12d		; .alpha
		movsx	r8d, r13l		; .newDepth
		sub	r8d, edi
		cmp	r8d, eax
		cmovl	r8d, eax
		mov	edi, r8d
		neg	edx
		lea	ecx, [rdx-1]
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
	     calign   8		;addition arif
.15skip:
    ; Step 16. full depth search   this is for when step 15 is skipped
		mov	eax, r13d
		movsx	r8d, al			; .newDepth
		movsx	eax, ah			; .givesCheck
		inc	eax
		cmp	r8d, r15d
		cmovl	r8d, r15d
		lea	ecx, [rax+2]		; mov	r10d, 16
		cmovg	eax, ecx		; cmovle r10d, r15d
  if PvNode = 0
		movzx	r9d, byte[.cutNode]
		not	r9d
  else
		xor	r9, r9
  end if
		mov	edx, r12d	;dword[.alpha]
		neg	edx
		lea	ecx, [rdx-1]
		mov	rax, [TableQsearch_NonPv+rax*8]		;8byte
		call	rax
		neg	eax
  if PvNode = 1
		cmp	eax, r12d	;dword[.alpha]
		jle	.17entry
.beforeDoFullPvSearch:
	if RootNode	= 0
		cmp	eax, dword[.beta]
		jge	.17entry
	end if
.DoFullPvSearch:
		xor	r9, r9
		mov	dword[.pv], r9d		; zero fill pv
		mov	eax, r13d
		movsx	r8d, al			; .newDepth
		movsx	eax, ah			; .givesCheck
		inc	eax
		cmp	r8d, r9d
		cmovl	r8d, r9d
		lea	ecx, [rax+2]	; mov	ecx, 16
		cmovg	eax, ecx	; cmovle ecx, r9d
		mov	rax,[TableQsearch_Pv+rax*8]
		mov	ecx, dword[.beta]
		mov	edx, r12d	; dword[.alpha]
		neg	edx
		neg	ecx
		call	rax
		neg	eax
  end if	;PvNode = 1
    ; Step 17. Undo move
.17entry:
		mov	edi, eax
		call	Move_Undo

    ; Step 18. Check for new best move
		xor	eax, eax
		cmp	al, byte[signals.stop]
		jne	.Return
		mov	ecx, dword[rbx+State.currentMove]	; .move
  if RootNode =	1
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		;lea   rdx, [rdx-sizeof.RootMove]
		sub	rdx, sizeof.RootMove
.FindRootMove:
		add	rdx, sizeof.RootMove
		;lea   rdx, [rdx+sizeof.RootMove]
	     Assert   b, rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender], 'cant	find root move'
		cmp	ecx, dword[rdx+RootMove.pv+4*0]
		jne	.FindRootMove
		mov	r9d, 1
		mov	r10d,	-VALUE_INFINITE
		cmp	r9d, dword[rbx+State.moveCount]
		 je	.FoundRootMove1
		cmp	edi, r12d	;dword[.alpha]
		jle	.FoundRootMoveDone
	    _vmovsd	xmm0,	qword[rbp-Thread.rootPos+Thread.bestMoveChanges]
	    _vaddsd	xmm0,	xmm0, qword[constd._1p0]
	    _vmovsd	qword[rbp-Thread.rootPos+Thread.bestMoveChanges],	xmm0
.FoundRootMove1:
		mov	r10d,	edi
		lea	r8, [.pv-4]
		movzx	eax, byte[rbp-Thread.rootPos+Thread.selDepth]
		mov	dword[rdx+RootMove.selDepth],	eax
		jmp	@2f
    @1:
		mov	dword[rdx+RootMove.pv+4*r9],	eax
		inc	r9
    @2:
		mov	eax, dword[r8+4*r9]
	       test	eax, eax
		jnz	@1b
		mov	dword[rdx+RootMove.pvSize], r9d
.FoundRootMoveDone:
		mov	dword[rdx+RootMove.score], r10d
  else
	if SUFFLEMOVE >= 1
.testSuffling:
	end if

  end if
    ; check for new best move
		cmp	di, word[.ltte+MainHashEntry.value_]
		jle	.18NoNewBestValue
		mov	word[.ltte+MainHashEntry.value_], di
		cmp	edi, r12d	;dword[.alpha]
		jle	.18NoNewAlpha
		mov	word[.ltte+MainHashEntry.move], cx
  if PvNode = 0
		; failhigh
		jmp	.MovePickDone
  else
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
		cmp	edi, dword[.beta]
		jge	.MovePickDone
		mov	r12d, edi	;dword[.alpha], edi
		jmp	.MovePickLoop
  end if
	     calign   8
.18NoNewAlpha:
.18NoNewBestValue:
		; ecx = move
		test	r13d, 0xff0000			; .captureOrPromotion = 0?
		jnz	@1f
		mov	eax, dword[.quietCount]
		cmp	eax, 64
		jae	.MovePickLoop
		mov	dword[.quietsSearched+4*rax],	ecx
		inc	eax
		mov	dword[.quietCount], eax
		jmp	.MovePickLoop
    @1:
		mov	eax, dword[.captureCount]
		cmp	eax, 32
		jae	.MovePickLoop
		mov	dword[.capturesSearched+4*rax], ecx
		inc	eax
		mov	dword[.captureCount],	eax
		jmp	.MovePickLoop
	     calign   8		;addition arif
.EndCycle:
    ; Step 20. Check for mate and stalemate
		xor	edx, edx
		movsx	edi, word[.ltte+MainHashEntry.value_]
		movzx	ecx, word[.ltte+MainHashEntry.move]
		cmp	dword[rbx+State.moveCount], edx
		jne	.MovePickDone	;1
	if PvNode = 0
		cmp	dword[rbx+State.excludedMove], edx
		cmovne	edi, r12d	;dword[.alpha]
		jne	.ReturnBestValue
	end if
		movzx	edi, byte[rbx+State.ply]
		sub	edi, VALUE_MATE
		cmp	rdx, qword[rbx+State.checkersBB]
		cmove	edi, edx
		jmp	.20TTStoreSave
	     calign   8		;addition arif
.MovePickDone:
	; fail high r15 = 0, eax = 0
	; edi .bestValue
	; ecx .bestMove
	; r13d flags
;		mov	eax, dword[rbx+State.history]
;		cmp	eax, r15d
;		cmovl	eax, r15d
;		mov	dword[rbx+State.history],eax

;.MovePickDone1:
		mov	r15d, dword[.success]
		mov	eax, esi		; .depth harus esi
		imul	eax, eax
		lea	r10d, [rax+2*rsi-2]
		xor	edx,edx
		cmp	esi, 17
		cmovg	r10d, edx
		;29dd+138*d-134
    ; r15d = offset of [piece_on(prevSq),prevSq]
    ; ecx = move
    ; esi = depth
    ; r10d = bonus
		test	ecx, ecx
		jz	.20CheckBonus
;.20Quiet:
	if PvNode = 1
		mov	eax, ecx
		mov	edx, eax
		and	eax, 63
		shr	edx, 14
		movzx	eax, byte[rbp+Pos.board+rax]
		or	al, byte[_CaptureOrPromotion_or+rdx]
		test	al, byte[_CaptureOrPromotion_and+rdx]
	else
		test	r13d, 0xff0000			; .captureOrPromotion = 0?
;		cmp	byte[rbx+State.captureOrPromotion], 0
	end if
		jnz	.20Quiet_UpdateCaptureStats
		UpdateStats	ecx, .quietsSearched, dword[.quietCount], r11d, r10d, r15
		jmp	.20Quiet_UpdateStatsDone
.20Quiet_UpdateCaptureStats:
		;added====================================================================
		xor	eax, eax
		cmp	rax, qword[rbx+State.checkersBB]
		jne	.20Quiet_UpdateStatsDone
		;
		UpdateCaptureStats	ecx, .capturesSearched, dword[.captureCount],	r11d, r10d
.20Quiet_UpdateStatsDone:
		cmp	dword[rbx-1*sizeof.State+State.moveCount], 1
		jne	.20TTStore
		cmp	byte[rbx+State.capturedPiece], 0
		jne	.20TTStore
		lea	r10d, [r10+2*(rsi+1)+1]
    ; r10d = penalty
		cmp	r10d,	324
		jae	.20TTStore
		imul	r11d,	r10d, -32
		jmp	.20TTBeforeStore
	     calign   8		;addition arif
.20CheckBonus:
    ; we already checked that bestMove = 0
	if PvNode = 0
;		cmp	dword[rbx+State.excludedMove], ecx
;		jne	.ReturnBestValue
		mov	eax, dword[rbx-1*sizeof.State+State.currentMove]
		dec	eax
		lea	edx, [rsi-3*ONE_PLY]
		or	edx, eax
		js	.20TTStore
	end if
		cmp	byte[rbx+State.capturedPiece], cl	;0
		jne	.20TTStore
		cmp	r10d,	324
		jae	.20TTStore
		imul	r11d,	r10d, 32
.20TTBeforeStore:
		UpdateCmStats	(rbx-1*sizeof.State),	r15, r11d, r10d, r8
.20TTStore:
    ; edi = bestValue
if PvNode = 0
		cmp	dword[rbx+State.excludedMove],0
		jnz	.ReturnBestValue
end if
.20TTStoreSave:
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[.posKey]
		mov	edx, edi
		lea	eax, [rdi+VALUE_MATE_IN_MAX_PLY]
		cmp	eax, 2*VALUE_MATE_IN_MAX_PLY
		jae	.20ValueToTT
.20ValueToTTRet:
		movzx	eax, word[.ltte+MainHashEntry.move]
  if PvNode = 0
		xor	r10d, r10d
		cmp	edi, r12d	;dword[.beta]
		setg	r10l		;setge
		;add	r10d, BOUND_UPPER
		inc	r10d
  else
		mov	ecx, BOUND_LOWER
		cmp	eax, 1
		sbb	r10d, r10d
		lea	r10d, [(BOUND_EXACT-BOUND_UPPER)*r10+BOUND_EXACT]
		cmp	edi, dword[.beta]
		cmovge	r10d, ecx
  end if
	; sil = .depth
	MainHash_Save   .ltte, r8, r9w, edx, r10l, sil, eax, word[rbx+State.staticEval]	
.ReturnBestValue:
.Return_edi_Value:
		mov	eax, edi
.Return:
Display	2, "Search returning %i0%n"
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
if RootNode =	0
	     calign   8		;addition arif
.ValueFromTT:
		movzx	r8d, byte[rbx+State.ply]
		mov	r9d, edi
		sar	r9d, 31
		xor	r8d, r9d
		add	edi, r9d
		sub	edi, r8d
		mov	word[.ltte+MainHashEntry.value_], di	; .ttValue converted
		jmp	.ValueFromTTRet
end if

  if PvNode = 0
	 calign   8
.ReturnTTValue:
; If ttMove is quiet, update move sorting heuristics on TT hit
    ; edi = ttValue
		test	ecx, ecx			; .ttmove
		jz	.Return_edi_Value
		mov	eax, esi			; .depth
		imul	eax, eax
		lea	r10d,	[rax+2*rsi-2]
    ; esi = depth
    ; r10d = bonus
		mov	eax, ecx
		mov	edx, eax
		and	edx, 63
		shr	eax, 14
		mov	dl, byte[rbp+Pos.board+rdx]
		or	dl, byte[_CaptureOrPromotion_or+rax]
		and	dl, byte[_CaptureOrPromotion_and+rax]
    ; dl = capture or promotion
    ; ttMove is	quiet; update move sorting heuristics on TT hit
		cmp	edi, r12d			;dword[.beta]
		jle	.ReturnTTValue_Penalty		;jl
		mov	eax, dword[rbx-1*sizeof.State+State.currentMove]
		and	eax, 63
		movzx	r15d, byte[rbp+Pos.board+rax]
		shl	r15d, 6
		add	r15d, eax
    ; r15d = offset of [piece_on(prevSq),prevSq]
	       test	dl, dl
		jnz	.ReturnTTValue_UpdateCaptureStats
	UpdateStats	ecx,	0, 0, r11d, r10d, r15
	;UpdateStats	r12d,	0, 0, r11d, r10d, r15
;		jmp   .ReturnTTValue_UpdateStatsDone
.ReturnTTValue_UpdateCaptureStats:
;Extra penalty for a quiet TT move in previous ply when it gets refuted
;UpdateCaptureStats   r12d, 0, 0, r11d,	r10d
;.ReturnTTValue_UpdateStatsDone:
    ; r10d = penalty
		cmp	dword[rbx-1*sizeof.State+State.moveCount], 1
		jne	.Return_edi_Value
		cmp	byte[rbx+State.capturedPiece], 0
		jne	.Return_edi_Value
		lea	r10d,	[r10+2*(rsi+1)+1]
		cmp	r10d,	324
		jae	.Return_edi_Value
		imul	r11d,	r10d, -32	;	       imul   bonus32, absbonus, 32
	UpdateCmStats	(rbx-1*sizeof.State),	r15, r11d, r10d, r8
		jmp	.Return_edi_Value
	     calign   8		;addition arif
.ReturnTTValue_Penalty:
		test	dl, dl
		jnz	.Return_edi_Value
    ; r8 = offset in history table
		cmp	r10d,	324
		jae	.Return_edi_Value
		imul	r11d,	r10d, -32
		;Penalty for a quiet ttMove that fails low
		and	ecx, (64*64)-1
		mov	r9d, ecx
		mov	r8d, dword[rbp+Pos.sideToMove]
		shl	r8d, 12+2
		add	r8, qword[rbp+Pos.history]
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
  end if
	 calign   8
.20ValueToTT:
		movzx	edx, byte[rbx+State.ply]
		mov	eax, edi
		sar	eax, 31
		xor	edx, eax
		sub	edx, eax
		add	edx, edi
		jmp	.20ValueToTTRet
  if RootNode = 0
	 calign   8
.resetMovePick:
		lea	r14, [MovePick_CAPTURES_GEN]
		lea	rcx, [MovePick_ALL_EVASIONS]
		cmp	rax, qword[rbx+State.checkersBB]
		cmovne	r14, rcx
		mov	dword[.ttCapture], eax
	if PvNode =	1
		mov	dword[.pvExact], eax
	end if
		mov	rax, 0xffffffff00000000
		and	rdi, rax
		jmp	.skipsingular
    if USE_SYZYGY
	     calign   8
.CheckTablebase:
Display	2,"Info String second phase before DoTbProbe %i0%n"
	; get a	count of the piece for tb
		mov	rax, qword[rbx+State.Occupied]
		_popcnt	rax, rax,	r8
		cmp	eax, dword[Tablebase_Cardinality]
		jg	.CheckTablebaseReturn
		cmp	esi, dword[Tablebase_ProbeDepth]	; esi .depth
		jge	.DoTbProbe
		cmp	eax, dword[Tablebase_Cardinality]
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
		movsx	ecx, byte[Tablebase_UseRule50]
		lea	edx, [2*rax]
		and	edx, ecx
		mov	edi, edx
		mov	r8d, -VALUE_MATE + MAX_PLY
		movzx	r9d, byte[rbx+State.ply]
		add	r9d, r8d
		cmp	eax, ecx
		cmovl	edx, r8d
		cmovl	edi, r9d
		neg	ecx
		mov	r8d, VALUE_MATE -	MAX_PLY
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
		xor	eax, eax
      MainHash_Save   .ltte, r8, r9w, edx, BOUND_EXACT,	sil, eax, VALUE_NONE
	
		mov	eax, edi
		jmp	.Return
    end if
  end if
  if USE_CURRMOVE = 1 &	VERBOSE	< 2 & RootNode = 1
	 calign   8
.PrintCurrentMove:
		mov	dword[rbx+State.currentMove],	ecx		; save .move
		lea	rdi, [Output]
		mov	edx, dword[rbx+State.moveCount]
		inc	edx						; added after legal
		add	edx, dword[rbp-Thread.rootPos+Thread.PVIdx]
		push	rdx rdx rcx rsi					; esi = .depth ecx = .move
		lea	rcx, [sz_format_currmove]
		mov	rdx, rsp
		xor	r8, r8
		call	PrintFancy
		pop	rax rax rax rax
		call	WriteLine_Output
		mov	ecx, dword[rbx+State.currentMove]		; load .move
		jmp	.PrintCurrentMoveRet
  end if
end macro
