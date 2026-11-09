class_name WorldLayout
extends RefCounted
## Tata letak dunia uji Fase 2 (placeholder). Dua lapisan teks dengan ukuran sama.
## Lantai: . rumput, d tanah, s batu, ~ air (tidak bisa dilewati)
## Objek : . kosong, T pohon, R batu, W dinding, C peti, @ titik mulai pemain
## Ini data uji, bukan desain dunia final.

const GROUND_ROWS: Array[String] = [
	"...........dd...........",
	"...........dd...........",
	"...........dd...........",
	"...........dd.....~~~...",
	"...........dd....~~~~~..",
	"...........dd....~~~~~..",
	"...........dd....~~~~~..",
	"...........dd.....~~~...",
	"...........dd...........",
	".........ssssss.........",
	".........ssssss.........",
	"dddddddddssssssddddddddd",
	"dddddddddssssssddddddddd",
	".........ssssss.........",
	".........ssssss.........",
	"..dddddd...dd...........",
	"..dddddd...dd...........",
	"..dddddd...dd...........",
	"..dddddd...dd...........",
	"..dddddd...dd...........",
	"...........dd...........",
	"...........dd...........",
	"...........dd...........",
	"...........dd...........",
]

const OBJECT_ROWS: Array[String] = [
	"T.T.T.T.T.T...T.T.T.T.TT",
	".....T..................",
	"T.T.............T.....TT",
	".....TT..T..............",
	"T......................T",
	".......T.TT.............",
	"T..T....TT.............T",
	"...T..TR.T.....T........",
	"T.......C......C.......T",
	".T.T....................",
	"TT.T..R................T",
	"........................",
	"............@......R....",
	"..................T.....",
	"T......................T",
	".T......C......R........",
	"T..WWWW.T.......R......T",
	"...W..W.................",
	"T..W.WW.........T......T",
	"..........T...R.........",
	"TT.T...................T",
	"........T.T..T..........",
	"T...............T..T...T",
	"T.T.T.T.T.T...T.T.T.T.T.",
]
