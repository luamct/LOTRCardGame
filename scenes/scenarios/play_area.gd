@tool
class_name PlayArea
extends MeshInstance3D

@export var show_in_game: bool
@export var size: Vector2 = Vector2(20, 20)
@export var color: Color
var height: float = 0.0

var cards: Array[Card]

func _ready():
	mesh = ImmediateMesh.new()
	mesh.clear_surfaces()
	update_material()
	
func _process(_delta):
	if show_in_game or Engine.is_editor_hint() and not OS.has_feature("editor"):
		update_mesh()

func update_material():
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.flags_transparent = true
	material_override = mat

func update_mesh():
	mesh.clear_surfaces()

	var verts = [
		Vector3(0, height, 0),
		Vector3(size.x, height, 0),
		Vector3(0, height, size.y),
		Vector3(size.x, height, size.y),
	]

	# Filled transparent plane
	mesh.surface_begin(Mesh.PrimitiveType.PRIMITIVE_TRIANGLE_STRIP)
	for v in verts:
		mesh.surface_add_vertex(v)
	mesh.surface_end()

	update_material()

func add_card(card: Card):
	if card.get_parent():
		card.reparent(self, true)
	else:
		add_child(card)
		
	cards.append(card)
	reposition_cards()

func reposition_cards():
	if cards.is_empty():
		return

	var card_width: float = cards[0].width
	var card_height: float = cards[0].height
	var card_spacing: float = card_width/4
	for i in cards.size():
		var card: Card = cards[i]
		var x = card_width/2 + i * (card_width + card_spacing)

		var secs = 0.5
		var tween: Tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(card, "position:x", x, secs)
		tween.tween_property(card, "position:z", card_height/2, secs)
		tween.tween_property(card, "rotation_degrees:z", 0, secs)
