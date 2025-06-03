class_name Deck
extends Node3D

var decklist: Array[CardData]
var cards: Array[Card]

func setup(scenario: Scenario, _decklist: Array[CardData]):
	decklist = _decklist
	for card_data: CardData in decklist:
		var card_node: Card = Card.create(card_data, Card.Zone.DECK, scenario)
		card_node.rotation_degrees.z = 180  # Face down while in the deck
		cards.append(card_node)
		add_child(card_node)
	 
	shuffle()

func shuffle():
	cards.shuffle()

func draw(n: int) -> Array[Card]:
	return cards.slice(0, n, 1)

func find_by_name(_name: String) -> Card:
	return cards.filter(func(card: Card): return card.data.name == _name)[0]

#func reveal(n: int):
	
	
	
