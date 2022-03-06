extends Spatial

class_name Disc

func set_mat(mat: Material):
	$Outer.material = mat
	$Outer/Inner.material = mat


func set_radius(r):
	$Outer.radius = r
