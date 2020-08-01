macro GetNextMove coldlabel
	; in: rbp Position
	;     rbx State
        ;     esi skipQuiets (0 for false, -1 for true)
	; out: ecx move
	; rdi r12 r13 r14 r15 are clobbered

		mov	rax, qword[rbx+State.stage]
coldlabel:
		call	rax
end macro

macro InsertionSort begin, ender, p, q
local Outer, Inner, InnerDone, OuterDone
		lea   p, [begin+sizeof.ExtMove]
		cmp   p, ender
		jae   OuterDone
Outer:
		mov   rax, qword[p]
		mov   edx, dword[p+ExtMove.value]
		mov   q, p

		cmp   q, begin
		jbe   InnerDone
		mov   rcx, qword[q-sizeof.ExtMove+ExtMove.move]
		cmp   edx, dword[q-sizeof.ExtMove+ExtMove.value]
		jle   InnerDone
Inner:
		mov   qword [q], rcx
		sub   q, sizeof.ExtMove

		cmp   q, begin
		jbe   InnerDone
		mov   rcx, qword[q-sizeof.ExtMove+ExtMove.move]
		cmp   edx, dword[q-sizeof.ExtMove+ExtMove.value]
		 jg   Inner
InnerDone:
		mov   qword[q], rax
		add   p, sizeof.ExtMove
		cmp   p, ender
		 jb   Outer
OuterDone:
end macro




; we have two implementation of partition

macro Partition2  cur, ender
; at return ender point to start of elements that are <=0
  local _048, _049, _050, _051, Done
		cmp   cur, ender
		lea   cur, [cur+8]
		 je   Done
_048:		mov   eax, dword [cur-4]
		lea   rcx, [cur-8]
	       test   eax, eax
		 jg   _051
		mov   eax, dword [ender-4]
		lea   ender, [ender-8]
		cmp   ender, rcx
		 jz   Done
	       test   eax, eax
		 jg   _050
_049:		sub   ender, 8
		cmp   ender, rcx
		 jz   Done
		mov   eax, dword [ender+4]
	       test   eax, eax
		jle   _049
_050:		mov   rdx, qword [cur-8]
		mov   rcx, qword [ender]
		mov   qword [cur-8], rcx
		mov   qword [ender], rdx
_051:		cmp   ender, cur
		lea   cur, [cur+8]
		jnz   _048

Done:
end macro



macro Partition1  first, last
; at return first point to start of elements that are <=0
  local Done, FindNext, FoundNot, PFalse, WLoop
		cmp   first, last
		 je   Done
FindNext:
		cmp   dword[first+4], 0
		jle   FoundNot
		add   first, 8
		cmp   first, last
		jne   FindNext
		jmp   Done
FoundNot:
		lea   rcx, [first+8]
WLoop:
		cmp   rcx, last
		 je   Done
		cmp   dword[rcx+4], 0
		jle   PFalse
		mov   rax, qword[first]
		mov   rdx, qword[rcx]
		mov   qword[first], rdx
		mov   qword[rcx], rax
		add   first, 8
PFalse:
		add   rcx, 8
		jmp   WLoop
Done:
end macro

;18 lines
macro PickBest	beg, start, ender
	; out: ecx best move
  local Next, Done
		mov   ecx, dword[beg+0]
		mov   rdx, beg
		add   beg, sizeof.ExtMove
		cmp   beg, ender
		jae   Done
		mov   start, beg
		mov   eax, dword[rdx+4]
Next:
		mov   ecx, dword[start+4]
		cmp   ecx, eax
	      cmovg   rdx, start
	      cmovg   eax, ecx
		add   start, sizeof.ExtMove
		cmp   start, ender
		 jb   Next
		mov   rcx, qword[rdx]
		mov   rax, qword[beg-sizeof.ExtMove]
		mov   qword[rdx], rax
		mov   qword[beg-sizeof.ExtMove], rcx
Done:
end macro



; use assembler to set mask of bits used in see sign
;SeeSignBitMask = 0
;
;_from = 0
;while _from < 8
; _to = 0
; while _to < 8
;
;   _fromvalue = 0
;   if Pawn <= _from & _from <= Queen
;    _fromvalue = _from
;   end if
;
;   _tovalue = 0
;   if Pawn <= _to & _to <= Queen
;    _tovalue = _to
;   end if
;
;   if _fromvalue > _tovalue
;    SeeSignBitMask = SeeSignBitMask or (1 shl (_from+8*_to))
;   end if
;
;  _to = _to+1
; end while
; _from = _from+1
;end while
SeeSignBitMask = 0x7c00406070787c7c

macro SeeSignTestQSearch JmpTo
  local Positive
	; eax = 1 if see >= 0
	; eax = 0 if see <  0
	; jmp to JmpTo if see value is >=0  eax is undefined in this case
		
		mov	eax, r14d			; eax = FROM PIECE
		and	eax, 7
		mov	edx, r15d			; edx = TO PIECE
		and	edx, 7
		lea	edx, [rax+8*rdx]
		mov	rax, SeeSignBitMask
		 bt	rax, rdx
		jnc	JmpTo
		xor	edx, edx
		call	SeeTestGe.HaveFromTo
end macro

macro ScoreCaptures start, next, ender, nomove
  local WhileLoop
		cmp	start, ender
		je	nomove	;jae
		mov	next, start
		mov	r8, qword[rbp + Pos.captureHistory]
WhileLoop:
		mov	eax, dword[next + ExtMove.move]
		mov	ecx, eax
		shr	ecx, 6
		and	ecx, 63	;from
		and	eax, 63	;to
		movzx	ecx, byte[rbp + Pos.board + rcx]
		shl	ecx, 6
		add	ecx, eax
		movzx	eax, byte[rbp + Pos.board + rax]	;captured piece
		mov	edx, dword[PieceValue_MG + 4*rax]
		and	eax, 7
		lea	ecx, [8*rcx+rax]
		add	edx, dword[r8 + 4*rcx]
;		mov	eax, dword[r8 + 4*rcx]
;		sar	eax, 4	;div by 16?
;		add	edx, eax
		mov	dword[next+ExtMove.value], edx
		add	next, sizeof.ExtMove
		cmp	next, ender
		jb	WhileLoop

end macro

macro ScoreQuiets start, next, ender, nomove
  local cmh, fmh, fmh2, history_get_c
  local Looping, TestLoop

	cmh  equ r9
	fmh  equ r10
	fmh2 equ r11
	fmh5 equ r15


		cmp   start, ender
		je   nomove		;jae
		mov	next, start
		mov   cmh, qword[rbx-1*sizeof.State+State.counterMoves]
		mov   fmh, qword[rbx-2*sizeof.State+State.counterMoves]
		mov   fmh2, qword[rbx-4*sizeof.State+State.counterMoves]
if	Continuation_Five = 1
		mov   fmh5, qword[rbx-6*sizeof.State+State.counterMoves]
end if
		mov   r8d, dword[rbp+Pos.sideToMove]
		mov   r8, qword[rbp+Pos.history+8*r8]
	history_get_c equ r8
Looping:
		mov   eax, dword[next+ExtMove.move]
		and   eax, (64*64)-1
		mov   ecx, eax
		mov   edx, eax
		and   ecx, 63
		shr   edx, 6
	      movzx   edx, byte[rbp+Pos.board+rdx]
		shl   edx, 6
		add   edx, ecx
		mov   eax, dword[history_get_c+4*rax]
		add   eax, dword[cmh+4*rdx]
		add   eax, dword[fmh+4*rdx]
		add   eax, dword[fmh2+4*rdx]
if	Continuation_Five = 1
		mov   edx, dword[fmh5+4*rdx]
		sar	edx, 1
		add	eax, edx
end if
		mov   dword[next+ExtMove.value], eax
		add   next, sizeof.ExtMove
		cmp   next, ender
		 jb   Looping
end macro

;revision removing castle moves
macro ScoreEvasions start, next, ender, nomove
  local history_get_c
  local WhileLoop, Done, Capture

	history_get_c equ r8

		cmp	start, ender
		je	nomove		;jae
		mov	next, start
		mov	r8d, dword[rbp+Pos.sideToMove]
		mov	r8, qword[rbp+Pos.history+8*r8]
		;
;		mov	r9d, dword[rbx-1*sizeof.State+State.currentMove]
;		and	r9d, 63	;to
;		movzx	eax, byte[rbp+Pos.board+r9]
;		shl	eax, 6
;		add	r9d, eax
;		shl	r9d, 2+4+6
;		add	r9, qword[rbp+Pos.counterMoveHistory]

WhileLoop:
		mov	eax, dword[next+ExtMove.move]
		mov	ecx, eax 				; ecx = move
		add	next, sizeof.ExtMove
		and	eax, 63
	      movzx	eax, byte[rbp+Pos.board+rax]	; eax = to piece
	       test	eax, eax
		jnz	Capture
		cmp	ecx, MOVE_TYPE_EPCAP shl 12
		jae	Capture
		and	ecx, (64*64)-1
		mov	eax, dword[history_get_c+4*rcx]
		;
		;sub	eax, 1 shl 28
		;
;		mov	edx, ecx
;		shr	edx, 6
;		movzx	ecx, byte[rbp+Pos.board+rdx]
;		shl	ecx, 6
;		add	ecx, edx
;		add	eax, dword[r9+4*rcx]
		;
		mov	dword[next-1*sizeof.ExtMove+ExtMove.value], eax
		cmp	next, ender
		 jb	WhileLoop
		jmp	Done
Capture:			;or EPcap
		shr	ecx, 6
		and	ecx, 63
	      movzx	ecx, byte[rbp+Pos.board+rcx]	; ecx = from piece
		mov	eax, dword[PieceValue_MG+4*rax]
		and	ecx, 7
		sub	eax, ecx
		add	eax, HistoryStats_Max+1	; match piece types of master
		mov	dword[next-1*sizeof.ExtMove+ExtMove.value], eax
		cmp	next, ender
		 jb	WhileLoop
Done:
end macro