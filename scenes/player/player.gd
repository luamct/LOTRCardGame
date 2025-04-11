class_name Player
extends Node3D

@export var starting_hand_size: int
@export var decklist: DeckList

@onready var heroes_area: PlayArea = $HeroesArea
@onready var allies_area: PlayArea = $AlliesArea
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
#var allies: Array[Card]

# sphere -> amount, accounts for all heroes, always updated
var resources: Dictionary

func _ready():
	assert(decklist)

func setup():
	decklist.load()
	for card_data: CardData in decklist.cards:
		var card_node: Card = Card.create(card_data, Card.Zone.DECK, scenario, self)
		card_node.rotation_degrees.z = 180  # Face down while in the deck
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
		var card: Card = deck_cards.pop_front()
		card.reparent(cards_container, true)
		
		card.zone = Card.Zone.HAND

		var tween_duration = 0.5
		var pos = Vector3(7.5, 0, -8)
		var tween: Tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(card, "position", pos, tween_duration)
		tween.tween_property(card, "rotation_degrees:z", 0, tween_duration)
		tween.tween_property(card, "rotation_degrees:x", 0, tween_duration)
		tween.tween_callback(func():
			hand_cards.append(card)
			adjust_cards_in_hand()
		).set_delay(tween_duration + 0.2)
		await get_tree().create_timer(0.2).timeout

func adjust_cards_in_hand():
	if hand_cards.size() == 0:
		return

	var card_width = hand_cards[0].width
	var card_height = hand_cards[0].height
	var n: int = hand_cards.size()

	var offset = (n - 1) * (card_width * card_spacing) * 0.5

	# When there are more than 6 cards, we need to squeeze them more
	var height_curve_step = min(0.1, 0.5/(n - 1))
	for i in n:
		var card = hand_cards[i]
		var x_index = 0.5 + (1 + 2*i - n) * height_curve_step

		var tween_duration = 0.1
		var tween: Tween = create_tween().set_parallel(true)
		var new_position: Vector3 = Vector3(
			card_width * card_spacing * i - offset,
			i * 0.01,
			- cards_height_curve.sample(x_index) * max_card_height * card_height
		)
		tween.tween_property(card, "position", new_position, tween_duration)
 
		var middle = (n - 1) * 0.5
		var new_rotation_y =  (i - middle) * max_card_rotation
		tween.tween_property(card, "rotation_degrees:y", new_rotation_y, tween_duration)

func set_threat_level():
	for hero_card in heroes_area.cards:
		threat_level += hero_card.data.threat

	ui_threat.text = str(threat_level)

func shuffle():
	decklist.cards.shuffle()

func setup_heroes():
	for i in decklist.heroes.size():
		var card: Card = Card.create(decklist.heroes[i], Card.Zone.BATTLEFIELD, scenario, self)
		heroes_area.add_card(card)

func add_resources(sphere: String, amount: int):
	if sphere not in resources:
		resources[sphere] = 0
	resources[sphere] += amount

func resource_phase():
	for hero in heroes_area.cards:
		hero.add_resources(5)
		add_resources(hero.data.sphere, 5)

func remove_resources(sphere: String, cost: int):
	var paid = 0
	for hero in heroes_area.cards:
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
	if resources.get(card.data.sphere, 0) >= card.data.cost:
		remove_resources(card.data.sphere, card.data.cost)
		
		allies_area.add_card(card)
		hand_cards.erase(card)
		adjust_cards_in_hand()
	else:
		print("Not enough resources of the required sphere!")

func get_affected_cards(applies_to: AbilityData.TargetType) -> Array[Card]:
	match applies_to:
		AbilityData.TargetType.ALLY:
			return allies_area.cards

		AbilityData.TargetType.CHARACTER:
			return heroes_area.cards + allies_area.cards

	return []

func apply_stats_effect(effect: AbilityEffectData):
	var affected_cards: Array[Card] = []
	for applies_to in effect.applies_to: 
		affected_cards.append_array(get_affected_cards(applies_to))

	affected_cards.map(func(card: Card): card.apply_stats_effect(effect))

func _input(event: InputEvent):
	if Input.is_key_pressed(KEY_D):
		draw_cards(1)
