; generate_CAPTURES generates all pseudo-legal captures and queen
; promotions. Returns a pointer to the end of the move list.

	     calign   16
Gen_Captures:		;r15 r14 r13 -clobered-
	; in:	rbp address of position
	;	rbx address of state
	;	r15 mask
	; io: rdi address to write moves

		push	rsi r12
		mov	rdi, qword[rbx-1*sizeof.State+State.endMoves]
		mov	r14, qword[rbx+State.Occupied]
		cmp	byte[rbp+Pos.sideToMove],0
		jne	Gen_Captures_Black
Gen_Captures_White:
		and	r15, qword[rbp+Pos.typeBB+8*Black]	;change
	generate_all	White, CAPTURES
		pop	r12 rsi
		ret
	generate_jmp	White, CAPTURES

Gen_Captures_Black:
		and	r15, qword[rbp+Pos.typeBB+8*White]	;change
	generate_all	Black, CAPTURES
		pop	r12 rsi
		ret
	generate_jmp   Black, CAPTURES
