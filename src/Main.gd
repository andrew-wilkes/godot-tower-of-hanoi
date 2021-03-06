extends Spatial

signal move_completed

enum { SRC, AUX, DEST }

var disc_scene = preload("res://Disc.tscn")
var discs = []
var stack_offset
var move_number = 0
var moves = []
var restart = false
var completed = false
var start_pos
var end_pos
var disc
var peg_length

func _ready():
	create_discs()
	var _e = connect("move_completed", self, "make_move")
	start()


func start():
	var num_discs = $UI/HBox/NumDiscs.value
	clear_stack()
	build_stack(num_discs)
	moves.clear()
	completed = false
	hanoi(num_discs, SRC, DEST, AUX)
	move_number = 0
	make_move()


func hanoi(n, src, dest, aux):
	if n == 0: return
	hanoi(n - 1, src, aux, dest)
	moves.append([src, dest])
	hanoi(n - 1, aux, dest, src)


func make_move():
	if restart:
		restart = false
		start()
	elif move_number < moves.size():
		move_disc(moves[move_number])
		move_number += 1
		$UI/HBox/NumMoves.text = "Move %d of %d" % [move_number, moves.size()]
	else:
		completed = true


func create_discs():
	for n in range(1, 9):
		var d: Disc = disc_scene.instance()
		d.set_radius(lerp(0.5, 1.0, (n - 1) / 7.0))
		var mat = load("res://materials/color" + str(n) + ".tres")
		d.set_mat(mat)
		discs.append(d)


func clear_stack():
	for peg in $Pegs.get_children():
		for _disc in peg.get_children():
			peg.remove_child(_disc)


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


func move_disc(from_to):
	var speed = $UI/HBox/Speed.value
	# Get top-most disc
	var start_peg = $Pegs.get_child(from_to[0])
	disc = start_peg.get_children()[-1]
	var tween = get_node("Tween")
	# Move to top of pole
	var y = disc.translation.y
	var _tweenBool = tween.interpolate_method(self, "move_vertically", y, peg_length / 2 + 0.2, (peg_length - y) / speed, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	start_pos = disc.translation
	var end_peg = $Pegs.get_child(from_to[1])
	end_pos = Vector2(end_peg.translation.x - start_peg.translation.x, get_y_position_in_stack(end_peg.get_child_count()))
	var angle = PI if end_pos.x > 0 else -PI
	_tweenBool = tween.interpolate_method(self, "move_in_arc", 0.0, angle, angle * end_pos.x / speed, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	yield(tween, "tween_completed")
	_tweenBool = tween.interpolate_method(self, "move_vertically", disc.translation.y, end_pos.y, (peg_length - end_pos.y) / speed, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	yield(tween, "tween_completed")
	# Reparent disc
	start_peg.remove_child(disc)
	end_peg.add_child(disc)
	disc.translation.x = 0
	emit_signal("move_completed")


func move_vertically(y):
	disc.translation.y = y


func move_in_arc(phi):
	var x = end_pos.x * (1 - cos(phi)) / 2
	var y = end_pos.x / 3.5 * sin(phi) + start_pos.y
	disc.translation = Vector3(x, y, 0)


func _on_Restart_pressed():
	if completed:
		start()
	else:
		# Allow move to complete
		restart = true
