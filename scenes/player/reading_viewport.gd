class_name ReadingViewport
extends Marker3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var material: StandardMaterial3D = mesh.get_active_material(0)

func _ready():
	mesh.visible = false

func show_card(card_texture: CompressedTexture2D):
	mesh.visible = true
	mesh.position = Vector3(0, 2, 0)
	material.albedo_texture = card_texture

func highlight_hand_card(card: Card):
	mesh.visible = true
	mesh.position = Vector3(card.position.x, 0, 0)

	material.albedo_texture = card.texture

func hide_card():
	mesh.visible = false
