class_name Scenario
extends Node3D

signal end_of_phase
signal end_of_round

@export var scenario: ScenarioData

@onready var player: Player = $Player
@onready var encounter_deck: Deck = $EncounterDeck
@onready var quests_area: Marker3D = $QuestsArea
@onready var ui: ScenarioUI = $UI/TurnPhases
@onready var ability_controller: AbilityController = $AbilityController

var phase: Enums.TurnPhase = Enums.TurnPhase.None

func _ready():
	setup()
	phase = Enums.TurnPhase.Resource
	ui.set_turn_phase(phase)

func setup():
	player.setup()

	var instance: Card = Card.create(scenario.quest_cards[0], Card.Zone.BATTLEFIELD, self, player)
	quests_area.add_child(instance)

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
