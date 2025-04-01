class_name Player
extends Node3D

@export var starting_hand_size: int
@export var decklist: DeckList

@onready var heroes_area: Node3D = $HeroesArea
@onready var allies_area: Node3D = $AlliesArea
@onready var ui_threat: Label = $UI.find_child("ThreatValue")
@onready var scenario: Scenario = get_tree().get_first_node_in_group("scenario")
@onready var camera: Camera3D = %Camera3D
@onready var deck: Deck = $Deck

@export_group("Hand")
@onready var drop_to_play_marker = %DropToPlayMarker
@onready var dragging_surface_collision = %DraggingSurface/CollisionShape3D
@onready var cards_container = %CardsContainer

# How much each card is not covered by the neighbouring ones (as a percentage of its width)
@export var card_spacing: float = 0.5

@export var max_card_height: float
@export var cards_height_curve: Curve

@export var max_card_rotation: float = -4
@export var cards_rotation_curve: Curve

var deck_cards: Array[Card]
var hand_cards: Array[Card]

# Battlefield state
var threat_level = 0
var heroes: Array[Card]
var allies: Array[Card]

# sphere -> amount, accounts for all heroes, always updated
var resources: Dictionary

func _ready():
	assert(decklist)

func setup():
	decklist.load()
	for card_data: CardData in decklist.cards:
		var card_node: Card = Card.create(card_data, Card.Zone.DECK, scenario, self)
		deck_cards.append(card_node)
		deck.add_child(card_node)
	deck_cards.shuffle()

	draw_cards(starting_hand_size)

	adjust_cards_in_hand()
	dragging(false)

	setup_heroes()
	set_threat_level()
	
func draw_cards(n: int):
	for i in n:
		var card_node: Card = deck_cards.pop_front()
		card_node.zone = Card.Zone.HAND

		#card_node.global_transform = deck.global_transform
		#card_node.position.y += 2
		#card_node.rotation_degrees.x += 90
		hand_cards.append(card_node)
		card_node.reparent(cards_container, false)

func adjust_cards_in_hand():
	var _cards = cards_container.get_children().map(func(card): return card as Card)
	if _cards.size() == 0:
		return

	var card_width = _cards[0].width
	var card_height = _cards[0].height

	var offset = (_cards.size() - 1) * (card_width * card_spacing) * 0.5
	var n_cards: int = _cards.size()

	# When there are more than 6 cards, we need to squeeze them more
	var height_curve_step = min(0.1, 0.5/(n_cards - 1))
	for i in n_cards:
		var card = _cards[i]
		var x_index = 0.5 + (1 + 2*i - n_cards) * height_curve_step

		var tween_duration = 0.1
		var tween: Tween = create_tween().set_parallel(true)
		var new_position: Vector3 = Vector3(
			card_width * card_spacing * i - offset,
			i * 0.01,
			- cards_height_curve.sample(x_index) * max_card_height * card_height
		)
		tween.tween_property(card, "position", new_position, tween_duration)
 
		var middle = (n_cards - 1) * 0.5
		var new_rotation_y =  (i - middle) * max_card_rotation
		tween.tween_property(card, "rotation_degrees:y", new_rotation_y, tween_duration)

func set_threat_level():
	for hero_card in heroes:
		threat_level += hero_card.data.threat

	ui_threat.text = str(threat_level)

func shuffle():
	decklist.cards.shuffle()

func setup_heroes():
	for i in decklist.heroes.size():
		var card: Card = Card.create(decklist.heroes[i], Card.Zone.BATTLEFIELD, scenario, self)
		heroes_area.add_child(card)
		card.position.x += i * card.width * 1.2

		heroes.append(card)

func add_resources(sphere: String, amount: int):
	if sphere not in resources:
		resources[sphere] = 0
	resources[sphere] += amount

func resource_phase():
	for hero in heroes:
		hero.add_resources(5)
		add_resources(hero.data.sphere, 5)

func remove_resources(sphere: String, cost: int):
	var paid = 0
	for hero in heroes:
		if hero.data.sphere == sphere:
			var to_pay = min(hero.get_resources(), cost)
			hero.remove_resources(to_pay)
			paid -= to_pay
			if (paid == cost):
				break

	resources[sphere] -= cost

func dragging(enabled: bool):
	dragging_surface_collision.disabled = !enabled

func try_to_play(card: Card):
	if (resources.get(card.data.sphere, 0) >= card.data.cost):
		remove_resources(card.data.sphere, card.data.cost)
		card.reparent(allies_area, false)
		
		card.position = Vector3.ZERO
		card.position.x = allies.size() * card.width * 1.2
		
		card.rotation = Vector3.ZERO
		card.scale = Vector3.ONE
		card.zone = Card.Zone.BATTLEFIELD
		card.state = Card.State.REST
		allies.append(card)
		hand_cards.erase(card)
		adjust_cards_in_hand()
	else:
		print("Not enough resources of the required sphere!")

func get_affected_cards(applies_to: AbilityData.TargetType) -> Array[Card]:
	match applies_to:
		AbilityData.TargetType.ALLY:
			return allies

		AbilityData.TargetType.CHARACTER:
			return heroes + allies

	return []

func apply_stats_effect(effect: AbilityEffectData):
	var affected_cards: Array[Card] = []
	for applies_to in effect.applies_to: 
		affected_cards.append_array(get_affected_cards(applies_to))

	affected_cards.map(func(card: Card): card.apply_stats_effect(effect))

func _input(event: InputEvent):
	if Input.is_key_pressed(KEY_D):
		draw_cards(1)
		#adjust_cards_in_hand()
