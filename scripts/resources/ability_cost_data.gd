class_name AbilityCostData
extends Resource

enum CostType {
	EXAUST_SELF,
	EXAUST_CHARACTER,
	EXAUST_HERO,
	RESOURCE
}

@export var cost_type: CostType
@export var amount: int
