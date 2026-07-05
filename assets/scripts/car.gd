extends CharacterBody2D

signal reset

@export var engine_power: float = 800.0
@export var braking_force: float = -450.0
@export var max_speed_reverse: float = 250.0

@export var max_steer_low: float = 25.0 
@export var min_steer_high: float = 5.0 
@export var threshold_speed: float = 600.0 

@export var friction: float = -0.9
@export var drag: float = -0.0015
@export var wheel_base: float = 70.0
@export var slip_speed: float = 400.0 
@export var traction_fast: float = 0.1 
@export var traction_slow: float = 0.7 

@onready var aicontrol = $AIController2D
@export var track: Node2D
@export var reward_label: Label

var acceleration: Vector2 = Vector2.ZERO
var input_turn: float = 0.0
var frame_reward = 0.0
var check_point_reward = 0.0
var reward := 0.0
var checkpoints = 0
var split_time := 0.0
var total_rewards := 0.0

func _physics_process(delta: float) -> void:
	split_time += delta
	total_rewards += reward
	reward_label.text = "%.2f" %total_rewards
	
	acceleration = Vector2.ZERO
	#get_input()
	get_input_from_model()
	apply_friction()
	calculate_steering(delta)
	
	velocity += acceleration * delta
	calculate_reward()
	move_and_slide()
	
	if split_time > 30:
		frame_reward = -50
	if split_time > 30.1:
		aicontrol.reset()
		reset.emit.call_deferred()
	
func get_input_from_model() -> void:
	input_turn = aicontrol.steer
	if aicontrol.accelerate == -1:
		acceleration = transform.x * braking_force
	elif aicontrol.accelerate == 1:
		acceleration = transform.x * engine_power
	else:
		acceleration = Vector2.ZERO

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

func calculate_reward():
	if frame_reward != -50:
		if velocity.dot(transform.x) > 0 and track.track_reward > 0.1:
			frame_reward = 0.01
		else:
			frame_reward = -0.01
		
	reward = frame_reward + track.track_reward + check_point_reward


	
func add_checkpoint_reward():
	var exponent = (-1)*0.6*(split_time-8)
	check_point_reward = 20 * (1 + exp(exponent))
	split_time = 0.0

func _on__1_entered(_body: Node2D) -> void:
	if checkpoints == 0 and split_time > 2:
		checkpoints += 1
		add_checkpoint_reward()

func _on__2_entered(_body: Node2D) -> void:
	if checkpoints == 1:
		checkpoints += 1
		add_checkpoint_reward()

func _on__3_entered(_body: Node2D) -> void:
	if checkpoints == 2:
		checkpoints += 1
		add_checkpoint_reward()

func _on__4_entered(_body: Node2D) -> void:
	if checkpoints == 3:
		checkpoints += 1
		add_checkpoint_reward()

func _on__5_entered(_body: Node2D) -> void:
	if checkpoints == 4:
		checkpoints += 1
		add_checkpoint_reward()
		reset.emit.call_deferred()
