extends Spatial

var disc = preload("res://Disc.tscn")
var discs = []

func _ready():
	create_discs()
	build_stack(8)


func create_discs():
	for n in range(1, 9):
		var d: Disc = disc.instance()
		d.set_radius(lerp(0.5, 1.0, (n - 1) / 7.0))
		var mat = load("res://materials/color" + str(n) + ".tres")
		d.set_mat(mat)
		discs.append(d)


func build_stack(n):
	var peg_length = n * 0.25 + 1
	$Pegs.translation.y = peg_length / 2 - 0.5
	for peg in $Pegs.get_children():
		peg.height = peg_length
	for i in n:
		var d = discs[i]
		d.translation.y = n * 0.125 - 0.25 * i
		$Pegs/Peg1.add_child(d)
