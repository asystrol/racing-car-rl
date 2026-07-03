extends Node2D

@export var car: CharacterBody2D
@export var path: Path2D

var track_reward: float
var tangent_dir: Vector2
var curve: Curve2D

func _ready() -> void:
	curve = path.curve

func _physics_process(_delta: float) -> void:
	
	var closest_offset = curve.get_closest_offset(car.global_position)
	var curve_transform = curve.sample_baked_with_rotation(closest_offset)
	var local_tangent = curve_transform.x.normalized()
	tangent_dir = path.global_transform.basis_xform(local_tangent).normalized()
	calculate_reward()

func calculate_reward():
	track_reward = (car.velocity.dot(tangent_dir)) / 500.0


func _on_path_2d_curve_built(built_curve: Curve2D) -> void:
	curve = built_curve
