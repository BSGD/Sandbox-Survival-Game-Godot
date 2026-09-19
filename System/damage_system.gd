class_name DamageSystem
extends RefCounted

enum DamageType {
	PHYSICAL,
	FIRE,
}

class Attack:
	var damage: float
	var type: int
	var ap: float  # armor penetration

	func _init(p_damage: float, p_type: int, p_ap: float = 0.0) -> void:
		damage = p_damage
		type = p_type
		ap = p_ap


class HealthComponent:
	var max_hp: float
	var max_shield: float
	var shield_regen: float
	var hp_regen: float
	var armor: Dictionary  # DamageType -> armor value

	var hp: float
	var shield: float

	func _init(
		p_max_hp: float,
		p_max_shield: float,
		p_shield_regen: float,
		p_hp_regen: float,
		p_armor: Dictionary,
		p_start_hp: float = -1,
		p_start_shield: float = -1
	) -> void:
		max_hp = p_max_hp
		max_shield = p_max_shield
		shield_regen = p_shield_regen
		hp_regen = p_hp_regen
		armor = p_armor

		hp = max_hp if p_start_hp < 0 else p_start_hp
		shield = max_shield if p_start_shield < 0 else p_start_shield

	
	const ARMOR_CURVE_K: float = 0.4394449154672066
	const ARMOR_CURVE_MIDPOINT: float = 10.0

	
	const REGEN_COOLDOWN: float = 3.0
	var time_since_damage: float = REGEN_COOLDOWN

	static func armor_reduction(effective_armor: float) -> float:
		return 1.0 / (1.0 + exp(-ARMOR_CURVE_K * (effective_armor - ARMOR_CURVE_MIDPOINT)))

	func apply_attack(attack: Attack) -> void:
		var armor_value: float = armor.get(attack.type, 0)
		# Armor penetration reduces effective armor, clamped so it can never go negative.
		var effective_armor: float = maxf(armor_value - attack.ap, 0.0)
		var reduction: float = armor_reduction(effective_armor)
		var mitigated_damage: float = attack.damage * (1.0 - reduction)

		if shield > 0:
			var shield_damage: float = minf(shield, mitigated_damage)
			shield -= shield_damage
			mitigated_damage -= shield_damage

		hp = maxf(hp - mitigated_damage, 0.0)
		time_since_damage = 0.0

	func heal(amount: float) -> void:
		hp = minf(hp + amount, max_hp)

	func regen(delta: float) -> void:
		time_since_damage += delta
		if time_since_damage < REGEN_COOLDOWN:
			return
		if hp < max_hp and hp_regen > 0:
			hp = minf(hp + hp_regen * delta, max_hp)
		if shield < max_shield and shield_regen > 0:
			shield = minf(shield + shield_regen * delta, max_shield)
