;still bug on tb.epd num80
; summary: these functions get strong side in ecx

;IN HaveSpecializedEval NOT NECESSARY to save reg
	     calign   16
EndgameEval_KXK:
Display 2, "KXK%n"
	; Mate with KX vs K. This function is used to evaluate positions with
	; king and plenty of material vs a lone king. It simply gives the
	; attacking side a bonus for driving the defending king towards the edge
	; of the board, and for keeping the distance between the two kings small.
		mov   esi, ecx

	; r15 = strong pieces
		mov	rdi, qword[rbp+Pos.typeBB+8*King]
		mov	r14, qword[rbp+Pos.typeBB+8*rcx]
		and	r14, rdi
		xor	rdi, r14	;and   rdi, qword[rbp+Pos.typeBB+8*rcx]
		bsf	rdi, rdi
	; rdi = weak ksq
		bsf	r14, r14
	; r14 = strong ksq
		cmp	esi, dword[rbp+Pos.sideToMove]
		jne	.CheckStalemate
.NotStalemate:
		shl	r14d, 6
		mov	r9, qword[rbp+Pos.typeBB+8*Bishop]
		mov	r10, qword[rbp+Pos.typeBB+8*Knight]
		mov	r8, qword[rbx+State.checkSq]	;QxR
		movzx   eax, word[rbx+State.npMaterial+2*rsi]
		movzx   edx, byte[PushToEdges+1*rdi]
		movzx   edi, byte[SquareDistance+r14+1*rdi]
		movzx   edi, byte[PushClose+1*rdi]
		movzx	ecx, byte[rbp+Pos.pieceEnd+8*rsi+Pawn]
		and	ecx, 15
		imul	ecx, PawnValueEg
		add	eax, ecx
		add	eax, edi
		add	edi, edx

		mov	rcx, LightSquares
		mov	rdx, DarkSquares
		mov	edi, VALUE_MATE_IN_MAX_PLY - 1
		xor	esi, dword[rbp+Pos.sideToMove]
		neg	esi

	       test	r8, r8
		jnz	.Winning
	       test	r9, r9
		 jz	.Drawish
	       test	r10, r10
		jnz	.Winning
		and	rcx, r9
		 jz	.Drawish
		and	rdx, r9
		 jz	.Drawish
.Winning:
		add	eax, VALUE_KNOWN_WIN
		cmp	eax, edi
	      cmovg	eax, edi
.Drawish:
		xor	eax, esi
		sub	eax, esi
		ret


.CheckStalemate:
		mov	r15, qword[KingAttacks+8*rdi]
		mov	ecx, esi
		xor	ecx, 1
		mov	r10, qword[rbp+Pos.typeBB+8*rcx]
		mov	r11, qword[rbp+Pos.typeBB+8*rsi]
		shl	ecx, 6+3
		 or	r10, r11

 .NextSquare:
		bsf	rdx, r15
	       call	AttackersTo_Side.Set
	       test	rax, rax
		 jz	.NotStalemate
	      _blsr	r15, r15, rax
		jnz	.NextSquare
		or	byte[rbx+State.pvhit], JUMP_IMM_8	;drawish marker
		mov	byte[rbx+State.ltte+MainHashEntry.genBound], JUMP_IMM_8 +BOUND_EXACT
		xor	eax, eax
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KBNK:
Display 2, "KBNK%n"
	; Mate with KBN vs K. This is similar to KX vs K, but we have to drive the
	; defending king towards a corner square of the right color.

		mov   rax, LightSquares
		and   rax, qword[rbp+Pos.typeBB+8*Bishop]
		mov   rdx, qword[rbp+Pos.typeBB+8*King]
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		mov	r11,rdx
		xor   ecx, 1
		and   r10, rdx
		xor	r11, r10
		bsf   r10, r10	 ; strong ksq
		bsf   r11, r11	 ; weak ksq

		neg   rax
		sbb   eax, eax
		and   eax, 0111000b
;		xor   r10d, eax			dont flip strong ksq 20-12-2018
		xor   r11d, eax

		shl   r10, 6
	      movzx   edx, byte[SquareDistance+r10+r11]
	      movzx   edx, byte[PushClose+rdx]
	      movzx   eax, byte[PushToCorners+r11]
		add   eax, VALUE_KNOWN_WIN
		add   eax, edx

		xor   ecx, dword[rbp+Pos.sideToMove]
		sub   ecx, 1
		xor   eax, ecx
		sub   eax, ecx
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KPK:
Display 2, "KPK%n"
	; KP vs K. This endgame is evaluated with the help of a bitbase.

		mov   rdx, qword[rbp+Pos.typeBB+8*rcx]
		mov   r9, qword[rbp+Pos.typeBB+8*King]
		mov   r8, qword[rbp+Pos.typeBB+8*Pawn]
	; rdx = strong pieces
		xor   ecx, 1
	; ecx = weak side
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
	; r10 = weak pieces  should be the long king
		and   r8, rdx
		bsf   r8, r8
	; r8d = strong pawn
		and   r9, rdx
		bsf   r9, r9
	; r9d = strong king
		bsf   r10, r10
	; r10d = weak king
	; if black is the strong side, flip pieces along horizontal axis
		lea   eax, [rcx-1]
		and   eax, 0111000b
	; if weak king is on right side of board, flip pieces along vertical axis
		 bt   r10d, 2
		sbb   edx, edx
		and   edx, 0000111b
	; do the flip
		xor   eax, edx
		xor   r8d, eax
		xor   r9d, eax
		xor   r10d, eax
	; look up entry
		mov   eax, r8d
		shl   r8, 6
		lea   r11, [r8+r9]
		mov   r11, qword[KPKEndgameTable+8*(r11-8*64)]
	; figure out which bit to test
	; bit 2 of weak king should now be 0, so fill it with the correct side
		xor   ecx, dword[rbp+Pos.sideToMove]
		lea   edx, [r10+4*rcx]
		sub   ecx, 1
		shr   eax, 3
		add   eax, VALUE_KNOWN_WIN + PawnValueEg
		xor   eax, ecx
		sub   eax, ecx
	; eax = score if win
		 bt   r11, rdx
		sbb   edx, edx
		and   eax, edx
		ret



	     calign   16
EndgameEval_KRKP:
Display 2, "KRKP%n"
	; KR vs KP. This is a somewhat tricky endgame to evaluate precisely without
	; a bitbase. The function below returns drawish scores when the pawn is
	; far advanced with support of the king, while the attacking king is far
	; away.

		mov	esi, ecx
	       imul	eax, ecx, 56
		mov	r8, qword[rbp+Pos.typeBB+8*rcx]
		mov	r9, qword[rbp+Pos.typeBB+8*King]
		xor	esi, dword[rbp+Pos.sideToMove]	; esi = pos.side_to_move() == weakSide
		mov	r10, qword[rbp+Pos.typeBB+8*Rook]
		mov	r11, qword[rbp+Pos.typeBB+8*Pawn]
		and	r8, r9
		xor	r9, r8
		bsf	r8, r8
		bsf	r9, r9
		bsf   r10, r10
		bsf   r11, r11
		xor   r8d, eax
		xor   r9d, eax
		xor   r10d, eax
		xor   r11d, eax

wksq_ equ r8
bksq_ equ r9
rsq_ equ r10
psq_ equ r11
wksq equ r8d
bksq equ r9d
rsq equ r10d
psq equ r11d

	; If the stronger side's king is in front of the pawn, it's a win
		lea   rax, [8*wksq_]
	      movzx   eax, byte[SquareDistance+8*rax+psq_]
		sub   eax, RookValueEg

if 1
		mov	rcx, qword[ForwardBB+8*wksq_]
		bt	rcx, psq_ ;access memory
		jc	.Return
else
		mov   ecx, wksq
		mov   edx, psq
		and   ecx, 7
		and   edx, 7
		sub   ecx, edx
		mov   edx, psq
		sub   edx, wksq
		sar   edx, 31
		 or   ecx, edx
		 jz   .Return
end if
	; If the weaker side's king is too far from the pawn and the rook,
	; it's a win.
		shl   bksq, 6
	      movzx   ecx, byte[SquareDistance+bksq_+psq_]
	      movzx   edx, byte[SquareDistance+bksq_+rsq_]
		sub   ecx, 3
		sub   ecx, esi
		sub   edx, 3
		 or   ecx, edx
		jns   .Return

	; If the pawn is far advanced and supported by the defending king,
	; the position is drawish

		mov   edx, bksq
		shr   edx, 6+3
		cmp   edx, RANK_3
		 ja   @f
	      movzx   edx, byte[SquareDistance+bksq_+psq_]
		cmp   edx, 1
		jne   @f
		mov   edx, wksq
		shr   edx, 3
		cmp   edx, RANK_4
		 jb   @f
		lea   rdx, [8*wksq_]
	      movzx   edx, byte[SquareDistance+8*rdx+psq_]
		lea   eax, [8*rdx-80]
		mov   ecx, esi
		xor   ecx, 1
		add   ecx, 2
		cmp   edx, ecx
		 ja   .Return
@@:


		shl   wksq, 6
		mov   ecx, psq
		and   ecx, 7
		shl   ecx, 6
	      movzx   edx, byte[SquareDistance+bksq_+psq_+DELTA_S]
	      movzx   eax, byte[SquareDistance+wksq_+psq_+DELTA_S]
	      movzx   ecx, byte[SquareDistance+rcx+psq_]
		sub   eax, edx
		sub   eax, ecx
		lea   eax, [8*rax-200]

.Return:
		sub   esi, 1
		xor   eax, esi
		sub   eax, esi
		ret

restore wksq_
restore bksq_
restore rsq_
restore psq_
restore wksq
restore bksq
restore rsq
restore psq


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KRKB:
Display 2, "KRKB%n"
	; KR vs KB. This is very simple, and always returns drawish scores.  The
	; score is slightly bigger when the defending king is close to the edge.

		xor   ecx, 1
		mov   rax, qword[rbp+Pos.typeBB+8*King]
		and   rax, qword[rbp+Pos.typeBB+8*rcx]
		bsf   rax, rax
	      movzx   eax, byte[PushToEdges+rax]
		xor   ecx, dword[rbp+Pos.sideToMove]
		sub   ecx, 1
		xor   eax, ecx
		sub   eax, ecx
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KRKN:
Display 2, "KRKN%n"
	; KR vs KN. The attacking side has slightly better winning chances than
	; in KR vs KB, particularly if the king and the knight are far apart.

		xor   ecx, 1
		mov   r8, qword[rbp+Pos.typeBB+8*Knight]
		mov   r9, qword[rbp+Pos.typeBB+8*King]
		and   r9, qword[rbp+Pos.typeBB+8*rcx]
		bsf   r8, r8
		bsf   r9, r9
		shl   r8, 6
	      movzx   eax, byte[SquareDistance+r8+r9]
	      movzx   eax, byte[PushAway+rax]
	      movzx   edx, byte[PushToEdges+r9]
		xor   ecx, dword[rbp+Pos.sideToMove]
		sub   ecx, 1
		add   eax, edx
		xor   eax, ecx
		sub   eax, ecx
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KQKP:
Display 2, "KQKP%n"
	; KQ vs KP. In general, this is a win for the stronger side, but there are a
	; few important exceptions. A pawn on 7th rank and on the A,C,F or H files
	; with a king positioned next to it can be a draw, so in that case, we only
	; use the distance between the kings.

		mov   r8, qword[rbp+Pos.typeBB+8*Pawn]
		mov   rdx, qword[rbp+Pos.typeBB+8*King]
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		lea   r9d, [1+5*rcx]  ; weak 7th rank
		xor   ecx, 1
		and   r10, rdx
		mov	r11, rdx
		xor	r11, r10
		bsf   r10, r10	 ; strong ksq
		bsf   r11, r11	 ; weak ksq
		bsf   rdx, r8	 ; weak pawn sq
		shl   r11, 6
		mov   rax, FileABB or FileCBB or FileFBB or FileHBB
		and   r8, rax
		cmp   r8, 1
		sbb   r8d, r8d
	      movzx   eax, byte[SquareDistance+r11+rdx]
		sub   eax, 1
		 or   eax, r8d
		shr   edx, 3
		xor   edx, r9d
		 or   eax, edx
		neg   eax
		sbb   eax, eax
		and   eax, QueenValueEg - PawnValueEg
	      movzx   edx, byte[SquareDistance+r11+r10]
	      movzx   edx, byte[PushClose+rdx]
		xor   ecx, dword[rbp+Pos.sideToMove]
		sub   ecx, 1
		add   eax, edx
		xor   eax, ecx
		sub   eax, ecx
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KQKR:
Display 2, "KQKR%n"
	; KQ vs KR.  This is almost identical to KX vs K:  We give the attacking
	; king a bonus for having the kings close together, and for forcing the
	; defending king towards the edge. If we also take care to avoid null move for
	; the defending side in the search, this is usually sufficient to win KQ vs KR.

		mov   rdx, qword[rbp+Pos.typeBB+8*King]
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		xor   ecx, 1
		mov   r11, rdx
		and   r10, rdx
		xor	r11, r10
		bsf   r10, r10	 ; strong ksq
		bsf   r11, r11	 ; weak ksq
		shl   r10, 6
	      movzx   edx, byte[SquareDistance+r10+r11]
	      movzx   edx, byte[PushClose+rdx]
	      movzx   eax, byte[PushToEdges+r11]
		xor   ecx, dword[rbp+Pos.sideToMove]
		sub   ecx, 1
		add   eax, QueenValueEg - RookValueEg
		add   eax, edx
		xor   eax, ecx
		sub   eax, ecx
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameEval_KNNK:
Display 2, "KNNK%n"
	; Some cases of trivial draws
		xor   eax, eax
		ret

	     calign   16
EndgameEval_KNNKP:
Display 2, "KNNKP%n"
		xor	ecx, 1
		mov	rdx, qword[rbp+Pos.typeBB+8*King]
		and	rdx, qword[rbp+Pos.typeBB+8*rcx]
		bsf	rdx, rdx	 ; weak ksq
		movzx   eax, byte[PushToEdges+rdx]
		add	eax, 2*KnightValueEg-PawnValueEg
if	0
		shl	rdx,6
		mov	r8, qword[rbp+Pos.typeBB+8*Knight]
		bsf	r9, r8
		bsr	r8, r8
	      movzx   r10, byte[SquareDistance+rdx+r8]
	      movzx   r11, byte[SquareDistance+rdx+r9]
	      add	r10,r11
		shl	r10, 1	;3 good
		sub	eax, r10d
end if		
		xor	ecx, dword[rbp+Pos.sideToMove]
		sub	ecx, 1
		xor	eax, ecx
		sub	eax, ecx
		ret

;Note: in Scale not necessary to save into stack for rdi, ecx only r15, r12, r13, r14, rsi
;	in = r11 = qword[rbp+Pos.typeBB+8*Pawn]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KBPsK:
Display 2, "KBPsK%n"
	; r8 = pawns
	; r9 = strong pieces
		mov   r8, r11	;qword[rbp+Pos.typeBB+8*Pawn]
		mov   r9, qword[rbp+Pos.typeBB+8*rcx]
	; are all of the pawns on B or G file?
		mov   r10, not FileBBB
	       test   r8, r10
		 jz   .AllOnBFile
		mov   r10, not FileGBB
	       test   r8, r10
		 jz   .AllOnGFile
	; are all of the strong pawns on A or H file?
		and   r8, r9
		mov   rax, not FileABB
		mov   r11, LightSquares
		mov   edx, SQ_A8
	       test   r8, rax
		 jz   .OnAFile
		mov   rax, not FileHBB
	       test   r8, rax
		 jnz	.ReturnNone
		not   r11
		add   edx, 7
.OnAFile:
		neg   rcx
		xor   r11, rcx
	; r11 = color bb of queening square
		and   r9, qword[rbp+Pos.typeBB+8*Bishop]
	       test   r11, r9
		jnz   .ReturnNone
	; r9 = strong bishop bitboard
		mov   rax, qword[rbp+Pos.typeBB+8*King]
		and   rax, qword[rbp+Pos.typeBB+8+8*rcx]
		bsf   rax, rax
	; eax = weak king square
		and   ecx, 56
		xor   edx, ecx
	; edx = queening square
	; bishop is opp color as queening square
		shl   eax, 6
		cmp   byte[SquareDistance+rdx+rax], 2
		jae   .ReturnNone
	; distance(queeningSq, kingSq) <= 1
		xor   eax, eax
;Display 0, "info string eval::KBPsK=%i0%n"
		ret
	     calign   8
.ReturnNone:
;Display 0, "info string eval::KBPsK=%i0%n"
		mov   eax, SCALE_FACTOR_NONE
		ret

	     calign   8
.AllOnBFile:
.AllOnGFile:
	; r8 = pawns
		xor   ecx, 1
	; ecx = weak side
		mov   r11, qword[rbp+Pos.typeBB+8*rcx]
	; r11 = weak pieces
	      movzx   eax, word[rbx+State.npMaterial+2*rcx]
		and   r8, r11
		 jz   .ReturnNone
	       test   eax, eax
		jnz   .ReturnNone
		and   r11, qword[rbp+Pos.typeBB+8*King]
		bsf   r11, r11
	; r11 = weakKingSq
		xor   ecx, 1
	; ecx = strong side
		 jz   .BlackIsWeak
		bsf   r8, r8
		jmp   .WhiteIsWeak
	.BlackIsWeak:
		bsr   r8, r8
	.WhiteIsWeak:
	; r8 = weakPawnSq
		mov   r10, qword[rbp+Pos.typeBB+8*Bishop]
		and   r10, r9
		bsf   r10, r10
	; r10 = bishopSq
	       imul   edx, ecx, 7
		mov   eax, r8d
		shr   eax, 3
		xor   eax, edx
		cmp   eax, RANK_7
		jne   .ReturnNone2
	; relative_rank(strongSide, weakPawnSq) == RANK_7
		lea   eax, [2*rcx-1]
		lea   eax, [r8+8*rax]
	; eax = weakPawnSq + pawn_push(weakSide)
		mov   rdx, qword[rbp+Pos.typeBB+8*Pawn]
		and   rdx, r9
		 bt   rdx, rax
		jnc   .ReturnNone2
	; pos.pieces(strongSide, PAWN) & (weakPawnSq + pawn_push(weakSide))
		and   r9, qword[rbp+Pos.typeBB+8*King]
		bsf   r9, r9
	; r9 = strongKingSq
	      _blsr   rax, rdx
	; rax is zero if strong has one pawn
		 jz   @f
		xor   r10d, r8d
		and   r10d, 01001b
		 jz   .ReturnNone2
		cmp   r10d, 01001b
		 je   .ReturnNone2
    @@: ; opposite_colors(bishopSq, weakPawnSq) || pos.count<PAWN>(strongSide) == 1)
		shl   r8, 6
	      movzx   eax, byte[SquareDistance+r8+r11]
	      movzx   edx, byte[SquareDistance+r8+r9]
		cmp   eax, 3
		jae   .ReturnNone2
		cmp   eax, edx
		 ja   .ReturnNone2
	       imul   edx, ecx, 56
		xor   edx, r11d
		cmp   edx, SQ_A7
		 jb   .ReturnNone2
;		cmp	dword[rbp+Pos.sideToMove], ecx
;		je	@1f
;		or	byte[rbx+State.pvhit], JUMP_IMM_8	;drawish marker
;	@1:
		xor   eax, eax
		ret
	     calign   8
.ReturnNone2:
		mov   eax, SCALE_FACTOR_NONE
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KQKRPs:
Display 2, "KQKRPs%n"
		mov   eax, ecx
		xor   ecx, 1
		mov   rdx, qword[rbp+Pos.typeBB+8*rcx]
		mov   r9, qword[rbp+Pos.typeBB+8*King]
		mov   r10, qword[rbp+Pos.typeBB+8*Rook]
		mov	r8, r9
		and   r10, rdx
		and   r9, rdx
		xor	r8,r9
		bsf   r8, r8
		bsf   r9, r9
		bsf   r10, r10
	; r8 = strong ksq
	; r9 = kingSq
	; r10 = rsq
	       imul   edx, ecx, 56
		xor   r8d, edx
		cmp   r8d, SQ_A4
		 jb   .ReturnNone
		shl   eax, 6+3
		and   r11, qword[KingAttacks+8*r9]	;only one side pawn
		and   r11, qword[PawnAttacks+rax+8*r10]
		 jz   .ReturnNone
		xor   r9d, edx
		cmp   r9d, SQ_A3
		jae   .ReturnNone
		xor   r10d, edx
		shr   r10d, 3
		cmp   r10d, RANK_3
		jne   .ReturnNone
		xor   eax, eax
		ret
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
		ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KRPKR:
Display 2, "KRPKR%n"

		push	r15 r13 r12
		mov	r10, qword[rbp+Pos.typeBB+8*rcx]
		mov	r12, qword[rbp+Pos.typeBB+8*King]
		mov	r9, qword[rbp+Pos.typeBB+8*Rook]
		bsf	r8, r11	;only one pawn
		mov	r11, r9
		and	r9, r10
		xor	r11, r9
		bsf	r9, r9
		bsf	r11, r11
		and	r10, r12
		xor	r12, r10
		bsf	r10, r10	;wk
		bsf	r12, r12	;bk
		xor	ecx, 1
		lea	edx, [rcx-1]
		and	edx, 0111000b
		 bt	r8d, 2
		sbb	eax, eax
		and	eax, 0000111b
		xor	eax, edx
		xor	r8d, eax
		xor	r9d, eax
		xor	r10d, eax
		xor	r11d, eax
		xor	r12d, eax

wpsq_ equ r8
wrsq_ equ r9
wksq_ equ r10
brsq_ equ r11
bksq_ equ r12
wpsq equ r8d
wrsq equ r9d
wksq equ r10d
brsq equ r11d
bksq equ r12d

f_ equ r13
r_ equ rdi
qs_ equ r15
f equ r13d
r equ edi
qs equ r15d

		mov   f, wpsq
		and   f, 7
		mov   r, wpsq
		shr   r, 3
		lea   qs, [8*7+f_]
		xor   ecx, dword[rbp+Pos.sideToMove]
	; ecx = tempo
.l1:
		cmp   r, RANK_5
		 ja   .l2
	       imul   eax, bksq, 64
		cmp   byte[SquareDistance+rax+qs_], 1
		 ja   .l2
		cmp   wksq, SQ_H5
		 ja   .l2
		mov   eax, brsq
		shr   eax, 3
		cmp   eax, RANK_6
		 je   .ReturnDraw
		cmp   r, RANK_3
		 ja   .l2
		mov   eax, wrsq
		shr   eax, 3
		cmp   eax, RANK_6
		jne   .ReturnDraw
.l2:
		cmp   r, RANK_6
		jne   .l3
	       imul   eax, bksq, 64
		cmp   byte[SquareDistance+rax+qs_], 1
		 ja   .l3
		mov   eax, wksq
		shr   eax, 3
		add   eax, ecx
		cmp   eax, RANK_6
		 ja   .l3
		mov   eax, brsq
		shr   eax, 3
		cmp   eax, RANK_1
		 je   .ReturnDraw
	       test   ecx, ecx
		jnz   .l3
		mov   eax, brsq
		mov   edx, wpsq
		and   eax, 7
		and   edx, 7
		sub   eax, edx
		cmp   eax, 3
		jge   .ReturnDraw
		cmp   eax, -3
		jle   .ReturnDraw
.l3:
		cmp   r, RANK_6
		 jb   .l4
		cmp   bksq, qs
		jne   .l4
		mov   eax, brsq
		shr   eax, 3
		cmp   eax, RANK_1
		jne   .l4
	       test   ecx, ecx
		 jz   .ReturnDraw
	       imul   eax, wksq, 64
		cmp   byte[SquareDistance+rax+wpsq_], 2
		jae   .ReturnDraw
.l4:
		cmp   wpsq, SQ_A7
		jne   .l5
		cmp   wrsq, SQ_A8
		jne   .l5
		cmp   bksq, SQ_H7
		 je   @f
		cmp   bksq, SQ_G7
		jne   .l5
	@@:	
                mov   eax, brsq
		and   eax, 7
		cmp   eax, FILE_A
		jne   .l5
		mov   eax, brsq
		shr   eax, 3
		cmp   eax, RANK_3
		jbe   .ReturnDraw
		mov   eax, wksq
		and   eax, 7
		cmp   eax, FILE_D
		jae   .ReturnDraw
		mov   eax, wksq
		shr   eax, 3
		cmp   eax, RANK_5
		jbe   .ReturnDraw
.l5:
		cmp   r, RANK_5
		 ja   .l6
		lea   eax, [wpsq_+DELTA_N]
		cmp   eax, bksq
		jne   .l6
	       imul   eax, wksq, 64
	      movzx   eax, byte[SquareDistance+rax+wpsq_]
		sub   eax, ecx
		cmp   eax, 2
		 jl   .l6
	       imul   eax, wksq, 64
	      movzx   eax, byte[SquareDistance+rax+brsq_]
		sub   eax, ecx
		cmp   eax, 2
		jge   .ReturnDraw
.l6:
		cmp   r, RANK_7
		jne   .l7
		cmp   f, FILE_A
		 je   .l7
		mov   eax, wrsq
		and   eax, 7
		cmp   eax, f
		jne   .l7
		cmp   wrsq, qs
		 je   .l7
	       imul   eax, wksq, 64
	       imul   edx, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+qs_]
	      movzx   edx, byte[SquareDistance+rdx+qs_]
		;sub   edx, 2
		;add   edx, ecx
		lea	edx,[edx+ecx-2]
		cmp   eax, edx
		jge   .l7
	       imul   edx, bksq, 64
	      movzx   edx, byte[SquareDistance+rdx+wrsq_]
		add   edx, ecx
		cmp   eax, edx
		jge   .l7
		add   eax, eax
		sub   eax, SCALE_FACTOR_MAX
		neg   eax
		pop   r12 r13 r15
		ret
.l7:
		cmp   f, FILE_A
		 je   .l8
		mov   eax, wrsq
		and   eax, 7
		cmp   eax, f
		jne   .l8
		cmp   wrsq, wpsq
		jae   .l8
	       imul   eax, wksq, 64
	       imul   edx, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+qs_]
	      movzx   edx, byte[SquareDistance+rdx+qs_]
		;sub   edx, 2
		;add   edx, ecx
		lea	edx,[edx+ecx-2]
		cmp   eax, edx
		jge   .l8
	       imul   eax, wksq, 64
	       imul   edx, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+wpsq_+DELTA_N]
	      movzx   edx, byte[SquareDistance+rdx+wpsq_+DELTA_N]
		lea	edx,[edx+ecx-2]
		;sub   edx, 2
		;add   edx, ecx
		cmp   eax, edx
		jge   .l8
	       imul   eax, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+wrsq_]
		add   eax, ecx
		cmp   eax, 3
		jge   @f
	       imul   eax, wksq, 64
	       imul   edx, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+qs_]
	      movzx   edx, byte[SquareDistance+rdx+wrsq_]
		add   edx, ecx
		cmp   eax, edx
		jge   .l8
	       imul   eax, wksq, 64
	       imul   edx, bksq, 64
	      movzx   eax, byte[SquareDistance+rax+wpsq_+DELTA_N]
	      movzx   edx, byte[SquareDistance+rdx+wrsq_]
		add   edx, ecx
		cmp   eax, edx
		jge   .l8
	@@:
	       imul   eax, wpsq, 64
	       imul   edx, wksq, 64
	      movzx   eax, byte[SquareDistance+rax+qs_]
	      movzx   edx, byte[SquareDistance+rdx+qs_]
	       imul   eax, -8
	       imul   edx, -2
		add   eax, SCALE_FACTOR_MAX
		add   eax, edx
		pop   r12 r13 r15
		ret
.l8:
		cmp   r, RANK_4
		 ja   .l9
		cmp   bksq, wpsq
		 jb   .l9
		mov   eax, bksq
		and   eax, 7
		mov   edx, wpsq
		and   edx, 7
		cmp   eax, edx
		jne   @f
		mov   eax, 10
		pop   r12 r13 r15
		ret
	@@:
		mov   eax, bksq
		and   eax, 7
		mov   edx, wpsq
		and   edx, 7
		sub   eax, edx
		add   eax, 1
	       test   eax, not 2
		jnz   .l9
	       imul   eax, wksq, 64
	      movzx   eax, byte[SquareDistance+rax+bksq_]
		cmp   eax, 2
		jbe   .l9
		add   eax, eax
		sub   eax, 24
		neg   eax
		pop   r12 r13 r15
		ret
.l9:
		mov   eax, SCALE_FACTOR_NONE
		pop   r12 r13 r15
		ret
.ReturnDraw:
		xor   eax, eax
		pop   r12 r13 r15
		ret



restore wpsq_
restore wrsq_
restore wksq_
restore brsq_
restore bksq_
restore wpsq
restore wrsq
restore wksq
restore brsq
restore bksq

restore f_
restore r_
restore qs_
restore f
restore r
restore qs


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KRPKB:
Display 2, "KRPKB%n"

ksq_ equ r8
bsq_ equ r9
psq_ equ r10
ppush_	equ r11
ksq equ r8d
bsq equ r9d
psq equ r10d
ppush  equ r11d
		mov   rax, FileABB or FileHBB
	       test   rax, r11
		 jz   .ReturnNone
		bsf   r10, r11	;only one side pawn
		xor   ecx, 1
		mov   r8, qword[rbp+Pos.typeBB+8*rcx]
		and   r8, qword[rbp+Pos.typeBB+8*King]
		mov   r9, qword[rbp+Pos.typeBB+8*Bishop]
		bsf   r9, r9	;only one side bishop
		bsf   r8, r8
		lea   ppush_, [2*rcx-1]
		shl   ppush_, 3
		xor   ecx, 1
	       imul   edx, ecx, 7
		mov   eax, psq
		shr   eax, 3
		xor   eax, edx
		cmp   eax, RANK_5
		 je   .Rank5
		cmp   eax, RANK_6
		 je   .Rank6
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
.Return:
		ret
.Rank6:
	       imul   eax, ksq, 64
		add   eax, psq
	      movzx   eax, byte[SquareDistance+rax+2*ppush_]
		cmp   eax, 1
		 ja   .ReturnNone
		lea   eax, [psq+ppush]
		mov   rdx, qword[BishopAttacksPDEP+8*bsq_]
		 bt   rdx, rax
		jnc   .ReturnNone
		mov   eax, bsq
		mov   edx, psq
		and   eax, 7
		and   edx, 7
		sub   eax, edx
		add   eax, 1
		cmp   eax, 3
		 jb   .ReturnNone
		mov   eax, 8
		ret
.Rank5:
		mov   eax, bsq
		xor   eax, psq
		and   eax, 01001b
		cmp   eax, 01000b
		 je   .ReturnNone
		cmp   eax, 00001b
		 je   .ReturnNone
		lea   edx, [psq_+ppush_]
		lea   edx, [rdx+2*ppush_]
                shl   edx, 6
	      movzx   edx, [SquareDistance+rdx+ksq_]
;		mov   eax, 48
		cmp   edx, 2
		 ja   .Return48
		mov   eax, 24
	       test   edx, edx
		jnz   .Return24
		sub   ksq, ppush
		sub   ksq, ppush
		mov   rdx, qword[rbp+Pos.typeBB+8*King]
		and   rdx, qword[rbp+Pos.typeBB+8*rcx]
		bsf   rdx, rdx
		cmp   ksq, edx
		jne   .Return
.Return48:
		mov   eax, 48
.Return24:
		ret
restore ksq_
restore bsq_
restore psq_
restore ppush_
restore ksq
restore bsq
restore psq
restore ppush


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KRPPKRP:
Display 2, "KRPPKRP%n"

wpsq1_ equ r8
wpsq2_ equ r9
bksq_  equ r10
wpsq1 equ r8d
wpsq2 equ r9d
bksq  equ r10d
KRPPKRPScaleFactors equ (0+256*(9+256*(10+256*(14+256*(21+256*(44))))))

	       imul   eax, ecx, 64*8
		mov	r8, r11
		and	r8, qword[rbp+Pos.typeBB+8*rcx]
		xor	r11, r8	;opp pawn	=weak pawn
		bsf	r9, r8
		bsr	r8, r8
	       test	r11, qword[PassedPawnMask+rax+8*r8]
		 jz	.ReturnNone
	       test	r11, qword[PassedPawnMask+rax+8*r9]
		 jz	.ReturnNone
		xor   ecx, 1
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		and   r10, qword[rbp+Pos.typeBB+8*King]
		bsf   r10, r10
		lea   eax, [rcx-1]
		and   eax, 7
		mov   r11d, wpsq1
		mov   edx, wpsq2
		shr   r11d, 3
		shr   edx, 3
		xor   r11d, eax
		xor   edx, eax
		cmp   r11d, edx
	      cmovb   r11d, edx
		mov   edx, bksq
		shr   edx, 3
		xor   edx, eax
		cmp   edx, r11d
		jbe   .ReturnNone
		mov   eax, bksq
		and   eax, 7
		mov   edx, wpsq1
		and   edx, 7
		sub   eax, edx
		add   eax, 1
		cmp   eax, 3
		jae   .ReturnNone
		mov   eax, bksq
		and   eax, 7
		mov   edx, wpsq2
		and   edx, 7
		sub   eax, edx
		add   eax, 1
		cmp   eax, 3
		jae   .ReturnNone
		mov   rax, KRPPKRPScaleFactors
		lea   ecx, [8*r11]
		shr   rax, cl
	      movzx   eax, al
		ret
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
		ret
restore wpsq1_
restore wpsq2_
restore bksq_
restore wpsq1
restore wpsq2
restore bksq
restore KRPPKRPScaleFactors


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KPsK:
Display 2, "KPsK%n"

pawns equ r11
ksq  equ r9d
ksq_  equ r9

;		and   r11, qword[rbp+Pos.typeBB+8*rcx]	;only one side pawn
		xor   ecx, 1
		mov   r9, qword[rbp+Pos.typeBB+8*rcx]
		and   r9, qword[rbp+Pos.typeBB+8*King]
		bsf   r9, r9
		mov   eax, ksq
		and   eax, 7
		bsf   rdx, pawns
		and   edx, 7
		sub   eax, edx
		add   eax, 1
		cmp   eax, 3
		jae   .ReturnNone
		shl	ecx, 9
		mov	rax, qword[ForwardBB+rcx+8*ksq_]
		not   rax
	       test   rax, pawns
		jnz   .ReturnNone
		mov   rax, not FileABB
		and   rax, pawns
		 jz   .Return
		mov   rax, not FileHBB
		and   rax, pawns
		 jz   .Return
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
.Return:
		ret
restore pawns
restore ksq
restore ksq_


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KBPKB:
Display 2, "KBPKB%n"

pawnSq	       equ r8d
strongBishopSq equ r9d
weakBishopSq   equ r10d
weakKingSq     equ r11d
pawnSq_ 	equ r8
strongBishopSq_ equ r9
weakBishopSq_	equ r10
weakKingSq_	equ r11

		mov   r8, qword[rbp+Pos.typeBB+8*rcx]
		xor   ecx, 1
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		mov   r9, qword[rbp+Pos.typeBB+8*Bishop]
		mov   r11, qword[rbp+Pos.typeBB+8*King]
		and   r11, r10
		and   r10, r9
		and   r9, r8
		and   r8, qword[rbp+Pos.typeBB+8*Pawn]
		bsf   r8, r8
		bsf   r9, r9
		bsf   r10, r10
		bsf   r11, r11
		mov   eax, weakKingSq
		and   eax, 7
		mov   edx, pawnSq
		and   edx, 7
		cmp   eax, edx
		jne   .c2
		lea   ecx, [rcx-1]
		and   ecx, 7
		mov   eax, pawnSq
		shr   eax, 3
		mov   edx, weakKingSq
		shr   edx, 3
		xor   eax, ecx
		xor   edx, ecx
		cmp   eax, edx
		jae   .c2
		mov   edx, weakKingSq
		shr   edx, 3
		xor   edx, ecx
		cmp   edx, RANK_6
		jbe   .ReturnDraw
		mov   eax, weakKingSq
		xor   eax, strongBishopSq
		and   eax, 01001b
		 jz   .c2
		cmp   eax, 01001b
		 je   .c2
.ReturnDraw:
		xor   eax, eax
		ret
.c2:
		xor	strongBishopSq_, weakBishopSq_
		mov	rcx, strongBishopSq_
		shr	strongBishopSq_, 3
		xor	strongBishopSq_, rcx
		and	strongBishopSq_, 0x1
		jnz	.ReturnDraw
if	0
		mov	eax, weakBishopSq
		xor	eax, strongBishopSq
		and	eax, 01001b
		jnz	.ReturnDraw
		cmp	eax, 01001b
		jne	.ReturnDraw
end if
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
		ret

restore pawnSq
restore strongBishopSq
restore weakBishopSq
restore weakKingSq
restore pawnSq_
restore strongBishopSq_
restore weakBishopSq_
restore weakKingSq_



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KBPPKB:
Display 2, "KBPPKB%n"

wbsq equ r8d
bbsq equ r9d
ksq  equ r10d
psq1 equ r11d
psq2 equ r12d
blockSq1 equ r13d
blockSq2 equ edi
wbsq_ equ r8
bbsq_ equ r9
ksq_  equ r10
psq1_ equ r11
psq2_ equ r12
blockSq1_ equ r13
blockSq2_ equ rdi

		push	r15 r13 r12
		mov	r8, qword[rbp+Pos.typeBB+8*rcx]
		mov	r9, qword[rbp+Pos.typeBB+8*Bishop]
		xor	ecx, 1
		mov	r10, qword[rbp+Pos.typeBB+8*rcx]
		and	r10, qword[rbp+Pos.typeBB+8*King]

		and	r8, r9
		xor	r9, r8
		bsf	r8, r8
		bsf	r9, r9
;opposite colorcheck removed
		bsf   r10, r10
		bsf   r12, r11	;only one side pawn
		bsr   r11, r11	;only one side pawn
	       test   ecx, ecx
		 jz   @f
	       xchg   r11d, r12d ; ensure relative_rank(strongSide, psq1) <= relative_rank(strongSide, psq2)
	@@:
		lea   rax, [2*rcx-1]
		lea   blockSq1, [psq2_+8*rax]
		mov   blockSq2, psq1
		and   blockSq2, 7
		mov   edx, psq2
		and   edx, 0111000b
		add   blockSq2, edx
		mov   eax, ksq
		xor   eax, wbsq
		and   eax, 01001b
		 jz   .ReturnNone2
		cmp   eax, 01001b
		 je   .ReturnNone2
		mov   eax, psq1
		and   eax, 7
		mov   edx, psq2
		and   edx, 7
		sub   eax, edx
		 je   .c0
		cmp   eax, 1
		 je   .c1
		cmp   eax, -1
		 je   .c1
		jmp   .ReturnNone2
.c0:
		mov   eax, ksq
		and   eax, 7
		mov   edx, blockSq1
		and   edx, 7
		cmp   eax, edx
		jne   .ReturnNone2
		mov   eax, ksq
		shr   eax, 3
		mov   edx, blockSq1
		shr   edx, 3
		lea   ecx, [rcx-1]
		and   ecx, 7
		xor   eax, ecx
		xor   edx, ecx
		cmp   eax, edx
		 jb   .ReturnNone2
.ReturnDraw:
		xor   eax, eax
		pop   r12 r13 r15
		ret
.c1:
		cmp   ksq, blockSq1
		jne   .c12
		cmp   bbsq, blockSq2
		 je   .ReturnDraw
		mov   eax, psq1
		shr   eax, 3
		mov   edx, psq2
		shr   edx, 3
		sub   eax, edx
		add   eax, 1
		cmp   eax, 3
		jae   .ReturnDraw
      BishopAttacks   rax, blockSq2_, qword[rbx+State.Occupied], rdx
		and   rax, qword[rbp+Pos.typeBB+8*rcx]
		and   rax, qword[rbp+Pos.typeBB+8*Bishop]
		jnz   .ReturnDraw
.ReturnNone2:
		mov   eax, SCALE_FACTOR_NONE
		pop   r12 r13 r15
		ret
.c12:
		cmp   ksq, blockSq2
		jne   .ReturnNone2
		cmp   bbsq, blockSq1
		 je   .ReturnDraw
      BishopAttacks   rax, blockSq1_, qword[rbx+State.Occupied], rdx
		and   rax, qword[rbp+Pos.typeBB+8*rcx]
		and   rax, qword[rbp+Pos.typeBB+8*Bishop]
		jnz   .ReturnDraw
		mov   eax, SCALE_FACTOR_NONE
		pop   r12 r13 r15
		ret
restore wbsq
restore bbsq
restore ksq
restore psq1
restore psq2
restore blockSq1
restore blockSq2
restore wbsq_
restore bbsq_
restore ksq_
restore psq1_
restore psq2_
restore blockSq1_
restore blockSq2_



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KBPKN:
Display 2, "KBPKN%n"

pawnSq	       equ r8d
strongBishopSq equ r9d
weakKingSq     equ r10d
pawnSq_ 	equ r8
strongBishopSq_ equ r9
weakKingSq_	equ r10

		xor   ecx, 1
		mov   r9, qword[rbp+Pos.typeBB+8*Bishop]
		mov   r10, qword[rbp+Pos.typeBB+8*rcx]
		and   r10, qword[rbp+Pos.typeBB+8*King]
		bsf   r8, r11	;only one Pawn
		bsf   r9, r9	;only one Bishop
		bsf   r10, r10
		mov   eax, weakKingSq
		and   eax, 7
		mov   edx, pawnSq
		and   edx, 7
		cmp   eax, edx
		jne   .ReturnNone
		lea   ecx, [rcx-1]
		and   ecx, 7
		mov   eax, pawnSq
		shr   eax, 3
		mov   edx, weakKingSq
		shr   edx, 3
		xor   eax, ecx
		xor   edx, ecx
		cmp   eax, edx
		jae   .ReturnNone
		mov   edx, weakKingSq
		shr   edx, 3
		xor   edx, ecx
		cmp   edx, RANK_6
		jbe   @f
		mov   eax, weakKingSq
		xor   eax, strongBishopSq
		and   eax, 01001b
		 jz   .ReturnNone
		cmp   eax, 01001b
		 je   .ReturnNone
	@@:
		xor   eax, eax
		ret
.ReturnNone:
		mov   eax, SCALE_FACTOR_NONE
		ret
restore pawnSq
restore strongBishopSq
restore weakKingSq
restore pawnSq_
restore strongBishopSq_
restore weakKingSq_


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KNPK:
Display 2, "KNPK%n"
		bsf   r11, r11	;only one Pawn
		xor   ecx, 1
		mov   r9, qword[rbp+Pos.typeBB+8*King]
		and   r9, qword[rbp+Pos.typeBB+8*rcx]
		bsf   r9, r9
		lea   edx, [rcx-1]
		and   edx, 0111000b
		 bt   r11d, 2
		sbb   eax, eax
		and   eax, 0000111b
		xor   eax, edx
		xor   r11d, eax
		xor   r9d, eax
		mov   eax, SCALE_FACTOR_NONE
		cmp   r11d, SQ_A7
		jne   .Return
	      movzx   edx, byte[SquareDistance+64*SQ_A8+r9]
		cmp   edx, 1
		 ja   .Return
		xor   eax, eax
.Return:
		ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KNPKB:
Display 2, "KNPKB%n"

pawnSq	   equ r8d
bishopSq   equ r9d
weakKingSq equ r10d
pawnSq_     equ r8
bishopSq_   equ r9
weakKingSq_ equ r10

		mov	r8, qword[rbp+Pos.typeBB+8*rcx]
		mov	r10, qword[rbp+Pos.typeBB+8*King]
		mov	r9, qword[rbp+Pos.typeBB+8*Bishop]	;only one bishop
		not	r8
		and	r10, r8
		bsf	r8, r11		;only one pawn
		bsf	r9, r9
      BishopAttacks   rax, bishopSq_, qword[rbx+State.Occupied], rdx
		shl	ecx, 6+3
	       test	rax, qword[ForwardBB+rcx+8*pawnSq_]
		jnz	@f
		mov	eax, SCALE_FACTOR_NONE
		ret
@@:
		bsf	r10, r10
	       imul	eax, weakKingSq, 64
	      movzx	eax, byte[SquareDistance+rax+pawnSq_]
		ret
restore pawnSq
restore bishopSq
restore weakKingSq
restore pawnSq_
restore bishopSq_
restore weakKingSq_


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	     calign   16
EndgameScale_KPKP:
Display 2, "KPKP%n"

		mov   rdx, qword[rbp+Pos.typeBB+8*rcx]
		mov   r9, qword[rbp+Pos.typeBB+8*King]
		mov   r8, r11	;qword[rbp+Pos.typeBB+8*Pawn]
	; rdx = strong pieces
		xor   ecx, 1
	; ecx = weak side
		mov	r10, r9
	; r10 = weak pieces  should be the long king
		and   r8, rdx
		bsf   r8, r8
	; r8d = strong pawn
		and   r9, rdx
		xor	r10, r9
		bsf   r9, r9
	; r9d = strong king
		bsf   r10, r10
	; r10d = weak king
	; if black is the strong side, flip pieces along horizontal axis
		lea   eax, [rcx-1]
		and   eax, 0111000b
	; if weak king is on right side of board, flip pieces along vertical axis
		 bt   r10d, 2
		sbb   edx, edx
		and   edx, 0000111b
	; do the flip
		xor   eax, edx
		xor   r8d, eax
		xor   r9d, eax
		xor   r10d, eax
		lea   eax, [r8d+1]
		and   eax, 7
		cmp   r8d, SQ_A5
		 jb   .try_KPK
		cmp   eax, 2
		 jb   .try_KPK
		mov   eax, SCALE_FACTOR_NONE
		ret
.try_KPK:
	; look up entry
		mov   eax, r8d
		shl   r8, 6
		lea   r11, [r8+r9]
		mov   r11, qword[KPKEndgameTable+8*(r11-8*64)]
	; figure out which bit to test
	; bit 2 of weak king should now be 0, so fill it with the correct side
		xor   ecx, dword[rbp+Pos.sideToMove]
		lea   edx, [r10+4*rcx]
		sub   ecx, 1
		shr   eax, 3
		add   eax, VALUE_KNOWN_WIN + PawnValueEg
		xor   eax, ecx
		sub   eax, ecx
	; eax = score if win
		 bt   r11, rdx
		sbb   eax, eax
		and   eax, SCALE_FACTOR_NONE
		ret
