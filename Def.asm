if VERSION_OS = 'W'
  SEP_CHAR = ';'
else
  SEP_CHAR = ':'
end if

; MAX_RESETCNT should NOT be more than the number of times search is called per second/core,
; which is about half of nps/core (the other half comes from qsearch). Higher setting are 
; dangerous but lower settings lead to increased polling of the time
; MIN_RESETCNT should be fairly low, not more than 50, say.
; official sf polls the timer every 4096 calls, which is much too often
MAX_RESETCNT = 100000
MIN_RESETCNT = 40

; if USE_CURRMOVE, don't print current move info before this number of ms
CURRMOVE_MIN_TIME = 3000

; some bounds
MAX_MOVES = 224	; maximum number of pseudo legal moves for any position
AVG_MOVES = 96	; safe average number of moves per position, used for memory allocation
MAX_THREADS = 256
MAX_NUMANODES = 32
MAX_LINUXCPUS = 512			; should be a multiple of 64
MAX_HASH_LOG2MB = 16			; max hash size is (2^MAX_HASH_LOG2MB) MiB
THREAD_STACK_SIZE = 1048576
PAWN_HASH_ENTRY_COUNT = 16384 	; should be a power of 2
MATERIAL_HASH_ENTRY_COUNT = 8192	; should be a power of 2




FILE_H = 7
FILE_G = 6
FILE_F = 5
FILE_E = 4
FILE_D = 3
FILE_C = 2
FILE_B = 1
FILE_A = 0

repeat 8, i:1
  RANK_#i = i-1
  SQ_A#i = (0+8*(i-1))
  SQ_B#i = (1+8*(i-1))
  SQ_C#i = (2+8*(i-1))
  SQ_D#i = (3+8*(i-1))
  SQ_E#i = (4+8*(i-1))
  SQ_F#i = (5+8*(i-1))
  SQ_G#i = (6+8*(i-1))
  SQ_H#i = (7+8*(i-1))
end repeat

; some bitboards
DarkSquares  = 0xAA55AA55AA55AA55
LightSquares = 0x55AA55AA55AA55AA
AllSquares   = 0xFFFFFFFFFFFFFFFF
FileABB   = 0x0101010101010101
FileBBB   = 0x0202020202020202
FileCBB   = 0x0404040404040404
FileDBB   = 0x0808080808080808
FileEBB   = 0x1010101010101010
FileFBB   = 0x2020202020202020
FileGBB   = 0x4040404040404040
FileHBB   = 0x8080808080808080
Rank8BB   = 0xFF00000000000000
Rank7BB   = 0x00FF000000000000
Rank6BB   = 0x0000FF0000000000
Rank5BB   = 0x000000FF00000000
Rank4BB   = 0x00000000FF000000
Rank3BB   = 0x0000000000FF0000
Rank2BB   = 0x000000000000FF00
Rank1BB   = 0x00000000000000FF

Rank2_3BB = 0x0000000000FFFF00
Rank7_6BB = 0x00FFFF0000000000

White  = 0
Black  = 1
Pawn   = 2	;0010
Knight = 3	;0011
Bishop = 4	;0100
Rook   = 5	;0101
Queen  = 6	;0110
King   = 7	;0111

ALL_PIECES     = 0
;QUEEN_DIAGONAL = 1
SLIDER_ON_QUEEN	= 1

; piece values

PawnValueMg   = 175	;171
KnightValueMg = 764
BishopValueMg = 815	;826
RookValueMg   = 1282
QueenValueMg  = 2500	;2526

PawnValueEg   = 240
KnightValueEg = 848
BishopValueEg = 905	;891
RookValueEg   = 1373
QueenValueEg  = 2670	;2646

MidgameLimit = 15258
EndgameLimit = 3915
BonusMargin	= PawnValueMg
; values for evaluation
Eval_Tempo = 20

; values from stats tables
ValueHigh	= 2147483647
HistoryStats_Max = 268435456
CmhDeadOffset    = 4*(8*64)*(16*64)	;in bytes
CounterMovePruneThreshold = 0

; depths for search
ONE_PLY = 1
MAX_PLY = 128
MAX_SYZYGY_PLY = 20
DEPTH_QS_CHECKS     =  0
DEPTH_QS_NO_CHECKS  = -1
DEPTH_QS_RECAPTURES = -5
DEPTH_NONE	    = -6

; values for evaluation
VALUE_ZERO	 = 0
VALUE_DRAW	 = 0
VALUE_KNOWN_WIN  = 10000
VALUE_MATE	 = 32000
VALUE_INFINITE   = 32001
VALUE_NONE	 = 32002
VALUE_MATE_IN_MAX_PLY  =  VALUE_MATE - 2 * MAX_PLY
VALUE_MATED_IN_MAX_PLY = -VALUE_MATE + 2 * MAX_PLY
VALUE_MATE_THREAT	 = -VALUE_MATE + 4 * MAX_PLY

PHASE_MIDGAME	 = 128

SCALE_FACTOR_DRAW    = 0
SCALE_FACTOR_ONEPAWN = 48
SCALE_FACTOR_NORMAL  = 64
SCALE_FACTOR_MAX     = 128
SCALE_FACTOR_NONE    = 255
SCALE_FACTOR_BISHOP   = 10101010b

; move types
MOVE_TYPE_NORMAL = 0
MOVE_TYPE_PROM   = 4
MOVE_TYPE_EPCAP  = 8
;1000b
MOVE_TYPE_CASTLE = 12
;1100b

JUMP_IMM_1 = 1
JUMP_IMM_2 = 2		;nulLmove
JUMP_IMM_3 = 4		;jum to IID search before evalstate
JUMP_IMM_4 = 8
JUMP_IMM_5 = 16
JUMP_IMM_6 = 32		;ttHit
JUMP_IMM_7 = 64
JUMP_IMM_8 = 128	;singular / zero moves / one or none bestmove

; special moves (should be <=0 as 32bit quantities)
MOVE_NONE    = 0
MOVE_NULL    = 65 + 0x0FFFFF000

; definitions for move gen macros
CAPTURES     = 0
QUIETS       = 1
QUIET_CHECKS = 2
EVASIONS     = 3
NON_EVASIONS = 4
LEGAL	     = 5
CAPTURES_CUSTOM = 6

DELTA_N =  8
DELTA_E =  1
DELTA_S = -8
DELTA_W = -1

DELTA_NN = 16
DELTA_NE = 9
DELTA_SE = -7
DELTA_SS = -16
DELTA_SW = -9
DELTA_NW = 7

; bounds           don't change
BOUND_NONE  = 0
BOUND_UPPER = 1
BOUND_LOWER = 2
BOUND_EXACT = 3

; endgame eval fxn indices  see Endgames_Int.asm for details

	EndgameEval_KPK_index	= 1  ; KP vs K
	EndgameEval_KNNK_index	= 2  ; KNN vs K
	EndgameEval_Draw_index	= 2	;insufficient
	EndgameEval_KBNK_index	= 3  ; KBN vs K
	EndgameEval_KRKP_index	= 4  ; KR vs KP
	EndgameEval_KRKB_index	= 5  ; KR vs KB
	EndgameEval_KRKN_index	= 6  ; KR vs KN
	EndgameEval_KQKP_index	= 7  ; KQ vs KP
	EndgameEval_KQKR_index	= 8  ; KQ vs KR
	EndgameEval_KNNKP_index	= 9  ; KQ vs KR
	EndgameEval_KXK_index	= 10 ; Generic mate lone king eval

	; endgame scale fxn indices  see Endgames_Int.asm for details
	EndgameScale_KNPK_index    = 1  ; KNP vs K
	EndgameScale_KNPKB_index   = 2  ; KNP vs KB
	EndgameScale_KRPKR_index   = 3  ; KRP vs KR
	EndgameScale_KRPKB_index   = 4  ; KRP vs KB
	EndgameScale_KBPKB_index   = 5  ; KBP vs KB
	EndgameScale_KBPKN_index   = 6  ; KBP vs KN
	EndgameScale_KBPPKB_index  = 7  ; KBPP vs KB
	EndgameScale_KRPPKRP_index = 8  ; KRPP vs KRP
	EndgameScale_KBPsK_index   = 10 ; KB and pawns vs K
	EndgameScale_KQKRPs_index  = 11 ; KQ vs KR and pawns
	EndgameScale_KPsK_index    = 12 ; K and pawns vs K
	EndgameScale_KPKP_index    = 13 ; KP vs KP
