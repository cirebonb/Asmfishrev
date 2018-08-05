; generate<QUIET_CHECKS> generates all pseudo-legal non-captures and knight
; underpromotions that give check. Returns a pointer to the end of the move list.
; generate non Incheck Condition
	     calign  16
Gen_QuietChecks:		;r15 r13 -clobered-
	; in: rbp address of position
	;     rbx address of state
	; io: rdi address to write moves

		push	rsi r12 r14 
		mov	r15, qword[rbx+State.Occupied]
		mov	r14, qword[rbx+State.dcCandidates]
		test	r14, r14
		jz	.PopLoopDone
		mov	r12, r15
		not	r12
.PopLoop:
		_tzcnt	r13, r14
		_blsr	r14, r14, rax
		movzx	edx, byte[rbp+Pos.board+r13]
		and	edx, 7
;		cmp	edx, Knight
;		je	Gen_QuietChecks_Jmp.AttacksFromKnight
;		cmp	edx, Bishop
;		je	Gen_QuietChecks_Jmp.AttacksFromBishop
;		cmp	edx, Rook
;		je	Gen_QuietChecks_Jmp.AttacksFromRook
;		cmp	edx, King
;		je	Gen_QuietChecks_Jmp.AttacksFromKing
;		jmp	.PopSkip
;		cmp	edx, Pawn
;		je	Gen_QuietChecks_Jmp.AttacksFromKnight
		jmp	qword[Gen_QuietChecks_Jmp.JmpTable+8*rdx]
;======================================================
	     calign   8
.AttacksFromRet:
;		test	rsi, rsi
		jz	.PopSkip
		shl	r13d, 6
.MoveLoop:
		_tzcnt	rax, rsi
		or	eax, r13d
		mov	dword[rdi], eax
		;lea	rdi, [rdi+sizeof.ExtMove]
		add	rdi, sizeof.ExtMove
		_blsr	rsi, rsi, rdx
		jnz	.MoveLoop
.PopSkip:
		test	r14, r14
		jnz	.PopLoop

.PopLoopDone:
		mov	r14, r15	;original mov	r14, qword[rbx+State.Occupied]
		not	r15
		cmp	byte[rbp+Pos.sideToMove], 0
		jne	Gen_QuietChecks_Black
;	     calign   8
;Gen_QuietChecks_White:
		generate_all	White, QUIET_CHECKS
		pop	r14 r12 rsi
		ret
		generate_jmp   White, QUIET_CHECKS

	     calign   8
Gen_QuietChecks_Black:
		generate_all   Black, QUIET_CHECKS
		pop	r14 r12 rsi
		ret
		generate_jmp   Black, QUIET_CHECKS

Gen_QuietChecks_Jmp:
	     calign   8
.AttacksFromKnight:
		mov	rsi, qword[KnightAttacks+8*r13]
		and	rsi, r12
;		_andn	rsi, r15, rsi
		jmp	Gen_QuietChecks.AttacksFromRet

	     calign   8
.AttacksFromKing:
		mov	rsi, qword[KingAttacks+8*r13]
		and	rsi, r12
;		_andn	rsi, r15, rsi
		movzx	eax, byte [rbx+State.ksq]
		shl	eax, 6
		mov	rax, qword[LineBB+rax+8*r13]
		not	rax
		and	rsi, rax
;		movzx	ecx, byte [rbx+State.ksq]
;		mov	rax, qword[RookAttacksPDEP+8*rcx]
;		or	rax, qword[BishopAttacksPDEP+8*rcx]
;		not	rax
;		and	rsi, rax

;		_andn	rsi, rax, rsi
		jmp	Gen_QuietChecks.AttacksFromRet

	     calign   8
.AttacksFromBishop:
		BishopAttacks	rsi, r13, r15, rax
		and	rsi, r12
;		_andn	rsi, r15, rsi
		jmp	Gen_QuietChecks.AttacksFromRet

	     calign   8
.AttacksFromRook:
		RookAttacks	rsi, r13, r15, rax
		and	rsi, r12
;		_andn	rsi, r15, rsi
		jmp	Gen_QuietChecks.AttacksFromRet

;	     calign   8
;.AttacksFromQueen:
		;QueenAttacks	rsi, r13, r15, rax, rdx
;		BishopAttacks	rsi, r13, r15, rax
;		RookAttacks	rdx, r13, r15, rax
;		or	rsi, rdx
		;and	rsi, r12
;		_andn	rsi, r15, rsi
		
;		xor	eax,eax
;		mov	eax,[eax]	;raise error if executed
;		jmp	Gen_QuietChecks.AttacksFromRet
             calign   8
.JmpTable:
	dq 0	;Gen_QuietChecks_Jmp.PopSkip
	dq 0	;Gen_QuietChecks_Jmp.PopSkip
	dq Gen_QuietChecks.PopSkip
	dq Gen_QuietChecks_Jmp.AttacksFromKnight
	dq Gen_QuietChecks_Jmp.AttacksFromBishop
	dq Gen_QuietChecks_Jmp.AttacksFromRook
	dq 0	;Gen_QuietChecks_Jmp.AttacksFromQueen
	dq Gen_QuietChecks_Jmp.AttacksFromKing
