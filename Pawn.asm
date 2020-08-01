
macro EvalPawns Us
	; in  rbp address of Pos struct
	;     rdi address of pawn table entry
	; out esi score
	local	Them, Up, Right, Left
	local	NextPiece, AllDone
	local	Continue, NoPassed, PopLoop, DoneWithoutAdded, breakloop
	local	lneighbours, lresult, lbackward, lresult0

  if Us = White
	Them		= Black
	Up		= DELTA_N
	Right		= DELTA_NE
	Left		= DELTA_NW
	BBPawn_Us	= r15
	BBPawn_Them	= r14
  else
	Them		= White
	Up		= DELTA_S
	Right		= DELTA_SW
	Left		= DELTA_SE
	BBPawn_Us	= r14
	BBPawn_Them	= r15
  end if

;  constexpr Score Backward = S( 9, 24);
;  constexpr Score Doubled  = S(11, 56);
;  constexpr Score Isolated = S( 5, 15);
	Isolated	= (5 shl 16) + (15)
	Backward	= (9 shl 16) + (24)
	Doubled		= (11 shl 16) + (56)

		xor	esi, esi
if Us = White
		;init
		mov	dword[rdi + PawnEntry.asymmetry], esi	;zero fill asymmetry+weakUnopposed
		mov	qword[rdi+PawnEntry.passedPawns+8*Us], rsi
		mov	qword[rdi+PawnEntry.passedPawns+8*Them], rsi
		mov	qword[rdi+PawnEntry.pawnAttacksSpan+8*Us], rsi
		mov	qword[rdi+PawnEntry.pawnAttacksSpan+8*Them], rsi
		mov	eax, 0xffff4040
		mov	dword[rdi+PawnEntry.kingSquares], eax

		mov	r15, qword[rbp+Pos.typeBB+8*Pawn]
		mov	r14, r15
		and	r14, qword[rbp+Pos.typeBB+8*Them]
		xor	r15, r14	;and	r15, qword[rbp+Pos.typeBB+8*Us]
    ; r14 = their pawns
    ; r15 = our pawns
		mov	rax, r15
		ShiftBB	Right, rax, rcx
		mov	rdx, r15
		ShiftBB	Left, rdx, rcx
		mov	rcx, rax
		or	rax, rdx
		and	rdx, rcx
		mov	qword[rdi+PawnEntry.pawnAttacks+8*Us], rax
		mov	qword[rdi+PawnEntry.doubleAttacks+8*Us], rdx
		mov	rdx, LightSquares
		and	rdx, r15
		_popcnt	rax, rdx, rcx
		xor	rdx, r15		;		mov	rdx, DarkSquares, and	rdx, r15
		_popcnt	rdx, rdx, rcx
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Us+White], al
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Us+Black], dl
    ; esi = score
		mov	rax, r14
		ShiftBB	DELTA_SW, rax, rcx
		mov	rdx, r14
		ShiftBB	DELTA_SE, rdx, rcx
		mov	rcx, rax
		or	rax, rdx
		and	rdx, rcx
		mov	qword[rdi+PawnEntry.pawnAttacks+8*Them], rax
		mov	qword[rdi+PawnEntry.doubleAttacks+8*Them], rdx
		mov	rdx, LightSquares
		and	rdx, r14
		_popcnt	rax, rdx, rcx
		xor	rdx, r14		;		mov	rdx, DarkSquares, and	rdx, r14
		_popcnt	rdx, rdx, rcx
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Them+White], al
		mov	byte[rdi+PawnEntry.pawnsOnSquares+2*Them+Black], dl

end if
		test	BBPawn_Us, BBPawn_Us
		jz	AllDone

		lea	r13, [rbp+Pos.pieceList+16*(8*Us+Pawn)]
		movzx	ecx, byte[r13]	;[rbp+Pos.pieceList+16*(8*Us+Pawn)]
NextPiece:
		inc	r13
		mov	edx, ecx
		and	edx, 7
		mov	r12d, ecx
		shr	r12d, 3
    ; ecx = s, edx = f
		movzx	eax, byte[rdi+PawnEntry.semiopenFiles+Us]
		btr	eax, edx
		mov	byte[rdi+PawnEntry.semiopenFiles+Us], al
		mov	rax, qword[PawnAttackSpan+8*(64*Us+rcx)]
		or	qword[rdi+PawnEntry.pawnAttacksSpan+8*Us], rax
		mov	r11, qword[ForwardBB+8*(64*Us+rcx)]
		mov	r9, qword[AdjacentFilesBB+8*rdx]
    ; r9 = adjacent_files_bb(f)
		mov	rbx, qword[RankBB+8*r12]
		mov	r8, qword[RankBB+8*r12-Up]
		mov	r10, qword[PassedPawnMask+8*(64*Us+rcx)]
		and	r11, BBPawn_Them
		and	r10, BBPawn_Them
		neg	r11
		sbb	r11d, r11d
		and	r9, BBPawn_Us
		and	r8, r9
		and	rbx, r9
		lea	eax, [rcx-Up]
		bt	BBPawn_Us, rax
		mov	rax, r8           ; dirty trick relies on fact
		sbb	rax, 0            ; that r8>0 as signed qword
		lea	eax, [rsi-Doubled]
		cmovs	esi, eax
    ; doubled is taken care of
    ; r11d = opposed
    ; r10 = stoppers
    ; r9 = neighbours
    ; r8 = supported
    ; rbx = phalanx
		_popcnt	rax, r8, rdx
		mov	rdx, rbx
		or	rdx, r8
		jz	lneighbours
    ; r12d = relative_rank(Us, s)
  if Us eq Black
		xor	r12d, 7
  end if
		neg	r11d
		neg	rbx
		adc	r11d, r11d
		lea	r11d, [3*r11]
		add	r11d, eax
		lea	r11d, [8*r11+r12]
		add	esi, dword[Connected+4*r11]
		neg	rbx
		jmp	lresult0
lneighbours:
		test	r9, r9
		jnz	lbackward
		sub	esi, Isolated
		jmp	lresult
lbackward:
		;backward =  !(ourPawns & pawn_attack_span(Them, s + Up)) && (stoppers & (leverPush | (s + Up)));
		lea	r9d, [rcx+Up]
		test	BBPawn_Us, qword[PawnAttackSpan+8*(64*Them+r9)]
		jnz	lresult0
		mov	rdx, qword[PawnAttacks+8*(64*Us+r9)]
		and	rdx, BBPawn_Them
		bts	rdx, r9
		and	rdx, r10
		jz	lresult0
		sub	esi, Backward
lresult:
		inc	r11d	;lea	r11d, [r11 + 1]
  if Us = Black
		shl	r11d, 4*Us
  end if
		add	byte[rdi+PawnEntry.weakUnopposed], r11l
lresult0:
    ; r8 = supported
    ; rax = popcnt(supported)
    ; r10 = stoppers
		mov	r12, r10
		mov	r11, qword[PawnAttacks+8*(64*Us+rcx)]
		mov	rdx, qword[PawnAttacks+8*(64*Us+rcx+Up)]
		and	r11, BBPawn_Them
		and	rdx, BBPawn_Them
	; r11 = lever
	; rdx = leverPush
		xor	r10, r11
		xor	r10, rdx
		jnz	NoPassed
		_popcnt	rbx, rbx, r10
    ; rbx = popcnt(phalanx)
		_popcnt	r11, r11, r10
		_popcnt	rdx, rdx, r10
		dec	r11	;added 13-06-2018
		sub	rax, r11
		sub	rbx, rdx
		or	rax, rbx
		jns	breakloop
NoPassed:
		lea	eax, [rcx+Up]
		btc	r12, rax
		test	r12, r12
		jnz	DoneWithoutAdded
		cmp	ecx, SQ_A5
	if Us eq White
		jb	DoneWithoutAdded
		shl	r8, 8
	else
		jae	DoneWithoutAdded
		shr	r8, 8
	end if
		_andn   r8, BBPawn_Them, r8
PopLoop:
		jz	DoneWithoutAdded
		_tzcnt	rax, r8
		mov	rax, qword[PawnAttacks+8*(64*Us+rax)]
		and	rax, BBPawn_Them
		_blsr	rdx, rax
		jz	breakloop
		_blsr	r8, r8, rax
		jmp	PopLoop
		calign 8
breakloop:
		mov	eax, 1
		mov	edx, eax	; edx is either 0, or 1 and will be added to byte[rdi + PawnEntry.asymmetry]
		shl	rax, cl
		or	qword[rdi+PawnEntry.passedPawns+8*Us], rax
		add	byte[rdi + PawnEntry.asymmetry], dl
DoneWithoutAdded:
		movzx	ecx, byte[r13]
		cmp	ecx, 64
		jb	NextPiece
AllDone:
end macro
