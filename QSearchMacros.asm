
macro QSearch PvNode, InCheck
        ; in:
        ;  rbp: address of Pos struct in thread struct
        ;  rbx: address of State
        ;  ecx: alpha
        ;  edx: beta
        ;  r8d: depth


virtual at rsp
	.ttDepth		rd 1	;4=8
	.oldAlpha		rd 1	;4
	.beta			rd 1	;4=8
	.depth			rd 1	;4
if PvNode = 1
  ._pv		   rd MAX_PLY+1
end if

  .lend rb 0

end virtual
.localsize = ((.lend-rsp+15) and (-16))
.ltte	equ (rbx+State.ltte)

	       push   rsi rdi r12 r13 r14 r15
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

if PvNode = 1
  if InCheck = 1
Display 2, "QSearch<1,1>(alpha=%i1, beta=%i2, depth=%i8) called%n"
  else
Display 2, "QSearch<1,0>(alpha=%i1, beta=%i2, depth=%i8) called%n"
  end if
else
  if InCheck = 1
Display 2, "QSearch<0,1>(alpha=%i1, beta=%i2, depth=%i8) called%n"
  else
Display 2, "QSearch<0,0>(alpha=%i1, beta=%i2, depth=%i8) called%n"
  end if
end if

		xor	eax, eax
		movzx	esi, cx
		mov	r13d, edx
		mov	dword[.depth], r8d
             Assert   le, r8d, 0, 'assertion depth<=0 failed in qsearch'

	if PvNode = 1
		lea	r9, [._pv]
		mov	qword[rbx+1*sizeof.State+State.pv], r9
		mov	r9, qword[rbx+State.pv]
		mov	dword[r9], eax
		mov	dword[.oldAlpha], ecx
	end if

		;eax = DEPTH_QS_CHECKS
	if InCheck = 1
		mov	dword[.ttDepth], eax
		if PvNode = 0
			mov   r12d, eax
		end if
	else
		mov	r12d, DEPTH_QS_NO_CHECKS
		cmp	r8d, eax
		cmovge	r12d, eax
		mov	dword[.ttDepth], r12d
	end if
	; transposition table lookup

		call	MainHash_Probe
		mov	qword[.ltte], rcx
		mov	rdi, rcx
		sar	rdi, 48				; MainHashEntry.value_ 48-16=32
		test	edx, edx			; .ttHit
		jz	.DontReturnTTValue
		cmp	edi, VALUE_NONE
		je	.DontReturnTTValue
		lea	r8d, [rdi+VALUE_MATE_IN_MAX_PLY]
		cmp	r8d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ValueFromTT		;ecx,edx standpat
.ValueFromTTRet:
	if PvNode = 0
		movsx	eax, ch			;.ttdepth
		sub	r12d, 1
		sub	r12d, eax
		sar	r12d, 31
	; r12d = 0 if tte.depth <  ttDepth
	;      =-1 if tte.depth >= ttDepth
		mov	eax, edi
		sub	eax, r13d		;dword[.beta]
		sar	eax, 31
	; eax = 0 if ttValue<beta
	;     =-1 if ttvalue>=beta
		add	eax, 2
	; eax = 2 if ttValue<beta     ie BOUND_UPPER
	;     = 1 if ttvalue>=beta    ie BOUND_LOWER
		and	eax, r12d
	       test	al, cl				; byte[.ltte+MainHashEntry.genBound]
		mov	eax, edi
		jnz	.Return
	end if
.DontReturnTTValue:
	; Evaluate the position statically
if InCheck = 1
		mov	dword[rbx+State.staticEval], VALUE_NONE
		mov	r12d, 0x82FF				; .bestValue (-VALUE_INFINITE) +.moveCount
else
		or	r15l, byte[rbx+State.flags]
		test	r15l,JUMP_IMM_6	or JUMP_IMM_2		; .ttHit
		jz	.StaticValueNoTTHit
		mov	r14, rcx
		mov	eax, dword[rbx+State.staticEval]
		test	r15l, JUMP_IMM_2
		jnz	.improving_eval
;=====YesTTHit:======
		sar	rcx, 32
		movsx	eax, cx					; word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		jne	@f
.StaticValueNoTTHit:
		call	Evaluate
	@@:
		mov	dword[rbx+State.staticEval], eax
	
	.improving_eval:
		cmp	edi, VALUE_NONE
		je	.StaticValueDone
		cmp	edi, eax
	       setg	cl
		inc	ecx
	; ecx = 2 if ttValue > bestValue   ie BOUND_LOWER
	;     = 1 if ttValue <=bestValue   ie BOUND_UPPER
	       test	cl, r14l				; byte[.ltte+MainHashEntry.genBound]
	     cmovnz	eax, edi

.StaticValueDone:
		or	byte[rbx+State.flags], JUMP_IMM_2
		movzx	r12d, ax
	; Return immediately if static value is at least beta
    if PvNode = 1
		cmp	eax, r13d		;dword[.beta]
		jge	.ReturnStaticValue
		cmp	si, ax
		cmovl	si, ax
    else
		cmp	ax, si
		jg	.ReturnStaticValue
    end if
		add	eax, 128
		shl	eax, 16
		or	r12d, eax				; .bestValue +.futilityBase
end if ; InCheck = 1

	; initialize move picker
		movzx	ecx, word[.ltte+MainHashEntry.move]
	if InCheck = 1
		lea	r15, [MovePick_ALL_EVASIONS]
		lea	r14, [MovePick_EVASIONS]
	else
		lea	r15, [MovePick_QCAPTURES_CHECKS_GEN]
		lea	r14, [MovePick_QSEARCH_WITH_CHECKS]
		mov	edx, dword[.depth]
		cmp	edx, DEPTH_QS_NO_CHECKS
		 jg	.MovePickInitGo
		mov	dword[rbx+State.endBadCaptures], edx		; .depthQs
		lea	r15, [MovePick_QCAPTURES_NO_CHECKS_GEN]
		lea	r14, [MovePick_QSEARCH_WITHOUT_CHECKS]
		cmp	edx, DEPTH_QS_RECAPTURES
		 jg	.MovePickInitGo
		mov	eax, dword[rbx-1*sizeof.State+State.currentMove]
		and	eax, 63
		mov	dword[rbx+State.endBadCaptures+4], eax		; .recaptureSquare
		xor	edx, edx
		mov	r10d, ecx
		and	r10d, 63					; r13d = to
		cmp	r10d, eax
		cmovne	ecx, edx
	end if
    .MovePickInitGo:
		test	ecx, ecx
		jz	.MovePickNoTTMove
		call	Move_IsPseudoLegal
;		test	rax, rax
		cmovz	ecx, eax
		cmovnz	r15, r14
    .MovePickNoTTMove:
		mov	dword[rbx+State.ttMove], ecx
		mov	dword[.beta], r13d
		mov	rax, r15
		jmp	.Pickcaller

;konsep rdi = move, r12 = .bestValue

	     calign   8
.MovePickLoop:
	GetNextMove .Pickcaller
		 jz	.MovePickDone	;uses flags

	; check for check and get address of search function
		call	Move_GivesCheck
		; out: r9d = to & r8d = from, ecx stand as move
		mov	byte[rbx+State.givesCheck], al
		lea	edi,[rax+1]

		movzx	r14d, byte[rbp+Pos.board+r8]     ; r14d = from piece
		movzx	r15d, byte[rbp+Pos.board+r9]     ; r15d = to piece

		; futility pruning
	if InCheck = 0
		test	edi, edi			; move_is_check?
		jz	.SkipFutilityPruning		; yes check
		cmp	r12d, (-VALUE_KNOWN_WIN) shl 16	; .futilityBase
		jle	.SkipFutilityPruning
		mov	edx, r14d
		and	edx, 7
		cmp	edx, Pawn
		 je	.CheckAdvancedPawnPush
.DoFutilityPruning:
		mov	r13d, r12d			; .futilityBase
		sar	r13d, 16
		mov	edx, dword[PieceValue_EG+4*r15]
		add	edx, r13d
		cmp	dx, si
		jle	.ContinueFromFutilityValue
		cmp	r13w, si
		jle	.ContinueFromFutilityBase
.SkipFutilityPruning:
		test	ecx, 0xFFFFF000
		jnz	.DontSeeTest
	else
		; Detect non-capture evasions that are candidates to be pruned
		test	ecx, 0xFFFFF000
		jnz	.DontSeeTest
		cmp	r12w, VALUE_MATED_IN_MAX_PLY
		jle	.DontSeeTest
		test	r15d, r15d
		jnz	.DontSeeTest
		mov	eax, r12d		; .moveCount shl 16
		shr	eax, 16
		or	eax, dword[.depth]
		jz	.DontSeeTest
	end if	;InCheck = 0
		SeeSignTestQSearch	.DontSeeTest 
		test	eax, eax
		jz	.MovePickLoop

.DontSeeTest:
	; check for legality
		call	Move_IsLegal
		jz	.MovePickLoop
if InCheck = 1
		add	r12d, 0x10000
end if

		mov	r14d, ecx		; .move
	; make the move
		call	Move_Do__QSearch
		jz	.DontdoSearch		;flags
	; search the move
		movsx	edx, si
		neg	edx
		mov	r8d, dword[.depth]

		sub	r8d, 1
	if PvNode = 1
		mov	ecx, dword[.beta]
		neg	ecx
		mov	rdi,[TableQsearch_Pv+rdi*8]
	else
		lea	ecx, [rdx-1]
		mov	rdi,[TableQsearch_NonPv+rdi*8]
	end if
		xor	r15,r15
		call	rdi
		neg	eax
.DontdoSearch:
	; undo the move
		mov	edi, eax
	       call	Move_Undo
	; check for new best move
		cmp	di, r12w		; .bestValue
		jle	.MovePickLoop
		mov	r12w, di
		cmp	di, si
		jle	.MovePickLoop

if PvNode = 1
		lea	r9, [._pv-4]
		mov	r8, qword[rbx+State.pv]
		mov	dword[r8], r14d		; .move
		mov	edx, 1
    @1:
		mov	eax, dword[r9+rdx*4]
		mov	dword[r8+rdx*4], eax
		inc	edx
		test	eax, eax
		jnz	@1b

		cmp	edi, dword[.beta]
		jge	.FailHigh
		shl	r14d, 16
		or	r14w, di
		mov	esi, r14d		; .bestMove + .alpha
		jmp	.MovePickLoop
.FailHigh:
end if
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[rbx+State.key+6]
		mov	edx, edi
		lea	eax, [rdx+VALUE_MATE_IN_MAX_PLY]
		cmp	eax, 2*VALUE_MATE_IN_MAX_PLY
		jae	.FailHighValueToTT
.FailHighValueToTTRet:
		mov	eax, r14d		; .move
      MainHash_Save   .ltte, r8, r9w, edx, BOUND_LOWER, byte[.ttDepth], eax, word[rbx+State.staticEval]
		mov	eax, edi
		jmp	.Return

.FailHighValueToTT:
;		movzx	ecx, byte[rbx+State.ply]
;		mov	eax, edx
;		sar	eax, 31
;		xor	ecx, eax
;		sub	edx, eax
;		add	edx, ecx

	      movzx   edx, byte[rbx+State.ply]
		mov   eax, edi
		sar   eax, 31
		xor   edx, eax
		sub   edx, eax
		add   edx, edi
		jmp   .FailHighValueToTTRet


.MovePickDone:
if InCheck = 1
		cmp	r12w, -VALUE_INFINITE
		je	.MATE
end if
		shr	esi, 16			; .bestMove
		movsx	r12d, r12w		; .bestValue
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[rbx+State.key+6]
		mov	edx, r12d
		lea	ecx, [rdx+VALUE_MATE_IN_MAX_PLY]
                cmp	ecx, 2*VALUE_MATE_IN_MAX_PLY
                jae	.ValueToTT
.ValueToTTRet:
                mov	eax, esi		; .bestMove
  if PvNode = 0
      MainHash_Save	.ltte, r8, r9w, edx, BOUND_UPPER, byte[.ttDepth], eax, word[rbx+State.staticEval]
  else
		mov	r10d, dword[.oldAlpha]
		sub	r10d, r12d
		sar	r10d, 31
		and	r10d, BOUND_EXACT-BOUND_UPPER	;=2
		inc	r10d				;+1
      MainHash_Save	.ltte, r8, r9w, edx, r10l, byte[.ttDepth], eax, word[rbx+State.staticEval]
  end if
		mov	eax, r12d

             calign   8
.Return:
Display 2, "QSearch returning %i0%n"
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
if InCheck = 1
             calign   8
.MATE:
		movzx	eax, byte[rbx+State.ply]
                sub	eax, VALUE_MATE
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
end if

  if InCheck = 0
             calign   8
.CheckAdvancedPawnPush:
		mov	eax, r14d
		and	eax, 8
		neg	eax
		and	eax, 7 shl 3
		;mov	eax, dword[rbp+Pos.sideToMove]
		;imul	eax, 56		;colour*56
		xor	eax, r8d
		cmp	eax, SQ_A5
		jb	.DoFutilityPruning
		jmp	.SkipFutilityPruning
             calign   8
.ContinueFromFutilityBase:
		mov	edx, edi	; edx = VALUE_ZERO + 1 = edi
		call	SeeTestGe.HaveFromTo
		test	eax, eax
		jnz	.DontSeeTest	; .SkipFutilityPruning	;changed at 05-06-2018
		mov	edx, r13d			;dword[.futilityBase]
.ContinueFromFutilityValue:
                cmp	r12w, dx
              cmovl	r12w, dx
                jmp	.MovePickLoop

             calign   8
.ReturnStaticValue:
		test	r15l,JUMP_IMM_6	;ttHit
                jnz	.Return
                mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[rbx+State.key+6]
		mov	edx, eax
		lea	r10d, [rax+VALUE_MATE_IN_MAX_PLY]
		cmp	r10d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ReturnStaticValue_ValueToTT
.ReturnStaticValue_ValueToTTRet:
      MainHash_Save   .ltte, r8, r9w, edx, BOUND_LOWER, DEPTH_NONE, 0, word[rbx+State.staticEval]
                movsx	eax, r12w
                jmp	.Return
             calign   8
.ReturnStaticValue_ValueToTT:
		movzx	ecx, byte[rbx+State.ply]
		sar	eax, 31
		xor	ecx, eax
		sub	edx, eax
		add	edx, ecx
		jmp	.ReturnStaticValue_ValueToTTRet
  end if	;InCheck = 0
             calign   8
.ValueToTT:
		movzx	edx, byte[rbx+State.ply]
		mov	eax, r12d
		sar	eax, 31
		xor	edx, eax
		sub	edx, eax
		add	edx, r12d

;		movzx	ecx, byte[rbx+State.ply]
;		mov	eax, edx
;		sar	eax, 31
;		xor	ecx, eax
;		sub	edx, eax
;		add	edx, ecx

		jmp	.ValueToTTRet
             calign   8
.ValueFromTT:
		; value in edi is not VALUE_NONE
		movzx   r9d, byte[rbx+State.ply]
		mov	r8d, edi
		sar	r8d, 31
		xor	r9d, r8d
		add	edi, r8d
		sub	edi, r9d
                jmp	.ValueFromTTRet

end macro
