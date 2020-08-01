
Thread_Think:
	; in: rcx address of Thread struct

	       push   rbp rbx rsi rdi r13 r14 r15
virtual at rsp
 .timeReduction		rq 1
 .delta			rd 1
 .lastBestMove		rd 1
 .lastBestMoveDepth	rd 1
if	PrintFilter = 1
 .printedScore		rd 1
 .printedMove		rd 1
end if
 .lend	     rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))
	 _chkstk_ms   rsp, .localsize
		sub   rsp, .localsize

		lea	rbp, [rcx+Thread.rootPos]
		mov	rbx, qword[rbp+Pos.state]
		mov	rax, qword 1.0
if TRACE = 1
		mov	qword[Rootrbx], rbx
end if
		mov	qword[.timeReduction], rax
	; clear the search stack
if	Continuation_Five = 1
		lea	rdx, [rbx-8*sizeof.State]
else
		lea	rdx, [rbx-5*sizeof.State]
end if
		lea	r8, [rbx+3*sizeof.State]
		mov	r9d, CmhDeadOffset
		add	r9, qword[rbp+Pos.counterMoveHistory]
		xor	eax, eax
if	PrintFilter = 1
		mov	qword[.printedScore], rax
end if
.clear_stack:
		;avoid using string opcodes
		mov	qword[rdx+State.killers], rax
		mov	qword[rdx+State.currentMove], rax
		mov	qword[rdx+State.counterMoves], r9
		add	rdx, sizeof.State
		cmp	rdx, r8
		 jb	.clear_stack
		mov	dword[rbx-sizeof.State+State.moveCount], 0xffff00

;initialize variable
		mov	r13d, +VALUE_INFINITE		;.beta		= +VALUE_INFINITE
		mov	edi, -VALUE_INFINITE		;.bestValue	= -VALUE_INFINITE
		mov	r12d, edi			;.alpha		= -VALUE_INFINITE
		mov	word[rbx+State.ply], ax
		mov	byte[rbx+State.pvhit], 0x4	;+JUMP_IMM_7 ;'RootSearch Mark'

		mov	qword[.lastBestMove], rax	;+.lastBestMoveDepth
		mov	dword[.delta], edi
	; resets for main thread
		mov	qword[rbp-Thread.rootPos+Thread.bestMoveChanges], rax

	; set move list for current state
		mov	rax, qword[rbp+Pos.moveList]
		mov	qword[rbx-1*sizeof.State+State.endMoves], rax

	; set multiPV
		;RootMovesVec_Size
		mov	rax, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		sub	rax, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	ecx, sizeof.RootMove
		xor	edx, edx
		div	ecx

		mov	ecx, dword[options.multiPV]
		cmp	eax, ecx
		cmova	eax, ecx
		mov	r15d, eax			;.multiPV

        ; set initial contempt
		imul	eax, dword[options.contempt], PawnValueEg
                mov	ecx, 100
                cdq
		idiv	ecx
                mov	ecx, eax
                cdq
                sub	eax, edx
                sar	eax, 1
                shl	ecx, 16
                add	ecx, eax
                mov	eax, dword[rbp+Pos.sideToMove]
                neg	eax
                xor	ecx, eax
                sub	ecx, eax
                mov	dword[ContemptScore], ecx

;		mov   eax, dword[options.contempt]
;		cdq
;		imul  eax, PawnValueEg  ; options.contempt * PawnValueEg ---> [edx:eax]
;		mov   ecx, 100 
;		idiv  ecx               ; [edx:eax]/100 -->  EAX gets quotient, EDX gets remainder.
;		                        ; eax holds contempt value (ignore remainder in edx)
;		                        ; Next, we construct mg/eg contempt score
;		mov   ecx,eax           ; ecx represents mg value now (i.e., the contempt value just calculated)
;		shr   eax, 1            ; contempt / 2 => weaken the contempt for the endgame (eg value)
;		shl   ecx, 16           ; move mg contempt into upper 16 bits
;		add   ecx, eax          ; layer in eg value to get overall "Score"
;
;		mov   eax, dword[rbp+Pos.sideToMove]
;		test  eax, eax ;
;		jz   .save_contempt_score ; if white, save score as it currently is
;		
;		; black contempt scoring requires we negate the score first before saving it in ContemptScore
;		neg   ecx
;		
;.save_contempt_score:
;		mov dword[ContemptScore], ecx

	; id loop
;		mov   esi, dword[rbp-Thread.rootPos+Thread.rootDepth]	 ; this should be set to 0 by ThreadPool_StartThinking
		xor	esi, esi
.id_loop:
		xor   eax, eax
		mov   ecx, dword[limits.depth]
		cmp   eax, dword[rbp-Thread.rootPos+Thread.idx]
	     cmovne   ecx, eax
		sub   ecx, 1
		cmp   al, byte[signals.stop]
		jne   .id_loop_done
		cmp   esi, ecx
		 ja   .id_loop_done
		add   esi, 1
;		mov   dword[rbp-Thread.rootPos+Thread.rootDepth], esi
		cmp   esi, MAX_PLY
		jge   .id_loop_done

	; skip depths for helper threads
		mov   eax, dword[rbp-Thread.rootPos+Thread.idx]
		sub   eax, 1
		 jc   .age_out

		xor   edx, edx
		mov   ecx, 20
		div   ecx
	; edx = idx-1 after idx has been updated by edx=(idx-1)%+1
		xor   ecx, ecx
	.loopSkipPly:
		add   ecx, 1
		lea   eax, [rcx+1]
	       imul   eax, ecx
		cmp   eax, edx
		jbe   .loopSkipPly
		lea   eax, [rsi+rdx]
		add   eax, dword[rbp+Pos.gamePly]
		xor   edx, edx
		div   ecx
		sub   eax, ecx
	       test   eax, 1
		 jz   .id_loop
		jmp   .save_prev_score

.age_out:
	; Age out PV variability metric
	    _vmovsd   xmm0, qword[rbp-Thread.rootPos+Thread.bestMoveChanges]
	    _vmulsd   xmm0, xmm0, qword[constd._0p517]		;qword[constd._0p505]
	    _vmovsd   qword[rbp-Thread.rootPos+Thread.bestMoveChanges], xmm0

.save_prev_score:
	; Save the last iteration's scores before first PV line is searched and all the move scores except the (new) PV are set to -VALUE_INFINITE.
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
    .save_next:
		mov   eax, dword[rcx+RootMove.score]
		mov   dword[rcx+RootMove.prevScore], eax
		add   rcx, sizeof.RootMove
		cmp   rcx, rdx
		 jb   .save_next

if USE_WEAKNESS
	; if using weakness, reset multiPV local variable
		cmp   byte[weakness.enabled], 0
		 je   @f
		mov   r15d, dword[weakness.multiPV]	;dword[.multiPV], eax
	@@:
end if

	; MultiPV loop. We perform a full root search for each PV line
		or	r14d, -1
.multipv_loop:
		add	r14d, 1
		mov	al, byte[signals.stop]
		mov	dword[rbp-Thread.rootPos+Thread.PVIdx], r14d
		cmp	r14d, r15d		;.multiPV
		jae	.multipv_done
		test	al, al
		jnz	.multipv_done

        ; Reset UCI info selDepth for each depth and each PV line
                mov	byte[rbp-Thread.rootPos+Thread.selDepth], al

		cmp	esi, 5
		jl	.reset_window_done
		
	; Reset aspiration window starting size
		mov	edx, 18			;delta
		imul	r8d, r14d, sizeof.RootMove
		add	r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	eax, dword[r8+RootMove.prevScore]
		mov	r13d, eax
		mov	ecx, -VALUE_INFINITE
		sub	eax, edx
		cmp	eax, ecx
		cmovl	eax, ecx
		mov	r12d, eax		;.alpha
		neg	ecx		; mov	ecx, VALUE_INFINITE
		add	r13d, edx	; eax, edx
		cmp	r13d, ecx	; eax, ecx
		cmovg	r13d, ecx	; eax, ecx
		mov	dword[.delta], edx

        ; Adjust contempt based on current situation

;		edi	= .bestValue
		test	edi, edi
		setg	al
		movzx	eax, al
		mov	edx, edi
		shr	edx, 31
		sub	eax, edx
		mov	eax, edi
		sar	eax, 31
		mov	ecx, edi
		xor	ecx, eax
		sub	ecx, eax
		add	ecx, 200
		imul	eax, edi, 88
		cdq
		idiv	ecx
		mov	r8d, eax

		imul	eax, dword[options.contempt], PawnValueEg
		mov	ecx, 100
		cdq
		idiv	ecx
		add	eax, r8d
		mov	ecx, eax
		cdq
		sub	eax, edx
		sar	eax, 1
		shl	ecx, 16
		add	ecx, eax
		mov	eax, dword[rbp+Pos.sideToMove]
		neg	eax
		xor	ecx, eax
		sub	ecx, eax
		mov	dword[ContemptScore], ecx

    .reset_window_done:

	; Start with a small aspiration window and, in the case of a fail high/low,
        ; re-search with a bigger window until we're not failing high/low anymore.
.search_loop:
		call	Search_Root ; rootPos is in rbp, ss is in rbx
		mov	edi, eax
                mov	qword[rbp+Pos.state], rbx
		imul	ecx, r14d, sizeof.RootMove
		add	rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		call	RootMovesVec_StableSort

	; If search has been stopped, break immediately. Sorting and writing PV back to TT is safe because RootMoves is still valid, although it refers to the previous iteration.
		cmp	byte[signals.stop], 0
		jne	.search_done
	; When failing high/low give some update before a re-search.
		cmp	dword[rbp-Thread.rootPos+Thread.idx], 0
		jne	.dont_print_pv
		cmp	r15d, 1
		jne	.dont_print_pv
		cmp	edi, r12d	;.alpha
		jle	@f
		cmp	edi, r13d	;.beta
		jl	.dont_print_pv
	@@:
		call	Os_GetTime
		sub	rax, qword[time.startTime]
if VERBOSE = 0
		cmp	rax, 3000
		jle	.dont_print_pv
end if
		cmp	byte[limits.infinite],0		;addition 
		jne	.skipnoprint0
		mov	ecx,dword[options.minThinkTime]
		cmp	rax,rcx
		jb	.dont_print_pv
	.skipnoprint0:
if	PrintFilter = 1
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
                mov	ecx, dword[rdx+RootMove.score]
                mov	edx, dword[rdx+RootMove.pv]
		cmp	ecx, dword[.printedScore]
		jne	@1f
		cmp	edx, dword[.printedMove]
		je	.dont_print_pv
	@1:
		mov	dword[.printedScore], ecx
		mov	dword[.printedMove], edx
end if
;		esi	= .depth
;		r12d	= .alpha
;		r13d	= .beta
;		r15d	= .multiPV
		mov	r9, rax
		call	DisplayInfo_Uci
	.dont_print_pv:

	; In case of failing low/high increase aspiration window and re-search, otherwise exit the loop.
		mov	eax, dword[.delta]
		mov	r10d, eax
		cdq
		and	edx, 3
		add	eax, edx
		sar	eax, 2
		lea	r10d, [r10+rax+5]
	; r10d = delta + delta / 4 + 5
		lea	eax, [r12+r13]
		cdq
		sub	eax, edx
		sar	eax, 1
	; eax = (alpha + beta) / 2
		mov	edx, edi
		cmp	edi, r12d
		jle	.fail_low
		cmp	edi, r13d
		 jl	.search_done
    .fail_high:
		add	edx, dword[.delta]
		mov	ecx, VALUE_INFINITE
		cmp	edx, ecx
	      cmovg	edx, ecx
		mov	r13d, edx		;.beta
		mov	dword[.delta], r10d
		jmp	.search_loop
    .fail_low:
		sub	edx, dword[.delta]
		mov	ecx, -VALUE_INFINITE
		cmp	edx, ecx
	      cmovl	edx, ecx
		mov	r12d, edx		;.alpha
		mov	r13d, eax		;.beta
		mov	dword[.delta], r10d
		cmp	dword[rbp-Thread.rootPos+Thread.idx], 0
		jne	.search_loop
		mov	byte[signals.stopOnPonderhit], 0
		jmp	.search_loop
.search_done:
	; Sort the PV lines searched so far and update the GUI
		imul	edx, r14d, sizeof.RootMove
		mov	rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		lea	rdx, [rcx+rdx+sizeof.RootMove]
		call	RootMovesVec_StableSort

		cmp	dword[rbp-Thread.rootPos+Thread.idx], 0
		jne	.multipv_loop
		call	Os_GetTime
		mov	r9, rax
		sub	r9, qword[time.startTime]
		cmp	byte[signals.stop], 0
		jne	.print_pv2
		lea	eax, [r14+1]
		cmp	eax, r15d		;.multiPV
		je	.print_pv2
if VERBOSE = 0
		cmp	r9, 3000
		jle	.multipv_loop
end if
.print_pv2:
		cmp	byte[limits.infinite], 0
		jne	.skipnoprint
		cmp	r9d, dword[options.minThinkTime]
		jb	.multipv_loop
if	PrintFilter = 1
		mov	rdx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
                mov	ecx, dword[rdx+RootMove.score]
                mov	edx, dword[rdx+RootMove.pv]
		cmp	ecx, dword[.printedScore]
		jne	@1f
		cmp	edx, dword[.printedMove]
		je	.multipv_loop
	@1:
		mov	dword[.printedScore], ecx
		mov	dword[.printedMove], edx
end if

	.skipnoprint:
		mov	qword[time.lastPrint], r9
;		esi	= .depth
;		r12d	= .alpha
;		r13d	= .beta
;		r15d	= .multiPV
		call	DisplayInfo_Uci

if USE_WEAKNESS
		cmp	byte[weakness.enabled], 0
		je	.multipv_loop
		call	Weakness_SetMultiPV
end if
		jmp	.multipv_loop
	calign 8
.multipv_done:
		cmp	byte[signals.stop], 0
		jne	@1f
		mov	dword[rbp-Thread.rootPos+Thread.completedDepth], esi
	@1:
		mov	rax, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	eax, dword[rax+RootMove.pv+4*0]
		cmp	eax, dword[.lastBestMove]
		je	@1f
		mov	dword[.lastBestMove], eax
		mov	dword[.lastBestMoveDepth], esi
	@1:

	; Have we found a "mate in x"
	; not implemented
		cmp	dword[rbp-Thread.rootPos+Thread.idx], 0
		jne	.id_loop
	; edi = bestValue  remember
		cmp	byte[limits.useTimeMgmt], 0
		je	.id_loop
		mov	al, byte[signals.stop]
		or	al, byte[signals.stopOnPonderhit]
		jnz	.id_loop

    ; Stop the search if only one legal move is available, or if all
    ; of the available time has been used
		call	Os_GetTime
		sub	rax, qword[time.startTime]
		mov	r11, rax
	; r11 = Time.elapsed()

;          double fallingEval = (306 + 9 * (mainThread->previousScore - bestValue)) / 581.0;
		mov	ecx, dword[rbp-Thread.rootPos+Thread.previousScore]
		sub	ecx, edi
		lea	ecx, [9*rcx+306]
		_vcvtsi2sd	xmm3, xmm3, ecx
		_vmovsd		xmm0, qword[constd._581p0]
		_vdivsd		xmm3, xmm3, xmm0
;          fallingEval        = std::max(0.5, std::min(1.5, fallingEval));
		_vmovsd		xmm0, qword[constd._1p5]
		_vcomisd	xmm0, xmm3
		jae	.min_FE
		_vmovapd	xmm3, xmm0
.min_FE:
		_vmovsd		xmm0, qword[constd._0p5]
		_vcomisd	xmm0, xmm3
		jbe	.max_FE
		_vmovapd	xmm3, xmm0
.max_FE:
		; xmm3 = fallingEval

		_vmovsd		xmm2, qword[rbp - Thread.rootPos + Thread.bestMoveChanges]
		_vaddsd		xmm2, xmm2, qword[constd._1p0]
		; xmm2 = unstablePvFactor or bestMoveInstability

;          timeReduction = lastBestMoveDepth + 10 * ONE_PLY < completedDepth ? 1.95 : 1.0;

		_vcvtsi2sd	xmm1, xmm1, dword[.lastBestMoveDepth]
		_vmovsd		xmm0, qword[constd._1p95]
		cmp		esi, 10 *ONE_PLY
		jl	@1f
		_vmovsd		xmm0, qword[constd._1p0]
@1:
		_vaddsd		xmm0, xmm0, xmm1
		_vmovsd		qword[.timeReduction], xmm0


		mov	r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		add	r8, sizeof.RootMove
		cmp	r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		je	.set_stop

		_vmovsd		xmm4, qword[rbp - Thread.rootPos + Thread.previousTimeReduction]
		_vsqrtsd	xmm4, xmm4, xmm4
		_vdivsd		xmm4, xmm4, xmm0
		_vmulsd		xmm2, xmm2, xmm4

		_vmulsd		xmm2, xmm2, xmm3
		_vcvtsi2sd	xmm0, xmm0, r11d
		_vcvtsi2sd	xmm1, xmm1, dword[time.optimumTime]
		_vmulsd		xmm1, xmm1, xmm2
		_vcomisd	xmm0, xmm1
		jbe	.id_loop
    .set_stop:
		cmp	byte[limits.ponder], 0
		jne	@1f
		mov	byte[signals.stop], -1
		jmp	.id_loop
    @1:
		mov	byte[signals.stopOnPonderhit], -1
		jmp	.id_loop
		
		calign	8
.id_loop_done:
		mov	rax, qword[.timeReduction]
		mov	qword[rbp - Thread.rootPos + Thread.previousTimeReduction], rax
;GD_String <db 'Thread_Think returning',10>
		add	rsp, .localsize
		pop	r15 r14 r13 rdi rsi rbx rbp
		ret

MainThread_Think:
	; in: rcx address of Thread struct   should be mainThread

	       push   rbp rbx rsi rdi r15
		lea   rbp, [rcx+Thread.rootPos]
		mov   rbx, qword[rbp+Pos.state]

		mov   ecx, dword[rbp+Pos.sideToMove]
		mov   edx, dword[rbp+Pos.gamePly]
	       call   TimeMng_Init

		add   byte[mainHash.date], 8	;4 if without pvhit
cmp	byte[mainHash.date],128
jne	@1f
	mov	byte[mainHash.date],0
@1:

if USE_WEAKNESS
	; set multipv and change maximumTime
		cmp   byte[weakness.enabled], 0
		 je   @f
	; start with one line, may be changed by Weakness_PickMove
		mov   dword[weakness.multiPV], 1
	       call   Weakness_AdjustTime
	@@:
end if

	; check for mate
		mov   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		cmp   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		 je   .mate

if USE_BOOK
        ; if we are pondering then we still want to search
        ; even if the result of the search will be discarded
                xor   esi, esi
                mov   dword[book.move], esi
                mov   dword[book.weight], esi
                mov   dword[book.ponder], esi
                cmp   sil, byte[limits.infinite]
                jne   @f
                cmp   sil, byte[book.ownBook]
                 je   @f
                cmp   rsi, qword[book.buffer]
                 je   @f
               call   Book_GetMove
                mov   dword[book.move], eax
                mov   dword[book.weight], edx
                mov   dword[book.ponder], ecx
                cmp   sil, byte[limits.ponder]
                jne   @f
               test   eax, eax
                jnz   .search_done
        @@:
end if

	; start workers
		xor   esi, esi
    .next_worker:
		inc	esi	;add   esi, 1
		cmp   esi, dword[threadPool.threadCnt]
		jae   .workers_done
		mov   rcx, qword[threadPool.threadTable+8*rsi]
	       call   Thread_StartSearching
		jmp   .next_worker
    .workers_done:

	; start searching
		lea   rcx, [rbp-Thread.rootPos]
	       call   Thread_Think

.search_done:

	; check for wait
		cmp	byte[signals.stop], 0
		jne	.dont_wait
		mov   al, byte[limits.ponder]
		 or   al, byte[limits.infinite]
		 jz   .dont_wait
		mov   byte[signals.stopOnPonderhit], -1
		lea   rcx, [rbp-Thread.rootPos]
		lea   rdx, [signals.stop]
	       call   Thread_Wait
	.dont_wait:
		mov   byte[signals.stop], -1

	; wait for workers
		xor   esi, esi
	.next_worker2:
		inc	esi	;add   esi, 1
		cmp   esi, dword[threadPool.threadCnt]
		jae   .workers_done2
		mov   rcx, qword[threadPool.threadTable+8*rsi]
	       call   Thread_WaitForSearchFinished
		jmp   .next_worker2
	.workers_done2:

if USE_BOOK
        ; must do after waiting for workers
        ; since ponder could have started the workers
                mov   esi, dword[book.move]
               test   esi, esi
                jnz   .play_book_move
end if

	; check for mate again
		mov   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.ender]
		cmp   r8, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		 je   .mate_bestmove

if USE_WEAKNESS
		cmp   byte[weakness.enabled], 0
		jne   .pick_weak_move
end if

	; find best thread  index esi, best score in r9d
		xor   esi, esi	;check if there are threads with a better score than main thread
		mov   r10, qword[threadPool.threadTable+8*rsi]
		mov   r8d, dword[r10+Thread.completedDepth]
		mov   r9, qword[r10+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   r9d, dword[r9+0*sizeof.RootMove+RootMove.score]
		mov   eax, dword[options.multiPV]
		sub   eax, 1
		 or   eax, dword[limits.depth]
		jne   .best_done
		mov   rcx, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.pv+4*0]
	       test   ecx, ecx
		 jz   .best_done
		xor   edi, edi
	.next_worker3:
		inc	edi	;add   edi, 1
		cmp   edi, dword[threadPool.threadCnt]
		jae   .workers_done3
		mov   r10, qword[threadPool.threadTable+8*rdi]
		mov   eax, dword[r10+Thread.completedDepth]		;depthDiff
		cmp   eax, r8d
		jl    .next_worker3
		mov   rcx, qword[r10+Thread.rootPos+Pos.rootMovesVec+RootMovesVec.table]
		mov   ecx, dword[rcx+0*sizeof.RootMove+RootMove.score]	;scoreDiff
		cmp   ecx, r9d
		jle   .next_worker3
	
		mov   r8d, eax
		mov   r9d, ecx
		mov   esi, edi
		jmp   .next_worker3
	.workers_done3:
.best_done:
		mov	dword[rbp-Thread.rootPos+Thread.previousScore], r9d
		mov	rcx, qword[threadPool.threadTable+8*rsi]
.display_move:
		cmp	byte[options.displayInfoMove], 0
		je	.return
		call	DisplayMove_Uci
.return:
		pop	r15 rdi rsi rbx rbp
		ret

if USE_WEAKNESS
.pick_weak_move:
	       call   Weakness_PickMove
		mov   rax, qword[rbp+Pos.rootMovesVec.table]
		mov   eax, dword[rax+0*sizeof.RootMove+RootMove.score]
		lea   rcx, [rbp-Thread.rootPos]
		mov   dword[rcx+Thread.previousScore], eax
		jmp   .display_move
end if

if USE_BOOK
.play_book_move:
    ; esi book move
            lea   rdi, [Output]
            mov   rax, 'info str'
          stosq
            mov   eax, 'ing '
          stosd
            mov   rax, 'playing '
          stosq
            mov   rax, 'book mov'
          stosq
            mov   rax, 'e weight'
          stosq
            mov   al, ' '
          stosb
            mov   eax, dword[book.weight]
           call   PrintUnsignedInteger
        PrintNL
           call   WriteLine_Output
            lea   rdi, [Output]
            mov   rax, 'bestmove'
          stosq
            mov   al, ' '
          stosb
            mov   ecx, esi
          movzx   edx, byte[rbp+Pos.chess960]
           call   PrintUciMove
            mov   ecx, dword[book.ponder]
           test   ecx, ecx
             jz   .NoBookPonder
            mov   rax, ' ponder '
          stosq
          movzx   edx, byte[rbp+Pos.chess960]
           call   PrintUciMove
.NoBookPonder:
        PrintNL
           call   WriteLine_Output
            jmp   .return
end if

.mate:
            lea  rdi, [Output]
            mov  rax, 'info dep'
          stosq
            mov  rax, 'th 0 sco'
          stosq
            mov  eax, 're '
          stosd
            sub  rdi, 1
            cmp  qword[rbx+State.checkersBB], 1
            sbb  ecx, ecx
            and  ecx, VALUE_DRAW + VALUE_MATE
            sub  ecx, VALUE_MATE
           call  PrintScore_Uci
        PrintNL
            cmp  byte[options.displayInfoMove], 0
             je  .return
           call  WriteLine_Output
            jmp  .search_done

.mate_bestmove:
            lea  rdi, [Output]
            mov  rax, 'bestmove'
          stosq
            mov  rax, ' NONE'
          stosq
            sub  rdi, 3
        PrintNL
            cmp  byte[options.displayInfoMove], 0
             je  .return
           call  WriteLine_Output
            jmp  .return

	calign	16
DisplayMove_Uci:
    ; in: rcx address of best thread
		lea	rbp, [rcx+Thread.rootPos]
	; print best move and ponder move
		lea	rdi, [Output]
		mov	rax, 'bestmove'
		stosq
		mov	al, ' '
		stosb
		mov	rsi, qword[rbp + Pos.rootMovesVec + RootMovesVec.table]
		mov	ecx, dword[rsi + 0*sizeof.RootMove + RootMove.pv + 4*0]
		call	PrintUciMove

		mov	eax, dword[rsi + 0*sizeof.RootMove + RootMove.pvSize]
		cmp	eax, 2
		jnb	.have_ponder_from_tt
	     	call	ExtractPonderFromTT
		jz	.skip_ponder
.have_ponder_from_tt:
		mov	rax, ' ponder '
		stosq
		mov	ecx, dword[rsi + 0*sizeof.RootMove + RootMove.pv + 4*1]
		call	PrintUciMove
.skip_ponder:
	PrintNL
		call	WriteLine_Output
		ret
	calign	16
ExtractPonderFromTT:
		push	r13 r14
		mov	r14, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
		mov	ecx, dword[r14+RootMove.pv+4*0]
		xor	eax, eax
		cmp	eax, ecx
		je	.ReturnEPFT
		mov	rbx, qword[rbp+Pos.state]
		call	Move_GivesCheck
		mov	byte[rbx+State.givesCheck], al
		call	Move_Do__ExtractPonderFromTT
		call	MainHash_Probe.Main
		xor	r13d, r13d
		test	edx, edx
		jz	.done
		shr	ecx, 16
		call	Move_IsPseudoLegal
		jz	.done
		call	Move_IsLegal
		jz	.done
		or	r13d, -1
		mov	dword[r14+RootMove.pv+4*1], ecx
		mov	dword[r14+RootMove.pvSize], 2
.done:
		call	Move_Undo
		mov	eax, r13d
		test	eax, eax
.ReturnEPFT:
		pop	r14 r13
		ret

DisplayInfo_Uci:
	; in: rbp thread pos
	;	esi	= depth
	;	r12	= alpha
	;	r13	= beta
	;     r9 elapsed
	;     r10d multipv

		push	rdi r14 r15
virtual at rsp
 .elapsed    rq 1
 .nodes      rq 1
 .tbHits     rq 1
 .nps	     rq 1
 .multiPV    rd 1
 .hashfull   rd 1
	     rd 1
 .output     rb 8*MAX_PLY
 .lend rb 0
end virtual
.localsize = ((.lend-rsp+15) and (-16))
	 _chkstk_ms	rsp, .localsize
		sub	rsp, .localsize
		mov	qword[.elapsed], r9
		mov	dword[.multiPV], r15d

;	     Assert   ne, r10d, 0, 'assertion dword[.multiPV]!=0 in Position_WriteOutUciInfo failed'
		cmp	byte[options.displayInfoMove], 0
		je	.return
if USE_HASHFULL
    if VERBOSE < 2
		 or   eax, -1
		cmp   r9, 1000
		 jb   @f
    end if
	       call   MainHash_HashFull
	@@:
                mov   dword[.hashfull], eax
end if

	       call   ThreadPool_NodesSearched_TbHits
		mov   qword[.nodes], rax
		mov   qword[.tbHits], rdx
		mov   edx, 1000
		mul   rdx
		mov   rcx, qword[.elapsed]
		cmp   rcx, 1
		adc   rcx, 0
		div   rcx
		mov   qword[.nps], rax


		xor	r15d, r15d
.multipv_loop:
		imul	r14d, r15d, sizeof.RootMove
		add	r14, qword[rbp+Pos.rootMovesVec+RootMovesVec.table]
                mov   ecx, dword[r14+RootMove.score]
                cmp   ecx, -VALUE_INFINITE
              setne   cl
		xor   eax, eax
		cmp   r15d, dword[rbp-Thread.rootPos+Thread.PVIdx]
	      setbe   al
                and   eax, ecx

		lea	ecx, [rsi-1]
		mov	edx, eax
		or	edx, ecx
		jz	.multipv_cont
		add	ecx, eax

		lea   rdi, [.output]
		mov   r11d, dword[r14+4*rax]
		mov   rax, 'info dep'
	      stosq
		mov   eax, 'th '
	      stosd
		dec	rdi	;sub   rdi, 1
		mov   eax, ecx
	       call   PrintUnsignedInteger

		mov   rax, ' seldept'
	      stosq
		mov   eax, 'h '
	      stosw
	        movzx   eax, byte[r14+RootMove.selDepth]
	       call   PrintUnsignedInteger

		mov   al, ' '
	      stosb
		mov   rax, 'multipv '
	      stosq
		lea   eax, [r15+1]
	       call   PrintUnsignedInteger

if VERBOSE < 2
		mov   rax, ' time '
	      stosq
		sub   rdi, 2
		mov   rax, qword[.elapsed]
	       call   PrintUnsignedInteger

		mov   rax, ' nps '
	      stosq
		sub   rdi, 3
		mov   rax, qword[.nps]
	       call   PrintUnsignedInteger
end if

if USE_SYZYGY
	      movsx   r10d, byte[Tablebase_RootInTB]
		mov   eax, r11d
		cdq
		xor   eax, edx
		sub   eax, edx
		sub   eax, VALUE_MATE - MAX_PLY
		sar   eax, 31
		and   r10d, eax
	     cmovnz   r11d, dword[Tablebase_Score]
end if

		mov   rax, ' score '
	      stosq
		dec	rdi	;sub   rdi, 1
		mov   ecx, r11d
	       call   PrintScore_Uci	;r10, r11 not clobered

if USE_SYZYGY
	       test   r10d, r10d        ; undefined without syzygy
		jnz   .no_bound
end if
		cmp   r15d, dword[rbp-Thread.rootPos+Thread.PVIdx]
		jne   .no_bound
		mov   rax, ' lowerbo'
		cmp   r11d, r13d	;dword[.beta]
		jge   .yes_bound
		mov   rax, ' upperbo'
		cmp   r11d, r12d	;dword[.alpha]
		 jg   .no_bound
	.yes_bound:
	      stosq
		mov   eax, 'und'
	      stosd
		sub   rdi, 1
	.no_bound:

		mov   rax, ' nodes '
	      stosq
		sub   rdi, 1
		mov   rax, qword[.nodes]
	       call   PrintUnsignedInteger

if USE_HASHFULL
            mov  ecx, dword[.hashfull]
           test  ecx, ecx
             js  @1f
            mov  rax, ' hashful'
          stosq
            mov  ax, 'l '
          stosw
            mov  eax, ecx
           call  PrintUnsignedInteger
    @1:
end if
if USE_SYZYGY
            mov  rax, ' tbhits '
          stosq
            mov  rax, qword[.tbHits]
           call  PrintUnsignedInteger
end if
            mov  eax, ' pv'
          stosd
            dec	rdi	;sub  rdi, 1
            mov  r11d, dword[r14+RootMove.pvSize]
            lea  r14, [r14+RootMove.pv]
            lea  r11, [r14+4*r11]
.next_move:
            mov  al, ' '
            cmp  r14, r11
            jae  .moves_done
          stosb
            mov  ecx, dword[r14]
;           call  PrintUciMove	;r10 clobered
call	_PrintUciMove
mov	qword[rdi], rax
add	rdi, rdx
;
	    add  r14, 4
            jmp  .next_move
.moves_done:
        PrintNL
            lea  rcx, [.output]
           call  WriteLine
.multipv_cont:
            inc	r15	;add  r15d, 1
            cmp  r15d, dword[.multiPV]
             jb  .multipv_loop
.return:
		add	rsp, .localsize
		pop	r15 r14 rdi
DisplayMove_None:
DisplayInfo_None:
            ret
