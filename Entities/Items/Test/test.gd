extends Item

var colors = [Color(1,0,0), Color(0,1,0), Color(0,0,1)]
var current_color_index = 0

func use() -> bool:
	current_color_index = (current_color_index + 1) % colors.size()

	var csg = $Box
	if csg:
		var mat = csg.material
		if mat == null:
			mat = StandardMaterial3D.new()
		else:
			mat = mat.duplicate()  # avoid changing shared material

		mat.albedo_color = colors[current_color_index]
		csg.material = mat

	return false
