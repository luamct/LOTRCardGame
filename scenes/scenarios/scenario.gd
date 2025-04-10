class_name Scenario
extends Node3D

signal end_of_phase
signal end_of_round

@export var scenario_data: ScenarioData

@onready var player: Player = $Player
@onready var encounter_deck: Deck = $EncounterDeck
@onready var quests_area: Marker3D = $QuestsArea
@onready var ui: ScenarioUI = $UI/TurnPhases
@onready var ability_controller: AbilityController = $AbilityController
@onready var staging_area: PlayArea = $StagingArea

var current_quest_index: int = 0
var current_quest: Card
var phase: Enums.TurnPhase = Enums.TurnPhase.None

func _ready():
	setup()
	phase = Enums.TurnPhase.Resource
	ui.set_turn_phase(phase)

func setup():
	player.setup()
	encounter_deck.setup(self, get_scenario_encounter_decklist())
	
	open_next_quest_card()

func open_next_quest_card():
	var quest_card: Card = Card.create(
		scenario_data.quest_cards[current_quest_index], 
		Card.Zone.BATTLEFIELD, 
		self)
	
	for effect in quest_card.data.effects_a:
		await resolve_effect(effect)
	
	current_quest = quest_card
	quests_area.add_child(quest_card)

func resolve_effect(effect: QuestEffectData):
	match effect.effect_type:
		QuestEffectData.EffectType.SEARCH_AND_ADD_TO_STAGING:
			var card: Card = encounter_deck.find_by_name(effect.card_name)
			staging_area.add_card(card)

func go_to_phase(_phase: Enums.TurnPhase):
	end_of_phase.emit()
	phase = _phase
	ui.set_turn_phase(phase)

func _process(delta):
	match phase:
		Enums.TurnPhase.Resource:
			resource_phase()
			go_to_phase(Enums.TurnPhase.Planning)

		Enums.TurnPhase.Planning:
			pass

		Enums.TurnPhase.Quest:
			pass

		Enums.TurnPhase.Travel:
			pass

		Enums.TurnPhase.Encounter:
			pass

		Enums.TurnPhase.Combat:
			pass

		Enums.TurnPhase.Refresh:
			pass

		_:
			print("Unhandled phase: " + str(phase))

func resource_phase():
	player.resource_phase()
	
func _input(_event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _on_pass_button_button_down():
	match phase:
		Enums.TurnPhase.Planning:
			go_to_phase(Enums.TurnPhase.Quest)
		
		Enums.TurnPhase.Quest:
			go_to_phase(Enums.TurnPhase.Travel)

		Enums.TurnPhase.Travel:
			go_to_phase(Enums.TurnPhase.Encounter)
			
		Enums.TurnPhase.Encounter:
			go_to_phase(Enums.TurnPhase.Combat)

		Enums.TurnPhase.Combat:
			go_to_phase(Enums.TurnPhase.Refresh)
		
		Enums.TurnPhase.Refresh:
			go_to_phase(Enums.TurnPhase.Resource)

func resolve_ability(ability: AbilityData, card: Card, _player: Player):
	ability_controller.resolve_ability(ability, self, card, _player)

func get_scenario_encounter_decklist() -> Array[CardData]:
	var encounter_decklist: Array[CardData]
	for card in CardDatabase.cards:
		if card.encounter_set in scenario_data.encounter_sets:
			for i in card.quantity:
				encounter_decklist.append(card)
	
	return encounter_decklist
