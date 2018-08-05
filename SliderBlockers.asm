
; version with one less branch is slightly faster
;result = blocker
macro SliderBlockers result, sliders, s, pinners,\
		     pieces, pieces_color,\
		     b, snipers, t

local YesPinners, NoPinners, MoreThanOne

;	     Assert   e, result, 0, 'Assertion result=0 failed in slider_blockers'
;	     Assert   e, pinners, 0, 'Assertion pinners=0 failed in slider_blockers'

		mov	snipers, qword[rbx+State.checkSq]	; QxR
		mov	b, qword[rbx+State.checkSq+8]		; QxB
		and   snipers, qword[RookAttacksPDEP+8*s]
		and   b, qword[BishopAttacksPDEP+8*s]
		 or   snipers, b
		shl   s#d, 6+3
		lea   s, [BetweenBB+s]
		and   snipers, sliders
		 jz   NoPinners
YesPinners:
             _tzcnt   t, snipers
		mov   b, pieces
		and   b, qword[s+8*t]
		lea   t, [b-1]
	       test   t, b
		jnz   MoreThanOne
	      _blsi   t, snipers
		 or   result, b
		 and	b, pieces_color
		 cmovz   t, b
		 or   pinners, t
MoreThanOne:
	      _blsr   snipers, snipers, t
		jnz   YesPinners
NoPinners:
end macro


; version with one less branch is slightly faster
macro SliderBlockers2 result, sliders, s, pinners,\
		     pieces, pieces_color,\
		     b, snipers, t

local YesPinners, NoPinners, MoreThanOne

;	     Assert   e, result, 0, 'Assertion result=0 failed in slider_blockers'
;	     Assert   e, pinners, 0, 'Assertion pinners=0 failed in slider_blockers'
;blsi		mov   a, b
;		neg   a
;		and   a, b
;blsr		lea   t, [a-1]
;		and   a, t

		mov   snipers, qword[rbp+Pos.typeBB+8*Queen]
		mov   b, snipers
		 or   snipers, qword[rbp+Pos.typeBB+8*Rook]
		 or   b, qword[rbp+Pos.typeBB+8*Bishop]
		mov	qword[rbx+State.checkSq],snipers	; QxR
		mov	qword[rbx+State.checkSq+8],b		; QxB
		and   snipers, qword[RookAttacksPDEP+8*s]
		and   b, qword[BishopAttacksPDEP+8*s]
		 or   snipers, b
		shl   s#d, 6+3
		lea   s, [BetweenBB+s]
		and   snipers, sliders
		 jz   NoPinners
YesPinners:
             _tzcnt   t, snipers
		mov   b, pieces
		and   b, qword[s+8*t]
		lea   t, [b-1]
	       test   t, b
		jnz   MoreThanOne
	      _blsi   t, snipers
		 or   result, b
		 and	b, pieces_color
		 cmovz   t, b
		 or   pinners, t
MoreThanOne:
	      _blsr   snipers, snipers, t
		jnz   YesPinners
NoPinners:
end macro


; slightly slower version with both branches
;
;macro SliderBlockers result, sliders, s, pinners,\
;                     pieces, pieces_color,\
;                     b, snipers, snipersSq, t {
;
;local ..YesPinners, ..NoPinners, ..Skip
;
;             Assert   e, result, 0, 'Assertion result=0 failed in slider_blockers'
;             Assert   e, pinners, 0, 'Assertion pinners=0 failed in slider_blockers'
;
;                mov   snipers, qword[rbp+Pos.typeBB+8*Queen]
;                mov   b, snipers
;                 or   snipers, qword[rbp+Pos.typeBB+8*Rook]
;                and   snipers, qword[RookAttacksPDEP+8*s]
;                 or   b, qword[rbp+Pos.typeBB+8*Bishop]
;                and   b, qword[BishopAttacksPDEP+8*s]
;                 or   snipers, b
;                shl   s#d, 6+3
;                lea   s, [BetweenBB+s]
;                and   snipers, sliders
;                 jz   ..NoPinners
;..YesPinners:
;                bsf   snipersSq, snipers
;                mov   b, pieces
;                and   b, qword[s+8*snipersSq]
;                lea   t, [b-1]
;               test   t, b
;                jnz   ..Skip
;                 or   result, b
;               test   b, pieces_color
;                 jz   ..Skip
;                bts   pinners, snipersSq ; pinners should not be memory here else very slow
;..Skip:
;               blsr   snipers, snipers, t
;                jnz   ..YesPinners
;..NoPinners:
;}
