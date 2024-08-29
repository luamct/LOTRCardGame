extends Node

@export var card_sets: Dictionary

func _ready():
	var file = FileAccess.open("res://assets/database/jsons/Revised Core Set.json", FileAccess.READ)
	var content = file.get_as_text()
	var cards_json = JSON.parse_string(content)

	var database: Database = Database.new()

	var MAX_CARDS = 200
	for i  in cards_json.slice(0, MAX_CARDS).size():
		var card_json: Dictionary = cards_json[i]

		var card: CardData = CardData.new()
		card.name = card_json["name"]
		card.set_ = card_json["set"]
		card.type = card_json["type"]
		card.id = card_json["id"]
		card.encounter_set = card_json.get("encounter_set", "")
		card.sphere = card_json.get("sphere_name", "")
		card.cost = parse_cost(card_json.get("cost", "0"))
		card.threat = card_json.get("threat", 0)
		card.threat_cost = card_json.get("threat_cost", 0)
		card.quest_points = card_json.get("quest_points", 0)
		card.willpower = card_json.get("willpower", 0)
		card.attack = card_json.get("attack", 0)
		card.defense = card_json.get("defense", 0)
		card.health = card_json.get("health", 0)
		card.text = card_json.get("text", "")
		card.shadow = card_json.get("shadow", "")
		
		ResourceSaver.save(card, "res://assets/resources/cards/%s/%s.tres" % [card.set_, card.id])
		database.cards[card.name] = card

	ResourceSaver.save(database, "res://assets/resources/database.tres")

	get_tree().quit()

func parse_cost(cost: String):
	return -1 if cost == "X" else int(cost)

func load_set(_name: String) -> CardSetData:
	return load("res://assets/resources/sets/%s.tres" % _name) as CardSetData
