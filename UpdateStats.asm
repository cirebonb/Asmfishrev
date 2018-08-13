
macro UpdateCmStats ss, offset, bonus32, absbonus, t1
	; bonus32 is 32*bonus
	; absbonus is abs(bonus)
	; clobbers rax, rcx, rdx, t1
  local over1, over2, over3
	     Assert   b, absbonus, 324, 'assertion abs(bonus)<324 failed in UpdateCmStats'

		cmp   dword[ss-1*sizeof.State+State.currentMove], 1
		 jl   over1
		mov   t1, qword[ss-1*sizeof.State+State.counterMoves]
	apply_bonus   (t1+4*(offset)), bonus32, absbonus, 936
over1:

		cmp   dword[ss-2*sizeof.State+State.currentMove], 1
		 jl   over2
		mov   t1, qword[ss-2*sizeof.State+State.counterMoves]
	apply_bonus   (t1+4*(offset)), bonus32, absbonus, 936
over2:

		cmp   dword[ss-4*sizeof.State+State.currentMove], 1
		 jl   over3
		mov   t1, qword[ss-4*sizeof.State+State.counterMoves]
	apply_bonus   (t1+4*(offset)), bonus32, absbonus, 936
over3:
end macro


macro UpdateStats move, quiets, quietsCnt, bonus32, absbonus, prevOffset
	; clobbers rax, rcx, rdx, r8, r9
	; it also might clobber rsi and change the sign of bonus32
  local DontUpdateKillers, DontUpdateOpp, NextQuiet, Return, Continue

		xor	eax, eax
		cmp	rax, qword[rbx+State.checkersBB]
		jne	DontUpdateKillers

		mov	eax, dword[rbx+State.killers+4*0]
		cmp	eax, move
		je	DontUpdateKillers
		mov	dword[rbx+State.killers+4*1], eax
		mov	dword[rbx+State.killers+4*0], move
DontUpdateKillers:
		cmp	dword[rbx-1*sizeof.State+State.currentMove], 1
		 jl	DontUpdateOpp
		mov	rax, qword[rbp+Pos.counterMoves]
		mov	dword[rax+4*prevOffset], move
DontUpdateOpp:

		test	absbonus,absbonus
		jz	Return
		cmp	absbonus, 324
		jae	Return		;BonusTooBig
		imul	bonus32, absbonus, 32

		mov	eax, move
		and	eax, (64*64)-1
		mov	r9d, eax

		mov	r14d, dword[rbp+Pos.sideToMove]
		shl	r14d, 12+2
		add	r14, qword[rbp+Pos.history]
		lea	r8, [r14+4*rax]
	apply_bonus	r8, bonus32, absbonus, 324

		mov	eax, r9d
		and	r9d, 63
		shr	eax, 6
	      movzx	eax, byte[rbp+Pos.board+rax]
		shl	eax, 6
		add	r9d, eax
      UpdateCmStats   (rbx-0*sizeof.State), r9, bonus32, absbonus, r8


  match =0, quiets
  else
	; Decrease all the other played quiet moves
		mov	r13d, quietsCnt
		test	r13d, r13d
		jz	Return
		neg	bonus32
NextQuiet:
		mov	eax, dword[quiets+4*r13-4]
		and	eax, (64*64)-1
		lea	r8, [r14+4*rax]

		mov	r9d, eax
		and	r9d, 63
		shr	eax, 6
		movzx	eax, byte[rbp+Pos.board+rax]
		shl	eax, 6
		lea	r9d, [rax+r9]

	apply_bonus	r8, bonus32, absbonus, 324

      UpdateCmStats	(rbx-0*sizeof.State), r9, bonus32, absbonus, r8

		dec	r13d
		jnz	NextQuiet
  end match

Return:
end macro


macro UpdateCaptureStats move, captures, captureCnt, bonusW, absbonus
	; clobbers rax, rcx, rdx, r8, r9
	; it also might clobber rsi
  local Skipit, NextCapture, Return

		test	absbonus,absbonus
		jz	Return
		cmp	absbonus, 324
		jae	Return		;BonusTooBig
;           imul  bonusW, absbonus, 32		;2
		lea	bonusW, [2*absbonus]
;	    mov	bonusW, absbonus
;	    shl	bonusW, 4
		mov	r9, qword[rbp + Pos.captureHistory]

		mov	eax, move
		and	eax, (64*64)-1
;		jz	Skipit
		mov	ecx, eax	;move
		shr	ecx, 6
		and	eax, 63
		movzx	ecx, byte[rbp + Pos.board + rcx]
		shl	ecx, 6
		add	ecx, eax
		movzx	eax, byte[rbp + Pos.board + rax]
		and	eax, 7
		lea	ecx,[rax+8*rcx]
		lea	r8, [r9 + 4*rcx]
		apply_bonus  r8, bonusW, absbonus, 324
;Skipit:

  match =0, captures	;quiets
  else
		mov	r13d, captureCnt
		test	r13d, r13d
		jz	Return
		neg	bonusW
NextCapture:
		mov	eax, dword[captures + 4*r13 - 4]
		mov	ecx, eax			;dword[captures + 4*rsi]
		shr	ecx, 6
		and	eax, 63
		and	ecx, 63
		movzx	ecx, byte[rbp + Pos.board + rcx]
		shl	ecx, 6
		add	ecx, eax
		movzx	eax, byte[rbp + Pos.board + rax]
		and	eax, 7
		lea	ecx, [rax+8*rcx]
		lea	r8, [r9 + 4*rcx]
		apply_bonus  r8, bonusW, absbonus, 324

		dec	r13d
		jnz	NextCapture
  end match

Return:
end macro
