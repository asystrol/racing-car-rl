extends Node2D

@export var car: CharacterBody2D

@export var ray1: RayCast2D
@export var ray2: RayCast2D
@export var ray3: RayCast2D
@export var ray4: RayCast2D
@export var ray5: RayCast2D
@export var ray6: RayCast2D
@export var ray7: RayCast2D
@export var ray8: RayCast2D
@export var ray9: RayCast2D
@export var ray10: RayCast2D
@export var ray11: RayCast2D

var rays: Array[Node2D]
var obs: PackedFloat64Array

func _ready() -> void:
	rays = [ray1, ray2, ray3, ray4, ray5, ray6, ray7, ray8, ray9, ray10, ray11]

func get_raycasts():
	obs.clear()
	var norm_dist
	for ray in rays:
		if ray.is_colliding():
			norm_dist = global_position.distance_to(ray.get_collision_point())
			norm_dist = norm_dist / 201
		else:
			norm_dist = 1
		obs.append(norm_dist)
	
	return obs
