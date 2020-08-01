		calign   8
MainHash_Probe:
		mov	r11, rax
		shr	r11d, 3  -  1
		and	r11d, 3 shl 1
		neg	r11
		lea	r11, [8*3+3*r11]
		movzx	ecx, word[r11+rax]
		cmp	cx, word[rbx+State.key+6]
		jne	.ValueNone
		mov	rcx, qword[rax]
		mov	qword[rbx+State.ltte], rcx
		or	r15l, JUMP_IMM_6
		ret
		calign   8
.Main:
	; in:   rcx  key
	; out:  rax  address of entry
	;       rcx  entry (8 bytes)
		mov	rax, qword[rbx+State.tte]
		test	rax,rax
		jnz	MainHash_Probe
		mov	rcx, qword[rbx+State.key]
		mov	rax, qword[mainHash.mask]
		and	rax, rcx
		shr	rcx, 48
		add	rax, qword[mainHash.table]
		movzx	r11d, byte[mainHash.date]
		mov	rdx, qword[rax+8*3]
		test	dx, dx
		jz	.Found
		cmp	dx, cx
		je	.FoundRefresh
		shr	rdx, 16
		add	rax, 8
		test	dx, dx
		jz	.Found
		cmp	dx, cx
		je	.FoundRefresh
		shr	rdx, 16
		add	rax, 8
		test	dx, dx
		jz	.Found
		cmp	dx, cx
		je	.FoundRefresh
		movsx	r8d, word[rax-2*8]
		movsx	r9d, word[rax-1*8]
		movsx	r10d, word[rax-0*8]

		add	r11d, 263
		and	r8l, 127
		and	r9l, 127
		and	r10l, 127

		movzx	ecx, r8l
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0F8
		sar	r8d, 8
		sub	r8d, edx
		
		movzx	ecx, r9l
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0F8
		sar	r9d, 8
		sub	r9d, edx

		movzx	ecx, r10l
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0F8
		sar	r10d, 8
		sub	r10d, edx

		mov	rdx, rax
		sub	rax, 8*2
		lea	rcx, [rax+8*1]
		cmp	r8d, r9d
		cmovg	r8d, r9d
		cmovg	rax, rcx
		cmp	r8d, r10d
		cmovg	rax, rdx
.Found:
		;mov   rcx, VALUE_NONE shl (8*MainHashEntry.value_)
		;mov	rcx, (VALUE_NONE shl 48) or (VALUE_NONE shl 32) or (DEPTH_NONE shl 8)
		mov	rcx, 0x7D027D020000FA02
		mov	qword[rbx+State.ltte], rcx
		mov	qword[rbx+State.tte], rax
		;and	r15l, NOT JUMP_IMM_6
		test	r15l, JUMP_IMM_2	;only on Cutnode & Qsearch
		jnz	.onNull
		ret
	     calign   8
.FoundRefresh:
		mov	rcx, qword[rax]
		or	cl, byte[rbx+State.pvhit]
		and	rcx, 0xFFFFFFFFFFFFFF87
		or	rcx, r11
		mov	dl, cl
		and	dl, 4+JUMP_IMM_8
		mov	byte[rax+MainHashEntry.genBound], cl
		mov	qword[rbx+State.tte], rax
		mov	qword[rbx+State.ltte], rcx
		or	byte[rbx+State.pvhit], dl
		or	r15l, JUMP_IMM_6
		ret
	     calign   8
.onNull:
		movsx	edx, word[rbx-1*sizeof.State+State.ltte+MainHashEntry.eval_]
		neg	edx
		add	edx, 2*Eval_Tempo
		mov	word[rbx+State.ltte+MainHashEntry.eval_], dx
		mov	word[rbx+State.ltte+MainHashEntry.value_], dx
		mov	rcx, qword[rbx+State.ltte]
		ret
	     calign   8
.ValueNone:	;lost
		mov	rcx, qword[rbx+State.ltte]
if	0
		mov	rdx, qword[rax]
		movzx	r8d, word[rbx+State.key+6]
		mov	r9, qword[rbx+State.checkersBB]
		movzx	r10d, byte[rbx+State.ply]
		;movzx	r11d, word[rbx+State.ltte+MainHashEntry.move]
		Display	0, "info string Key =[%I8] [.flag=%i15] [ply=%i10] [.tte=%I0] [.ltteTT=%I2] [.oldltte=%I1] [.depth=%I6] [.checkersBB=%I9]%n"
		;notify repeatly from check condition
end if
		ret
