extends Node2D


@export var bullet_damage = 100


@onready var area: Area2D = $Area2D
@onready var bullet_visuals = $Polygon2D#REPLACE W/ PARTICLES NODE IF I ADD THEM
@onready var b_sound: AudioStreamPlayer2D = $bullet_sound



var velocity : Vector2 = Vector2.ZERO
var shooter_name : String = ""

func _ready():
	GDSync.expose_func(queue_free)


func _multiplayer_ready() -> void:
#	_multiplayer_ready() is called when instantiating this node using a NodeInstaniator
#	_multiplayer_ready() is called after all variables are synchronized. This is not the case yet during _ready()
	#area.body_entered.connect(_on_body_entered)
	look_at(global_position + velocity)
	b_sound.pitch_scale = randfn(1.0, 0.1)
	b_sound.play()
	$life_time.start()
	$fragments2.emitting = true
	


func _physics_process(delta: float) -> void:
	if !GDSync.is_host(): return
	var target_position = global_position + velocity * delta
	global_position = global_position.lerp(target_position, 0.1)






func destroy_bullet():
#	Destroy the bullet locally
	queue_free()
	
#	Destroy the bullet on other clients
	GDSync.call_func(queue_free)


func _on_life_time_timeout():
	print("life out")
	destroy_bullet()


func _on_area_2d_body_entered(body):
	if body.name == shooter_name:
		return
	
	if body.is_in_group("damageables"):
		body.damage(bullet_damage)

	explode()




func explode():
	$Area2D/CollisionPolygon2D.call_deferred("set_disabled", true)
	$explode.emitting = true
	$Polygon2D.visible = false
	$PointLight2D.visible = false
	$fragments2.visible = false



func _on_explode_finished():
	print("fragments finished")
	destroy_bullet()


func _on_trail_start_time_timeout():
	$fragments2.emitting = true
