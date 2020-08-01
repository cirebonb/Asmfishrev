	QueenSide   = FileABB or FileBBB or FileCBB or FileDBB
	CenterFiles = FileCBB or FileDBB or FileEBB or FileFBB
	KingSide    = FileEBB or FileFBB or FileGBB or FileHBB
	Center      = (FileDBB or FileEBB) and (Rank4BB or Rank5BB)

	BishopPawns		= (  3 shl 16) + ( 5)	;<- not updated
	CloseEnemies		= (  8 shl 16) + (  0)	;(  7 shl 16) + (  0)

	Hanging 		= ( 57 shl 16) + ( 32)	;( 52 shl 16) + ( 30)	;( 48 shl 16) + ( 27)
	KnightOnQueen		= ( 21 shl 16) + ( 11)
	LongRangedBishop        = ( 46 shl 16) + (  0)	;( 22 shl 16) + (  0)
	MinorBehindPawn 	= ( 16 shl 16) + (  0)	;====>( 18 shl 16) + (  3)


	PawnlessFlank		= ( 20 shl 16) + ( 80)
	RookOnPawn		= ( 10 shl 16) + ( 30)	;(  8 shl 16) + ( 24)
	RestrictedPiece		= (  7 shl 16) + ( 7);
	SliderOnQueen		= ( 42 shl 16) + ( 21)
	ThreatByKing		= ( 23 shl 16) + ( 76)
	canPushPawn		= ( 7 shl 16) + ( 3)
	ThreatBySafePawn        = (165 shl 16) + (133)	;(175 shl 16) + (168)
	ThreatByRank		= ( 16 shl 16) + (  3)
	ThreatByPawnPush	= ( 49 shl 16) + ( 30)	;( 47 shl 16) + ( 26)
	TrappedRook		= ( 47 shl 16) + (  4)	;( 92 shl 16) + (  0)
	TrappedBishopA1H1       = ( 50 shl 16) + ( 50)
	WeakQueen		= ( 50 shl 16) + ( 10)
	WeakUnopposedPawn       = (  5 shl 16) + ( 26)	;(  5 shl 16) + ( 25)

LazyThreshold = 1500


macro EvalInit Us

  local Them
  local NotUsed
   if Us	= White
	Them	= Black
	KingsqThem		= r9
	attackedbyKingThem	= r13
	attackedbyKingUs	= r12
   else
	Them	= White
	KingsqThem		= r8
	attackedbyKingThem	= r12
	attackedbyKingUs	= r13
   end if
.eimobility	equ (.ei.attackedBy+8*Pawn)
.eikingring	equ (.ei.attackedBy+8*(8*1+Pawn))

;		Assert   e, rdi, qword[.ei.pi], 'assertion rdi = ei.pi failed in EvalInit'
		mov	r10, qword[rdi+PawnEntry.pawnAttacks+8*Us]
	; rdx =	b
		xor	rcx, rcx
if Us	= White
		mov	qword[.eimobility], rcx
end if
		xor	edx, edx
		cmp	word[rbx+State.npMaterial+2*Us], RookValueMg + KnightValueMg
		jb	NotUsed
		mov	dword[.ei.kingAttackersWeight+4*Us], edx
		mov	dword[.ei.kingAdjacentZoneAttacksCount+4*Us], edx
		mov	rcx, qword[rdi+PawnEntry.doubleAttacks+8*Them]
		_andn   rcx, rcx, qword[KingRingA+8*KingsqThem]
		mov	rdx, rcx	;attackedbyKingThem
		and	rdx, r10
		_popcnt	rdx, rdx, rax  

NotUsed:
if	QueenThreats > 0
		mov	qword[.ei.attackedBy+8*(8*Us+0)], r10	;for Queen
end if
		mov	qword[.ei.kingRing+8*Them], rcx
		mov	dword[.ei.kingAttackersCount+4*Us], edx
		and	r10, attackedbyKingUs
		or	r10, qword[rdi+PawnEntry.doubleAttacks+8*Us]
		mov	qword[.ei.attackedBy2+8*Us], r10
end macro


macro EvalPieces Us, Pt
	; in:  rbp address of Pos struct
	;      rbx address of State struct
	;      rsp address of evaluation info
	;      rdi address of PawnEntry struct
	; io:  esi score accumulated
	;
	; in: r13 all pieces
	;	r14 = white
	;	r15 = black
	;	r8, r9, r10 free

  local addsub, subadd
  local Them, OutpostRanks

  local RookOnFile0, RookOnFile1
  local Outpost0, Outpost1, KingAttackWeight
  local MobilityBonus, ProtectorBonus, notdoubleattack, doubleattackLoop

  local NextPiece, NoPinned, NoKingRing, AllDone
  local OutpostElse, OutpostDone, NoBehindPawnBonus
  local NoEnemyPawnBonus, NoOpenFileBonus, NoTrappedByKing
  local SkipQueenPin, QueenPinLoop, QDirectAttacknRelatifPin, Pinned2

	PiecesPawn	= r11
  if Us = White
	Down		= DELTA_S
	;addsub		  equ add
	;subadd		  equ sub
	macro addsub a,	b
		add  a,	b
	end macro
	macro subadd a,	b
		sub  a,	b
	end macro
	Them		  = Black
	OutpostRanks	  = 0x0000FFFFFF000000
	AttackedByUs    = r12
	AttackedByThem  = r13
	PiecesUs	= r14
	PiecesThem	= r15
  else
	Down		= DELTA_N
	;addsub		  equ sub
	;subadd		  equ add
	macro addsub a,	b
		sub  a,	b
	end macro
	macro subadd a,	b
		add  a,	b
	end macro
	Them		  = White
	OutpostRanks	  = 0x000000FFFFFF0000
	AttackedByUs    = r13
	AttackedByThem  = r12
	PiecesUs	= r15
	PiecesThem	= r14
  end if

	RookOnFile0	  = ((20 shl 16) + (7))
	RookOnFile1	  = ((45 shl 16) + (20))

  if Pt	= Knight
if	0
	Outpost0	  = 4*((9 shl 16)+3)
	Outpost1	  = 2*((9 shl 16)+3)
else
	Outpost0	  = ((22 shl 16) + ( 6))
	Outpost1	  = ((36 shl 16) + (12))
end if
	MobilityBonus	  equ MobilityBonus_Knight
	KingAttackWeight  = 77			; 78
	KingProtector_Pt  = ((4 shl 16) + (6))	; ((-3 shl 16) + (-5))
  else if Pt = Bishop
if	0
	Outpost0	  = 2*((9 shl 16)+3)
	Outpost1	  = 1*((9 shl 16)+3)
else
	Outpost0	  = (( 9 shl 16) + (2))
	Outpost1	  = ((15 shl 16) + (5))
end if
	MobilityBonus	  equ MobilityBonus_Bishop
	KingAttackWeight  = 55			;56
	KingProtector_Pt  = ((6 shl 16) + (3))	;((-4 shl 16) + (-3))
  else if Pt = Rook
	KingAttackWeight  = 44			;45
	MobilityBonus	  equ MobilityBonus_Rook
  else if Pt = Queen
	KingAttackWeight  = 10			;11
	MobilityBonus	  equ MobilityBonus_Queen
  else
    err	'bad Pt	in Eval	Pieces'
  end if

;	     Assert   e, rdi, qword[.ei.pi], 'assertion	rdi=qword[.ei.pi] failed in EvalPieces'
		xor	eax, eax
		mov	qword[.ei.attackedBy+8*(8*Us+Pt)], rax
  if Pt	= Queen
		mov	qword[.ei.attackedBy+8*(8*Us+SLIDER_ON_QUEEN)], rax
  end if
		lea	r9, [rbp+Pos.pieceList+16*(8*Us+Pt)]
		movzx   r8d, byte[r9]	;rbp+Pos.pieceList+16*(8*Us+Pt)]
		cmp	r8d, 64
		jae	AllDone
NextPiece:
		inc	r9
	; r8 =	square s
	; Find attacked	squares, including x-ray attacks for bishops and rooks
	if Pt	= Knight
		mov	r10, qword[KnightAttacks+8*r8]
	else if Pt = Bishop
		lea	rax, [PiecesThem+PiecesUs]
		xor	rax, qword[rbp+Pos.typeBB+8*Queen]
		BishopAttacks   r10, r8, rax, rdx
	else if Pt = Rook
		lea	rax, [PiecesThem+PiecesUs]
		xor	rax, qword[rbx+State.checkSq]	; QxR
		mov	rdx, qword[rbp+Pos.typeBB+8*Rook]
		and	rdx, PiecesThem
		xor	rax, rdx
		RookAttacks  r10, r8, rax, rdx
	else if Pt = Queen
		lea	rax, [PiecesThem+PiecesUs]
		;QueenAttacks   r10, r8, r13, rax, rdx
		QueenAttacksMinReg	r10, r8, rax, rdx
		mov	rcx, r10
	else
		err	'bad Pt	in EvalPieces'
	end if
if QueenThreats > 0 & Pt <> Queen
		or	qword[.ei.attackedBy+8*(8*Us+0)], r10
end if
	; r10 = b
		mov	rax, qword[rbx+State.blockersForKing+8*Us]
		bt	rax, r8
		jnc	NoPinned	; 98.92%
	if Pt	= Knight
		xor	r10, r10
	else
		movzx	eax, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		shl	eax, 6+3
		and	r10, qword[LineBB+rax+8*r8]
	end if
NoPinned:
		mov	rax, r10
		and	rax, AttackedByUs
		or	AttackedByUs, r10
		or	qword[.ei.attackedBy2+8*Us], rax
		or	qword[.ei.attackedBy+8*(8*Us+Pt)], r10

		mov	rax, qword[.ei.mobilityArea+8*Us]
		and	rax, r10
if Pt = Rook
		_popcnt	rdx, rax, rcx
		mov	eax, dword[MobilityBonus+4*rdx]
else
		_popcnt	rax, rax, rdx
		mov	eax, dword[MobilityBonus+4*rax]
end if
.eimobility	equ (.ei.attackedBy+8*Pawn)
		addsub	dword[.eimobility], eax

		test	r10, qword[.ei.kingRing+8*Them]
		jz	NoKingRing	; 74.44%
		add	dword[.ei.kingAttackersCount+4*Us], 1
		add	dword[.ei.kingAttackersWeight+4*Us], KingAttackWeight
		mov	rax, qword[.ei.attackedBy+8*(8*Them+King)]
		and	rax, r10
if Pt = Rook
		_popcnt	rax, rax, rcx
else
		_popcnt	rax, rax, rdx
end if
		add	dword[.ei.kingAdjacentZoneAttacksCount+4*Us], eax
NoKingRing:

  if Pt	= Knight | Pt =	Bishop

		movzx	eax, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		shl	eax, 3+3
		movzx	eax, byte[SquareDistance+rax+r8]
		imul	eax, KingProtector_Pt
		addsub	esi, eax

	; Bonus	when behind a pawn
		mov	rax, PiecesPawn
		ShiftBB   Down, rax, rax
		bt	rax, r8
		lea	eax, [rsi+MinorBehindPawn*(Them-Us)]
		cmovc	esi, eax
NoBehindPawnBonus:

	; Bonus for outpost squares
		mov	rax, OutpostRanks
		mov	rcx, qword[rdi+PawnEntry.pawnAttacksSpan+8*Them]
		_andn   rcx, rcx, rax
		bt	rcx, r8
		jnc	OutpostElse
if	0
		mov	ecx, 1
		mov	rax, qword[rdi+PawnEntry.pawnAttacks+8*Us]	;qword[.ei.attackedBy+8*(8*Us+Pawn)]
		bt	rax, r8
		adc	ecx, ecx
		imul	eax, ecx,Outpost0
		addsub	esi, eax
else		
		lea	ecx, [rsi+2*Outpost1*(Them-Us)]
		add	esi, 2*Outpost0*(Them-Us)
		mov	rax, qword[rdi+PawnEntry.pawnAttacks+8*Us]	;qword[.ei.attackedBy+8*(8*Us+Pawn)]
		bt	rax, r8
		cmovc   esi, ecx
end if
		jmp	OutpostDone
OutpostElse:
		mov	rax, PiecesUs
		_andn	rax, rax, rcx
		and	rax, r10
		jz	OutpostDone
if	0
		xor	ecx,ecx
		test	rax, qword[rdi+PawnEntry.pawnAttacks+8*Us]	;qword[.ei.attackedBy+8*(8*Us+Pawn)]
		setnz	cl
		inc	ecx
		imul	eax, ecx, Outpost1
		addsub	esi, eax
else
		lea	ecx, [rsi+Outpost1*(Them-Us)]
		add	esi, Outpost0*(Them-Us)
		test	rax, qword[rdi+PawnEntry.pawnAttacks+8*Us]	;qword[.ei.attackedBy+8*(8*Us+Pawn)]
		cmovnz	esi, ecx
end if
OutpostDone:

	; Penalty for pawns on the same color square as the bishop
    if Pt = Bishop
		mov	rax, CenterFiles	;FileCBB or FileDBB or FileEBB or FileFBB
		lea	r10, [r14+r15]
		and	r10, rax
		ShiftBB   Down, r10, r10
		and	r10, PiecesUs	;us
		and	r10, PiecesPawn
		_popcnt   r10, r10, rcx
		inc	r10

		xor	ecx, ecx
		mov	rax, DarkSquares
		bt	rax, r8
		adc	rcx, rdi
		movzx	eax, byte[rcx+PawnEntry.pawnsOnSquares+2*Us]
		imul	eax, r10d
		imul	eax, BishopPawns
		subadd	esi, eax
    ; Bonus for	bishop on a long diagonal which	can "see" both center squares
	BishopAttacks	rax, r8, PiecesPawn, rcx
		bts	rax, r8
		mov	r10, Center	;(FileDBB or FileEBB) and (Rank4BB or Rank5BB)
		and	rax, r10
		_blsr	rcx, rax	;lea	rcx, [rax - 1];test	rcx, rax
		lea	eax, [rsi + (Them - Us)*LongRangedBishop]
		cmovnz	esi, eax

		cmp	byte[rbp + Pos.chess960],	0
		je	@2f
		lea	rdx, [rbp	+ Pos.board + r8]
		mov	rcx, DELTA_E +	8*(1-2*Us)
		cmp	r8d, SQ_A1 xor (56*Us)
		je	@1f
		mov	rcx, DELTA_W +	8*(1-2*Us)
		cmp	r8d, SQ_H1 xor (56*Us)
		jne	@2f
    @1:
		cmp	byte[rdx + rcx], 8*Us + Pawn
		jne	@2f
		mov	eax, 4*TrappedBishopA1H1
		cmp	byte[rdx + rcx	+ 8*(1-2*Us)], 0
		jne	@1f
		mov	eax, 2*TrappedBishopA1H1
		cmp	byte[rdx + rcx	+ rcx],	8*Us + Pawn
		je	@1f
		mov	eax, TrappedBishopA1H1
    @1:
		subadd   esi, eax
    @2:

    end if



  else if Pt = Rook

    if Us = White
		cmp	r8d, SQ_A5
		jb	NoEnemyPawnBonus
    else
		cmp	r8d, SQ_A5
		jae	NoEnemyPawnBonus
    end if
		mov	rax, PiecesThem	;qword[rbp+Pos.typeBB+8*Them]
		and	rax, PiecesPawn	;qword[rbp+Pos.typeBB+8*Pawn]
		and	rax, qword[RookAttacksPDEP+8*r8]
		_popcnt	rax, rax, rcx
		imul	eax, RookOnPawn
		addsub	esi, eax
NoEnemyPawnBonus:
		mov	ecx, r8d
		and	ecx, 7
		movzx	eax, byte[rdi+PawnEntry.semiopenFiles+1*Us]
		movzx	r8d, byte[rdi+PawnEntry.semiopenFiles+1*Them]
		bt	eax, ecx
		jnc	NoOpenFileBonus
		bt	r8d, ecx
		lea	eax, [rsi+RookOnFile0*(Them-Us)]
		lea	esi, [rsi+RookOnFile1*(Them-Us)]
		cmovnc	esi, eax
		jmp	NoTrappedByKing
NoOpenFileBonus:
		cmp	edx, 4		; mob
		jae	NoTrappedByKing
if	0	;rook hanging
		and	r10, qword[rbx+State.checkSq]
		test	r10, PiecesThem
		jnz	NoTrappedByKing
end if
		movzx	eax, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		and	eax, 7		;file ksq = kf
		cmp	eax, FILE_E
		setl	ah
		cmp	cl, al		;cl =	sq_rook
		setl	al
		cmp	ah, al
		jnz	NoTrappedByKing
		movzx	eax, byte[rbx+State.castlingRights]
		and	eax, 3 shl (2*Us)
		setz	al
		inc	eax
		imul	eax, eax, TrappedRook
		subadd	esi, eax
NoTrappedByKing:

  else if Pt = Queen
		mov	rax, qword[.ei.attackedBy+8*(8*Them+Bishop)]
		or	rax, qword[.ei.attackedBy+8*(8*Them+Rook)]
		and	rax, rcx
		or	qword[.ei.attackedBy+8*(8*Us+SLIDER_ON_QUEEN)], rax
		mov	rax, qword[RookAttacksPDEP+8*r8]
		mov	rdx, qword[BishopAttacksPDEP+8*r8]
		and	rax, qword[rbp+Pos.typeBB+8*Rook]
		and	rdx, qword[rbp+Pos.typeBB+8*Bishop]
		or	rax, rdx
		and	rax, PiecesThem
		jz	SkipQueenPin
		;sniper exist
		shl	r8d, 6+3
		lea	rdx, [r14+r15]
QueenPinLoop:
		_tzcnt   rcx, rax
		mov	r10, qword[BetweenBB+r8+8*rcx]
		and	r10, rdx
		jz	QDirectAttacknRelatifPin
		_blsr	rcx, r10	;lea	rcx, [r10-1]; test	rcx, r10
		jz	QDirectAttacknRelatifPin
Pinned2:
		_blsr	rax, rax, r10
		jnz	QueenPinLoop
		jmp	SkipQueenPin
QDirectAttacknRelatifPin:
		add	esi, WeakQueen*(Us-Them)
SkipQueenPin:
  end if

		movzx	r8d, byte[r9]
		cmp	r8d, 64
		jb	NextPiece
AllDone:
end macro


macro EvalKing Us
	; in  rbp address of Pos struct
	;     rbx address of State struct
	;     rsp address of evaluation info
	; add/sub score to dword[.ei.score]

  local Them, Up, Camp
  local PiecesUs, PiecesThem
  local QueenCheck, RookCheck, BishopCheck, KnightCheck
  local AllDone, DoKingSafety, b4KingSafetyDoneRet, KingSafetyDoneRet
  local RookDone, BishopDone, KnightDone, TRank8BB
  local NoKingSide, NoQueenSide, NoPawns

	PiecesPawn	= r11

  if Us = White
	Them		= Black
	Up		= DELTA_N
	Down		= DELTA_S
	TRank8BB	= Rank1BB
	TRank7BB	= Rank2BB
	AttackedByUs    = r12
	AttackedByThem  = r13
	PiecesUs	= r14
	PiecesThem	= r15
	Camp		= AllSquares xor Rank6BB xor Rank7BB xor Rank8BB	;Rank1BB or Rank2BB or Rank3BB or Rank4BB or Rank5BB
  else
	Them		= White
	Up		= DELTA_S
	Down		= DELTA_N
	TRank8BB	= Rank8BB
	TRank7BB	= Rank7BB
	AttackedByUs	= r13
	AttackedByThem	= r12
	PiecesUs	= r15
	PiecesThem	= r14
	Camp		= AllSquares xor Rank1BB xor Rank2BB xor Rank3BB	;Rank4BB or Rank5BB or Rank6BB or Rank7BB or Rank8BB
  end if

if	RevertCheckChange = 1
	QueenCheck      = 780
	RookCheck       = 880
	BishopCheck     = 435
	KnightCheck	= 790
else
	QueenCheck      = 780
	RookCheck       = 1080
	BishopCheck     = 635
	KnightCheck	= 790
end if
		Assert   e, rdi, qword[.ei.pi], 'assertion rdi=qword[.ei.pi] failed in EvalKing'
		Assert   e, PiecesUs, qword[rbp+Pos.typeBB+8*Us], 'assertion PiecesUs failed in EvalKing'
		Assert   e, PiecesThem, qword[rbp+Pos.typeBB+8*Them], 'assertion PiecesThem failed in EvalKing'

		movzx	ecx, byte[rbp+Pos.pieceList+16*(8*Us+King)]

		mov	r10d, ecx 
		mov	edx, ecx
		and	edx, 7

		mov	rax, Camp
		and	rax, qword[KingFlank+8*rdx]
		and	rax, AttackedByThem

		mov	rdx, qword[.ei.attackedBy2+8*Them]
		and	rdx, rax
		_popcnt	rdx, rdx, r9
		_popcnt	rax, rax, r9
		add	eax, edx
		mov	dword[.ei.tropism], eax
		; r10d = our king square
		movzx	eax, byte[rbx+State.castlingRights]
		movzx	edx, byte[rdi+PawnEntry.castlingRights]
		mov	esi, dword[rdi+PawnEntry.kingSafety+4*Us]
		cmp	cl, byte[rdi+PawnEntry.kingSquares+1*Us]
		jne	DoKingSafety	; 27.75%
		xor	eax, edx
		test	eax, 3 shl (2*Us)
		jnz	DoKingSafety	; 0.68%
KingSafetyDoneRet:

		mov	edi, dword[.ei.kingAttackersCount+4*Them]
if	1
		movzx	ecx, byte[rbp+Pos.pieceEnd+(8*Them+Queen)]
		and	ecx, 15
		add	ecx, edi
		cmp	ecx, 2
		jb	AllDone
end if

		mov	r8, qword[.ei.attackedBy2+8*Us]
		_andn	r8, r8, AttackedByThem
		mov	r9, AttackedByUs
		not	r9
		or	r9, qword[.ei.attackedBy+8*(8*Us+Queen)]
		or	r9, qword[.ei.attackedBy+8*(8*Us+King)]
		and	r8, r9 ; r8 = weak

		mov	r9, qword[.ei.kingRing+8*Us]
		and	r9, r8

		imul	edi, dword[.ei.kingAttackersWeight+4*Them]
		imul	eax, dword[.ei.kingAdjacentZoneAttacksCount+4*Them], 69
		add	edi, eax

		_popcnt rax, r9, rcx
		imul    eax, 185
		add     edi, eax
		mov	r9, qword[rbp+Pos.typeBB+8*Queen]
		test    PiecesThem, r9
		lea     eax, [rdi-873]
		cmovz   edi, eax

	; the following	does edi += - 6*mg_value(score)/8 - 30
		
		lea	ecx, [rsi+0x08000]
if	RevertCheckChange = 1
		sub	edi, 30
else
		sub	edi, 25
end if
		sar	ecx, 16
		lea	ecx, [2*rcx]
		lea	edx, [3*rcx]
		lea	eax, [rdx+7]
		cmovs	edx, eax
		sar	edx, 3
		sub	edi, edx ; edi =	kingDanger

.eimobility	equ (.ei.attackedBy+8*Pawn)
		mov	eax, dword[.eimobility]
		add	eax, 0x08000
		sar	eax, 16
if Them = White
		add	edi, eax
else
		sub	edi, eax
end if

		and	r9, PiecesUs	;r9 = QueenUs
		xor	r9, PiecesUs	;r9 = pizUs ^ QueenUs
		or	r9, PiecesThem
		BishopAttacks rdx, r10, r9, rax
		RookAttacks   rax, r10, r9, rcx
		and	r8, qword[.ei.attackedBy2+8*Them]
		_andn	r8, r8, AttackedByUs
		or	r8, PiecesThem
		not	r8 ; r8 = safe

if	RevertCheckChange = 1
	; Enemy	queen safe checks
		mov	r9, rax
		or	rax, rdx
		and	rax, r8
		and	rax, qword[.ei.attackedBy+8*(8*Them+Queen)]
		mov	rcx, qword[.ei.attackedBy+8*(8*Us+Queen)]
		not	rcx
		test	rax, rcx
		lea	ecx, [rdi+QueenCheck]
		cmovnz	edi, ecx

		and	r9, qword[.ei.attackedBy+8*(8*Them+Rook)]	;b1
	; r9 = b1 & ei.attackedBy[Them][ROOK]
		and	rdx, qword[.ei.attackedBy+8*(8*Them+Bishop)]	;b2
	; rdx = b1 & ei.attackedBy[Them][BISHOP]

	; Enemy rooks safe and other checks
		xor	ecx, ecx
		test	r9, r8
		lea	eax, [rdi+RookCheck]
		cmovnz	edi, eax
		cmovnz	r9, rcx
		; r9 = unsafeChecks
	; Enemy bishops safe and other checks
		test	rdx, r8
		lea	eax, [rdi+BishopCheck]
		cmovnz	edi, eax
		cmovnz	rdx, r9
		or	r9, rdx
else

		;b1 = rax = RookAttacks
		;b2 = rdx = BishopAttacks
		;r8 = safe
		;r9 = unsafeChecks

;    Bitboard RookCheck =  b1 & safe & attackedBy[Them][ROOK];
;    if (RookCheck) kingDanger += RookSafeCheck;
;    else	unsafeChecks |= b1 & attackedBy[Them][ROOK];

		mov	r9, rax
		and	r9, qword[.ei.attackedBy+8*(8*Them+Rook)]
		lea	ecx, [rdi+RookCheck]
		test	r9, r8
		cmovnz	edi, ecx
		mov	ecx, 0
		cmovnz	r9, rcx

;    Bitboard QueenCheck =  (b1 | b2) & attackedBy[Them][QUEEN]
;                         & safe & ~attackedBy[Us][QUEEN] & ~RookCheck;
;    if (QueenCheck) kingDanger += QueenSafeCheck;
		mov	rcx, rax
		or	rcx, rdx
		and	rcx, qword[.ei.attackedBy+8*(8*Them+Queen)]
		mov	rax, qword[.ei.attackedBy+8*(8*Us+Queen)]
		or	rax, r9			;& ~attackedBy[Us][QUEEN] & ~RookCheck; = & (~(attackedBy[Us][QUEEN] | RookCheck ))
		_andn   rax, rax, r8
		and	rcx, rax
		lea	eax,[rdi+QueenCheck]
		cmovnz	edi, eax
;    Bitboard BishopCheck =  b2 & safe & attackedBy[Them][BISHOP] & ~QueenCheck;
;    if (BishopCheck) kingDanger += BishopSafeCheck;
;    else	unsafeChecks |= b2 & attackedBy[Them][BISHOP];
		and	rdx, qword[.ei.attackedBy+8*(8*Them+Bishop)]
		_andn   rcx, rcx, rdx
		and	rcx, r8
		lea	eax, [rdi+BishopCheck]
		cmovnz	edi, eax
		cmovnz	rdx, r9
		or	r9, rdx
end if
		mov	rdx, qword[KnightAttacks+8*r10]
		and	rdx, qword[.ei.attackedBy+8*(8*Them+Knight)]	;b
	; Enemy knights safe and other checks
		test	rdx, r8
		lea	eax, [rdi+KnightCheck]
		cmovnz	edi, eax
		cmovnz	rdx, r9
		or	r9, rdx

		and	r9, qword[.ei.mobilityArea+8*Them]
		or	r9, qword[rbx+State.blockersForKing+8*Us]

		_popcnt rax, r9, rcx
if	RevertCheckChange = 1
		imul	eax, 129
else
		imul	eax, 150
end if
		add	edi, eax



	; Compute the king danger score and subtract it from the evaluation
if 0	;RevertCheckChange = 0
		lea	eax,[rdi-100]
		mov	r9, qword[.ei.attackedBy+8*(8*Us+King)]
		and	r9, qword[.ei.attackedBy+8*(8*Us+Knight)]
		cmovnz	edi, eax
end if

		mov	ecx, dword[.ei.tropism]
		imul	ecx, ecx
if	RevertCheckChange = 0
		lea	ecx, [5*rcx]
		sar	ecx, 4
else
		sar	ecx, 2
end if
		add	edi, ecx
if	1
		test	edi, edi
		js	AllDone
else
		cmp	edi, 100
		jle	AllDone
end if
		mov	eax, edi
		shr	eax, 4		; kingDanger / 16
		sub	esi, eax
		imul	edi, edi	; kingDanger * kingDanger
		shr	edi, 12		; previous / 4096
		shl	edi, 16
		sub	esi, edi
		jmp	AllDone
	calign 8
DoKingSafety:
	; rdi =	address	of PawnEntry
;		edx	= byte[rdi+PawnEntry.castlingRights]
;		ecx	= byte[rbp+Pos.pieceList+16*(8*Us+King)]
		movzx	eax, byte[rbx+State.castlingRights]
		and	eax, 3 shl (2*Us)
		and	edx, 3 shl (2*Them)
		add	edx, eax
		mov	byte[rdi+PawnEntry.kingSquares+1*Us], cl
		mov	byte[rdi+PawnEntry.castlingRights], dl

		call	ShelterStorm#Us
		mov	esi, eax
		test	byte[rbx+State.castlingRights], 1 shl (2*Us+0)
		jz	NoKingSide
		mov	ecx, SQ_G1 + Us*(SQ_G8-SQ_G1)
		call	ShelterStorm#Us
		cmp	esi, eax
		cmovl	esi, eax
NoKingSide:
		test	byte[rbx+State.castlingRights], 1 shl (2*Us+1)
		jz	NoQueenSide
		mov	ecx, SQ_C1 + Us*(SQ_C8-SQ_C1)
		call	ShelterStorm#Us
		cmp	esi, eax
		cmovl	esi, eax
NoQueenSide:
		shl	esi, 16
	; esi = score
		movzx	r10d, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		lea	ecx, [8*r10]		; r10d = ksq
		lea	rcx, [DistanceRingBB+8*rcx]
		mov	rdi, qword[.ei.pi]	; clobbered with previouse kingDanger +ShelterStorm
		mov	rdx, PiecesUs
		and	rdx, PiecesPawn
		jz	b4KingSafetyDoneRet
  iterate i, 0, 1, 2, 3, 4, 5, 6
		sub	esi, 16
		test	rdx, qword[rcx+8*i]
		jnz	b4KingSafetyDoneRet	;KingSafetyDoneRet
  end iterate
		sub	esi, 16
b4KingSafetyDoneRet:
		mov	dword[rdi+PawnEntry.kingSafety+4*Us], esi
		jmp	KingSafetyDoneRet
	calign 8
AllDone:
		and	r10d, 7
		mov	eax, dword[.ei.tropism]
		mov	rdi, qword[.ei.pi]	; we may have clobbered rdi with kingDanger
		test	PiecesPawn, qword[KingFlank+8*r10]
		;mov	r10, qword[KingFlank+8*r10]
		;test	r10, PiecesPawn
		lea	ecx, [rsi-PawnlessFlank]
		cmovz   esi, ecx		; pawnless flank
		
		imul	eax, CloseEnemies
		sub	esi, eax		; king tropism
  if Us eq White
		add	dword[.ei.score], esi
  else
		sub	dword[.ei.score], esi
  end if


end macro



macro ShelterStorm Us
	; in: rbp position
	;     rbx state
	;     ecx ksq
	; out: eax safety
	PiecesPawn	= r11

  if Us = White
	Them		= Black
	Up		= DELTA_N
	Down		= DELTA_S
	PiecesUs	equ r14
	PiecesThem	equ r15
	BlockRanks	= (FileABB or FileHBB) and (Rank1BB or Rank2BB)
  else
	Them		= White
	Up		= DELTA_S
	Down		= DELTA_N
	PiecesUs	equ r15
	PiecesThem	equ r14
	BlockRanks	= (FileABB or FileHBB) and (Rank8BB or Rank7BB)
  end if

	MaxSafetyBonus = 374	;264	;374	;258	;374

		Assert   e, PiecesUs, qword[rbp+Pos.typeBB+8*Us], 'assertion PiecesUs failed in EvalPassedPawns'
		Assert   e, PiecesThem, qword[rbp+Pos.typeBB+8*Them], 'assertion PiecesThem failed in EvalPassedPawns'

	; ecx = ksq
		mov	r8, qword[ForwardBB+8*(64*Them+rcx)]
		_andn   r8, r8, PiecesPawn
	; r8 = b
		mov	r9, PiecesUs
		and	r9, r8
	; r9 = ourPawns
		and	r8, PiecesThem
		mov	r10, r8
	; r10 = theirPawns

		ShiftBB   Down, r8, r8
		mov	rax, BlockRanks
		and	rax, r8
		bt	rax, rcx
		sbb	eax, eax
		and	eax, (MaxSafetyBonus-5)
		add	eax, 5	;MaxSafetyBonus

	; eax = safety
	; r13d = relative_rank(Us, ksq)+1
		and	ecx, 7
	; ecx = file of ksq
		lea	edx, [5*rcx]
		lea	edx, [rdx+8*rcx+2]
		shr	edx, 4
	; edx = max(FILE_B, min(FILE_G, ecx))-1

  macro ShelterStormAcc
	local rkUs, rkUsd, fileMax, fileMaxd, next0
	; used reg r8, rcx, rsi, rdi
	if Us eq White
		rkUs	= r8
		rkUsd	= r8d
		fileMax = rcx
		fileMaxd = ecx
	else
		rkUs	= rcx
		rkUsd	= ecx
		fileMax = r8
		fileMaxd = r8d
	end if

		mov	r8, qword[FileBB+8*rdx]
		mov	rcx, r8
		and	r8, r10
	if Us eq White
		bsf	rdi, r8
		cmovz	edi, r8d
		shr	edi, 3
	else
		bsr	rdi, r8
		mov	r8d, 7 shl 3
		cmovz	edi, r8d
		shr	edi, 3
		xor	edi, 7
	end if
	; edi = rkThem

		and	rcx, r9
	if Us eq White
		bsf	rkUs, rcx
		cmovz	rkUsd, ecx
		shr	rkUsd, 3
	else
		bsr	rkUs, rcx
		cmovz	rkUsd, r8d
		shr	rkUsd, 3
		xor	rkUsd, 7
	end if
	; esi = rkUs

		mov	fileMaxd, edx
		shl	fileMaxd, 3+2
	; ShelterWeakness and StormDanger are twice as big
	; to avoid an anoying min(f,FILE_H-f) in ShelterStorm

		inc	rkUsd
	; esi = rkUs+1

;      int d = std::min(f, ~f);
;      safety += ShelterStrength[d][ourRank];
;      safety -= (ourRank && (ourRank == theirRank - 1)) ? BlockedStorm[theirRank]: UnblockedStorm[d][theirRank];
		add	eax, dword[ShelterStrength-4+fileMax+4*rkUs]
		add	fileMax, UnblockedStorm
		cmp	rkUsd, 1
		je	next0
		cmp	rkUsd, edi
		lea	rkUs, [BlockedStorm]
		cmove	fileMax, rkUs
next0:
		sub	eax, dword[fileMax+4*rdi]
		inc	edx

  end macro

    ShelterStormAcc
    ShelterStormAcc
    ShelterStormAcc
		ret
end macro


macro EvalThreats Us
	; in: rbp position
	;     rbx state
	;     rsp evaluation info
	;     r10-r15 various bitboards
	; io: esi score accumulated

  local addsub, Them, Up, Left, Right
  local AttackedByUs, AttackedByThem, PiecesPawn, PiecesUs, PiecesThem
  local TRank3BB
  local WeakDone, Weakoppdone
  local ThreatMinorLoop, ThreatMinorDone, ThreatRookLoop, ThreatRookDone
  local ThreatQueenSkip

	PiecesPawn	equ r11
  if Us	= White
	;addsub		equ add
	macro addsub a,	b
		add  a,	b
	end macro

	AttackedByUs	equ r12
	AttackedByThem	equ r13
	PiecesUs	equ r14
	PiecesThem	equ r15
	Them            = Black
	Up              = DELTA_N
	Left            = DELTA_NW
	Right           = DELTA_NE
	TRank3BB	= Rank3BB
  else
	;addsub		equ sub
	macro addsub a,	b
		sub  a,	b
	end macro
	AttackedByUs	equ r13
	AttackedByThem	equ r12
	PiecesUs	equ r15
	PiecesThem	equ r14
	Them		= White
	Up              = DELTA_S
	Left            = DELTA_SE
	Right           = DELTA_SW
	TRank3BB	= Rank6BB
  end if

	     Assert   e, PiecesPawn, qword[rbp+Pos.typeBB+8*Pawn], 'assertion PiecesPawn failed in EvalThreats'
	     Assert   e, PiecesUs, qword[rbp+Pos.typeBB+8*Us], 'assertion PiecesUs failed in EvalThreats'
	     Assert   e, PiecesThem, qword[rbp+Pos.typeBB+8*Them], 'assertion PiecesThem failed in EvalThreats'


;    // Non-pawn enemies
;    nonPawnEnemies = pos.pieces(Them) ^ pos.pieces(Them, PAWN);
		mov	r8, PiecesPawn
		_andn   r8, r8, PiecesThem
		mov	rdx, r8		;    nonPawnEnemies

;    // Squares strongly protected by the enemy, either because they defend the
;    // square with a pawn, or because they defend the square twice and we don't.
;    stronglyProtected =  attackedBy[Them][PAWN] | (attackedBy2[Them] & ~attackedBy2[Us]);
		mov	r9, qword[.ei.attackedBy2+8*Us]
		_andn   r9, r9, qword[.ei.attackedBy2+8*Them]
		or	r9, qword[rdi+PawnEntry.pawnAttacks+8*Them]	;qword[.ei.attackedBy+8*(8*Them+Pawn)]
		mov	r10, r9		;r10 = stronglyProtected

;    // Non-pawn enemies, strongly protected
;    defended = nonPawnEnemies & stronglyProtected;
		and	r8, r9

;    // Enemies not strongly protected and under our attack
;    weak = pos.pieces(Them) & ~stronglyProtected & attackedBy[Us][ALL_PIECES];
		_andn   r9, r9, PiecesThem
		and	r9, AttackedByUs	;weak

;    // Bonus according to the kind of attacking pieces
;    if (defended | weak)
if	0
		or	r8, qword[rbx+State.checkSq]	;qword[rbp+Pos.typeBB+8*Rook]
		and	r8, PiecesThem
end if
		or	r8, r9
		jz	WeakDone
;    {
;        b = (defended | weak) & (attackedBy[Us][KNIGHT] | attackedBy[Us][BISHOP]);
;	while (b)
;        {
;            Square s = pop_lsb(&b);
;            score += ThreatByMinor[type_of(pos.piece_on(s))];
;            if (type_of(pos.piece_on(s)) != PAWN)
;                score += ThreatByRank * (int)relative_rank(Them, s);
;        }
		mov	rax, qword[.ei.attackedBy+8*(8*Us+Knight)]
		or	rax, qword[.ei.attackedBy+8*(8*Us+Bishop)]
		and	r8, rax
		jz	ThreatMinorDone
ThreatMinorLoop:
		bsf	rax, r8
		movzx	ecx, byte[rbp+Pos.board+rax]
		addsub	esi, dword[Threat_Minor+4*rcx]
		shr	eax, 3
  if Us eq White
		xor	eax, Them*7
  end if
	; tricky: we want only the lower byte of the memory here,
	;  but the upper 3 bytes of eax are zero anyways
		and	eax, dword[IsNotPawnMasks+rcx]
		imul	eax, ThreatByRank
		addsub	esi, eax
		_blsr	r8, r8, rcx
		jnz	ThreatMinorLoop
ThreatMinorDone:
;        b = weak & attackedBy[Us][ROOK];
;        while (b)
;        {
;            Square s = pop_lsb(&b);
;            score += ThreatByRook[type_of(pos.piece_on(s))];
;            if (type_of(pos.piece_on(s)) != PAWN)
;                score += ThreatByRank * (int)relative_rank(Them, s);
;        }
		mov	r8, r9
		and	r8, qword[.ei.attackedBy+8*(8*Us+Rook)]
		jz	ThreatRookDone
ThreatRookLoop:
		bsf	rax, r8
		movzx	ecx, byte[rbp+Pos.board+rax]
		addsub	esi, dword[Threat_Rook+4*rcx]
		shr	eax, 3
  if Us eq White
		xor	eax, Them*7
  end if
		and	eax, dword[IsNotPawnMasks+rcx]
		imul	eax, ThreatByRank
		addsub	esi, eax
		_blsr	r8, r8, rcx
		jnz	ThreatRookLoop
ThreatRookDone:

;        if (weak & attackedBy[Us][KING]) score += ThreatByKing;
		test	r9, qword[.ei.attackedBy+8*(8*Us+King)]
		lea	eax, [rsi+ThreatByKing*(Them-Us)]
		cmovnz	esi, eax
;        b = (nonPawnEnemies & attackedBy2[Us][ALL_PIECES]) | (~attackedBy[Them][ALL_PIECES]);

		mov	rax, rdx
		and	rax, qword[.ei.attackedBy2+8*Us]
		mov	rcx, AttackedByThem
		not	rcx
		or	rax, rcx
;        score += Hanging * popcount(weak & b);
		and	rax, r9
		_popcnt	rax, rax, rcx
		imul	eax, Hanging
		addsub	esi, eax

WeakDone:

		mov	rax, r10
		_andn   rax, rax, AttackedByThem
		and	rax, AttackedByUs
		_popcnt	rax, rax, rcx
		imul	eax, RestrictedPiece
		addsub	esi, eax

;    // Bonus for enemy unopposed weak pawns
;    if (pos.pieces(Us, ROOK, QUEEN))	score += WeakUnopposedPawn * pe->weak_unopposed(Them);
		test	PiecesUs, qword[rbx+State.checkSq]	;QxR
		jz	Weakoppdone
		movzx   eax, byte[rdi + PawnEntry.weakUnopposed]
  if Us	= White
		shr	eax, 4
  else
		and	eax, 0x0F
  end if
		imul	eax, WeakUnopposedPawn
		addsub	esi, eax
Weakoppdone:
;at this point r9 (weak) is free to use ================================
;    // Find squares where our pawns can push on the next move
;    b  = shift<Up>(pos.pieces(Us, PAWN)) & ~pos.pieces();
;    b |= shift<Up>(b & TRank3BB) & ~pos.pieces();
		mov	rax, PiecesUs
		and	rax, PiecesPawn
		ShiftBB	Up, rax
		mov	r8, qword[rbx+State.Occupied]
		not	r8
		and	rax, r8

		mov	rcx, TRank3BB
		and	rcx, rax
		ShiftBB	Up, rcx
		and	rcx, r8
		or	rax, rcx

;    // Safe or protected squares
;    safe = ~attackedBy[Them][ALL_PIECES] | attackedBy[Us][ALL_PIECES];
		mov	r9, AttackedByThem
		_andn   r9, r9, AttackedByUs	;safe
;    // Keep only the squares which are relatively safe
;    b &= ~attackedBy[Them][PAWN] & safe;
		mov	rcx, qword[rdi+PawnEntry.pawnAttacks+8*Them]	;qword[.ei.attackedBy+8*(8*Them+Pawn)]
		_andn   rcx, rcx, r9
		and	rcx, rax
;    // Bonus for safe pawn threats on the next move
;    b = pawn_attacks_bb<Us>(b) & pos.pieces(Them);
;    score += ThreatByPawnPush * popcount(b);
		mov	rax, rcx
		ShiftBB   Left, rax, r8
		ShiftBB   Right, rcx, r8
		or	rax, rcx
		and	rax, PiecesThem
		_popcnt	rax, rax,	rcx
		imul	eax, ThreatByPawnPush
		addsub	esi, eax

;    // Our safe or protected pawns
;    b = pos.pieces(Us, PAWN) & safe;
		and	r9, PiecesUs
		and	r9, PiecesPawn
;    b = pawn_attacks_bb<Us>(b) & nonPawnEnemies;
;    score += ThreatBySafePawn * popcount(b);
		mov	rax, r9
		ShiftBB   Left, rax, rcx
		ShiftBB   Right, r9, rcx
		or	rax, r9
		and	rax, rdx	; nonPawnEnemies
		_popcnt	rax, rax, rcx
		imul	eax, ThreatBySafePawn
		addsub	esi, eax
;    // Bonus for threats on the next moves against enemy queen
;    if (pos.count<QUEEN>(Them) == 1)
;    {
		cmp	byte[rbp+Pos.pieceEnd+(8*Them+Queen)] , (16*(8*Them+Queen))+1
		jne	ThreatQueenSkip

;	Square s = pos.square<QUEEN>(Them);
		movzx	ecx, byte[rbp+Pos.pieceList+16*(8*Them+Queen)]
;        safe = mobilityArea[Us] & ~stronglyProtected;
		_andn   r10, r10, qword[.ei.mobilityArea+8*Us]
;        b = attackedBy[Us][KNIGHT] & pos.attacks_from<KNIGHT>(s);
		mov	rax, qword[KnightAttacks+8*rcx]
if	0
		bts	rax, rcx
end if
		and	rax, qword[.ei.attackedBy+8*(8*Us+Knight)]
		and	rax, r10
;        score += KnightOnQueen * popcount(b & safe);
		_popcnt	rax, rax, rdx
		imul	eax, KnightOnQueen
		addsub	esi, eax

;        b =  (attackedBy[Us][BISHOP] & pos.attacks_from<BISHOP>(s))
;           | (attackedBy[Us][ROOK  ] & pos.attacks_from<ROOK  >(s));
;        score += SliderOnQueen * popcount(b & safe & attackedBy2[Us]);
		and	r10, qword[.ei.attackedBy+8*(8*Them+SLIDER_ON_QUEEN)]
		and	r10, qword[.ei.attackedBy2+8*Us]
		_popcnt   rax, r10, rcx
		imul	eax, SliderOnQueen
		addsub	esi, eax

;    }

ThreatQueenSkip:
;  }

end macro

if	QueenThreats = 100
macro EvalQueenThreats Us, labelexit, labelend, matethreat

  local Them, NotSidetomove
  local PiecesUs, PiecesThem
  local iteratesqBox, next_sqBox, Neednext_Queen, ReciprocalQueen, beforelabelexit
	PiecesPawn	= r11
  if Us	= White
	AttackedByUs    = r12
	AttackedByThem  = r13
	PiecesUs	= r14
	PiecesThem	= r15
	Them            = Black
  else
	AttackedByUs    = r13
	AttackedByThem  = r12
	PiecesUs	= r15
	PiecesThem	= r14
	Them		= White
  end if
		mov	rcx, qword[.ei.attackedBy+8*(8*Us+King)]
		mov	rax, qword[.ei.attackedBy+8*(8*Them+Queen)]
		mov	r11, qword[.ei.attackedBy+8*(8*Them+0)]		;passive attacker w/o Queen Attack
		or	r11, qword[.ei.attackedBy2+8*Them]		;added
		and	rax, rcx
		and	rax, r11
		jz	labelend

		or	r11, PiecesUs
		_andn	r11, r11, rcx

		mov	rcx, qword[.ei.attackedBy2+8*Us]
		or	rcx, PiecesThem
		_andn	rcx, rcx, rax
		jz	labelend

		movzx	eax, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		shl	eax, 6+3
		jmp	iteratesqBox
	calign	8
iteratesqBox:
		bsf	r10, rcx
		mov	r9, PiecesThem
		and	r9, qword[rbp+Pos.typeBB+8*Queen]
		jmp	ReciprocalQueen
	calign	8
ReciprocalQueen:
		bsf	rdx, r9
		_blsi	r8, r9
		xor	r9, r8
		shl	rdx, 6+3
		mov	rsi, qword[rbx+State.Occupied]
		test	rsi, qword[LineBB+rdx+8*r10]
		jz	Neednext_Queen
		test	rsi, qword[BetweenBB+rdx+8*r10]	;make sure this Queen have access
		jnz	Neednext_Queen
		xor	rsi, r8
		QueenAttacks rdx, r10, rsi, rdi, r8
		mov	r8, rdx
		_andn	rdx, rdx, r11
		and	rdx, qword[Evade+rax+8*r10]	;escape KingUs
		jnz	next_sqBox			;Neednext_Queen

		mov	rdx, r8
		and	rdx, qword[rbx+State.checkSq]	; QxR
		and	rdx, qword[RookAttacksPDEP+8*r10]
		and	rdx, PiecesUs
		jnz	Neednext_Queen
		and	r8, qword[rbx+State.checkSq+8]	; QxB
		and	r8, qword[BishopAttacksPDEP+8*r10]
		and	r8, PiecesUs
		jz	beforelabelexit
Neednext_Queen:
		test	r9, r9
		jnz	ReciprocalQueen
next_sqBox:
		_blsr	rcx, rcx, r8
		jnz	iteratesqBox
		jmp	labelend
beforelabelexit:
		cmp	dword[rbp+Pos.sideToMove], Them
		jne	matethreat
		jmp	labelexit
	calign	8
	if Us	= Black
NotSidetomove:
	end if
end macro
end if

macro EvalPassedPawns Us
	; in: rbp position
	;     rbx state
	;     rsp evaluation info
	;     r15 qword[rdi+PawnEntry.passedPawns+8*Us]
	; add to dword[.ei.score]

  local addsub, subadd, Them, Up, s, PiecesUs, PiecesThem
  local NextPawn, AddToBonus, Continue
  local DoScaleDown, DontScaleDown


  if Us = White
	;addsub		equ add
	;subadd		equ sub
	macro addsub a,	b
		add  a,	b
	end macro
	macro subadd a,	b
		sub  a,	b
	end macro

	Them		equ Black
	Up		equ DELTA_N	;8
	PiecesPawn	equ r11
	AttackedByUs	equ r12
	AttackedByThem	equ r13
	PiecesUs	equ r14
	PiecesThem	equ r15
  else
	;addsub		equ sub
	;subadd		equ add
	macro addsub a,	b
		sub  a,	b
	end macro
	macro subadd a,	b
		add  a,	b
	end macro

	Them		equ White
	Up		equ DELTA_S	;-8
	PiecesPawn	equ r11
	AttackedByUs	equ r13
	AttackedByThem	equ r12
	PiecesUs	equ r15
	PiecesThem	equ r14
  end if

;ProfileInc EvalPassedPawns

	     Assert   e, rdi, qword[.ei.pi], 'assertion rdi = ei.pi failed in EvalPassedPawns'
	     Assert   ne, r9, 0, 'assertion r9!=0 failed in EvalPassedPawns'
	     Assert   e, PiecesUs, qword[rbp+Pos.typeBB+8*Us], 'assertion PiecesUs failed in EvalPassedPawns'
	     Assert   e, PiecesThem, qword[rbp+Pos.typeBB+8*Them], 'assertion PiecesThem failed in EvalPassedPawns'

NextPawn:
		bsf	r8, r9

		mov	ecx, r8d
		shr	ecx, 3
  
  if Us = Black
		xor	ecx, 7
  end if
	; ecx = r
		mov	esi, dword[PassedRank+4*rcx]
	; esi = (mbonus, ebonus)
		add	r8d, Up
	; r8d = blockSq
	; ecx = r

  if Us = White
		cmp	r8d, SQ_A4+Up
		jb	Continue
  else
		cmp	r8d, SQ_A6+Up
		jae	Continue
  end if
        ; edi = RankFactor[r]
	; at this point edi!=0

	s equ (r8-Up)

		movzx   edx, byte[rbp+Pos.pieceList+16*(8*Us+King)]
		movzx   eax, byte[rbp+Pos.pieceList+16*(8*Them+King)]
		shl	eax, 6
		shl	edx, 6
		xor	r10d, r10d
		movzx   edi, byte[SquareDistance_Cap5+rdx+r8+Up]
		movzx   edx, byte[SquareDistance_Cap5+rdx+r8]
		movzx   eax, byte[SquareDistance_Cap5+rax+r8]
		lea	eax, [5*rax]
  if Us = White
		cmp	r8d, SQ_A7+Up
		cmovb	r10d, edi
  else
		cmp	r8d, SQ_A3+Up
		cmovae	r10d, edi
  end if
		mov	edi, dword[RankFactor+4*rcx]
		lea	edx, [2*rdx+r10]
		sub	eax, edx
               imul	eax, edi
		add	esi, eax


		lea	eax, [rdi+2*rcx]
		bt	PiecesUs, r8
		jc	AddToBonus	; the pawn is blocked by us
		bt	PiecesThem, r8
		jc	Continue	; the pawn is blocked by them
if	0
	RookAttacks   rax, s, qword[rbx+State.Occupied], rdx

		mov	rdx, qword[rbx+State.checkSq]	; QxR
		and	rdx, qword[ForwardBB+8*(64*Them+s)]
		mov	r10, qword[ForwardBB+8*(64*Us+s)]
		mov	rcx, r10
		and	rax, rdx
else
		mov	rax, qword[rbx+State.checkSq]	; QxR
		and	rax, qword[ForwardBB+8*(64*Them+s)]
		mov	r10, qword[ForwardBB+8*(64*Us+s)]
		mov	rcx, r10
end if
		or	rdx, -1
		test	PiecesThem, rax
              cmovz	rdx, AttackedByThem
                 or	rdx, PiecesThem
                and	rcx, rdx
        ; rcx = unsafeSquares
                 or	rdx, -1
               test	PiecesUs, rax
              cmovz	rdx, AttackedByUs
                and	r10, rdx
        ; r10 = defendedSquares

                xor	eax, eax
                 bt	rcx, r8
                mov	edx, 9
	     cmovnc	eax, edx
               test	rcx, rcx
                mov	edx, 20
              cmovz	eax, edx
	; eax = k
                xor	edx, edx
                 bt	r10, r8
                adc	edx, edx
                xor	r10, qword[ForwardBB+8*(64*Us+s)]
                cmp	r10, 1
                adc	edx, edx
                lea	eax, [rax + 2*rdx]
	; eax = k
               imul	eax, edi
AddToBonus:
               imul	eax, 0x00010001
                add	esi, eax

Continue:		
	; r8d = blockSq

	; scale down bonus for candidate passers which need more than one pawn
	; push to become passed
		test	PiecesPawn, qword[ForwardBB+8*(64*Us+s)]
		jnz	DoScaleDown
		mov	r10, PiecesPawn
		and	r10, PiecesThem
		test	r10, qword[PassedPawnMask+8*(r8+64*(Us))]
		jz	DontScaleDown
DoScaleDown:
		lea	ecx, [rsi+0x08000]
		sar	ecx, 16
		movsx	eax, si
		cdq
		sub	eax, edx
		sar	eax, 1
		xchg	eax, ecx
		cdq
		sub	eax, edx
		sar	eax, 1
		shl	eax, 16
		lea	esi, [rax+rcx]
DontScaleDown:

		and	r8d, 7
		add	esi, dword[PassedFile+4*r8]
		addsub	dword[.ei.score], esi

		_blsr	r9, r9, rax
		jnz	NextPawn

		mov	rdi, qword[.ei.pi]
end macro




macro EvalSpace Us
	; in: rbp position
	;     rbx state
	;     rdi qword[.ei.pi]
	;     r10-r15 various bitboards
	;     rsp evaluation info

  local addsub, Them, SpaceMask
  local AttackedByUs, AttackedByThem
  local PiecesPawn, PiecesAll, PiecesUs, PiecesThem

  if Us = White
	;addsub	       equ add
	macro addsub a,	b
		add  a,	b
	end macro

	AttackedByUs   equ r12
	AttackedByThem equ r13
	PiecesPawn     equ r11
	PiecesUs       equ r14
	PiecesThem     equ r15
	Them	       = Black
	SpaceMask      = (CenterFiles and (Rank2BB or Rank3BB or Rank4BB))
  else
	;addsub	       equ sub
	macro addsub a,	b
		sub  a,	b
	end macro
	AttackedByUs   equ r13
	AttackedByThem equ r12
	PiecesPawn     equ r11
	PiecesUs       equ r15
	PiecesThem     equ r14
	Them	       = White
	SpaceMask      = (CenterFiles and (Rank7BB or Rank6BB or Rank5BB))
  end if


	     Assert   e, PiecesPawn, qword[rbp+Pos.typeBB+8*Pawn], 'assertion PiecesPawn failed in EvalSpace'
	     Assert   e, PiecesUs, qword[rbp+Pos.typeBB+8*Us], 'assertion PiecesUs failed in EvalSpace'
	     Assert   e, PiecesThem, qword[rbp+Pos.typeBB+8*Them], 'assertion PiecesThem failed in EvalSpace'


		mov	rdx, PiecesUs
		and	rdx, PiecesPawn
	; rdx = pos.pieces(Us, PAWN)

		mov	rax, rdx
		or	rax, qword[rdi+PawnEntry.pawnAttacks+8*Them]	;qword[.ei.attackedBy+8*(8*Them+Pawn)]
		mov	rcx, SpaceMask
		_andn	rax, rax, rcx
	; rax = safe

		mov	rcx, rdx
	if Us eq White
		shr	rdx, 8
		or	rcx, rdx
		mov	rdx, rcx
		shr	rdx, 16
		or	rcx, rdx
	else if Us eq Black
		shl	rdx, 8
		or	rcx, rdx
		mov	rdx, rcx
		shl	rdx, 16
		or	rcx, rdx
	end if
	; rcx = behind

		and	rcx, rax
	if Us eq White
		shl	rax, 32
	else if Us eq Black
		shr	rax, 32
	end if
		or	rax, rcx
		_popcnt	rax, rax, rdx

		movzx	ecx, byte[rdi+PawnEntry.openFiles]
		_popcnt	rdx, PiecesUs, r8
		sub	edx, ecx
		imul	edx, edx

		imul	eax, edx
		shr	eax, 4    ; eax>0 so division by 16 is easy
		shl	eax, 16

		addsub   esi, eax
end macro



Evaluate_Cold:


virtual at rsp
 .ei EvalInfo
end virtual
		calign   16
.DoPawnEval:
		mov	qword[.ei.attackedBy], rbx	; save [rbp+Pos.state] to void var
		EvalPawns   White
		mov	dword[rdi+PawnEntry.score], esi
		EvalPawns   Black
		mov	rbx, qword[.ei.attackedBy]
		mov	r8, qword[rbx+State.pawnKey]
		movzx	ecx, byte[rdi+PawnEntry.semiopenFiles+0]
		movzx	r9d, byte[rdi+PawnEntry.semiopenFiles+1]
		mov	eax, dword[rdi+PawnEntry.score]
		mov	edx, ecx
		xor	ecx, r9d
		and	edx, r9d
		sub	eax, esi
		_popcnt	rcx, rcx, r9
		_popcnt	rdx, rdx, r9
		add	edx, edx
		mov	qword[rdi+PawnEntry.key], r8
		mov	dword[rdi+PawnEntry.score], eax
		mov	byte[rdi+PawnEntry.openFiles], dl	; multiplication by 2
		add	byte[rdi+PawnEntry.asymmetry], cl
		jmp	Evaluate.DoPawnEvalReturn
		calign 8
.ReturnLazyEval:
;ProfileInc EvaluateLazy
if	0
		neg	ecx
		lea	edx, [2*(LazyThreshold+rcx+1)]
		add	eax, edx
else
		add	eax, 2*(LazyThreshold+1)
end if
		mov	ecx, dword[rbp+Pos.sideToMove]
		neg	ecx
		cdq			; divide eax by 2
		sub	eax, edx	;
		sar	eax, 1		;
		xor	eax, ecx
		sub	eax, ecx
		add	eax, Eval_Tempo
Display 2, "Info String OUTPUTEVAL1 = Lazy Eval returning %i0%n"
		mov	word[rbx+State.ltte+MainHashEntry.eval_], ax
		mov	word[rbx+State.ltte+MainHashEntry.value_], ax
		add	rsp, ((sizeof.EvalInfo+15) and (-16))
		pop	r15 r14 r13 r12 rdi rsi ;rbx
		ret

		calign   16
ShelterStormWhite:
ShelterStorm0:
	ShelterStorm White

		calign   16
ShelterStormBlack:
ShelterStorm1:
	ShelterStorm Black

		calign   64
Evaluate:
	; in  rbp address of Pos struct
	;     rbx address of State struct
	; out eax evaluation

;ProfileInc Evaluate
;new
virtual at rsp
 .ei EvalInfo
end virtual
		and	r15l, NOT JUMP_IMM_6
		push	rsi rdi r12 r13 r14 r15
		sub	rsp, ((sizeof.EvalInfo+15) and (-16))


		mov	esi, dword[rbx+State.materialIdx]
		test	esi, esi
		js	DoMaterialEval	;jnz	DoMaterialEval	; 0.87%
;.DoMaterialEvalReturn:
		lea	rsi, [materialTableExM+8*rsi]
		movsx	eax, word[rsi+MaterialEntryEx.value]
		movzx   ecx, byte[rsi+MaterialEntryEx.evaluationFunction]
.DoMaterialEvalReturn1:
		test	ecx, ecx
	;ProfileCond   nz, HaveSpecializedEval
		jnz	HaveSpecializedEval
		imul	eax, 0x00010001
		add	eax, dword[rbx+State.psq]
		add	eax, dword[ContemptScore]
		mov	dword[.ei.score], eax
		mov	qword[.ei.me], rsi
		lea	rdi, [VoidPawn]
		mov	r15, qword[rbx+State.pawnKey]
		cmp	r15, qword[Zobrist_noPawns]
		je	.DoPawnEvalReturn0
		mov	rdi, r15
		and	edi, PAWN_HASH_ENTRY_COUNT-1
		imul	edi, sizeof.PawnEntry
		add	rdi, qword[rbp+Pos.pawnTable]
		mov	eax, dword[rdi+PawnEntry.score]
		cmp	r15, qword[rdi+PawnEntry.key]
	;ProfileCond   ne, DoPawnEval
		jne	Evaluate_Cold.DoPawnEval	 ; 6.34%	;r14, r15 clobered
;        prefetchnta	[rdi] ;>>> recomended
.DoPawnEvalReturn:
		add	eax, dword[.ei.score]
		mov	dword[.ei.score], eax
.DoPawnEvalReturn0:
		mov	qword[.ei.pi], rdi


	; We have taken into account all cheap evaluation terms.
	; If score exceeds a threshold return a lazy evaluation.
	;  lazy eval is called about 5% of the time

	; checking if abs(a/2) > LazyThreshold
	; is the same as checking if a-2*(LazyThreshold+1)
	; is in the unsigned range [0,-4*(LazyThreshold+1)]
		
		lea	edx, [rax+0x08000]
		sar	edx, 16
		movsx	eax, ax
if	0
		movzx   ecx, word[rbx+State.npMaterial+2*0]
		add	cx, word[rbx+State.npMaterial+2*1]
		shr	ecx, 7
		neg	ecx
		lea	r9d, [4*rcx+1-4*(LazyThreshold+1)]
		lea	edx, [rdx+2*rcx-2*(LazyThreshold+1)]
		add	eax, edx
		cmp	eax, r9d
else
		lea	eax, [rax+rdx-2*(LazyThreshold+1)]
		cmp	eax, 1-4*(LazyThreshold+1)
end if
		jb	Evaluate_Cold.ReturnLazyEval

		mov	r14, qword[rbp+Pos.typeBB+8*White]
		mov	r15, qword[rbp+Pos.typeBB+8*Black]

		movzx   r8d, byte[rbp+Pos.pieceList+16*(8*White+King)]
		movzx   r9d, byte[rbp+Pos.pieceList+16*(8*Black+King)]

		mov	r12, qword[KingAttacks+8*r8]
		mov	r13, qword[KingAttacks+8*r9]

		mov	qword[.ei.attackedBy+8*(8*White+King)], r12
		mov	qword[.ei.attackedBy+8*(8*Black+King)], r13


		EvalInit   White
		EvalInit   Black

	; set all pieces
		lea	rax,  [r14+r15]
		mov	rdx,  rax
		
		ShiftBB   DELTA_S, rax
		ShiftBB   DELTA_N, rdx
;
		mov	r8, Rank2BB+Rank3BB
		mov	r9, Rank7BB+Rank6BB
;
		or	rax, r8
		or	rdx, r9
		mov	r11, qword[rbp+Pos.typeBB+8*Pawn]	;used in initiative
		mov	rcx, qword[rbp+Pos.typeBB+8*Queen]
		or	rcx, qword[rbp+Pos.typeBB+8*King]
		mov	r8, qword[rdi+PawnEntry.pawnAttacks+8*Black]	;qword[.ei.attackedBy+8*(8*Black+Pawn)]
		mov	r9, qword[rdi+PawnEntry.pawnAttacks+8*White]	;qword[.ei.attackedBy+8*(8*White+Pawn)]
		and	rax, r11
		and	rdx, r11
		or	rax, rcx
		or	rdx, rcx
		and	rax, r14
		and	rdx, r15

		or	rax, r8
		or	rdx, r9
		not	rax
		not	rdx
		mov	qword[.ei.mobilityArea+8*White], rax
		mov	qword[.ei.mobilityArea+8*Black], rdx
		or	r12, r9
		or	r13, r8

	; EvalPieces adds to esi
		mov   esi, dword[.ei.score]

		EvalPieces   White, Knight
		EvalPieces   Black, Knight
		EvalPieces   White, Bishop
		EvalPieces   Black, Bishop
		EvalPieces   White, Rook
		EvalPieces   Black, Rook
		EvalPieces   White, Queen
		EvalPieces   Black, Queen

.eimobility	equ (.ei.attackedBy+8*Pawn)
		add	esi, dword[.eimobility]
		mov	dword[.ei.score], esi
if QueenThreats = 100
;		cmp	byte[rbx+State.pliesFromNull],14
;		jg	.didntcheck
		EvalQueenThreats   Black, .JUMPINGEXIT, .NormalEnd, .JUMPINGEXIT2
	.NormalEnd:
		EvalQueenThreats   White, .JUMPINGEXIT, .NormalEnd2, .JUMPINGEXIT2
	.NormalEnd2:
		mov	r11, qword[rbp+Pos.typeBB+8*Pawn]	; clobbered
		mov	esi, dword[.ei.score]			; clobbered
		mov	rdi, qword[.ei.pi]			; clobbered
;.didntcheck:
end if

		;stored
;		mov	qword[.ei.attackedBy+8*(8*White+0)], r12
;		mov	qword[.ei.attackedBy+8*(8*Black+0)], r13

	; EvalKing adds to dword[.ei.score]
;				movsx	eax, si
;				Display 0, "info string eval::piece (value of eval)=%i0%n"
		EvalKing   Black
		EvalKing   White
;				movsx	eax, si
;				Display 0, "info string eval::king (value of eval)=%i0%n"

	; EvalPassedPawns adds to dword[.ei.score]
		mov	r9, qword[rdi+PawnEntry.passedPawns+8*White]
		test	r9, r9
		jnz	Evaluate_Cold2.EvalPassedPawns0
		mov	r9, qword[rdi+PawnEntry.passedPawns+8*Black]
		test	r9, r9
		jnz	Evaluate_Cold2.EvalPassedPawns1
.EvalPassedPawnsRet:
		mov	esi, dword[.ei.score]

	; EvalThreats, EvalSpace add to esi
	; EvalPassedPawns and EvalThreats are switched because
	;    EvalThreats and EvalSpace share r10-r15
	EvalThreats	Black
	EvalThreats	White
;				movsx	eax, si
;				Display 0, "info string eval::threat (value of eval)=%i0%n"

		movzx   r9d, word[rbx+State.npMaterial+2*0]
		movzx   ecx, word[rbx+State.npMaterial+2*1]
		add	r9d, ecx				;used in initiative
		cmp	r9d, 12222
		jb	.SkipSpace
		EvalSpace   Black
		EvalSpace   White
;				Display 2, "info string eval::space (value of eval)=%i0%n"

.SkipSpace:

		mov	r14, rdi
		mov	r15, qword[.ei.me]

	; Evaluate position potential for the winning side

		mov	r8, QueenSide
		mov	rcx, KingSide
		and	r8, r11
		and	rcx, r11
		mov	eax, 16
		neg	r8
		sbb	r8, r8
		and	r8, rcx
		cmovnz	r8d, eax

		_popcnt   rax, r11,	rcx
		movzx   edx, byte[rdi+PawnEntry.asymmetry]
		lea	edx, [rdx+rax-17]
		lea	r8d, [r8+4*rax]
		lea	r8d, [r8+8*rdx]
;12xpawn.count+8xPawn.asym-136
		cmp	r9d, 1
		sbb	r9d, r9d
		and	r9d, 48
		add	r8d, r9d
		;lea	r8d,[r8+r9]
;
		movsx   r9d, si
		sar	r9d, 31
		movsx   edi, si
		sub	esi, r9d
		xor	edi, r9d
		sub	edi, r9d
		neg	edi

		movzx   eax, byte[rbp+Pos.pieceList+16*(8*White+King)]
		movzx   ecx, byte[rbp+Pos.pieceList+16*(8*Black+King)]
		and	eax, 0111000b
		and	ecx, 0111000b
		sub	eax, ecx
		cdq
		xor	eax, edx
		sub	eax, edx
		sub	r8d, eax

		movzx   eax, byte[rbp+Pos.pieceList+16*(8*White+King)]
		movzx   ecx, byte[rbp+Pos.pieceList+16*(8*Black+King)]
		and	eax, 7
		and	ecx, 7
		sub	eax, ecx
		cdq
		xor	eax, edx
		sub	eax, edx
		lea	eax, [r8+8*rax]
        ; eax = initiative
;    int v = ((eg > 0) - (eg < 0)) * std::max(complexity, -abs(eg));

		cmp	eax, edi
		cmovl	eax, edi
		test	edi, edi
		cmovz	r9d, eax
		xor	eax, r9d
		add	esi, eax

	; esi = score
	; r14 = ei.pi
	; Evaluate scale factor for the winning side

		movsx	r12d, si
		lea	r13d, [r12-1]
		shr	r13d, 31

		movzx   ecx, byte[r15+MaterialEntryEx.scalingFunction+r13]
		movzx   eax, byte[r15+MaterialEntryEx.factor+r13]
		movzx   edx, byte[r15+MaterialEntryEx.gamePhase]
		add	esi, 0x08000
		sar	esi, 16
		test	ecx, ecx
		; r11 = Pawn / qword[rbp+Pos.typeBB+8*Pawn]
		jnz	Evaluate_Cold2.HaveScaleFunction		; 1.98%
.HaveScaleFunctionReturn:
		cmp	eax, SCALE_FACTOR_BISHOP
		jne	.ScaleFactorDone
		movzx   eax, byte[r14+PawnEntry.asymmetry]
		lea	eax, [4*rax+8]
.ScaleFactorDone:
	; eax = scale factor
	; edx = phase
	; esi = mg_score(score)
	; r12d = eg_value(score)
	; adjust score for side to move

  ;// Interpolate between a middlegame and a (scaled by 'sf') endgame score
  ;Value v =  mg_value(score) * int(ei.me->game_phase())
  ;         + eg_value(score) * int(PHASE_MIDGAME - ei.me->game_phase()) * sf / SCALE_FACTOR_NORMAL;
  ;v /= int(PHASE_MIDGAME);
		Display 2, "info string scale factor =%i0 value(mg)=%i6 (eg)=%i12 %n"

		mov	ecx, dword[rbp+Pos.sideToMove]
		mov	edi, 128	;PHASE_MIDGAME
		sub	edi, edx
		imul	edi, r12d
		imul	edi, eax
		lea	eax, [rdi+3FH]
		test	edi, edi
		cmovs	edi, eax
		imul	esi, edx
		sar	edi, 6		;/SCALE_FACTOR_NORMAL = /64
		lea	edx, [rdi+rsi]
		lea	eax, [rdx+7FH]
		test	edx, edx
		cmovs	edx, eax
		mov	eax, ecx
		neg	eax
		sar	edx, 7		;/PHASE_MIDGAME = /128
		xor	edx, eax
		lea	eax, [rcx+rdx+Eval_Tempo]
	Display 2, "Info String OUTPUTEVAL2 = Evaluate returning rax=%i0 rcx=%i1 rdx=%i2%n"
		mov	word[rbx+State.ltte+MainHashEntry.eval_], ax
		mov	word[rbx+State.ltte+MainHashEntry.value_], ax
if	0
		cmp	byte[rbx+State.rule50],50
		jle	@1f
		mov	cl, 114
		sub	cl, byte[rbx+State.rule50]
		movsx	ecx,cl
		mov	edx, eax
		imul	edx, ecx
		sar	edx, 6
		mov	word[rbx+State.ltte+MainHashEntry.value_], dx
		mov	qword[rsp+((sizeof.EvalInfo+15) and (-16))+4*8], rdx
@1:
end if
		add	rsp, ((sizeof.EvalInfo+15) and (-16))
		pop	r15 r14 r13 r12 rdi rsi ;rbx
		ret
if QueenThreats > 1
	calign 8
.JUMPINGEXIT:
		; rsi = NOT bbQueenAttacker
		; r10d = sq target/ to
		xor	rsi, qword[rbx+State.Occupied]
		bsf	rcx, rsi
		shl	ecx, 6
		or	ecx, r10d
		mov	eax, VALUE_MATE-1
		mov	rdx, 0x7CFF7CFF00000007
		mov	qword[rbx+State.ltte], rdx
		mov	word[rbx+State.ltte+MainHashEntry.move], cx
		mov	edx, eax
		movzx	ecx, byte[rbx+State.ply]
		sub	edx, ecx
		add	rsp, ((sizeof.EvalInfo+15) and (-16))
	Display 2, "Info String OUTPUTEVAL3 (MateThreat) = Evaluate returning rax=%i0 rcx=%i1 rdx=%i2%n"
		pop	r15 r14 r13 r12 rdi rsi
		mov	edi, edx
		ret
	calign 8
.JUMPINGEXIT2:
		;when oppside hash threat
		mov	eax, VALUE_MATE_THREAT
		mov	dword[rbx+State.ltte+MainHashEntry.eval_], ((VALUE_MATE_THREAT+1) shl 16) + VALUE_MATE_THREAT
		add	rsp, ((sizeof.EvalInfo+15) and (-16))
	Display 2, "Info String OUTPUTEVAL3 (MateThreat) = Evaluate returning rax=%i0 rcx=%i1 rdx=%i2%n"
		pop	r15 r14 r13 r12 rdi rsi
		mov	edi, eax
		ret
end if

	calign 8
Evaluate_Cold2:
virtual at rsp
 .ei EvalInfo
end virtual
.HaveScaleFunction:
		mov	eax, ecx
		shr	eax, 1
		mov	eax, dword[EndgameScale_FxnTable+4*rax]
		and	ecx, 1
		call	rax
	Display 2, "Scale returned %i0%n"
		cmp	eax, SCALE_FACTOR_NONE
		movzx	edx, byte[r15+MaterialEntryEx.gamePhase]
		movzx	ecx, byte[r15+MaterialEntryEx.factor+r13]
		cmove	eax, ecx
		jmp	Evaluate.HaveScaleFunctionReturn
	calign   16
.EvalPassedPawns0:
		EvalPassedPawns   White
		mov	r9, qword[rdi+PawnEntry.passedPawns+8*Black]
		test	r9, r9
		jz	Evaluate.EvalPassedPawnsRet
	calign	8
.EvalPassedPawns1:
		EvalPassedPawns	Black
		jmp	Evaluate.EvalPassedPawnsRet
	calign 8
HaveSpecializedEval:
		mov	eax, ecx
		shr	eax, 1
		mov	eax, dword[EndgameEval_FxnTable+4*rax]
		and	ecx, 1
		call	rax
		add	eax, Eval_Tempo
		Display 2, "Info String OUTPUTEVAL4 = Special Eval returned %i0%n"
		mov	word[rbx+State.ltte+MainHashEntry.eval_], ax
		mov	word[rbx+State.ltte+MainHashEntry.value_], ax
if	0
		cmp	byte[rbx+State.rule50],50
		jle	@1f
		mov	cl, 114
		sub	cl, byte[rbx+State.rule50]
		movsx	ecx,cl
		mov	edx, eax
		imul	edx, ecx
		sar	edx, 6
		mov	word[rbx+State.ltte+MainHashEntry.value_], dx
		mov	qword[rsp+((sizeof.EvalInfo+15) and (-16))+4*8], rdx
@1:
end if
		add	rsp, ((sizeof.EvalInfo+15) and (-16))
		pop	r15 r14 r13 r12 rdi rsi
		ret
	calign 8
DoMaterialEval:
		mov	r12, rsi
		and	esi, MATERIAL_HASH_ENTRY_COUNT-1
		shl	esi, 4
		mov	eax, dword[rbp+Pos.pieceEnd+Knight]	;white
		mov	edx, dword[rbp+Pos.pieceEnd+8+Knight]	;black
		add	rsi, qword[rbp+Pos.materialTable]
		cmp	edx, dword[rsi+MaterialEntry.key]
		jne	@f	;.Continuecount
		cmp	eax, dword[rsi+MaterialEntry.key+4]
		jne	@f
		movsx   eax, word[rsi+MaterialEntry.value]
		movzx   ecx, byte[rsi+MaterialEntry.evaluationFunction]
		lea	rsi, [rsi+8]	;convert struct from MaterialEntry to MaterialEntryEx
		Display 2, "info string info::out from EvalCustom 1st eax=%i0 ecx=%i1%n"
		jmp	Evaluate.DoMaterialEvalReturn1
@@:
;	calign 8
;.Continuecount:
		sub	rsp, 8*16

	; in: rsi address of MaterialEntry
	;     rbp address of position
	;     rbx address of state
	;     rsp address of EvalInfo
	; out:       return is .DoMaterialEvalReturn
	;     eax  sign_ext(word[rsi+MaterialEntry.value])
	;     ecx  zero_ext(byte[rsi+MaterialEntry.evaluationFunction])
		movzx	r14d, word[rbx+State.npMaterial+2*0]
		movzx	r15d, word[rbx+State.npMaterial+2*1]
		mov	dword[rsi+MaterialEntry.key], edx
		mov	dword[rsi+MaterialEntry.key+4], eax
.Try_KXK_White:
		mov	r8, qword[rbp+Pos.typeBB+8*Black]
		mov	r9, qword[rbp+Pos.typeBB+8*White]
		mov	ecx, 2*EndgameEval_KXK_index
		_blsr	r10, r8
		jnz	.Try_KXK_Black
		cmp	r14d, RookValueMg
		jge	@f	;.FoundEvalFxn
.Try_KXK_Black:
		_blsr	r10, r9
		jnz	.Continue	;.Try_KXK_Done
		cmp	r15d, RookValueMg
		jl	.Continue
		inc	ecx
@@:	;.FoundEvalFxn:
		xor	eax, eax	; obey out condtions
		mov	byte[rsi+MaterialEntry.evaluationFunction], cl
		add	rsi, 8		;convert struct from MaterialEntry to MaterialEntryEx
		add	rsp, 8*16
		Display 2, "info string info::out from EvalCustom 2nd eax=%i0 ecx=%i1%n"
		jmp	Evaluate.DoMaterialEvalReturn1
	calign 8
.Continue:
		movzx	r11d, byte[rbp+Pos.pieceEnd+0+Pawn]
		movzx	r12d, byte[rbp+Pos.pieceEnd+8+Pawn]
		and	eax, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)
		and	edx, (15 shl 24) or (15 shl 16) or (15 shl 8) or (15)

		movzx	ecx, ah		;bishop
		movzx	r8d, al		;Knight
		cmp	ah, 2
		sbb	edi, edi
		inc	edi
		shr	eax, 16
		movzx	r10d, al	;Rook
		movzx	eax, ah		;Queen
		and	r11d, 15
		mov	dword[rsp+4*(0+1)], edi		    ; bishop pair
		mov	dword[rsp+4*(0+Pawn)], r11d
		mov	dword[rsp+4*(0+Knight)], r8d
		mov	dword[rsp+4*(0+Bishop)], ecx
		mov	dword[rsp+4*(0+Rook)], r10d
		mov	dword[rsp+4*(0+Queen)], eax

		movzx	ecx, dh		;bishop
		movzx	r9d, dl		;Knight
		cmp	dh, 2
		sbb	edi, edi
		inc	edi
		shr	edx, 16
		movzx	r10d, dl	;Rook
		movzx	eax, dh		;Queen
		and	r12d, 15
		mov	dword[rsp+4*(8+1)], edi		    ; bishop pair
		mov	dword[rsp+4*(8+Pawn)], r12d
		mov	dword[rsp+4*(8+Knight)], r9d
		mov	dword[rsp+4*(8+Bishop)], ecx
		mov	dword[rsp+4*(8+Rook)], r10d
		mov	dword[rsp+4*(8+Queen)], eax

		mov	edx, ((SCALE_FACTOR_NORMAL shl 8) or (SCALE_FACTOR_NORMAL shl 0))	;init
		test	r11d, r11d		;White Pawn
		jnz	.P1
		mov	ecx, r14d
		sub	ecx, r15d
		cmp	ecx, BishopValueMg
		jg	.P1
		mov	eax, 14
		mov	ecx, 4
		cmp	r15d, BishopValueMg
		cmovle	eax, ecx
		mov	ecx, SCALE_FACTOR_DRAW
		cmp	r14d, RookValueMg
		cmovl	eax, ecx
		mov	dl, al	;byte[rsi+MaterialEntry.factor+1*White], al
.P1:
		test	r12d, r12d		;Black Pawn
		jnz	.P2
		mov	ecx, r15d
		sub	ecx, r14d
		cmp	ecx, BishopValueMg
		jg	.P2
		mov	eax, 14
		mov	ecx, 4
		cmp	r14d, BishopValueMg
		cmovle	eax, ecx
		mov	ecx, SCALE_FACTOR_DRAW
		cmp	r15d, RookValueMg
		cmovl	eax, ecx
		mov	dh, al	;byte[rsi+MaterialEntry.factor+1*Black], al
.P2:
;=============
		mov	ecx, 7
		mov	r8d, dword[rsp+4*(White+Bishop)]
		cmp	r8d, dword[rsp+4*(Black+Bishop)]
		jne	@f
		cmp	r8d,1
		jne	@f
		movzx	r8, byte[rbp+Pos.pieceList+16*(8*White+Bishop)]
		xor	r8l, byte[rbp+Pos.pieceList+16*(8*Black+Bishop)]
		mov	r9, r8
		shr	r8, 3
		xor	r8, r9
		and	r8, 0x1
		jz	@f
		mov	r9d, dword[rbx+State.npMaterial]
		cmp	r9d, (BishopValueMg shl 16) + BishopValueMg
		je	.Scale_Factor_Bishop	;.ScaleFactorDone0
		mov	ecx, 2
@@:
		mov	eax, ecx
		cmp	dl, SCALE_FACTOR_NORMAL	;byte[rsi+MaterialEntry.factor+1*White], SCALE_FACTOR_NORMAL
		jne	@f
		imul	ecx, r11d	;dword[rsp+4*(8*White+Pawn)]
		add	ecx, 40
		cmp	ecx, SCALE_FACTOR_NORMAL
		jge	@f
		mov	dl, cl	;byte[rsi+MaterialEntry.factor+1*White], cl
@@:
		cmp	dh, SCALE_FACTOR_NORMAL	;byte[rsi+MaterialEntry.factor+1*Black], SCALE_FACTOR_NORMAL
		jne	.ScaleFactorDone0
		imul	eax, r12d	;dword[rsp+4*(8*Black+Pawn)]
		add	eax, 40
		cmp	eax, SCALE_FACTOR_NORMAL
		jge	.ScaleFactorDone0
		mov	dh, al	;byte[rsi+MaterialEntry.factor+1*Black], al
		jmp	.ScaleFactorDone0
	calign	8
.Scale_Factor_Bishop:
		cmp	dl, SCALE_FACTOR_NORMAL	;byte[rsi+MaterialEntry.factor+1*White], SCALE_FACTOR_NORMAL
		jne	.not_normal
		mov	dl, SCALE_FACTOR_BISHOP	;byte[rsi+MaterialEntry.factor+1*White], SCALE_FACTOR_BISHOP
.not_normal:
		cmp	dh, SCALE_FACTOR_NORMAL	;byte[rsi+MaterialEntry.factor+1*Black], SCALE_FACTOR_NORMAL
		jne	.ScaleFactorDone0
		mov	dh, SCALE_FACTOR_BISHOP	;byte[rsi+MaterialEntry.factor+1*Black], SCALE_FACTOR_BISHOP
.ScaleFactorDone0:
		
		mov	dword[rsi+MaterialEntry.factor+1*White], edx	;v
		lea	eax, [r14+r15]
		xor	edx, edx
		mov	ecx, MidgameLimit - EndgameLimit
		sub	eax, EndgameLimit
		cmovs	eax, edx
		cmp	eax, ecx
		cmovae	eax, ecx
		shl	eax, 7
		div	ecx
		mov	byte[rsi+MaterialEntry.gamePhase], al

		lea	r8, [rsp+4*0]	;  pieceCount[Us]
		lea	r9, [rsp+4*8]	;  pieceCount[Them]

		xor	eax, eax
		xor	r15d, r15d
.ColorLoop:
		xor	r10d, r10d	; partial index into quadatic
		mov	r14d, 1
 .Piece1Loop:
		xor	r11d, r11d
		mov	r13d, 1

		cmp	dword[r8+4*r14], r11d
		je	.SkipPiece
  .Piece2Loop:
		mov	ecx, dword[DoMaterialEval_Data.QuadraticOurs+r10+4*r13]
		mov	edx, dword[DoMaterialEval_Data.QuadraticTheirs+r10+4*r13]
		imul	ecx, dword[r8+4*r13]
		imul	edx, dword[r9+4*r13]
		add	r11d, ecx
		add	r11d, edx
		inc	r13
		cmp	r13d, r14d
		jbe	.Piece2Loop

		lea	edx, [2*r15-1]
		imul	edx, dword[r8+4*r14]
		imul	r11d, edx
		sub	eax, r11d
.SkipPiece:
		inc	r14
		add	r10d, 8*4
		cmp	r14d, Queen
		jbe	.Piece1Loop

		xchg	r8, r9
		inc	r15
		cmp	r15d, 2
		jb	.ColorLoop

	; divide by 16, round towards zero
		cdq
		and	edx, 15
		add	eax, edx
		sar	eax, 4

		mov	word[rsi+MaterialEntry.value], ax
		movzx   ecx, byte[rsi+MaterialEntry.evaluationFunction]
		;mov	edx, dword[rsp+4*(8+Queen)]

		add	rsi, 8		;convert struct from MaterialEntry to MaterialEntryEx
		add	rsp, 8*16
		Display 2, "info string info::out from EvalCustom 3rd eax=%i0 ecx=%i1 edx =%i2 %n"
		jmp	Evaluate.DoMaterialEvalReturn1
restore MinorBehindPawn
restore BishopPawns
restore RookOnPawn
restore TrappedRook
restore WeakQueen
restore CloseEnemies
restore PawnlessFlank
restore ThreatByRank
restore Hanging
restore ThreatByPawnPush
restore LazyThreshold
