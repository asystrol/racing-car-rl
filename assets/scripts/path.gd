extends Path2D

@export var initial_point_count: int = 20
@export var bounding_size: float = 2000.0
@export var max_displacement: float = 300.0
@export var min_distance: float = 200.0
@export var min_angle_deg: float = 75.0
@export var push_iterations: int = 5
@export var curve_smoothness: float = 0.3
@export var track_width: float = 10.0
@export var bounding_box_size: float = 2200.0

@export var car: CharacterBody2D


func _ready():
	self.curve = Curve2D.new()
	generate_track()
	build_world()
	car.global_position = curve.get_baked_points()[0]
	car.rotation = (curve.get_baked_points()[1] - curve.get_baked_points()[0]).angle()

func generate_track():
	self.curve.clear_points()
	randomize() 
	var raw_points = []
	var half_size = bounding_size / 2.0
	for i in range(initial_point_count):
		var x = randf_range(-half_size, half_size)
		var y = randf_range(-half_size, half_size)
		raw_points.append(Vector2(x, y))

	
	var hull_points = Geometry2D.convex_hull(raw_points)
	
	if hull_points.size() > 0 and hull_points[0].is_equal_approx(hull_points[hull_points.size()-1]):
		hull_points.remove_at(hull_points.size() - 1)

	# STEP 3: Compute midpoints and displace by a random amount
	var displaced_points = []
	for i in range(hull_points.size()):
		var p1 = hull_points[i]
		var p2 = hull_points[(i + 1) % hull_points.size()]
		
		displaced_points.append(p1)
		
		# Calculate midpoint and a normal vector perpendicular to the edge
		var midpoint = (p1 + p2) / 2.0
		var edge_dir = (p2 - p1).normalized()
		var normal = Vector2(-edge_dir.y, edge_dir.x) # Orthogonal vector
		
		# Displace the midpoint randomly along the normal
		var displacement = randf_range(-max_displacement, max_displacement)
		displaced_points.append(midpoint + (normal * displacement))

	# STEP 4: Push points apart (Relaxation phase)
	var final_points = displaced_points.duplicate()
	var min_angle_rad = deg_to_rad(min_angle_deg)
	
	for iteration in range(push_iterations):
		for i in range(final_points.size()):
			var p_prev = final_points[(i - 1 + final_points.size()) % final_points.size()]
			var p_curr = final_points[i]
			var p_next = final_points[(i + 1) % final_points.size()]

			# a) Minimum distance threshold
			var dist_to_next = p_curr.distance_to(p_next)
			if dist_to_next < min_distance and dist_to_next > 0:
				var push_dir = (p_curr - p_next).normalized()
				var overlap = min_distance - dist_to_next
				# Push both points away from each other by half the overlap
				final_points[i] += push_dir * (overlap / 2.0)
				final_points[(i + 1) % final_points.size()] -= push_dir * (overlap / 2.0)

			# b) Minimum angle threshold
			var v_in = (p_curr - p_prev).normalized()
			var v_out = (p_next - p_curr).normalized()
			
			# Calculate the angle between the two vectors
			var angle = abs(v_in.angle_to(v_out))
			
			# If the turn is too sharp (angle is less than threshold)
			if angle > min_angle_rad: # Note: sharper turns have higher absolute dot product/angles in this vector math
				# Smooth the sharp point by moving it slightly towards the average of its neighbors
				var target_pos = (p_prev + p_next) / 2.0
				final_points[i] = final_points[i].lerp(target_pos, 0.5)

	# STEP 5: Interpolate points with splines forcing them to pass through input points
	for p in final_points:
		self.curve.add_point(p)
		
	# Close the loop
	self.curve.add_point(final_points[0]) 

	# Apply Catmull-Rom style control handles to make the curve perfectly smooth
	var point_count = self.curve.get_point_count()
	for i in range(point_count):
		# Handle wrapping for closed loop tangents
		var p_prev_idx = i - 1 if i > 0 else point_count - 2
		var p_next_idx = i + 1 if i < point_count - 1 else 1
		
		var pos_prev = self.curve.get_point_position(p_prev_idx)
		var pos_next = self.curve.get_point_position(p_next_idx)
		
		# Calculate tangent vector across the neighboring points
		var tangent = (pos_next - pos_prev) * curve_smoothness
		
		# Set the "in" and "out" control handles (Bezier handles)
		self.curve.set_point_in(i, -tangent)
		self.curve.set_point_out(i, tangent)


func build_world():
	# 1. Clean up any previously generated world nodes if we regenerate
	for child in get_children():
		child.queue_free()

	# Get a highly detailed array of points along our smooth curve
	# Godot 3: use self.curve.tessellate()
	var baked_points = curve.get_baked_points()
	
	# Remove the last point if it overlaps the first to form a clean polygon
	if baked_points.size() > 0 and baked_points[0].is_equal_approx(baked_points[baked_points.size()-1]):
		baked_points.remove_at(baked_points.size() - 1)
	
	var bed_line = Line2D.new()
	bed_line.points = baked_points
	bed_line.closed = true
	bed_line.width = track_width * 2
	bed_line.default_color = Color.WEB_GREEN
	bed_line.joint_mode = Line2D.LINE_JOINT_ROUND 
	bed_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bed_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(bed_line)

	var track_line = Line2D.new()
	track_line.points = baked_points
	track_line.closed = true
	track_line.width = track_width
	track_line.default_color = Color.DARK_GRAY
	track_line.joint_mode = Line2D.LINE_JOINT_ROUND 
	track_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	track_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(track_line)
	
	var mid_line = Line2D.new()
	mid_line.points = baked_points
	mid_line.closed = true
	mid_line.width = 2
	mid_line.default_color = Color.WHITE
	mid_line.joint_mode = Line2D.LINE_JOINT_ROUND
	mid_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	mid_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(mid_line)

	# --- INNER COLLISION (The Island) ---
	var inner_polys = Geometry2D.offset_polygon(baked_points, -track_width)
	
	for poly in inner_polys:
		if poly.size() < 3:
			continue
			
		var inner_static_body = StaticBody2D.new()
		var inner_collision = CollisionPolygon2D.new()
		var inner_visual = Polygon2D.new()
		
		inner_collision.polygon = poly
		
		# THE FIX: Tell the physics engine to build a hollow fence, skipping decomposition
		inner_collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS 
		
		inner_visual.polygon = poly
		inner_visual.color = Color.DARK_GREEN 
		
		inner_static_body.add_child(inner_collision)
		add_child(inner_visual)
		add_child(inner_static_body)
		

	# --- OUTER COLLISION (The 2000x2000 Boundary) ---
	# Create the massive square bounding box
	# 1. Get the outer boundary of the track
	# Godot 3: use Geometry.offset_polygon_2d()
	var track_outer_edge = Geometry2D.offset_polygon(baked_points, track_width)[0]
	
	var outer_static_body = StaticBody2D.new()
	var outer_collision = CollisionPolygon2D.new()
	var outer_visual = Polygon2D.new()
	
	# 2. Physics: Create a physical fence exactly on the track's outer edge
	outer_collision.polygon = track_outer_edge
	# BUILD_SEGMENTS tells Godot this is a hollow wall, not a solid block. 
	# This completely bypasses the convex decomposition error!
	outer_collision.build_mode = CollisionPolygon2D.BUILD_SEGMENTS 
	
	# 3. Visuals: Draw the grass naturally without clipping math
	outer_visual.polygon = track_outer_edge
	outer_visual.invert_enabled = true # Tell Godot to draw OUTSIDE the polygon
	outer_visual.invert_border = 3500.0 # How far the grass stretches outward
	outer_visual.color = Color.DARK_GREEN
	
	outer_static_body.add_child(outer_collision)
	
	add_child(outer_visual)
	add_child(outer_static_body)
	
	var in_bound = Line2D.new()
	in_bound.points = inner_polys[0]
	in_bound.closed = true
	in_bound.width = 3
	in_bound.default_color = Color.DARK_RED
	in_bound.joint_mode = Line2D.LINE_JOINT_ROUND 
	in_bound.begin_cap_mode = Line2D.LINE_CAP_ROUND
	in_bound.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(in_bound)
	
	var out_bound = Line2D.new()
	out_bound.points = track_outer_edge
	out_bound.closed = true
	out_bound.width = 3
	out_bound.default_color = Color.DARK_RED
	out_bound.joint_mode = Line2D.LINE_JOINT_ROUND 
	out_bound.begin_cap_mode = Line2D.LINE_CAP_ROUND
	out_bound.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(out_bound)
