class_name PlayerHealthBar
extends ProgressBar
var last_value = 1
var target_value = 1

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	self.value = (last_value + target_value)/2
	last_value = self.value
	
func _on_player_health_changed(hp, max) -> void:
	target_value = hp / max
