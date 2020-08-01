
Search_Init:
	       push   r14 r13 r12 rbp rdi rsp rbx
		lea   r12, [Reductions]
		xor   ebp, ebp
		xor   ebx, ebx
._0048:
		mov   rax, rbp
		mov   esi, ebp
		mov   edi, 1
		shl   rax, 12
		xor   esi, 01H
		lea   r14, [r12+rax+40H]
		and   esi, 01H
._0049:
	     _vpxor   xmm0, xmm0, xmm0
	 _vcvtsi2sd   xmm0, xmm0, edi				; d
		xor   r13d, r13d
	       call   Math_Log_d_d
	   _vmovapd   xmm7, xmm0
._0050:
		lea   edx, [r13+1H]
	     _vpxor   xmm0, xmm0, xmm0
	 _vcvtsi2sd   xmm0, xmm0, edx				; mc
	       call   Math_Log_d_d
	    _vmulsd   xmm1, xmm0, xmm7
	    _vdivsd   xmm1, xmm1, qword[.constd_1p95]
;		_vmovsd	xmm3, xmm1		;added
		xor	r8d, r8d
	    _vaddsd   xmm1, xmm1, qword[.constd_0p5]
	_vcvttsd2si   r8d, xmm1
		lea   r9d, [r8-1H]
	       test   r9d, r9d
	      cmovs   r9d, ebx
		mov	byte[r14+r13+2000H], r9l	;for pvnode=1
		cmp   r8d, 1	;1 off
		jle   ._0051	;2 off
	       test   sil, sil
		 jz   ._0051
;		comisd xmm3, qword[.constd_1p0]	;added
;		jbe	._0051			;added

		add   r8d, 1
._0051:
		mov   byte[r14+r13+0H], r8l	;d		;for pvnode=0
		add   r13, 1
		cmp   r13, 63	; mc
		jnz   ._0050
		add   edi, 1
		add   r14, 64
		cmp   edi, 64		; d
		jne   ._0049
		sub   rbp, 1
		 jz   ._0052
		mov   ebp, 1
		jmp   ._0048
._0052:


		xor   ebp, ebp
	    _vmovsd   xmm6, qword[.constd_2p4]
	    _vmovsd   xmm7, qword[.constd_0p74]
	    _vmovsd   xmm8, qword[.constd_5p0]
	    _vmovsd   xmm9, qword[.constd_1p0]
.FutilityLoop:
	 _vcvtsi2sd   xmm0, xmm0, ebp
	    _vmovsd   xmm1, qword[.constd_1p78]
	       call   Math_Power_d_dd
	   _vmovapd   xmm1, xmm6
	  _vfmaddsd   xmm0, xmm0, xmm7, xmm6
	_vcvttsd2si   eax, xmm0
		mov	ecx, eax
		mov	edx, 127
		cmp	ecx, edx
		cmovg	ecx, edx
		sub	ecx, 2
		mov   byte[FutilityMoveCounts+rbp], cl	;eax

	 _vcvtsi2sd   xmm0, xmm0, ebp
	    _vmovsd   xmm1, qword[.constd_2p0]
	       call   Math_Power_d_dd
	  _vfmaddsd   xmm0, xmm0, xmm9, xmm8
	_vcvttsd2si   eax, xmm0
		mov	ecx, eax
		mov	edx, 127
		cmp	ecx, edx
		cmovg	ecx, edx
		sub	ecx, 2
		mov   byte[FutilityMoveCounts+(rbp+16)], cl	;eax

		add   ebp, 1
		cmp   ebp, 16
		 jb   .FutilityLoop

		lea	rsi,[.TableQsearch_NonPv]
		lea	rdi,[TableQsearch_NonPv]
		mov	ecx, 8*8/4
		rep	movsd

		pop   rbx rsi rdi rbp r12 r13 r14
		ret


             calign 8
.constd_0p5     dq 0.5
.constd_1p95    dq 1.95

.constd_2p4     dq 2.4
.constd_0p74    dq 0.74
.constd_5p0     dq 5.0
.constd_1p0     dq 1.0
.constd_1p78    dq 1.78
.constd_2p0     dq 2.0

.TableQsearch_NonPv	dq QSearch_NonPv_InCheck,QSearch_NonPv_NoCheck,Search_NonPv,Search_NonPv
.TableQsearch_Pv	dq QSearch_Pv_InCheck,QSearch_Pv_NoCheck,Search_Pv,Search_Pv