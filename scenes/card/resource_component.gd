class_name ResourceComponent
extends Node

@export var resource_token_scene: PackedScene

var resources: int = 0
var resource_tokens: Array

func add_resources(amount: int):
	resources += amount
	for i in amount:
		var resource_token: RigidBody3D = resource_token_scene.instantiate()
		resource_token.rotation.x += 90
		resource_token.position.z += 2
		resource_token.position.y += -4.5
		resource_tokens.append(resource_token)
		get_parent().add_child(resource_token)

func remove_resources(amount: int):
	resources -= amount
	for i in amount:
		resource_tokens.pop_back().queue_free()
