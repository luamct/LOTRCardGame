class_name Deck
extends Node3D

var cards: Array[CardData]


func _ready():
	pass # Replace with function body.


func _process(delta):
	pass


func setup(_cards: Array[CardData]):
	cards = _cards
	shuffle()


func shuffle():
	cards.shuffle()


func draw(n: int) -> Array[CardData]:
	return cards.slice(0, n, 1)
