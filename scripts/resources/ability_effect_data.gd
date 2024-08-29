class_name AbilityEffectData
extends Resource

enum EffectType {
	DAMAGE,
	QUEST_STAT,
	COST_STAT,
	ATTACK_STAT,
	DEFENSE_STAT,
	HEALTH_STAT,
	THREAT_STAT,
	READY,
	HEAL,
	DRAW
}

enum EffectDuration {
	END_OF_PHASE,
	END_OF_ROUND,
	INSTANT
}

@export var effect_type: EffectType
@export var applies_to: Array[AbilityData.TargetType]
@export var duration: EffectDuration
@export var amount: int
