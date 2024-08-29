class_name AbilityData
extends Resource

enum TargetType {
	PLAYER,
	CHARACTER,
	HERO,
	ALLY,
	ENEMY,
	LOCATION
}

enum AbilityType {
	ACTIVATED,
	RESPONSE,
	FORCED
}

@export var type: AbilityType
@export var turn_phase: Enums.TurnPhase
@export var costs: Array[AbilityCostData]
@export var targets: Array[AbilityData.TargetType]
@export var effects: Array[AbilityEffectData]
