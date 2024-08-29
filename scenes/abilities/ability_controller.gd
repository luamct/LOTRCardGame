class_name AbilityController
extends Node

func resolve_ability(ability: AbilityData, scenario: Scenario, card: Card, player: Player):
	
	#if ability.turn_phase != null && ability.turn_phase
	var cannot_pay_all_costs: bool = false
	var unmet_costs_messages = unmet_costs(ability.costs, card)
	if not unmet_costs_messages.is_empty():
		print("Cannot activate ability:")
		for message in unmet_costs_messages:
			print("\t", message)
			
	pay_costs(ability.costs, card)
	
	resolve_effects(ability, card, player)
	

func unmet_costs(costs: Array[AbilityCostData], card: Card) -> Array[String]:
	var unmet_costs_messages: Array[String] = []
	for cost: AbilityCostData in costs:
		match cost.cost_type:
			AbilityCostData.CostType.EXAUST_SELF:
				if card.exausted:
					unmet_costs_messages.append("Card is already exausted")

			AbilityCostData.CostType.RESOURCE:
				pass

	return unmet_costs_messages

func pay_costs(costs: Array[AbilityCostData], card: Card):
	for cost: AbilityCostData in costs:
		match cost.cost_type:
			AbilityCostData.CostType.EXAUST_SELF: 
				card.exaust()

			AbilityCostData.CostType.RESOURCE:
				pass

func resolve_effects(ability: AbilityData, card: Card, player: Player):
	for effect: AbilityEffectData in ability.effects:
		match effect.effect_type:
			AbilityEffectData.EffectType.DAMAGE: pass
			AbilityEffectData.EffectType.QUEST_STAT: 
				player.apply_stats_effect(effect)
				
			AbilityEffectData.EffectType.COST_STAT: pass
			AbilityEffectData.EffectType.ATTACK_STAT: pass
			AbilityEffectData.EffectType.DEFENSE_STAT: pass
			AbilityEffectData.EffectType.HEALTH_STAT: pass
			AbilityEffectData.EffectType.THREAT_STAT: pass
			AbilityEffectData.EffectType.READY: pass
			AbilityEffectData.EffectType.HEAL: pass
			AbilityEffectData.EffectType.DRAW: pass
			
			_: print("Unknown effect type: ", effect)
	
	
	
