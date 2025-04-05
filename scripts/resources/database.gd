class_name Database
extends Resource

@export var cards: Array[CardData]
@export var cards_by_name: Dictionary

func add_card(card: CardData):
	cards.append(card)
	cards_by_name[card.name] = card

func card_by_name(name: String):
	return cards_by_name[name]
