class_name ScenarioUI
extends CanvasLayer

@onready var turn_highlight = $TurnHighlight
@onready var instructions_label: Label = %InstructionsLabel
@onready var questing_panel: PanelContainer = $QuestingPanel

@onready var threat_value: Label = %ThreatValue
@onready var quest_power_value: Label = %QuestPowerValue

const quest_instructions := "Choose characters to go Questing"

@onready var phase_labels = {
	Enums.TurnPhase.Resource: find_child("Resource"),
	Enums.TurnPhase.Planning: find_child("Planning"),
	Enums.TurnPhase.Quest: find_child("Quest"),
	Enums.TurnPhase.Travel: find_child("Travel"),
	Enums.TurnPhase.Encounter: find_child("Encounter"),
	Enums.TurnPhase.Combat: find_child("Combat"),
	Enums.TurnPhase.Refresh: find_child("Refresh")
}

func set_turn_phase(phase: Enums.TurnPhase) :
	turn_highlight.global_position.y = phase_labels[phase].global_position.y - 8
	
	instructions_label.text = ""
	
	match phase:
		Enums.TurnPhase.Quest:
			instructions_label.text = quest_instructions

func set_willpower(power: int):
	quest_power_value.text = str(power)
	
func set_questing_threat(threat: int):
	threat_value.text = str(threat)
	
func show_questing_panel():
	questing_panel.visible = true

func hide_questing_panel():
	questing_panel.visible = false
