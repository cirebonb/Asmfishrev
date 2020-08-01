		calign   16
Move_Do__ProbCut:
		call	Move_GivesCheck	;.HaveFromTo
		xor	r15, r15
		mov	r14, qword[TableQsearch_NonPv+8+rax*8]
		movzx	edx, byte[rbp+Pos.board+r8]
		shl	edx, 6
		add	edx, r9d
		shl	edx, 2+4+6
		add	rdx, qword[rbp+Pos.counterMoveHistory]
		mov	qword[rbx+State.counterMoves], rdx
		mov	byte[rbx+State.givesCheck], al
		jmp	Move_Do__Search
;===========================================================================
		calign   16
Move_Do__Root:
Move_Do__QSearch:
Move_Do__Search:
Move_Do1:	Move_DoMacro 1
	     calign   16
Move_Do__UciParseMoves:
Move_Do__PerftGen_Root:
Move_Do__PerftGen_Branch:
Move_Do__ExtractPonderFromTT:
Move_Do__Tablebase_ProbeAB:
Move_Do__Tablebase_ProbeWDL:
Move_Do__Tablebase_ProbeDTZNoEP:
Move_Do__Tablebase_ProbeDTZ:
Move_Do__Tablebase_RootProbe:
Move_Do__Tablebase_RootProbeWDL:
Move_Do0:	Move_DoMacro 0

;calign 8
;.cetakdolo:	
;		Display 0, "info string %i0%n"
;		jmp	.NullAbortSearch_PlySmaller
if USE_GAMECYCLE = 1
	 calign	  16
has_game_cycle_spesial:
		mov	r8d, eax
		shr	r8d, 16		;.ply
		neg	r8d
		movzx	eax, ah		;.pliesFromNull
		add	r8d, eax	;.pliesFromNull
		lea	r9d, [rax-3]
		lea	r11, [rbx-3*sizeof.State+State.key]
		mov	rdx, qword[rbx+State.key]
	.hgcs_loopcheck:
		mov	r10, rdx
		xor	r10, qword[r11]
		mov	eax, r10d
		and	eax, 0x1fff	;H1
		cmp	r10, qword[cuckoo+rax*8]
		je	.hgcs_yescyclefound
		mov	eax, r10d
		shr	eax, 16
		and	eax, 0x1fff	;H2
		cmp	r10, qword[cuckoo+rax*8]
		je	.hgcs_yescyclefound
	.hgcs_nocyclefound:
		sub	r11, 2*sizeof.State
		sub	r9d, 2
		jns	.hgcs_loopcheck
.hgcs_not_found:
		mov	word[rbx+State.movelead0], -1
		or	eax,-1
		;jmp	detectRepetition
		ret
	calign 8
	.hgcs_yescyclefound:
		movzx	r10, word[cuckooMove+rax*2]
		mov	rax, qword[rbx+State.Occupied]
		test	rax, qword[BetweenBB+r10*8]
		jnz	.hgcs_nocyclefound
		cmp	r8d, r9d
		jl	.hgcs_found

		mov	eax, r10d
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax],ah
		jne	.Yespiece
		mov	eax, r10d
		shr	eax, 6
		and	eax, 63
	.Yespiece:
		movzx	eax, byte[rbp+Pos.board+rax]
		shr	eax, 3
		cmp	eax, dword[rbp+Pos.sideToMove]
		jne	.hgcs_nocyclefound
		
		cmp	byte[r11-State.key+State.onerep],0
		je	.hgcs_not_found
if	0
		;all move drawish
		mov	word[rbx+State.movelead0], 0x7fff
		xor	eax, eax
		ret
end if
.hgcs_found:
		mov	eax, r10d
		shr	eax, 6
		and	eax, 63
		cmp	byte[rbp+Pos.board+rax],ah
		jne	.test0
		and	r10d, 63
		shl	r10d, 6
		or	r10d, eax
	.test0:
		mov	word[rbx+State.movelead0], r10w
		xor	r8d, r8d
		cmp	r10d, ecx	;dword[rbx+State.excludedMove] if match should continue
		cmovne	eax, r8d
		test	eax, eax
		ret
end if
if	0
	     calign   16
detectRepetition:
	; in	: r8 & r9
		cmp	ecx, MOVE_TYPE_PROM shl 12
		jae	.NO_DRAW
		mov	r8d, ecx
		shr	r8d, 6
		and	r8d, 63
		mov	r9d, ecx
		and	r9d, 63

	; get update rule50 and pliesFromNull
		movzx	eax, byte[rbp+Pos.board+r9]	; eax = TO PIECE
		and	eax, 7
		jnz	.NO_DRAW
		movzx	r10d, byte[rbp+Pos.board+r8]     ; r10 = FROM PIECE
		mov	eax, r10d
		and	eax, 7
		cmp	eax, Pawn
		je	.NO_DRAW
		mov	edx, dword[rbx+State.rule50]
		add	edx, 0x010101
		cmp	edx, (MAX_PLY-1) shl 16
		ja	.YES_DRAW
		cmp	dl, 100
		jae	.YES_DRAW
		cmp	dh, 4
		jl	.NO_DRAW
	; build key
		mov	r11, qword[Zobrist_side]
		xor	r11, qword[rbx+State.key]
	; castling rights
		movzx	eax, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r8]
		or	al, byte[rbp-Thread.rootPos+Thread.castling_rightsMask+r9]
		and	al, byte[rbx+State.castlingRights]
		jnz	.Rights
.RightsRet:
	; ep square hash allready filtered out
		shl	r10d, 6+3
		mov	eax, edx
		xor	r11, qword[Zobrist_Pieces+r10+8*r8]
		xor	r11, qword[Zobrist_Pieces+r10+8*r9]
		lea	r10, [rbx-4*sizeof.State+1*sizeof.State+State.key]	; r9 = i
		mov	edx, 4
.TPDCheckNext:
		cmp	r11, qword[r10]
		je	.TPDKeysMatch
		sub	r10, 2*sizeof.State
		add	edx, 2
		cmp	dl, ah
		jle	.TPDCheckNext
		jmp	.NO_DRAW
.TPDKeysMatch:
		cmp	byte[r10-State.key+State.onerep], 0
		je	@1f
		neg	edx
	@1:
		shr	eax, 16			; State.ply
		cmp	edx, eax
		jl	.YES_DRAW
.NO_DRAW:
		or	eax,-1
		ret
	 calign	  8
.YES_DRAW:
		Display 0, "info string IS DRAWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW......%n"
		mov	word[rbx+State.movelead0], cx
		xor	eax, eax	;eax = VALUE_DRAW
		ret
	     calign	8
.Rights:
		xor	r11, qword[Zobrist_Castling+8*rax]
		jmp	.RightsRet
end if

