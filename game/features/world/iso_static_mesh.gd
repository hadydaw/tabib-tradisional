class_name IsoStaticMesh
extends Node2D
## Node yang menggambar satu mesh statis (1 draw call). Titik asal node = titik jangkar
## objek (kaki), yaitu titik urut Y-sort.

var mesh: ArrayMesh


func _draw() -> void:
	if mesh != null:
		draw_mesh(mesh, null)
