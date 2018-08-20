	     calign  16, SeeTestGe.HaveFromTo
SeeTestGe:
	; in: rbp address of Pos
	;     rbx address of State
	;     ecx capture move
	;     edx value
	;	r11	bool indirect check extended??
	; out: eax = 1 if  see >= edx
	;      eax = 0 if  see <  edx
	; r8,r9, r13, rcx not clobbered
from		equ r8
to		equ r9
stm		equ rsi
stm_d		equ esi
attackers	equ r15
occupied	equ r14
bb		equ rdi
bb_d		equ edi
stmAttackers	equ r12
swap		equ edx
res		equ eax
QxB		equ r10
QxR		equ r11

	; r8 = from
	; r9 = to
		mov	r8d, ecx
		shr	r8d, 6
		and	r8d, 63
		mov	r9d, ecx
		and	r9d, 63
.HaveFromTo:
		neg	swap
		xor	res, res

		test	ecx, 0xFFFFF000
		jnz	.Special

		movzx	r10d, byte[rbp+Pos.board+to]
		add	swap, dword[PieceValue_MG+4*r10]
		cmp	swap, res
		jl	.ReturnOnly	; 2.35%
		
		xor	res, 1   ; .res = 1
		neg	swap
		push	stm
		movzx	stm_d, byte[rbp+Pos.board+from]
		add	swap, dword[PieceSee_MG+4*stm]	; use piece_on(from)
		cmp	swap, res
		jl	.ReturnOnly0	; 13.63%	kingmoves filtered

		push	r12 r13 r14 r15 rdi		;r13 r14 r15 rsi rdi r8 & r9 stand pat
;.EpCaptureRet:
		and	stm_d, 8
	; r10 = bishops + queens
	; r11 = rooks + queens
		mov	QxB, qword[rbx+State.checkSq+8]	; QxB
		mov	QxR, qword[rbx+State.checkSq]	; QxR
		mov	occupied, qword[rbx+State.Occupied]
		btr	occupied, from
		btr	occupied, to
		;btc	occupied, to

	; at this point .from register r8 is free
	;  rdi, rcx are also free

		mov	attackers, qword[KingAttacks+8*to]
		and	attackers, qword[rbp+Pos.typeBB+8*King]
		mov	rdi, qword[BlackPawnAttacks+8*to]
		and	rdi, qword[rbp+Pos.typeBB+8*White]
		and	rdi, qword[rbp+Pos.typeBB+8*Pawn]
		or	attackers, rdi
		mov	rdi, qword[WhitePawnAttacks+8*to]
		and	rdi, qword[rbp+Pos.typeBB+8*Black]
		and	rdi, qword[rbp+Pos.typeBB+8*Pawn]
		or	attackers, rdi
		mov	rdi, qword[KnightAttacks+8*to]
		and	rdi, qword[rbp+Pos.typeBB+8*Knight]
		or	attackers, rdi
		
		xor	r13d, r13d
		bts	r13, from
		and	r13, qword[rbx+State.dcCandidates]
.Loop1st:
		RookAttacks   rdi, to, occupied, stmAttackers
		and	rdi, QxR
		or	attackers, rdi
.Loop2nd:
		BishopAttacks   rdi, to, occupied, stmAttackers
		and	rdi, QxB
		or	attackers, rdi
.Loop:	      ; while (1) {
		test	r13, r13
		jnz	.finalized
.Loop0:
		mov	r13, qword[rbx+State.blockersForKing+stm]	;set dcCandidate for opp?
		xor	stm_d, 8
		and	attackers, occupied

	; modified old
		mov	stmAttackers, qword[rbp+Pos.typeBB+stm]
		and	stmAttackers, attackers
		jz	.Return	; 44.45%
		test	stmAttackers, qword[rbx+State.blockersForKing+stm]	;for defender
		jnz	.Pinned
.afterloop:
		neg	swap
		xor	res, 1

		mov	bb, qword[rbp+Pos.typeBB+8*Pawn]
		and	bb, stmAttackers
		jnz	.FoundPawn

		mov	bb, qword[rbp+Pos.typeBB+8*Knight]
		and	bb, stmAttackers
		jnz	.FoundKnight

		mov	bb, qword[rbp+Pos.typeBB+8*Bishop]
		and	bb, stmAttackers
		jnz	.FoundBishop

		mov	bb, qword[rbp+Pos.typeBB+8*Rook]
		and	bb, stmAttackers
		jnz	.FoundRook

		mov	bb, qword[rbp+Pos.typeBB+8*Queen]
		and	bb, stmAttackers
		jnz	.FoundQueen

.FoundKing:
		xor	stm_d, 8
		mov	stmAttackers, qword[rbp+Pos.typeBB+stm]
		and	stmAttackers, attackers
	; .res has already been flipped so we must do
	;    return stmAttackers ? res^1 : res;
		neg	stmAttackers
		adc	res, 0
		and	res, 1
.Return:
		pop	rdi r15 r14 r13 r12
.ReturnOnly0:
		pop	rsi
.ReturnOnly:
		ret
		;below stmAttackers used for temp
.FoundQueen:
		add	swap, QueenValueMg
		cmp	swap, res
		jl	.Return
xor	r13d, r13d
		_blsi	bb, bb, stmAttackers
		xor	occupied, bb
		jmp	.Loop1st
.FoundRook:

		add	swap, RookValueMg
		cmp	swap, res
		jl	.Return
and	r13,bb
		_blsi	bb, bb, stmAttackers
		xor	occupied, bb
		RookAttacks	rdi, to, occupied, stmAttackers
		and	rdi, QxR
		or	attackers, rdi
		jmp	.Loop
	     calign   8
.FoundBishop:
		add	swap, BishopValueMg-PawnValueMg
.FoundPawn:
		add	swap, PawnValueMg
		cmp	swap, res
		jl	.Return2
and	r13,bb

		_blsi	bb, bb, stmAttackers
		xor	occupied, bb
		jmp	.Loop2nd
	     calign   8
.FoundKnight:
		add	swap, KnightValueMg
		cmp	swap, res
		 jl	.Return2
and	r13,bb

		_blsi	bb, bb, stmAttackers
		xor	occupied, bb
		jmp	.Loop
         calign  8
.Return2:
		pop	rdi r15 r14 r13 r12 rsi
		ret
         calign  8
.finalized:
		;240 =King Black 112=King white
		mov	r12d, stm_d
		xor	r12d, 8
		mov	rdi, qword[rbp+Pos.typeBB+8*King]
		and	rdi, qword[rbp+Pos.typeBB+r12]	;attacked king
		_tzcnt	r12, rdi
		
		shl	r12, 6+3
		test	r13, qword[LineBB+r12+8*to]	;move inline with king?
		jnz	.Loop0				;yes

		_tzcnt	r13, r13
		mov	r13, qword[LineBB+r12+8*r13]	;move from king
		and	r13, occupied
		mov	r12d, stm_d
		xor	r12d, 8
		and	r13, qword[rbx+State.pinnersForKing+r12]
		jz	.Loop0
		
		and	rdi, attackers			;oppking as attacker?
		jz	.Return2			;no

		and	attackers, occupied
		and	attackers, qword[rbp+Pos.typeBB+stm]	;is move protected?
		jnz	.Return2			;yes
		xor	res, 1				;otherwise no
		jmp	.Return2
	 calign  8
.Pinned:

		mov	rdi, qword[rbx+State.pinnersForKing+stm]
		and	rdi, occupied
		cmp	rdi, qword[rbx+State.pinnersForKing+stm]
		jne	.afterloop
		mov	rdi, qword[rbx+State.blockersForKing+stm]
		not	rdi
		and	stmAttackers, rdi
;		jz	.Return2	; 45.06%
		jnz	.afterloop
		pop	rdi r15 r14 r13 r12 rsi
		ret
         calign  8
.Special:
	; if we get here, swap = -value  and  res = 0
		cmp	swap, 0x80000000
		adc	res, res
		ret

restore from
restore to
restore stm
restore stm_d
restore attackers
restore occupied
restore bb
restore bb_d
restore stmAttackers
restore swap
restore res
restore QxB
restore QxR

