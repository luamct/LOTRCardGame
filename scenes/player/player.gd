class_name Player
extends Node3D

@export var starting_hand_size: int
@export var decklist: DeckList

@onready var hand: Hand = $Hand
@onready var heroes_area: Node3D = $HeroesArea
@onready var allies_area: Node3D = $AlliesArea
@onready var ui_threat: Label = $UI.find_child("ThreatValue")
@onready var scenario: Scenario = get_tree().get_first_node_in_group("scenario")
@onready var camera: Camera3D = $Camera3D

var threat_level = 0
var heroes: Array[Card]
var allies: Array[Card]

# sphere -> amount, accounts for all heroes, always updated
var resources: Dictionary

func _ready():
	assert(decklist)

func setup():

	decklist.load()
	print("\nDeck: " + str(decklist.cards.size()))
	for card: CardData in decklist.cards:
		var cd = card as CardData

	print("\nStarting hand:")
	var starting_cards_data: Array[CardData] = draw(starting_hand_size)
	for card in starting_cards_data:
		print(card.name)

	var starting_cards: Array[Card] = []
	starting_cards.assign(starting_cards_data.map(
		func(card_data): return Card.create(card_data, Card.Zone.HAND, scenario, self, hand, camera)
	))
	hand.setup(starting_cards)
	
	setup_heroes()

	set_threat_level()

func set_threat_level():
	for hero_card in heroes:
		threat_level += hero_card.data.threat

	ui_threat.text = str(threat_level)

func shuffle():
	decklist.cards.shuffle()

func draw(n: int) -> Array[CardData]:
	return decklist.cards.slice(0, n, 1)

func setup_heroes():
	for i in decklist.heroes.size():
		var card: Card = Card.create(decklist.heroes[i], Card.Zone.BATTLEFIELD, scenario, self, hand, camera)
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
			var to_pay = max(hero.get_resources(), cost)
			hero.remove_resources(to_pay)
			paid -= to_pay
			if (paid == cost):
				break

	resources[sphere] -= cost

func try_to_play(card: Card):
	if (resources.get(card.data.sphere, 0) >= card.data.cost):
		remove_resources(card.data.sphere, card.data.cost)
		card.reparent(allies_area, false)
		card.position = Vector3.ZERO
		card.rotation = Vector3.ZERO
		card.scale = Vector3.ONE
		card.zone = Card.Zone.BATTLEFIELD
		card.state = Card.State.REST
		allies.append(card)
		hand.cards.erase(card)
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
	print("Resolving effect to player")
	var affected_cards: Array[Card] = []
	for applies_to in effect.applies_to: 
		affected_cards.append_array(get_affected_cards(applies_to))
	
	affected_cards.map(func(card: Card): card.apply_stats_effect(effect))
	#print(affected)
