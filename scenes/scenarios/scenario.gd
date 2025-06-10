class_name Scenario
extends Node3D

signal end_of_phase
signal end_of_round

@export var scenario_data: ScenarioData

@onready var player: Player = $Player
@onready var encounter_deck: Deck = $EncounterDeck
@onready var quests_area: Marker3D = $QuestsArea
@onready var ui: ScenarioUI = $UI
@onready var ability_controller: AbilityController = $AbilityController
@onready var staging_area: PlayArea = $StagingArea
@onready var instructions_label: Label = %InstructionsLabel
@onready var interaction_button: Button = %PassButton

var n_players: int = 1
var current_quest_index: int = 0
var current_quest: Card
var current_willpower: int = 0
var phase: Enums.TurnPhase = Enums.TurnPhase.None

func _ready():
	interaction_button.button_down.connect(on_interaction_button_down)
	
	player.added_to_questing.connect(on_added_to_questing)
	player.removed_from_questing.connect(on_removed_from_questing)
	
	setup()
	enter_phase(Enums.TurnPhase.Resource)

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

func enter_phase(_phase: Enums.TurnPhase):
	if phase != Enums.TurnPhase.None:
		end_of_phase.emit()

	phase = _phase
	ui.set_turn_phase(phase)

	match phase:
		Enums.TurnPhase.Resource:
			resource_phase()
			await get_tree().create_timer(0.5).timeout
			enter_phase(Enums.TurnPhase.Planning)

		Enums.TurnPhase.Planning:
			pass

		Enums.TurnPhase.Quest:
			ui.show_questing_panel()
			ui.set_willpower(0)
			ui.set_questing_threat(staging_area.current_threat_value())
			interaction_button.text = "CONFIRM"

			player.enter_quest_selection()

		Enums.TurnPhase.Travel:
			interaction_button.text = "PASS"
			
			ui.hide_questing_panel()
			pass

		Enums.TurnPhase.Encounter:
			pass

		Enums.TurnPhase.Combat:
			pass

		Enums.TurnPhase.Refresh:
			player.ready_all()

		_:
			print("Unhandled phase: " + str(phase))

func resource_phase():
	player.resource_phase()
	
func _input(_event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func on_interaction_button_down():
	match phase:
		Enums.TurnPhase.Planning:
			enter_phase(Enums.TurnPhase.Quest)

		Enums.TurnPhase.Quest:
			resolve_questing()

		Enums.TurnPhase.Travel:
			enter_phase(Enums.TurnPhase.Encounter)
			
		Enums.TurnPhase.Encounter:
			enter_phase(Enums.TurnPhase.Combat)

		Enums.TurnPhase.Combat:
			enter_phase(Enums.TurnPhase.Refresh)
		
		Enums.TurnPhase.Refresh:
			enter_phase(Enums.TurnPhase.Resource)

func resolve_questing():
	var encounter_cards: Array[Card] = encounter_deck.draw(n_players)
	for encounter_card in encounter_cards:
		staging_area.add_card(encounter_card)

	var questing_progress = current_willpower - staging_area.current_threat_value()
	# Increase threat
	if questing_progress > 0:
		pass
	# Make progress on current quest
	elif questing_progress < 0:
		player.add_to_threat_level(-questing_progress)
		pass
	
	current_willpower = 0
	player.resolve_questing()
	enter_phase(Enums.TurnPhase.Travel)

func resolve_ability(ability: AbilityData, card: Card, _player: Player):
	ability_controller.resolve_ability(ability, self, card, _player)

func get_scenario_encounter_decklist() -> Array[CardData]:
	var encounter_decklist: Array[CardData]
	for card in CardDatabase.cards:
		if card.encounter_set in scenario_data.encounter_sets:
			for i in card.quantity:
				encounter_decklist.append(card)
	
	return encounter_decklist

func on_added_to_questing(card: Card):
	change_willpower(card.data.willpower)
	
func on_removed_from_questing(card: Card):
	change_willpower(-card.data.willpower)
	
func change_willpower(delta: int):
	current_willpower += delta
	ui.set_willpower(current_willpower)
