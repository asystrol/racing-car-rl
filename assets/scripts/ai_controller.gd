extends AIController2D

@export var raycasts: Node
@export var car: CharacterBody2D

var steer: float
var accelerate: int
var total_reward

func get_obs() -> Dictionary:
	var arr = raycasts.get_raycasts()
	arr.append(car.velocity.dot(car.transform.x)/600.0)
	arr.append(car.velocity.dot(car.transform.y)/600.0)
	arr.append(car.transform.x.x)
	arr.append(car.transform.x.y)
	return {"obs":arr}

func get_reward() -> float:
	var step_reward = car.reward
	car.check_point_reward = 0.0
	return step_reward
	
func get_action_space() -> Dictionary:
	return {
		"steer" : {
			"size": 1,
			"action_type": "continuous"
		},
		"accelerate" : {
			"size": 2,
			"action_type": "discrete"
		},
		"coast" : {
			"size": 2,
			"action_type": "discrete"
		}
	}
	
func set_action(action) -> void:
	steer = action["steer"][0]
	if action["coast"] == 1:
		accelerate = 0
	else:
		if action["accelerate"] == 1:
			accelerate = 1
		else:
			accelerate = -1
