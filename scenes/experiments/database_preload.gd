extends Node3D

@export var my_resource: MyResource

func _ready():
	my_resource.load()