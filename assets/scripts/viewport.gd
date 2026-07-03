extends Control

var path: Curve2D
@export var car: CharacterBody2D
@export var view_path: Path2D
@export var follower: Sprite2D

var path_made = false


func _process(_delta: float) -> void:
	if path_made:
		car.global_position = follower.position


func _on_path_2d_path_done(curve: Curve2D) -> void:
	path = curve
	make_path()


func make_path():
	view_path.curve = path
	scale = Vector2(0.2, 0.2)
	position += Vector2(-50,-50)
	path_made = true
