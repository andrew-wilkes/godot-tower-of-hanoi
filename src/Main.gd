extends Spatial

signal move_completed

const NUM_DISCS = 3

var disc_scene = preload("res://Disc.tscn")
var discs = []
var stack_offset
var stacks = [[], [], []]
var last_move = -1
var paused = false

func _ready():
	create_discs()
	build_stack(NUM_DISCS)
	var _e = connect("move_completed", self, "move_completed")
	make_move()


func make_move():
	# First move
	if last_move < 0:
		if stacks[0].size() % 2 == 0:
			move_disc(0, 1)
		else:
			move_disc(0, 2)
	else:
		# Pick smallest disc that was not just moved
		var smallest_value = INF
		var smallest_idx = 0
		var empty_idx = -1
		var next_value = INF
		var next_idx = -1
		# Scan stacks
		for i in 3:
			# Find empty peg
			if stacks[i].size() == 0:
				empty_idx = i
				continue
			# Find smallest disc
			var v = stacks[i][-1]
			if i != last_move:
				if v < smallest_value:
					smallest_idx = i
					smallest_value = v
		# Find next smallest disc
		for i in 3:
			if i != empty_idx:
				var v = stacks[i][-1]
				if v > smallest_value and v < next_value:
					next_value = v
					next_idx = i
		if next_idx < 0:
			next_idx = empty_idx
		# Place on larger disc
		move_disc(smallest_idx, next_idx)


func move_completed():
	if stacks[2].size() < NUM_DISCS and not paused:
		make_move()


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
		stacks[0].append(n - i)
		var d = discs[n - i - 1]
		d.translation.y = get_y_position_in_stack(i)
		$Pegs/Peg1.add_child(d)


func get_y_position_in_stack(disc_index): # 0 is the base, 1, 2, 3 ...
	return 0.25 * disc_index - stack_offset

var start_pos
var end_pos
var disc
var peg_length

const SPEED = 20.0

func move_disc(from_peg, to_peg):
	stacks[to_peg].append(stacks[from_peg].pop_back())
	last_move = to_peg
	# Get top-most disc
	var start_peg = $Pegs.get_child(from_peg)
	disc = start_peg.get_children()[-1]
	var tween = get_node("Tween")
	# Move to top of pole
	var y = disc.translation.y
	var _tweenBool = tween.interpolate_method(self, "move_vertically", y, peg_length / 2 + 0.2, (peg_length - y) / SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	start_pos = disc.translation
	var end_peg = $Pegs.get_child(to_peg)
	end_pos = Vector2(end_peg.translation.x - start_peg.translation.x, get_y_position_in_stack(end_peg.get_child_count()))
	var angle = PI if end_pos.x > 0 else -PI
	_tweenBool = tween.interpolate_method(self, "move_in_arc", 0.0, angle, angle * end_pos.x / SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	yield(tween, "tween_completed")
	_tweenBool = tween.interpolate_method(self, "move_vertically", disc.translation.y, end_pos.y, (peg_length - end_pos.y) / SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
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
	var y = end_pos.x / 3 * sin(phi) + start_pos.y
	disc.translation = Vector3(x, y, 0)


func _unhandled_key_input(event):
	paused = event.pressed
	if not paused:
		make_move()
