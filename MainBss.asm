; todo: see if the order/alignment of these variables affects performance
              align   16
Output 	  rb 4096  ; output buffer has static allocation
if DEBUG = 1
  DebugOutput rb 4096
end if

              align   16
ioBuffer        IOBuffer

if USE_WEAKNESS
              align   16
  weakness      Weakness
end if

if USE_BOOK
              align   16
  book          Book
end if

              align   16
options         Options
              align   16
time            Time
              align   16
signals         Signals
              align   16
limits          Limits
              align   16
mainHash        MainHash
              align   16
threadPool      ThreadPool


;;;;;;;;;;;; data for move generation  ;;;;;;;;;;;;;;;
              align   4096
if CPU_HAS_BMI2 = 0
  SlidingAttacksBB    rq 89524
else
  SlidingAttacksBB    rq 107648
end if
  BishopAttacksPEXT   rq 64     ; bitboards
  BishopAttacksMOFF   rd 64     ; addresses, only 32 bits needed
  BishopAttacksPDEP   rq 64     ; bitboards
  RookAttacksPEXT     rq 64     ; bitboards
  RookAttacksMOFF     rd 64     ; addresses, only 32 bits needed
  RookAttacksPDEP     rq 64     ; bitboards
if CPU_HAS_BMI2 = 0
  BishopAttacksIMUL   rq 64
  RookAttacksIMUL     rq 64
end if
PawnAttacks:
WhitePawnAttacks    rq 64     ; bitboards
BlackPawnAttacks    rq 64     ; bitboards
KnightAttacks       rq 64     ; bitboards
KingAttacks         rq 64     ; bitboards
TempBB:
KingRingA		rq 64

if USE_GAMECYCLE = 1
cuckoo			rq 8192
cuckooMove		rw 8192
end if

;;;;;;;;;;;;;;;;;;; bitboards ;;;;;;;;;;;;;;;;;;;;;
              align   4096
BetweenBB       rq 64*64
LineBB          rq 64*64
SquareDistance  rb 64*64
SquareDistance_Cap5  rb 64*64	;added
DistanceRingBB  rq 8*64
ForwardBB       rq 2*64
PawnAttackSpan  rq 2*64
PassedPawnMask  rq 2*64
AdjacentFilesBB rq 8
FileBB          rq 8
RankBB          rq 8
;;;;;;;;;;;;;;;;;;;; DoMove data ;;;;;;;;;;;;;;;;;;;;;;;;
              align   64
Scores_Pieces:	   rq 16*64
Zobrist_Pieces:    rq 16*64

Zobrist_Castling:  rq 16
Zobrist_Ep:	   rq 8
Zobrist_side:	   rq 1
Zobrist_noPawns:   rq 1
PieceValue_MG:	   rd 16
PieceValue_EG:	   rd 16
IsNotPawnMasks:    rb 16
IsPawnMasks:	   rb 16
;;;;;;;;;;;;;;;;;;;; data for search ;;;;;;;;;;;;;;;;;;;;;;;
              align   4096
Reductions	        rb 2*2*64*64
FutilityMoveCounts      rb 16*2
TableQsearch_NonPv	rq 4
TableQsearch_Pv		rq 4
PROMBB			rq 2
;;;;;;;;;;;;;;;;;;;; data for evaluation ;;;;;;;;;;;;;;;;;;;;
              align   64
Connected      rd 2*2*3*8
MobilityBonus_Knight rd 16
MobilityBonus_Bishop rd 16
MobilityBonus_Rook   rd 16
MobilityBonus_Queen  rd 32

ShelterStrength	rd 8*8
UnblockedStorm	rd 8*8
BlockedStorm	rd 8

KingFlank                  rq 8
Threat_Minor               rd 16
Threat_Rook                rd 16
PassedRank                 rd 8
PassedFile                 rd 8
DoMaterialEval_Data:
.QuadraticOurs:            rd 8*6
.QuadraticTheirs:          rd 8*6
;QueenMinorsImbalance       rd 16
RankFactor              rd 8		;added

ContemptScore              rd 1
Reserved                   rd 1 ; explicitly pad to 64-bit alignment. Can be used.
;rootKey			rq 1

;;;;;;;;;;;;;; data for endgames ;;;;;;;;;;;;;;
              align   64

	TableMaterialM		rq	16*64
	TablePromMatM		rq	2*2*16	;twice bigger
	
	CountNormalM		rd	8*16
	POC		rd 16
	EndgameEval_FxnTable       rd 10+1+1 ;+1 to give an even
	EndgameScale_FxnTable      rd 13+1
	VoidPawn		rb sizeof.PawnEntry
if	TRACE = 1 
Rootrbx	rq 1
end if
if QueenThreats > 0
Evade		rq 64*64
end if
		align 64

KPKEndgameTable            rq 48*64
PushToEdges                rb 64
PushToCorners              rw	64	;rb 64
PushClose                  rb 8
PushAway                   rb 8

if USE_SYZYGY
              align   4096
Tablebase_MaxCardinality   rd 1
Tablebase_Cardinality      rd 1
Tablebase_ProbeDepth       rd 1
Tablebase_Score            rd 1
Tablebase_RootInTB         rb 1    ; boole 0 or -1
Tablebase_UseRule50        rb 1    ; boole 0 or -1
                           rb 2
                           rd 11

_ZL7pfactor:
	rb    128

_ZL7pawnidx:
	rb    512

_ZL8binomial:
	rb    1280

_ZL9DTZ_table:
	rq    1

L_333:	rq    1

L_334:	rq    184

L_335:
	rb    24

L_336:
	rb    16

L_337:	rq    1

_ZL7TB_hash:
	rb    81920

_ZL7TB_pawn:
	rb    98304

_ZL8TB_piece:
	rb    30480

_ZL10TBnum_pawn:
	rd    1

_ZL11TBnum_piece:
	rd    1

; let n = num_paths
; the paths are stored in paths[0],...,path[n-1]
; the counts of found tbs are stored in paths[n],...,paths[2n-1]
_ZL5paths:
	rq    1

_ZL11path_string:
	rq    1

_ZL9num_paths:
	rd    1


_ZL11initialized:
	rb    4

tb_total_cnt:
        rd 1

align 16
_ZL8TB_mutex:
	rq    6
end if
		align 64

	materialTableExM	rb	MaterialTableSize*sizeof.MaterialEntryEx
