extends Path2D

var bezier : Curve2D = Curve2D.new()
var points : PackedVector2Array = PackedVector2Array()
var points_array


func _ready() -> void:
	for i in range(20):
		points.append(rnd_pt(-1000,1000))
		
	convexhull_method()
	
	

func _process(_delta: float) -> void:
	pass


func rnd_pt(mi: float, mx: float):
	return Vector2(randf_range(mi,mx),randf_range(mi,mx))

func sort_method():
	
	points_array = Array(points)
	points_array.sort_custom(func(a: Vector2, b: Vector2):
		var angle_a = atan2(a.y, a.x)
		var angle_b = atan2(b.y, b.x)
		return angle_a < angle_b)
	set_curve(bezier)

	for i in range(5):
		if (not i):
			bezier.add_point(points.get(0),rnd_pt(-200,200))
			bezier.set_point_out(i, bezier.get_point_in(i)*(-1))
		else:
			bezier.add_point(points.get(i),rnd_pt(-200,200))
			bezier.set_point_out(i, bezier.get_point_in(i)*(-1))
	bezier.add_point(bezier.get_point_position(0),bezier.get_point_in(0),bezier.get_point_out(0))
	
func convexhull_method():
	var hull = Geometry2D.convex_hull(points)
	
	if hull.size()%2 == 1:
		hull.remove_at(hull.size()-1)
	for i in range(hull.size()/2):
		bezier.add_point(hull[2*i], hull[2*i-1] - hull[2*i], hull[2*i+1] - hull[2*i])
	bezier.add_point(hull[0], hull[-1] - hull[0], hull[1] - hull[0])
	set_curve(bezier)
