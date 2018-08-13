
macro EvalPawns Us
	; in  rbp address of Pos struct
	;     rdi address of pawn table entry
	; out esi score
  local Them, Up, Right, Left
  local Doubled
  local NextPiece, AllDone, Done, WritePawnSpan
  local Neighbours_True, Neighbours_True__Lever_False
  local Neighbours_True__Lever_False__RelRank_small, Neighbours_False
  local Neighbours_True__Lever_True, Neighbours_True__Lever_False__RelRank_big
  local Continue, NoPassed, PopLoop, DoneWithoutAdded
  if Us = White
	Them  = Black
	Up    = DELTA_N
	Right = DELTA_NE
	Left  = DELTA_NW
  else
	Them  = White
	Up    = DELTA_S
	Right = DELTA_SW
	Left  = DELTA_SE
  end if

if 1	;Latest
	Isolated	= (4 shl 16) + (20)	;(13 shl 16) + (18)
	Backward	= (21 shl 16) + (22)	;(24 shl 16) + (12)
	Doubled		= (12 shl 16) + (54)	;(18 shl 16) + (38)
else
	Isolated	= (13 shl 16) + (18)
	Backward	= (24 shl 16) + (12)
	Doubled		= (18 shl 16) + (38)
end if

		xor	esi, esi
if Us = White
		;init
		xor	eax, eax
		mov	dword[rdi + PawnEntry.asymmetry], eax	;zero fill asymmetry+weakUnopposed
		mov	qword[rdi+PawnEntry.passedPawns+8*Us], rax
		mov	qword[rdi+PawnEntry.passedPawns+8*Them], rax
		mov	qword[rdi+PawnEntry.pawnAttacksSpan+8*Us], rax
		mov	qword[rdi+PawnEntry.pawnAttacksSpan+8*Them], rax
		mov	eax, 0xffff4040
		mov	dword[rdi+PawnEntry.kingSquares], eax
		;mov	byte[rdi+PawnEntry.kingSquares+Us], 64
		;mov	byte[rdi+PawnEntry.kingSquares+Them], 64
		;mov	byte[rdi+PawnEntry.semiopenFiles+Us], 0xFF
		;mov	byte[rdi+PawnEntry.semiopenFiles+Them], 0xFF

		mov	r15, qword[rbp+Pos.typeBB+8*Pawn]
		mov	r14, r15
		and	r14, qword[rbp+Pos.typeBB+8*Them]
		and	r15, qword[rbp+Pos.typeBB+8*Us]
    ; r14 = their pawns
    ; r15 = our pawns
		mov	rax, r15
		ShiftBB	Right, rax, rcx
		mov	rdx, r15
		ShiftBB	Left, rdx, rcx
		or	rax, rdx
		mov	qword[rdi+PawnEntry.pawnAttacks+8*Us], rax
		mov	rax, LightSquares
		and	rax, r15
		_popcnt	rax, rax, rcx
		mov	rdx, DarkSquares
		and	rdx, r15
		_popcnt	rdx, rdx, rcx
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Us+White], al
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Us+Black], dl
    ; esi = score
		mov	rax, r14
		ShiftBB	DELTA_SW, rax, rcx
		mov	rdx, r14
		ShiftBB	DELTA_SE, rdx, rcx
		or	rax, rdx
		mov	qword[rdi+PawnEntry.pawnAttacks+8*Them], rax
		mov	rax, LightSquares
		and	rax, r14
		_popcnt	rax, rax, rcx
		mov	rdx, DarkSquares
		and	rdx, r14
		_popcnt	rdx, rdx, rcx
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Them+White], al
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Them+Black], dl

		test	r15, r15
		jz	AllDone
else
		test	r14, r14
		jz	AllDone
		mov	rax, r15
		mov	r15, r14
		mov	r14, rax
end if

		lea	r13, [rbp+Pos.pieceList+16*(8*Us+Pawn)]
		movzx	ecx, byte[r13]	;[rbp+Pos.pieceList+16*(8*Us+Pawn)]
NextPiece:
		inc	r13	;add   r15, 1
		mov	edx, ecx
		and	edx, 7
		mov	r12d, ecx
		shr	r12d, 3
		mov	rbx, qword[RankBB+8*r12]
  if Us eq Black
		xor	r12d, 7
  end if
    ; ecx = s, edx = f, r12d = relative_rank(Us, s)
		movzx	eax, byte[rdi+PawnEntry.semiopenFiles+Us]
		btr	eax, edx
		mov	byte[rdi+PawnEntry.semiopenFiles+Us], al
		mov	rax, [PawnAttackSpan+8*(64*Us+rcx)]
		or	qword[rdi+PawnEntry.pawnAttacksSpan+8*Us], rax
		mov	r11, r14
		and	r11, qword[ForwardBB+8*(64*Us+rcx)]
		neg	r11
		sbb	r11d, r11d
    ; r11d = opposed
		mov	rdx, qword[AdjacentFilesBB+8*rdx]
    ; rdx = adjacent_files_bb(f)
		mov	r10, qword[PassedPawnMask+8*(64*Us+rcx)]
		and	r10, r14
		push	r10
    ; r10 = stoppers
		mov	r8d, ecx
		shr	r8d, 3
		mov	r8, qword[RankBB+8*r8-Up]
		mov	r9, r15
		and	r9, rdx
    ; r9 = neighbours
		and	r8, r9
    ; r8 = supported
		and	rbx, r9
    ; rbx = phalanx
		lea	eax, [rcx-Up]
		bt	r15, rax
		mov	rax, r8           ; dirty trick relies on fact
		sbb	rax, 0            ; that r8>0 as signed qword
		lea	eax, [rsi-Doubled]
		cmovs	esi, eax
    ; doubled is taken care of
		test	r9, r9
		jz	Neighbours_False
;Neighbours_True:
		test	r14, qword[PawnAttacks+8*(64*Us+rcx)]
		jnz	Neighbours_True__Lever_True
;Neighbours_True__Lever_False:
  if Us = White
		cmp	ecx, SQ_A5
		jae	Neighbours_True__Lever_False__RelRank_big
		mov	rax, r9
		or	rax, r10
		_tzcnt	rax, rax
  else
		cmp	ecx, SQ_A5
		jb	Neighbours_True__Lever_False__RelRank_big
		mov	rax, r9
		or	rax, r10
		bsr	rax, rax
  end if
Neighbours_True__Lever_False__RelRank_small:
		shr	eax, 3
		mov	rax, qword[RankBB+8*rax]
		and	rdx, rax
		ShiftBB	Up, rdx
		or	rdx, rax
		mov	eax, -Backward
		and	rdx, r10
		cmovnz	edx, eax
    ; edx = backwards ? Backward[opposed] : 0
		lea	eax, [r11 + 1]
		cmovnz	r10d, eax
		jmp	Continue
Neighbours_False:
		mov	edx, -Isolated
		lea	r10d, [r11 + 1]
		jmp	Continue

Neighbours_True__Lever_True:
Neighbours_True__Lever_False__RelRank_big:
		xor	edx, edx
		xor	r10, r10
Continue:
	if CPU_HAS_POPCNT = 1
		popcnt		rax, r8
		popcnt		r9, rbx
	else
		push	r10
		_popcnt		rax, r8, r10
		_popcnt		r9, rbx, r10
		pop	r10
	end if
		neg	r11d
		neg	rbx
		adc	r11d, r11d
		lea	r11d, [3*r11]
		add	r11d, eax
		lea	r11d, [8*r11+r12]
    ; r11 = [opposed][!!phalanx][popcount(supported)][relative_rank(Us, s)]
		or	rbx, r8
		cmovnz	edx, dword[Connected+4*r11]
		jnz	@1f
  if Us = Black
		shl	r10d, 4*Us
  end if
		add	byte[rdi+PawnEntry.weakUnopposed], r10l
    @1:
		add	esi, edx
    ; r8 = supported
    ; r9 = popcnt(phalanx)
    ; rax = popcnt(supported)
		pop	r10
    ; r10 = stoppers
		mov	r12, r10
;		test	r15, qword[ForwardBB+8*(64*Us+rcx)]	;not needed?
;		jnz	NoPassed				;not needed?
		mov	r11, qword[PawnAttacks+8*(64*Us+rcx)]
		and	r11, r14
	; r11 = lever
		mov	rdx, qword[PawnAttacks+8*(64*Us+rcx+Up)]
		and	rdx, r14
	; rdx = leverPush
		xor	r10, r11
		xor	r10, rdx
		jnz	NoPassed
		_popcnt	r11, r11, r10
		dec	r11	;added 13-06-2018
		_popcnt	rdx, rdx, r10
		sub	rax, r11
		sub	r9, rdx
		or	rax, r9
		js	NoPassed
		mov	eax, 1
		mov	edx, eax
		shl	rax, cl
		or	qword[rdi+PawnEntry.passedPawns+8*Us], rax
        ; edx is either 0, or 1 and will be added to byte[rdi + PawnEntry.asymmetry]
		jmp	Done
NoPassed:
		lea	eax, [rcx+Up]
		btc	r12, rax
		test	r12, r12
		jnz	DoneWithoutAdded	;Done
	if Us eq White
		cmp	ecx, SQ_A5
		jb	DoneWithoutAdded	;Done
		shl	r8, 8
	else
		cmp	ecx, SQ_A5
		jae	DoneWithoutAdded	;Done
		shr	r8, 8
	end if
		_andn   r8, r14, r8
		jz	DoneWithoutAdded	;Done
		xor	edx, edx	;added
PopLoop:
		xor	eax, eax
		_tzcnt	r9, r8
		mov	r9, qword[PawnAttacks+8*(64*Us+r9)]
		and	r9, r14
		_blsr	r11, r9		;changed
		setz	al
		or	edx, eax	;added
		shl	rax, cl
		or	qword[rdi+PawnEntry.passedPawns+8*Us], rax
		_blsr	r8, r8, rax
		jnz	PopLoop
Done:
		add	byte[rdi + PawnEntry.asymmetry], dl
DoneWithoutAdded:
		movzx	ecx, byte[r13]
		cmp	ecx, 64
		jb	NextPiece
AllDone:
end macro
