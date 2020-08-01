; generate<EVASIONS> generates all pseudo-legal check evasions when the side
; to move is in check. Returns a pointer to the end of the move list.

	     calign   16
Gen_Evasions:		;r15 r14 r13 -clobered-
	; in rbp address of position
	;    rbx address of state
	; io rdi address to write moves
		push   rsi r12
		
		xor	r12, r12
		mov	r13d, dword[rbp+Pos.sideToMove]
		mov	r15, qword[rbp+Pos.typeBB+8*r13]
		movzx	r14d, byte[rbx+State.ourKsq]
		mov	rcx, qword[rbx+State.checkersBB]
		mov	rsi, qword[rbp+Pos.typeBB+8*Pawn]
		or	rsi, qword[rbp+Pos.typeBB+8*Knight]
; r14 = our king square
; rsi = their sliding checkers
; r12 = sliderAttacks
		_andn	r15, r15, qword[KingAttacks+8*r14]
		shl	r14d, 6
		lea	r9, [8*r14]

		_andn	rsi, rsi, rcx
		jz	.SlidersDone

		mov	r11, rsi
.NextSlider:
		bsf	rdx, rsi
		or	r12, qword[LineBB+r9+8*rdx]
		_blsr	rsi, rsi, r8			;lea   t, [a-1] ; and   a, t
		jnz	.NextSlider
		not	r11
		and	r12, r11
.SlidersDone:
; generate moves for the king to safe squares
		_andn	r12, r12, r15
		jz	.KingMoveDone
.NextKingMove:
		bsf	rax, r12
		or	eax, r14d
		mov	dword [rdi], eax
		;lea	rdi, [rdi+sizeof.ExtMove]	;4byte
		add	rdi, sizeof.ExtMove		;4byte
		_blsr	r12, r12, r8
		jnz	.NextKingMove
.KingMoveDone:

; if there are multiple checkers, only king moves can be evasions
		_blsr	rax, rcx
		jnz	Gen_Evasions_White.Ret
		bsf	rax, rcx
		mov	r15, qword[BetweenBB+r9+8*rax]
		mov	r14, qword[rbx+State.Occupied]
		or	r15, rcx

		test	r13d, r13d
		jnz	Gen_Evasions_Black
Gen_Evasions_White:
	generate_all   White, EVASIONS
.Ret:
                pop	r12 rsi
		ret
	generate_jmp   White, EVASIONS

Gen_Evasions_Black:
	generate_all   Black, EVASIONS
                pop	r12 rsi
		ret
	generate_jmp   Black, EVASIONS
