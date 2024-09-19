class_name Card
extends Node3D

signal dragging_state_changed(on: bool, card: Card)

static var basic_card_scene_path: String = "res://scenes/card/basic_card.tscn"
static var hero_card_scene_path: String = "res://scenes/card/hero_card.tscn"

const TWEEN_DURATION = 0.05

@export var highlight_height_boost: float
@export var highlight_scale_boost: float
@export var default_card_z: float = 1
@export_flags_3d_physics var dragging_surface_layer

@onready var mesh: MeshInstance3D = $Mesh
@onready var width: float = 5
@onready var height: float = 7

@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var reading_viewport: ReadingViewport = get_tree().get_first_node_in_group("reading_viewport")
@onready var scenario: Scenario = get_tree().get_first_node_in_group("scenario")

var data: CardData
var player: Player
var camera: Camera3D
var card_material: StandardMaterial3D

# Stats
var cost: int
var willpower: int
var attack: int
var defense: int
var health: int

var ongoing_effects: Array[AbilityEffectData]

var base_scale: Vector3
var base_rotation: Vector3
var base_position: Vector3
var transform_at_hand: Transform3D

var reading_surface: CollisionShape3D
var dragging_offset: Vector3
var inside_drop_area: bool = false

# Refers to any effects applicable to the card
enum State {
	REST,
	HIGHLIGHT,
	DRAGGING,
	BATTLEFIELD,
	GRAVEYARD
}
var state: State

# Refers to game mechanics only
enum Zone {
	DECK,
	HAND,
	BATTLEFIELD,
	DISCARD
}
var zone: Zone

var exausted: bool

static func get_scene(card_type: String) -> PackedScene:
	match card_type:
		"Hero": return load(hero_card_scene_path)
		_: return load(basic_card_scene_path)

static func create(
	_data: CardData, 
	_zone: Zone,
	_scenario: Scenario,
	_player: Player, 
	_camera: Camera3D
) -> Card:
	var card: Card = get_scene(_data.type).instantiate() as Card
	card.data = _data
	card.player = _player
	card.camera = _camera
	card.reading_surface = _player.dragging_surface_collision
	card.zone = _zone
	card.state = State.REST
	card.exausted = false

	card.cost = _data.cost
	card.willpower = _data.willpower
	card.attack = _data.attack
	card.defense = _data.defense
	card.health = _data.health

	card.card_material = StandardMaterial3D.new()
	card.card_material.albedo_texture = get_card_art_texture(_data.id)
	card.get_node("CardMesh/Mesh").set_surface_override_material(2, card.card_material)
	
	_scenario.end_of_phase.connect(card.on_end_of_phase)
	_scenario.end_of_round.connect(card.on_end_of_round)
	
	return card

static func get_card_art_texture(card_id: int):
	return load("res://assets/database/scans/final/Revised Core Set/%d.png" % card_id)
	
func _ready():
	pass

func _on_area_3d_mouse_exited():
	if state == State.HIGHLIGHT:
		leave_highlight()
		enter_hand()

func enter_highlight():
	state = State.HIGHLIGHT

	base_scale = mesh.scale
	base_position = mesh.position
	base_rotation = mesh.rotation_degrees

	if zone == Zone.HAND:
		#mesh.scale *= (1 + highlight_scale_boost)
		#mesh.position.y += height * highlight_height_boost
		#mesh.position.z += 1
		reading_viewport.highlight_hand_card(self)
		
	elif zone == Zone.BATTLEFIELD:
		
		reading_viewport.show_card(self)

		#var space = get_world_3d().direct_space_state
		#var query = PhysicsRayQueryParameters3D.create(camera.global_position, global_position, dragging_surface_layer)
		#query.collide_with_areas = true
		#var hit = space.intersect_ray(query)
		#print(hit)

		#print("Ray from: ", camera.global_position)
		#print("Ray to: ", global_position)
		#Debug.draw_line(camera.global_position, global_position)
	# print("Highlight: card_y = %f, mesh_y = %f" % [position.y, mesh.position.y])
	# mesh.global_rotation_degrees.z = 0

func leave_highlight():
	mesh.scale = base_scale
	mesh.position = base_position
	mesh.rotation_degrees = base_rotation
	
	reading_viewport.hide_card()

func enter_hand():
	state = State.REST

func enter_dragging(mouse_position: Vector3):
	state = State.DRAGGING
	dragging_offset = mouse_position - position
	transform_at_hand = transform

	# scale *= (1 + highlight_scale_boost)
	position.y += height * highlight_height_boost
	position.z += 1
	rotation_degrees.z = 0

	player.dragging(true)
	# collision_shape.disabled = true
	# dragging_state_changed.emit(true, self)

func leave_dragging():
	transform = transform_at_hand
	player.dragging(false)
	# collision_shape.disabled = false
	# dragging_state_changed.emit(false, self)

func _on_area_3d_input_event(_camera, event, world_position, _normal, _shape_idx):
	match state:
		# Highlight the card upon mouse hovering by scaling
		State.REST:
			enter_highlight()

		# Left click while highlighted, so we start dragging the card
		State.HIGHLIGHT:
			if event.is_action_pressed("left_click"):
				if zone == Zone.HAND:
					leave_highlight()
					enter_dragging(world_position)
				elif zone == Zone.BATTLEFIELD:
					var activated_ability = get_activated_ability(data.abilities)
					
					if activated_ability != null:
						scenario.resolve_ability(activated_ability, self, player)
						

func get_activated_ability(abilities: Array[AbilityData]):
	return abilities \
		.filter(func (a): return a.type == AbilityData.AbilityType.ACTIVATED) \
		.pop_back()
	
func _input(event: InputEvent):
	if not (event is InputEventMouseMotion or event is InputEventMouseButton):
		return
	
	match state:
		State.DRAGGING:
			if event.is_action_released("left_click"):
				leave_dragging()

				if inside_drop_area:
					player.try_to_play(self)
				
				enter_hand()
			else:
				var mouse_position = event.position

				var ray_from = camera.project_ray_origin(mouse_position)
				var ray_direction = camera.project_ray_normal(mouse_position)
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_from, ray_from + 100 * ray_direction, dragging_surface_layer)
				query.collide_with_areas = true
				var result = get_world_3d().direct_space_state.intersect_ray(query)

				if (not result.has("position")):
					return

				global_position = result["position"]
				inside_drop_area = (global_position.y > player.drop_to_play_marker.global_position.y)

func _notification(what):
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			if state == State.DRAGGING:
				leave_dragging()
				enter_hand()

func add_resources(amount: int):
	assert($ResourceComponent)
	$ResourceComponent.add_resources(amount)

func remove_resources(amount: int):
	assert($ResourceComponent)
	$ResourceComponent.remove_resources(amount)

func get_resources():
	assert($ResourceComponent)
	return $ResourceComponent.resources

func exaust():
	exausted = true
	create_tween().tween_property(self, "rotation_degrees:z", -90, TWEEN_DURATION)
	
func ready():
	exausted = false
	create_tween().tween_property(self, "rotation_degrees:z", 0, TWEEN_DURATION)
	
func apply_stats_effect(effect: AbilityEffectData):
	match effect.effect_type:
		AbilityEffectData.EffectType.COST_STAT: pass
		AbilityEffectData.EffectType.QUEST_STAT: 
			willpower += effect.amount

		AbilityEffectData.EffectType.ATTACK_STAT: pass
		AbilityEffectData.EffectType.DEFENSE_STAT: pass
		AbilityEffectData.EffectType.HEALTH_STAT: pass
		AbilityEffectData.EffectType.THREAT_STAT: pass

	ongoing_effects.append(effect)

func unapply_stats_effect(effect: AbilityEffectData):
	match effect.effect_type:
		AbilityEffectData.EffectType.COST_STAT: pass
		AbilityEffectData.EffectType.QUEST_STAT: 
			willpower -= effect.amount

		AbilityEffectData.EffectType.ATTACK_STAT: pass
		AbilityEffectData.EffectType.DEFENSE_STAT: pass
		AbilityEffectData.EffectType.HEALTH_STAT: pass
		AbilityEffectData.EffectType.THREAT_STAT: pass

func on_end_of_round():
	for i in range(ongoing_effects.size() - 1, -1, -1):
		if ongoing_effects[i].duration == AbilityEffectData.EffectDuration.END_OF_ROUND:
			unapply_stats_effect(ongoing_effects[i])
			ongoing_effects.remove_at(i)

func on_end_of_phase():
	for i in range(ongoing_effects.size() - 1, -1, -1):
		if ongoing_effects[i].duration == AbilityEffectData.EffectDuration.END_OF_PHASE:
			unapply_stats_effect(ongoing_effects[i])
			ongoing_effects.remove_at(i)
	
func get_texture() -> CompressedTexture2D:
	return card_material.albedo_texture
