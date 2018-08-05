; generate_QUIETS generates all pseudo-legal non-captures and
; underpromotions. Returns a pointer to the end of the move list.

	     calign  16
Gen_Quiets:		;r15 r13 -clobered-
	; in: rbp address of position
	;     rbx address of state
	; io: rdi address to write moves

		push	rsi r12 r14 
		mov	r15, qword[rbx+State.Occupied]
		mov	r14, r15
		not	r15
		cmp	byte [rbp+Pos.sideToMove], 0
		jne	Gen_Quiets_Black
Gen_Quiets_White:
	generate_all	White, QUIETS
		pop	r14 r12 rsi
		ret
	generate_jmp	White, QUIETS
Gen_Quiets_Black:
	generate_all	Black, QUIETS
		pop	r14 r12 rsi
		ret
	generate_jmp	Black, QUIETS
