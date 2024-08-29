class_name Hand
extends Node3D

# How much each card is not covered by the neighbouring ones (as a percentage of its width)
@export var card_spacing: float = 0.5

@export var max_card_height: float
@export var cards_height_curve: Curve

@export var max_card_rotation: float = 15
@export var cards_rotation_curve: Curve

@onready var cards_container = $CardsContainer
@onready var dragging_surface_collision = $DraggingSurface/CollisionShape3D
@onready var drop_to_play_marker = $DropToPlayMarker

var cards: Array[Card]
var dragged_card: Card = null

func setup(starting_cards: Array[Card]):
	cards = starting_cards
	for card in cards:
		cards_container.add_child(card)
		
	position_cards()
	dragging(false)

func dragging(enabled: bool):
	dragging_surface_collision.disabled = !enabled

func position_cards():
	var _cards = cards_container.get_children().map(func(card): return card as Card)
	var card_width = _cards[0].width
	var card_height = _cards[0].height

	var offset = (_cards.size() - 1) * (card_width * card_spacing) * 0.5
	for i in _cards.size():
		var card = _cards[i]
		var index = i / (_cards.size() - 1.0)

		card.position.x = card_width * card_spacing * i - offset
		card.position.y = cards_height_curve.sample(index) * max_card_height * card_height
		card.position.z = -i * 0.01
		
		card.rotation_degrees.z = cards_rotation_curve.sample(index) * max_card_rotation
		
		#print("Card %s: %s" % [card.data.name, str(card.global_position)])

func _process(_delta):
	pass

# func _on_dragging_surface_input_event(camera: Node, event: InputEvent, mouse_position: Vector3, normal: Vector3, shape_idx: int):
	# pass
	# if event.is_action_released("left_click"):
	# 	dragged_card.leave_dragging()
	# 	dragged_card.enter_hand()
	# else:
	# 	dragged_card.global_position = mouse_position

# Enables the dragging surface when dragging starts, and disables it once done
func _on_dragging_state_changed(on: bool, card: Card):
	dragging_surface_collision.disabled = !on
	dragged_card = card
