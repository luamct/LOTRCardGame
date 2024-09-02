class_name ReadingViewport
extends Marker3D

const MAX_BATTLEFIELD_X = 30  # In both directions: -30, 30
const MAX_VIEWING_X = 8  # In both directions: -30, 30
@export var x_position_curve: Curve

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var material: StandardMaterial3D = mesh.get_active_material(0)

func _ready():
	mesh.visible = false

func sample_curve(x: float):
	if x > 0: return x_position_curve.sample(x)
	else: return -x_position_curve.sample(-x)
		
func show_card(card: Card):
	mesh.visible = true
	
	var x_position: float = card.global_position.x / MAX_BATTLEFIELD_X
	var mesh_x_position: float = sample_curve(x_position) * MAX_VIEWING_X
	mesh.position = Vector3(mesh_x_position, 3, 0)
	
	var texture: CompressedTexture2D = card.get_texture()
	material.albedo_texture = texture

func highlight_hand_card(card: Card):
	mesh.visible = true
	mesh.position = Vector3(card.position.x, 0, 0)

	material.albedo_texture = card.texture

func hide_card():
	mesh.visible = false
