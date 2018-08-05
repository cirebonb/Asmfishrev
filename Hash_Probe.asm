	     calign   16
MainHash_Probe:
	; in:   rcx  key
	; out:  rax  address of entry
	;       rdx  edx == -1 if found
	;            edx == 0  if not found
	;       rcx  entry (8 bytes)

;ProfileInc MainHash_Probe
		mov	rax, qword[rbx+State.tte]
		test	rax,rax
		jnz	.AllreadySet
		mov	rcx, qword[rbx+State.key]
		mov	rax, qword[mainHash.mask]
		and	rax, rcx
		shl	rax, 5
		mov	r8, rcx
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
		movsx	r9d, word[rax-8]
		movsx	r10d, word[rax]

		add	r11d, 259
		sub	rax, 8*2

		movzx	ecx, r8l
		sar	r8d, 8
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0FC
		add	edx, edx
		sub	r8d, edx
		movzx	ecx, r9l
		sar	r9d, 8
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0FC
		add	edx, edx
		sub	r9d, edx
		movzx	ecx, r10l
		sar	r10d, 8
		mov	edx, r11d
		sub	edx, ecx
		and	edx, 0x0FC
		add	edx, edx
		sub	r10d, edx

		lea	rcx, [rax+8*1]
		lea	rdx, [rax+8*2]
		cmp	r8d, r9d
		cmovg	r8d, r9d
		cmovg	rax, rcx
		cmp	r8d, r10d
		cmovg	rax, rdx
.Found:
		;mov   rcx, VALUE_NONE shl (8*MainHashEntry.value_)
		;mov	rcx, (VALUE_NONE shl 48) or (VALUE_NONE shl 32)
		mov	rcx, 0x7D027D0200000000
		xor	edx, edx
		mov	qword[rbx+State.tte], rax
		ret


	     calign   8
.FoundRefresh:
		mov	rcx, qword[rax]
		and	rcx, 0xFFFFFFFFFFFFFF03
		or	rcx, r11
		mov	byte[rax+MainHashEntry.genBound], cl
		mov	qword[rbx+State.tte], rax
		or	r15l, JUMP_IMM_6
		or	edx, -1
		ret
	     calign   8
.AllreadySet:
		mov	rcx, rax
		shr	ecx, 3  -  1
		and	ecx, 3 shl 1
		neg	rcx
		lea	rcx, [8*3+3*rcx]
		movzx	ecx, word[rcx+rax]
		cmp	cx, word[rbx+State.key+6]
		jne	.ValueNone
		mov	rcx, qword[rax]
		or	r15l, JUMP_IMM_6
		or	edx,-1
		ret
	     calign   8
.ValueNone:
		mov	rcx, 0x7D027D0200000000
		xor	edx, edx
		ret
;========================
if 0
	     calign   16
; in rdi = .ltte
MainHash_ProbeTakeIfFound:
		mov	rax, qword[rbx+State.tte]
		mov	rcx, rax
		shr	ecx, 3  -  1
		and	ecx, 3 shl 1
		neg	rcx
		lea	rcx, [8*3+3*rcx]
		movzx	ecx, word[rcx+rax]
		cmp	cx, word[rbx+State.key+6]
		jne	.NoResult
		mov	rcx, qword[rax]
		test	ecx,0xffff0000			; .ttMove
		jz	.NoResult
		mov	rax, rcx
		sar	rcx, 48
		cmp	ecx, VALUE_NONE
		je	.NoResult
		lea	r8d, [rcx+VALUE_MATE_IN_MAX_PLY]
		cmp	r8d, 2*VALUE_MATE_IN_MAX_PLY
		jae	.ValueToTT
		mov	qword[rbx+State.ltte], rax				;[.ltte]
		or	edx, -1
		ret
	     calign   8
.ValueToTT:
		movzx	r8d, byte[rbx+State.ply]
		mov	edx, ecx
		sar	edx, 31
		xor	r8d, edx
		add	ecx, edx
		sub	ecx, r8d
		mov	qword[rbx+State.ltte], rax				;[.ltte]
		mov	word[rbx+State.ltte+MainHashEntry.value_], cx
		or	edx, -1
		ret
	     calign   8
.NoResult:
		xor	edx, edx
		xor	eax, eax
		ret

end if