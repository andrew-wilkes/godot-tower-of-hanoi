extends Spatial

var disc_scene = preload("res://Disc.tscn")
var discs = []
var stack_offset

func _ready():
	create_discs()
	build_stack(8)


func create_discs():
	for n in range(1, 9):
		var d: Disc = disc_scene.instance()
		d.set_radius(lerp(0.5, 1.0, (n - 1) / 7.0))
		var mat = load("res://materials/color" + str(n) + ".tres")
		d.set_mat(mat)
		discs.append(d)


func build_stack(n):
	peg_length = 8 * 0.25 + 0.5
	stack_offset = peg_length / 2
	$Pegs.translation.y = stack_offset + 0.1
	stack_offset -= 0.125
	for peg in $Pegs.get_children():
		peg.height = peg_length
	# discs[0] is the smallest disc
	for i in n:
		var d = discs[n - i - 1]
		d.translation.y = get_y_position_in_stack(i)
		$Pegs/Peg1.add_child(d)


func get_y_position_in_stack(disc_index): # 0 is the base, 1, 2, 3 ...
	return 0.25 * disc_index - stack_offset

var start_pos
var end_pos
var disc
var radius
var peg_length

func move_disc(from_peg, to_peg):
	# Get top-most disc
	var start_peg = $Pegs.get_child(from_peg)
	disc = start_peg.get_children()[-1]
	start_pos = disc.translation
	var end_peg = $Pegs.get_child(to_peg)
	end_pos = Vector2(end_peg.translation.x, get_y_position_in_stack(end_peg.get_child_count()))
	var tween = get_node("Tween")
	var _tweenBool = tween.interpolate_method(self, "set_disc_position", 0.0, PI, 5.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()


func set_disc_position(phi):
	var x
	var y = radius * sin(phi)
	if phi > 1.5 and y < end_pos.y:
			return
	if start_pos.x > end_pos.x:	
		x = -clamp(radius * cos(phi), end_pos.x, start_pos.x)
	else:
		x = clamp(radius * cos(phi), start_pos.x, end_pos.x)
	disc.translation = Vector2(x, y)
