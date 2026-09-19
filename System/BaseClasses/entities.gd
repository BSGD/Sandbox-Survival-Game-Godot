class_name Entity extends Resource
signal OnDeath
signal OnDamage(dmg: float)

var health: float = 1.0
var armor: float = 0

func damage(dmg: float) -> void:
	health = maxf(health - dmg, 0.0)
	OnDamage.emit(dmg)
	if is_zero_approx(health):
		OnDeath.emit()
