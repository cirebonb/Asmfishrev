;version 07-04-2018 ;clobered edx,ecx , eax
macro apply_bonus address, bonus32, absbonus, denominator
; bonus32 is r11d
		mov	eax, dword[address]
	       imul	eax, absbonus
		cdq
		mov	ecx, denominator
	       idiv	ecx
		sub	eax, bonus32
		neg	eax
		add	dword[address], eax
;		mov   edx, bonus32
;		sub   edx, eax
;		add   edx, dword[address]
;		mov   dword[address], edx
end macro

macro UpdateCmStats ss, offset, bonus32, absbonus, t1
	; bonus32 is 32*bonus
	; absbonus is abs(bonus)
	; clobbers rax, rcx, rdx, t1=r8
  local over1, over2, over3, over4
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
if	Continuation_Five = 1
		cmp   dword[ss-6*sizeof.State+State.currentMove], 1
		 jl   over4
		mov   t1, qword[ss-6*sizeof.State+State.counterMoves]
	apply_bonus   (t1+4*(offset)), bonus32, absbonus, 936
over4:
end if
end macro

macro Updatemove move, prevOffset, PvNode, RootNode
  local DontUpdateKillers, DontUpdateMove, Backup
		mov	rax, qword[rbx+State.checkersBB]
		test	rax, rax
		jnz	DontUpdateMove

		mov	eax, dword[rbx+State.killers+4*0]
		cmp	eax, move
		je	DontUpdateKillers
		mov	dword[rbx+State.killers+4*1], eax
		mov	dword[rbx+State.killers+4*0], move
DontUpdateKillers:
if	RootNode = 0 | UpdateAtRoot = 1
	if PvNode = 0
		cmp	dword[rbx-1*sizeof.State+State.currentMove], 1
		jl	DontUpdateMove
	end if
	match size[addr], prevOffset
			movzx	edx, prevOffset
			mov	rax, qword[rbp+Pos.counterMoves]
			mov	dword[rax+4*rdx], ecx
	else
			mov	rax, qword[rbp+Pos.counterMoves]
			mov	dword[rax+4*prevOffset], ecx
	end match
end if

DontUpdateMove:

end macro

;================================
macro UpdateStats move, quiets, quietsCnt, bonus32, absbonus, Rootnode
	; clobbers rax, rcx, rdx, r8, r9
	; it also might clobber rsi and change the sign of bonus32
  local NextQuiet, Return, Continue
		test	byte[rbx+State.pvhit], JUMP_IMM_8
		jnz	Return

		imul	bonus32, absbonus, 32

		mov	eax, move
		and	eax, (64*64)-1
		mov	r9d, eax
		mov	r14d, dword[rbp+Pos.sideToMove]
		mov	r14, qword[rbp+Pos.history+8*r14]
		lea	r8, [r14+4*rax]
	apply_bonus	r8, bonus32, absbonus, 324
if Rootnode = 0| UpdateAtRoot = 1
		mov	eax, r9d
		and	r9d, 63
		shr	eax, 6
	      movzx	eax, byte[rbp+Pos.board+rax]
		shl	eax, 6
		add	r9d, eax
      UpdateCmStats   (rbx-0*sizeof.State), r9, bonus32, absbonus, r8
end if

  match =0, quiets
  else
	; Decrease all the other played quiet moves
		movzx	r13d, quietsCnt
		test	r13d, r13d
		jz	Return
		neg	bonus32
NextQuiet:
		mov	eax, dword[quiets+4*r13-4]
		and	eax, (64*64)-1
		lea	r8, [r14+4*rax]

if Rootnode = 0 | UpdateAtRoot = 1
		mov	r9d, eax
		and	r9d, 63
		shr	eax, 6
		movzx	eax, byte[rbp+Pos.board+rax]
		shl	eax, 6
		add	r9d, eax	;lea	r9d, [rax+r9]
end if

	apply_bonus	r8, bonus32, absbonus, 324
if Rootnode = 0| UpdateAtRoot = 1
      UpdateCmStats	(rbx-0*sizeof.State), r9, bonus32, absbonus, r8
end if

		dec	r13d
		jnz	NextQuiet
  end match

Return:
end macro


macro UpdateCaptureStats move, captures, captureCnt, bonusW, absbonus
	; clobbers rax, rcx, rdx, r8, r9
	; it also might clobber rsi
  local Skipit, NextCapture, Return, ItsQuiet
		test	byte[rbx+State.pvhit], JUMP_IMM_8
		jnz	Return

		lea	bonusW, [2*absbonus]
		mov	r9, qword[rbp + Pos.captureHistory]
		test	move,move
		jz	ItsQuiet

		mov	eax, move
		and	eax, (64*64)-1
		mov	ecx, eax	;move
		shr	ecx, 6
		and	eax, 63
		movzx	ecx, byte[rbp + Pos.board + rcx]
		movzx	edx, byte[rbp + Pos.board + rax]
		and	edx, 7
		shl	ecx, 6
		add	ecx, eax
		lea	ecx, [rdx+8*rcx]
		lea	r8,  [r9 + 4*rcx]
		apply_bonus  r8, bonusW, absbonus, 324
ItsQuiet:
  match =0, captures
  else
		movzx	r13d, captureCnt
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
		movzx	edx, byte[rbp + Pos.board + rax]
		and	edx, 7
		shl	ecx, 6
		add	ecx, eax
		lea	ecx, [rdx+8*rcx]
		lea	r8,  [r9 + 4*rcx]
		apply_bonus  r8, bonusW, absbonus, 324

		dec	r13d
		jnz	NextCapture
  end match

Return:
end macro
