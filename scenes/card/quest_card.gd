class_name QuestCard
extends Node3D

static var quest_card_scene: String = "res://scenes/card/quest_card.tscn"

@onready var mesh: MeshInstance3D = $Mesh

var data: QuestCardData
var side: String

static func create(_data: QuestCardData) -> QuestCard:
	var instance: QuestCard = load(quest_card_scene).instantiate() as QuestCard
	instance.data = _data
	instance.side = "A"

	return instance

func _ready():
	render()
	
func get_card_art_texture():
	var file_path = "res://assets/database/scans/final/%s/%d%s.png" % [data.set_, data.id, side]
	return load(file_path)

func render():
	var material: StandardMaterial3D = mesh.get_active_material(0)
	var texture: CompressedTexture2D = get_card_art_texture()
	material.albedo_texture = texture
