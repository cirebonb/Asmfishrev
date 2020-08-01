RootMovesVec_StableSort:
	; in: rcx start RootMove
	;     rdx end RootMove
	       push   rsi rdi r12 r13 r14 r15
		sub   rsp, ((sizeof.RootMove + 15) and (-16))
		mov   r14, rcx
		mov   r15, rdx
		mov   r13, r14
.l1:		add   r13, sizeof.RootMove
		cmp   r13, r15
		jae   .l1d
		mov   rdi, rsp
		mov   rsi, r13
		mov   ecx, sizeof.RootMove/4
	  rep movsd
		mov   r12, r13
.l2:		cmp   r12, r14
		jbe   .l2d
		mov   eax, dword[r12-1*sizeof.RootMove+RootMove.score]
		cmp   eax, dword[rsp+RootMove.score]
		 jg   .l2d
                 jl   .less
		mov   eax, dword[r12-1*sizeof.RootMove+RootMove.prevScore]
		cmp   eax, dword[rsp+RootMove.prevScore]
                jge   .l2d
.less:          mov   rdi, r12
		sub   r12, sizeof.RootMove
		mov   rsi, r12
		mov   ecx, sizeof.RootMove/4
	  rep movsd
		jmp   .l2
.l2d:		mov   rdi, r12
		mov   rsi, rsp
		mov   ecx, sizeof.RootMove/4
	  rep movsd
		jmp   .l1
.l1d:		add   rsp, ((sizeof.RootMove + 15) and (-16))
		pop   r15 r14 r13 r12 rdi rsi
		ret

