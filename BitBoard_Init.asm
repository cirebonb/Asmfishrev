
BitBoard_Init:
	       push   rbp rbx rsi rdi r11 r12 r13 r14 r15

	       call   Init_AdjacentFilesBB
	       call   Init_InFrontBB
	       call   Init_ForwardBB_PawnAttackSpan_PassedPawnMask
	       call   Init_SquareDistance_DistanceRingBB
	       call   Init_BetweenBB_LineBB
if QUEENTHREAT = 1
	       call	Init_EvadeKingBB	;new
end if
		pop   r15 r14 r13 r12 r11 rdi rsi rbx rbp
		ret


Init_InFrontBB:
		xor   ecx, ecx
.Next:		mov   rax, qword[RankBB+rcx]
		 or   rax, qword[InFrontBB+8*8+rcx]
		mov   qword[InFrontBB+8*9+rcx], rax
		not   rax
		mov   qword[InFrontBB+rcx], rax
		add   ecx, 8
		cmp   ecx, 56
		 jb   .Next
		ret



Init_ForwardBB_PawnAttackSpan_PassedPawnMask:
		lea   r9, [FileBB]
		lea   rbx, [InFrontBB]
		lea   r11, [AdjacentFilesBB]
		xor   r13d, r13d
		xor   r14d, r14d
._0017: 	lea   rcx, [ForwardBB]
	     movsxd   r10, r14d
		xor   r8d, r8d
		lea   r15, [PawnAttackSpan]
		shl   r10, 3
		lea   rax, [PassedPawnMask]
		lea   r12, [rcx+r13]
		lea   rdi, [r15+r13]
		lea   rsi, [rax+r13]
._0018: 	mov   rdx, r8
		shr   rdx, 3
		mov   ecx, edx
		add   rcx, r10
		mov   rax, qword[rbx+rcx*8]
		mov   rcx, r8
		and   ecx, 7
		mov   rdx, qword[r9+rcx*8]  ; filebb
		mov   rcx, qword[r11+rcx*8] ; adjfile
		mov   r15, rdx
		and   r15, rax
		or    rdx, rcx
		mov   qword[r12+r8*8], r15  ; ForwardBB
		mov   r15, rcx
		and   r15, rax
		and   rax, rdx
		mov   qword[rdi+r8*8], r15
		mov   qword[rsi+r8*8], rax
		add   r8, 1
		cmp   r8, 64
		jnz   ._0018
		add   r13, 512
		sub   r14d, 1
		jne   ._0029
		ret
._0029: 	mov   r14d, 1
		jmp   ._0017



Init_AdjacentFilesBB:
		lea   r9, [FileBB]
		lea   r11, [AdjacentFilesBB]
		xor   eax, eax
._0013:        test   rax, rax
		 je   ._0038
		lea   esi, [rax-1]
		cmp   eax, 7
		mov   rdx, qword[r9+rsi*8]
		 je   ._0037
._0014: 	lea   rdi, [FileBB+8]
		 or   rdx, qword[rdi+rax*8]
		mov   qword[r11+rax*8], rdx
		add   rax, 1
		cmp   rax, 8
		jnz   ._0013
._0015: 	ret
._0037: 	mov   qword[AdjacentFilesBB+56], rdx
		jmp   ._0015
._0038: 	xor   edx, edx
		jmp   ._0014


Init_BetweenBB_LineBB:


		xor   r15d,r15d
.NextSquare1:	xor   r14d,r14d
.NextSquare2:
		xor   rax,rax
		mov   edx,r15d
		shl   edx,6+3
		 bt   qword[BishopAttacksPDEP+8*r15],r14
		 jc   .Bishop
		 bt   qword[RookAttacksPDEP+8*r15],r14
		 jc   .Rook
		mov   qword[LineBB+rdx+8*r14],rax
		mov   qword[BetweenBB+rdx+8*r14],rax
		jmp   .Done

.Bishop:

		xor   r13,r13
      BishopAttacks   rax,r15,r13,r8
      BishopAttacks   rbx,r14,r13,r8
		and   rax,rbx
		bts   rax,r15
		bts   rax,r14
		mov   qword[LineBB+rdx+8*r14],rax


		xor   r13,r13
		bts   r13,r14
      BishopAttacks   rax,r15,r13,r8
		xor   r13,r13
		bts   r13,r15
      BishopAttacks   rbx,r14,r13,r8
		and   rax,rbx
		mov   qword[BetweenBB+rdx+8*r14],rax
		jmp   .Done

.Rook:

		xor   r13,r13
	RookAttacks   rax,r15,r13,r8
	RookAttacks   rbx,r14,r13,r8
		and   rax,rbx
		bts   rax,r15
		bts   rax,r14
		mov   qword[LineBB+rdx+8*r14],rax


		xor   r13,r13
		bts   r13,r14
	RookAttacks   rax,r15,r13,r8
		xor   r13,r13
		bts   r13,r15
	RookAttacks   rbx,r14,r13,r8
		and   rax,rbx
		mov   qword[BetweenBB+rdx+8*r14],rax
		jmp   .Done

.Done:
		add   r14d,1
		cmp   r14d,64
		 jb   .NextSquare2
		add   r15d,1
		cmp   r15d,64
		 jb   .NextSquare1

		ret


Init_SquareDistance_DistanceRingBB:
		xor   r15d, r15d
.Next1:
		xor   r14d, r14d
.Next2:
		mov   eax, r14d
		and   eax, 7
		mov   ecx, r15d
		and   ecx, 7
		sub   eax, ecx
		mov   ecx, eax
		sar   ecx, 31
		xor   eax, ecx
		sub   eax, ecx

		mov   edx, r14d
		shr   edx, 3
		mov   ecx, r15d
		shr   ecx, 3
		sub   edx, ecx
		mov   ecx, edx
		sar   ecx, 31
		xor   edx, ecx
		sub   edx, ecx

		cmp   eax, edx
	      cmovb   eax, edx
	       imul   ecx, r15d, 64
		mov	edx, 5						;added
		cmp	edx, eax					;
		cmova	edx, eax					;
		mov	byte[SquareDistance + rcx + r14], al		;
		mov	byte[SquareDistance_Cap5 + rcx + r14], dl	;added
;		mov   byte[SquareDistance+rcx+r14], al

		sub   eax, 1
		 js   @f
		lea   rax, [8*r15+rax]
		mov   rdx, qword[DistanceRingBB+8*rax]
		bts   rdx, r14
		mov   qword[DistanceRingBB+8*rax], rdx
	@@:
		add   r14d, 1
		cmp   r14d, 64
		 jb   .Next2
		add   r15d, 1
		cmp   r15d, 64
		 jb   .Next1
		ret


if QUEENTHREAT = 1
Init_EvadeKingBB:
		xor	r8, r8
		.loop_sq:
		;  for (sq = A1; sq <= H8; sq++)
		;r8 = index
		xor	r9, r9
		.loop_king:
		;    for (king = A1; king <= H8; king++)
		;     {
		;r9 = index kingsq
		mov	edx, r9d
		shl	edx, 6
		add	edx, r8d
		lea	rsi, [Evade+8*rdx]
			;Evade (king, sq) = AttK[king];
		mov	rax, qword[KingAttacks+8*r9]
		mov	qword[rsi],rax

		mov	rax, r9
		and	eax, 56
		mov	rcx, r8
		and	ecx, 56
		mov	rdx, rax
		sub	rdx, rcx
		sar	rdx, 3
		cmp	eax, ecx
		jne	.Rank_differ
		;	if (RANK (king) == RANK (sq))
		;	  {
		mov	eax, r9d
		and	eax, 7
		cmp	eax, FILE_A
		je	.Not_File_A
			    ;if (FILE (king) != FA)
		mov	eax, r9d
		sub	eax, 1
		btr	qword[rsi], rax
			      ;Evade (king, sq) ^= 1<<(king - 1);
		.Not_File_A:
		mov	eax, r9d
		and	eax, 7
		cmp	eax, FILE_H
		je	.Rank_differ
		;	    if (FILE (king) != FH)
		mov	eax, r9d
		add	eax, 1
		btr	qword[rsi], rax
			      ;Evade (king, sq) ^= SqSet[king + 1];
		;	  }
		.Rank_differ:
		mov	rax, r9
		and	rax, 7
		mov	rcx, r8
		and	rcx, 7
		mov	rdi, rax
		sub	rdi, rcx
		cmp	eax, ecx
		jne	.File_differ
		;	if (FILE (king) == FILE (sq))
		;	  {
		mov	eax, r9d
		and	eax, 56
		cmp	eax, RANK_1 shl 3
		je	.Not_Rank_1
		;	    if (RANK (king) != R1)
		mov	eax, r9d
		sub	eax, 8
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king - 8];
		.Not_Rank_1:
		mov	eax, r9d
		and	eax, 56
		cmp	eax, RANK_8 shl 3
		je	.File_differ
		;	    if (RANK (king) != R8)
		mov	eax, r9d
		add	eax, 8
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king + 8];
		;	  }
		.File_differ:
		cmp	rdx, rdi
		jne	.diag_differ
		;	if ((RANK (king) - RANK (sq)) == (FILE (king) - FILE (sq)))
		;	  {
		mov	rax, r9
		and	eax, 56
		cmp	eax, RANK_8 shl 3
		je	.diag_diff_0
		mov	rcx, r9
		and	rcx, 7
		cmp	ecx, FILE_H
		je	.diag_diff_0
		;	    if (RANK (king) != R8 && FILE (king) != FH)
		mov	eax, r9d
		add	eax, 9
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king + 9];
		.diag_diff_0:
		mov	rax, r9
		and	eax, 56
		cmp	eax, RANK_1 shl 3
		je	.diag_differ
		mov	rcx, r9
		and	rcx, 7
		cmp	ecx, FILE_A
		je	.diag_differ
		;	    if (RANK (king) != R1 && FILE (king) != FA)
		mov	eax, r9d
		sub	eax, 9
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king - 9];
		;	  }
		.diag_differ:
		neg	rdi
		cmp	rdx, rdi
		jne	.diag_differ2
		;	if ((RANK (king) - RANK (sq)) == (FILE (sq) - FILE (king)))
		;	  {
		mov	rax, r9
		and	eax, 56
		cmp	eax, RANK_8 shl 3
		je	.diag_diff2_0
		mov	rcx, r9
		and	rcx, 7
		cmp	ecx, FILE_A
		je	.diag_diff2_0
		;	    if (RANK (king) != R8 && FILE (king) != FA)
		mov	eax, r9d
		add	eax, 7
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king + 7];
		.diag_diff2_0:
		mov	rax, r9
		and	eax, 56
		cmp	eax, RANK_1 shl 3
		je	.diag_differ2
		mov	rcx, r9
		and	rcx, 7
		cmp	ecx, FILE_H
		je	.diag_differ2
		;	    if (RANK (king) != R1 && FILE (king) != FH)
		mov	eax, r9d
		sub	eax, 7
		btr	qword[rsi], rax
		;	      Evade (king, sq) ^= SqSet[king - 7];
		;	  }
		.diag_differ2:
		bt qword[KingAttacks+8*r9], r8
		jnc	.loop_it	
		;	if (AttK[king] & SqSet[sq])
		bts	qword[rsi], r8
		;	  Evade (king, sq) |= SqSet[sq];
		;      }
		.loop_it:
		add	r9, 1
		cmp	r9, 63
		jbe	.loop_king
		add	r8, 1
		cmp	r8, 63
		jbe	.loop_sq
		ret
end if
