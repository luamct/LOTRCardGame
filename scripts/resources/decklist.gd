class_name DeckList
extends Resource

var name: String
var heroes: Array[CardData]
@export var cards: Array[CardData]

@export_multiline var decklist: String

func load():
	if cards.size() == 0:
		parse_decklist()
	
	return cards

func parse_hero(hero_line: String) -> String:
	var regex = RegEx.new()
	regex.compile("(.*?)\\s+\\((.*?)\\)")
	var result = regex.search(hero_line)
	return result.get_string(1)

func parse_card(hero_line: String) -> String:
	var regex = RegEx.new()
	regex.compile("(\\d+x)\\s+(.*?)\\s+\\((.*?)\\)")
	var result = regex.search(hero_line)
	return result.get_string(2)

func parse_decklist():
	var lines = decklist.split("\n") #.filter(func(line): return line != "")
	name = lines[0]

	# print("Parsing hero line: %s" % lines[2])
	heroes.append(CardDatabase.cards[parse_hero(lines[2])])
	heroes.append(CardDatabase.cards[parse_hero(lines[3])])
	heroes.append(CardDatabase.cards[parse_hero(lines[4])])

	for line in lines.slice(6, -1):
		var card: CardData = CardDatabase.cards[parse_card(line)]
		cards.append(card)
