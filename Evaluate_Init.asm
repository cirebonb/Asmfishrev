
Evaluate_Init:
	       push  rbx rsi rdi


		lea   rsi, [.MobilityBonus_Knight]
		lea   rdi, [MobilityBonus_Knight]
		mov   ecx, 9
	  rep movsd
		lea   rsi, [.MobilityBonus_Bishop]
		lea   rdi, [MobilityBonus_Bishop]
		mov   ecx, 14
	  rep movsd
		lea   rsi, [.MobilityBonus_Rook]
		lea   rdi, [MobilityBonus_Rook]
		mov   ecx, 15
	  rep movsd
		lea   rsi, [.MobilityBonus_Queen]
		lea   rdi, [MobilityBonus_Queen]
		mov   ecx, 28
	  rep movsd

		lea   rsi, [.ShelterStrength]
		lea   rdi, [ShelterStrength]
		mov   ecx, 4*8*8
	  rep movsd
		lea   rsi, [.UnblockedStorm]
		lea   rdi, [UnblockedStorm]
		mov   ecx, 4*8*8
	  rep movsd
		lea   rsi, [.BlockedStorm]
		lea   rdi, [BlockedStorm]
		mov   ecx, 8
	  rep movsd

		lea   rdi, [Threat_Minor]
		lea   rsi, [.Threat_Minor]
		mov   ecx, 8
	  rep movsd
		lea   rsi, [.Threat_Minor]
		mov   ecx, 8
	  rep movsd
		lea   rdi, [Threat_Rook]
		lea   rsi, [.Threat_Rook]
		mov   ecx, 8
	  rep movsd
		lea   rsi, [.Threat_Rook]
		mov   ecx, 8
	  rep movsd

		lea   rsi, [.PassedRank]
		lea   rdi, [PassedRank]
		mov   ecx, 8
	  rep movsd
		lea   rsi, [.PassedFile]
		lea   rdi, [PassedFile]
		mov   ecx, 8
	  rep movsd

		lea   rsi, [.QuadraticOurs]
		lea   rdi, [DoMaterialEval_Data]
		mov   ecx, 8*(6+6)
	  rep movsd

                lea  rsi, [.RankFactor]
                lea  rdi, [RankFactor]
                mov  ecx, 8
          rep movsd

	    xor ecx,ecx
		mov dword[ContemptScore], ecx  ; akin to StockFish's: "Score Eval::Contempt = SCORE_ZERO;"

;  constexpr Bitboard KingFlank[FILE_NB] = { QueenSide ^ FileDBB, QueenSide, QueenSide, CenterFiles, CenterFiles, KingSide, KingSide, KingSide ^ FileEBB };

		lea	rdi, [KingFlank]
		mov	rax, QueenSide xor FileDBB
	      stosq
		mov	rax, QueenSide
	      stosq
	      stosq
		mov	rax, CenterFiles
	      stosq
	      stosq
		mov	rax, KingSide
	      stosq
	      stosq
		mov	rcx, FileEBB
		xor	rax, rcx
	      stosq

;                lea   rsi, [.QueenMinorsImbalance]
;                lea   rdi, [QueenMinorsImbalance]
;                mov   ecx, 16
;          rep movsd

		pop   rdi rsi rbx
		ret


             calign   4
.RankFactor:
 dd 0, 0, 0, 2, 7, 12, 19, 0

.MobilityBonus_Knight:
 dd (-75 shl 16) + (-76)
 dd (-57 shl 16) + (-54)
 dd (- 9 shl 16) + (-28)
 dd ( -2 shl 16) + (-10)
 dd (  6 shl 16) + (5)
 dd ( 14 shl 16) + (12)
 dd ( 22 shl 16) + (26)
 dd ( 29 shl 16) + (29)
 dd ( 36 shl 16) + (29)

.MobilityBonus_Bishop:
 dd (-48 shl 16) + (-59)
 dd (-20 shl 16) + (-23)
 dd (16 shl 16) + (-3)
 dd (26 shl 16) + (13)
 dd (38 shl 16) + (24)
 dd (51 shl 16) + (42)
 dd (55 shl 16) + (54)
 dd (63 shl 16) + (57)
 dd (63 shl 16) + (65)
 dd (68 shl 16) + (73)
 dd (81 shl 16) + (78)
 dd (81 shl 16) + (86)
 dd (91 shl 16) + (88)
 dd (98 shl 16) + (97)

.MobilityBonus_Rook:
 dd (-58 shl 16) + (-76)
 dd (-27 shl 16) + (-18)
 dd (-15 shl 16) + (28)
 dd (-10 shl 16) + (55)
 dd (-5 shl 16) + (69)
 dd (-2 shl 16) + (82)
 dd ( 9 shl 16) + (112)
 dd (16 shl 16) + (118)
 dd (30 shl 16) + (132)
 dd (29 shl 16) + (142)
 dd (32 shl 16) + (155)
 dd (38 shl 16) + (165)
 dd (46 shl 16) + (166)
 dd (48 shl 16) + (169)
 dd (58 shl 16) + (171)

.MobilityBonus_Queen:
 dd (-39 shl 16) + (-36)
 dd (-21 shl 16) + (-15)
 dd (3 shl 16) + (8)
 dd (3 shl 16) + (18)
 dd (14 shl 16) + (34)
 dd (22 shl 16) + (54)
 dd (28 shl 16) + (61)
 dd (41 shl 16) + (73)
 dd (43 shl 16) + (79)
 dd (48 shl 16) + (92)
 dd (56 shl 16) + (94)
 dd (60 shl 16) + (104)
 dd (60 shl 16) + (113)
 dd (66 shl 16) + (120)
 dd (67 shl 16) + (123)
 dd (70 shl 16) + (126)
 dd (71 shl 16) + (133)
 dd (73 shl 16) + (136)
 dd (79 shl 16) + (140)
 dd (88 shl 16) + (143)
 dd (88 shl 16) + (148)
 dd (99 shl 16) + (166)
 dd (102 shl 16) + (170)
 dd (102 shl 16) + (175)
 dd (106 shl 16) + (184)
 dd (109 shl 16) + (191)
 dd (113 shl 16) + (206)
 dd (116 shl 16) + (212)

.Doubled:
 dd (0 shl 16) + (0)
 dd (18 shl 16) + (38)
 dd (9 shl 16) + (19)
 dd (6 shl 16) + (12)
 dd (4 shl 16) + (9)
 dd (3 shl 16) + (7)
 dd (3 shl 16) + (6)
 dd (2 shl 16) + (5)


; ShelterWeakness and StormDanger are twice as big
; to avoid an anoying min(f,FILE_H-f) in ShelterStorm
.ShelterStrength:
		dd -6, 81, 93, 58, 39, 18,  25, 0
		dd -43, 61, 35, -49, -29, -11, -63, 0
		dd -10, 75, 23, -2, 32,  3, -45, 0
		dd -39, -13, -29, -52, -48, -67, -166, 0

		dd -39, -13, -29, -52, -48, -67, -166, 0
		dd -10, 75, 23, -2, 32,  3, -45, 0
		dd -43, 61, 35, -49, -29, -11, -63, 0
		dd -6, 81, 93, 58, 39, 18,  25, 0



.UnblockedStorm:
		dd 89, 107, 123, 93, 57, 45, 51, 0
		dd 44, -18, 123, 46, 39, -7, 23, 0
		dd  4, 52, 162, 37, 7, -14, -2, 0
		dd -10, -14, 90, 15, 2, -7, -16,  0

		dd -10, -14, 90, 15, 2, -7, -16,  0
		dd  4, 52, 162, 37, 7, -14, -2, 0
		dd 44, -18, 123, 46, 39, -7, 23, 0
		dd 89, 107, 123, 93, 57, 45, 51, 0


.BlockedStorm:
		dd 0, 0, 66, 6, 5, 1, 15,  0


;  constexpr Score ThreatByMinor[PIECE_TYPE_NB] = {
;    S(0, 0), S(0, 31), S(39, 42), S(57, 44), S(68, 112), S(62, 120)
;  };
;
;  constexpr Score ThreatByRook[PIECE_TYPE_NB] = {
;    S(0, 0), S(0, 24), S(38, 71), S(38, 61), S(0, 38), S(51, 38)
;  };



.Threat_Minor:
 dd (0 shl 16) + (0)
 dd (0 shl 16) + (0)
 dd (0 shl 16) + (31)		;(0 shl 16) + (33)
 dd (39 shl 16) + (42)		;(45 shl 16) + (43)
 dd (57 shl 16) + (44)		;(46 shl 16) + (47)
 dd (68 shl 16) + (112)		;(72 shl 16) + (107)
 dd (62 shl 16) + (120)		;(48 shl 16) + (118)
 dd (0 shl 16) + (0)

.Threat_Rook:
 dd (0 shl 16) + (0)
 dd (0 shl 16) + (0)
 dd (0 shl 16) + (24)		;(0 shl 16) + (25)
 dd (38 shl 16) + (71)		;(40 shl 16) + (62)
 dd (38 shl 16) + (61)		;(40 shl 16) + (59)
 dd (0 shl 16) + (38)		;(0 shl 16) + (34)
 dd (51 shl 16) + (38)		;(35 shl 16) + (48)
 dd (0 shl 16) + (0)



.PassedFile:
if 1
 dd (11 shl 16) + (14)		;(9 shl 16) + (10)
 dd (0 shl 16) + (-5)		;(2 shl 16) + (10)
 dd (-2 shl 16) + (-8)		;(1 shl 16) + (-8)
 dd (-25 shl 16) + (-13)	;(-20 shl 16) + (-12)
 dd (-25 shl 16) + (-13)	;(-20 shl 16) + (-12)
 dd (-2 shl 16) + (-8)		;(1 shl 16) + (-8)
 dd (0 shl 16) + (-5)		;(2 shl 16) + (10)
 dd (11 shl 16) + (14)		;(9 shl 16) + (10)
else
	dd	( -1 shl 16) + (7)
	dd	( 0 shl 16) + (9)
	dd	(-9 shl 16) + (-8)
	dd	(-30 shl 16) + (-14)
	dd	(-30 shl 16) + (-14)
	dd	(-9 shl 16) + (-8)
	dd	( 0 shl 16) + (9)
	dd	( -1 shl 16) + (7)
end if

.PassedRank:
if 1
 dd 0
 dd (4 shl 16) + (17)		;(5 shl 16) + (7)
 dd (7 shl 16) + (20)		;(5 shl 16) + (14)
 dd (14 shl 16) + (36)		;(31 shl 16) + (38)
 dd (42 shl 16) + (62)		;(73 shl 16) + (73)
 dd (165 shl 16) + (171)	;(166 shl 16) + (166)
 dd (279 shl 16) + (252)	;(252 shl 16) + (252)
 dd 0
else
	dd	(0)
	dd	(5 shl 16) + (18)
	dd	(12 shl 16) + (23)
	dd	(10 shl 16) + (31)
	dd	(57 shl 16) + (62)
	dd	(163 shl 16) + (167)
	dd	(271 shl 16) + (250)
	dd	(0)
end if

;.QueenMinorsImbalance:
;        dd 31, -8, -15, -25, -5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
if 1
.QuadraticOurs:
	dd 0, 1667,    0,    0,    0,	 0,    0,    0
	dd 0,	40,    0,    0,    0,	 0,    0,    0
	dd 0,	32,  255,   -3,    0,	 0,    0,    0
	dd 0,	 0,  104,    4,    0,	 0,    0,    0
	dd 0,  -26,   -2,   47,  105, -149,    0,    0
	dd 0, -185,   24,  122,  137, -134,    0,    0
.QuadraticTheirs:
	dd 0,	 0,    0,    0,    0,	 0,    0,    0
	dd 0,	36,    0,    0,    0,	 0,    0,    0
	dd 0,	 9,   63,    0,    0,	 0,    0,    0
	dd 0,	59,   65,   42,    0,	 0,    0,    0
	dd 0,	46,   39,   24,  -24,	 0,    0,    0
	dd 0,  101,  100,  -37,  141,  268,    0,    0
else
.QuadraticOurs:
	dd 0, 1438,    0,    0,    0,	 0,    0,    0
	dd 0,	40,   38,    0,    0,	 0,    0,    0
	dd 0,	32,  255,  -62,    0,	 0,    0,    0
	dd 0,	 0,  104,    4,    0,	 0,    0,    0
	dd 0,  -26,   -2,   47,  105, -208,    0,    0
	dd 0, -185,   24,  117,  133, -134,   -6,    0
.QuadraticTheirs:
	dd 0,	 0,    0,    0,    0,	 0,    0,    0
	dd 0,	36,    0,    0,    0,	 0,    0,    0
	dd 0,	 9,   63,    0,    0,	 0,    0,    0
	dd 0,	59,   65,   42,    0,	 0,    0,    0
	dd 0,	46,   39,   24,  -24,	 0,    0,    0
	dd 0,   97,  100,  -42,  137,  268,    0,    0

end if