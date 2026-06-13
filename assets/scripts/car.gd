extends CharacterBody2D

# --- Vehicle Specifications ---
@export var engine_power: float = 800.0
@export var braking_force: float = -450.0
@export var max_speed_reverse: float = 250.0

# --- Dynamic Steering Specs ---
@export var max_steer_low: float = 25.0 # Max turn angle (degrees) at low speeds
@export var min_steer_high: float = 5.0 # Max turn angle (degrees) at top speed
@export var threshold_speed: float = 600.0 # Speed at which steering becomes fully stiff

# --- Traction & Physics ---
@export var friction: float = -0.9
@export var drag: float = -0.0015
@export var wheel_base: float = 70.0
@export var slip_speed: float = 400.0 
@export var traction_fast: float = 0.1 
@export var traction_slow: float = 0.7 

var acceleration: Vector2 = Vector2.ZERO
var input_turn: float = 0.0

func _physics_process(delta: float) -> void:
	acceleration = Vector2.ZERO
	
	get_input()
	apply_friction()
	calculate_steering(delta)
	
	velocity += acceleration * delta
	move_and_slide()

func get_input() -> void:
	input_turn = Input.get_axis("steer left", "steer right")
	
	if Input.is_action_pressed("gas"):
		acceleration = transform.x * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = transform.x * braking_force

func apply_friction() -> void:
	if velocity.length() < 5 and acceleration.length() == 0:
		velocity = Vector2.ZERO
		
	var friction_force = velocity * friction
	var drag_force = velocity * velocity.length() * drag
	
	acceleration += drag_force + friction_force

func calculate_steering(delta: float) -> void:
	var current_speed = velocity.length()
	var speed_ratio = clamp(current_speed / threshold_speed, 0.0, 1.0)
	var dynamic_steer_limit_deg = lerp(max_steer_low, min_steer_high, speed_ratio)
	var steer_direction = input_turn * deg_to_rad(dynamic_steer_limit_deg)
	
	var rear_wheel = position - transform.x * (wheel_base / 2.0)
	var front_wheel = position + transform.x * (wheel_base / 2.0)
	
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	
	var new_heading = (front_wheel - rear_wheel).normalized()
	
	var traction = traction_slow
	if current_speed > slip_speed:
		traction = traction_fast
		
	var d = new_heading.dot(velocity.normalized())
	
	if d > 0:
		velocity = velocity.lerp(new_heading * current_speed, traction)
	elif d < 0:
		velocity = -new_heading * min(current_speed, max_speed_reverse)
		
	rotation = new_heading.angle()
