macro QSearch PvNode, InCheck 

virtual at rsp
	.ttDepth		rd 1	;1 ->dont change
	.depth			rd 1	;2 ->
	.oldAlpha		rd 1
	.beta			rd 1
if PvNode = 1
  ._pv		   rd MAX_PLY+1
end if

  .lend rb 0

end virtual
.localsize = ((.lend-rsp+15) and (-16))
.ltte	equ (rbx+State.ltte)
if PvNode = 0
localsizestackqsearch	= ((.lend-.ttDepth+15) and (-16))
end if
	       push   rsi rdi r12 r13 r14 r15
if PvNode = 1
	 _chkstk_ms   rsp, .localsize
end if
		sub   rsp, .localsize
		xor	eax, eax
		movzx	r12d, cx		; .alpha + .bestMove
if PvNode = 1
		mov	r13d, edx
end if
		mov	dword[.depth], r8d
             Assert   le, r8d, 0, 'assertion depth<=0 failed in qsearch'

	if PvNode = 1
		mov	r9, qword[rbx+State.pv]
		mov	dword[r9], eax
		mov	dword[.oldAlpha], ecx
	end if

		;eax = DEPTH_QS_CHECKS
	if InCheck = 1
		mov	dword[.ttDepth], eax
		if PvNode = 0
			mov   esi, eax
		end if
	else
		mov	esi, DEPTH_QS_NO_CHECKS
		cmp	r8d, eax
		cmovge	esi, eax
		mov	dword[.ttDepth], esi
	end if

if USE_GAMECYCLE = 1 & PvNode = 1
		cmp	r8d, eax
		jne	.1done
		cmp	r12d, eax
		jge	.1done
		cmp	r13d, eax
		jle	.1done
		mov	eax, dword[rbx+State.rule50]
		cmp	ah, 3
		jae	.has_game_cycle
	.1done:
end if

	; transposition table lookup
		call	MainHash_Probe.Main
if InCheck = 0 | PvNode = 0
.AfterHashProbe:
		mov	rdi, rcx
		sar	rdi, 48
		cmp	edi, VALUE_NONE
		je	.DontReturnTTValue
		lea	r8d, [rdi+VALUE_MATE_IN_MAX_PLY]
		cmp	r8d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ValueFromTT		;ecx,edx standpat
.ValueFromTTRet:
	if PvNode = 0
		movsx	eax, ch			;.ttdepth
		dec	esi			;sub	esi, 1
		sub	esi, eax
		sar	esi, 31
	; esi = 0 if tte.depth <  ttDepth
	;      =-1 if tte.depth >= ttDepth
		mov	ax, di
		sub	ax, r12w
		dec	ax
		sar	ax, 31-16
	; eax = 0 if ttValue<beta
	;     =-1 if ttvalue>=beta
		add	ax, 2
	; eax = 2 if ttValue<beta     ie BOUND_UPPER
	;     = 1 if ttvalue>=beta    ie BOUND_LOWER
		and	ax, si
	       test	al, cl				; byte[.ltte+MainHashEntry.genBound]
		mov	eax, edi
		jnz	.Return
	end if
.DontReturnTTValue:
	; Evaluate the position statically
end if
if InCheck = 1
		mov	word[.ltte+MainHashEntry.eval_], VALUE_NONE	; reset eval value
		mov	esi, 0x82FF				; .bestValue (-VALUE_INFINITE) +.moveCount
else
		movsx	eax, word[.ltte+MainHashEntry.eval_]
		cmp	eax, VALUE_NONE
		jne	@1f
		call	Evaluate
	@1:
		cmp	edi, VALUE_NONE
		je	.StaticValueDone
		cmp	edi, eax
	       setg	cl
		inc	ecx
	; ecx = 2 if ttValue > bestValue   ie BOUND_LOWER
	;     = 1 if ttValue <=bestValue   ie BOUND_UPPER
	       test	cl, byte[.ltte+MainHashEntry.genBound]
	     cmovnz	eax, edi

.StaticValueDone:
		movzx	esi, ax

	; Return immediately if static value is at least beta
    if PvNode = 1
		cmp	eax, r13d		;dword[.beta]
		jge	.ReturnStaticValue
		cmp	r12w, ax
		cmovl	r12w, ax
    else
		cmp	ax, r12w
		jg	.ReturnStaticValue
    end if
		add	eax, 128
		shl	eax, 16
		or	esi, eax				; .bestValue +.futilityBase
	if PvNode = 0
		lea	rax,[.skipnull]
		test	r15l, JUMP_IMM_2
		jnz	Search_NonPv.SetAttackOnNull
.skipnull:
	end if


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
		cmovz	ecx, eax
		cmovnz	r15, r14
    .MovePickNoTTMove:
if PvNode = 1
		lea	rax, [._pv]
		mov	qword[rbx+1*sizeof.State+State.pv], rax
		mov	dword[.beta], r13d
end if
		mov	dword[rbx+State.ttMove], ecx
		mov	rax, r15
		jmp	.Pickcaller
if InCheck = 1
		calign 8
.pruned:
		or	esi, 0x80000000
		jmp	.MovePickLoop
end if		
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
		cmp	esi, (-VALUE_KNOWN_WIN) shl 16	; .futilityBase
		jle	.SkipFutilityPruning
		mov	edx, r14d
		and	edx, 7
		cmp	edx, Pawn
		 je	.CheckAdvancedPawnPush
.DoFutilityPruning:
		mov	edx, dword[PieceValue_EG+4*r15]
		mov	r13d, esi			; .futilityBase
		sar	r13d, 16
		add	edx, r13d
		cmp	dx, r12w
		jle	.ContinueFromFutilityValue
		cmp	r13w, r12w
		jle	.ContinueFromFutilityBase
.SkipFutilityPruning:
if	0
		mov	edx, ecx
		shr	edx, 12
		lea	edx,[rdx-MOVE_TYPE_PROM]
		cmp	edx,4
		jb	.DontSeeTest
else
		test	ecx, 0xFFFFF000
		jnz	.DontSeeTest
end	if
	else
		; Detect non-capture evasions that are candidates to be pruned
		test	ecx, 0xFFFFF000
		jnz	.DontSeeTest
		cmp	si, VALUE_MATED_IN_MAX_PLY
		jle	.DontSeeTest
		test	r15d, r15d
		jnz	.DontSeeTest
		mov	eax, esi		; .moveCount shl 16
		sar	eax, 16+1
		or	eax, dword[.depth]
		jz	.DontSeeTest
	end if	;InCheck = 0
		SeeSignTestQSearch	.DontSeeTest 
		test	eax, eax
if InCheck = 1
		jz	.pruned
else
		jz	.MovePickLoop
end if
.DontSeeTest:
	; check for legality
		call	Move_IsLegal
		jz	.MovePickLoop
if InCheck = 1
		add	esi, 0x10000
end if

	; make the move
		call	Move_Do__QSearch
		jz	.DontdoSearch
	; search the move
		mov	r8d, dword[.depth]
		dec	r8d
		xor	r15,r15
	if PvNode = 1
		movsx	edx, r12w
		neg	edx
		mov	ecx, dword[.beta]
		neg	ecx
		mov	rax,qword[TableQsearch_Pv+rdi*8]
	else
		movsx	ecx, r12w
		neg	ecx
		dec	ecx
		mov	rax,qword[TableQsearch_NonPv+rdi*8]
	end if
		call	rax
		neg	eax
.DontdoSearch:
	; undo the move
		mov	edi, eax
	       call	Move_Undo
	       ;out	ecx = move
	; check for new best move
		cmp	di, si		; .bestValue
		jle	.MovePickLoop
		mov	si, di
		cmp	di, r12w
		jle	.MovePickLoop

if PvNode = 1
		cmp	edi, dword[.beta]
		jge	.FailHigh
		lea	r9, [._pv-4]
		mov	r8, qword[rbx+State.pv]
		mov	dword[r8], ecx		; .move
		mov	edx, 1
    @1:
		mov	eax, dword[r9+rdx*4]
		mov	dword[r8+rdx*4], eax
		inc	edx
		test	eax, eax
		jnz	@1b

		shl	ecx, 16
		or	cx, di
		mov	r12d, ecx		; .alpha + .bestMove
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
		mov	eax, ecx		; .move
      MainHash_Save   .ltte, r8, r9w, edx, BOUND_LOWER, byte[.ttDepth], eax, InCheck
		mov	eax, edi
		jmp	.Return
             calign   8
.FailHighValueToTT:
	      movzx   edx, byte[rbx+State.ply]
		mov   eax, edi
		sar   eax, 31
		xor   edx, eax
		sub   edx, eax
		add   edx, edi
		jmp   .FailHighValueToTTRet
             calign   8
.MovePickDone:
if InCheck = 1
		cmp	esi, 0x1ffff		; 0 or 1 but no pruned moves
		ja	@1f
		or	byte[rbx+State.pvhit], JUMP_IMM_8
		cmp	si, -VALUE_INFINITE
		je	.MATE
		@1:
else
		cmp	si, VALUE_MATE_THREAT
		je	.EvalMatethreat
.EvalMatethreatRet:
end if
		movsx	esi, si		; .bestValue
		mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[rbx+State.key+6]
		mov	edx, esi
		lea	ecx, [rdx+VALUE_MATE_IN_MAX_PLY]
                cmp	ecx, 2*VALUE_MATE_IN_MAX_PLY
                jae	.ValueToTT
.ValueToTTRet:
  if PvNode = 0
		MainHash_Save	.ltte, r8, r9w, edx, BOUND_UPPER, byte[.ttDepth], 0
  else
		shr	r12d, 16			; .bestMove
                mov	eax, r12d
		mov	r10d, dword[.oldAlpha]
		sub	r10d, esi
		sar	r10d, 31
		and	r10d, BOUND_EXACT-BOUND_UPPER	;=2
		inc	r10d				;+1
		MainHash_Save	.ltte, r8, r9w, edx, r10l, byte[.ttDepth], eax, InCheck
  end if
		mov	eax, esi
jmp	.Return
             calign   8
.Return:
Display 2, "QSearch returning %i0%n"
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
if InCheck = 1
             calign   8
.MATE:
		mov	r8, 0x83007D0200007F83
if	0
		mov	rax, qword[rbx+State.tte]
		mov	r11, rax
		shr	r11d, 3  -  1
		and	r11d, 3 shl 1
		neg	r11
		lea	r11, [8*3+3*r11]
		add	r11, rax
		movzx	ecx, word[r11]
		cmp	cx, word[rbx+State.key+6]
		jne	@1f
		mov	qword[rax], r8
		Display 2, "info string ada %n"
@1:
end if
		mov	qword[.ltte], r8
		mov	dword[.ltte-1*sizeof.State+MainHashEntry.eval_], 0x7cff7cff	;(((VALUE_MATE-1) shl 16) or (VALUE_MATE-1))
		movzx	eax, byte[rbx+State.ply]
                sub	eax, VALUE_MATE
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
end if
if InCheck = 0
             calign	8
.EvalMatethreat:
		cmp	si, word[.ltte+MainHashEntry.eval_]
		jne	.EvalMatethreatRet
		lea	eax, [r12d-1]
		cmp	ax, si
		cmovg	si, ax
		jmp	.EvalMatethreatRet
	     calign	8
.CheckAdvancedPawnPush:
		mov	eax, r14d
		and	eax, 8
		neg	eax
		and	eax, 7 shl 3
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
                cmp	si, dx
              cmovl	si, dx
                jmp	.MovePickLoop
             calign   8
.ReturnStaticValue:
		test	r15l,JUMP_IMM_6	+JUMP_IMM_2	;ttHit
                jnz	.Return
                mov	r8, qword[rbx+State.tte]
		mov	r9d, dword[rbx+State.key+6]
	MainHash_Save	.ltte, r8, r9w, 0, BOUND_NONE,	DEPTH_NONE, 0
		movsx	eax, si
                jmp	.Return
end if	;InCheck = 0
             calign   8
.ValueToTT:
		movzx	edx, byte[rbx+State.ply]
		mov	eax, esi
		sar	eax, 31
		xor	edx, eax
		sub	edx, eax
		add	edx, esi
		jmp	.ValueToTTRet
if InCheck = 0 | PvNode = 0
	     calign   8
.ValueFromTT:
		movzx   r9d, byte[rbx+State.ply]
	if	InCheck = 0
		cmp	edi, VALUE_MATE-1
		je	.ValueFromTTmod
	end if
		mov	r8d, edi
		sar	r8d, 31
		xor	r9d, r8d
		add	edi, r8d
		sub	edi, r9d
                jmp	.ValueFromTTRet
	if	InCheck = 0
	     calign   8
.ValueFromTTmod:
		;update depth?
		cmp	ch, 0
		jge	@1f
		mov	r8, qword[rbx+State.tte]
		mov	byte[r8+MainHashEntry.depth], 0
	@1:
		sub	edi, r9d
		mov	eax, edi
		add	rsp, .localsize
		pop	r15 r14 r13 r12 rdi rsi
		ret
	end if
end if
if USE_GAMECYCLE = 1 & PvNode = 1
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
;.hgcs_not_found:
		jmp	.1done	;1draw	;ret
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
		je	.1done

.hgcs_found:
		xor	r12d, r12d
		mov	dword[.oldAlpha], r12d
		jmp	.1done	;1draw	;ret
end if

end macro
