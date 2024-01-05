extends Node2D

@onready var anim_explode = $AnimationPlayer

func animation_explode():
	anim_explode.play("explode")

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = true
	explode()


func explode():
	$AnimationPlayer.play("explode")

@warning_ignore("unused_parameter")
func _on_animation_player_animation_finished(anim_name):
	$Timer.start()


func _on_timer_timeout():
	explode()
