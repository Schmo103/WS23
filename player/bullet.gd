extends Node2D


@export var scale_decay: Curve
@export var distance_limit: float = 5.0

@onready var area: Area2D = $Area2D
@onready var bullet_visuals = $Polygon2D#REPLACE W/ PARTICLES NODE IF I ADD THEM
@onready var b_sound: AudioStreamPlayer2D = $bullet_sound



var velocity : Vector2 = Vector2.ZERO
var shooter_name : String = ""

func _ready():
	GDSync.expose_func(queue_free)
	$life_time.start()
	


func _multiplayer_ready() -> void:
#	_multiplayer_ready() is called when instantiating this node using a NodeInstaniator
#	_multiplayer_ready() is called after all variables are synchronized. This is not the case yet during _ready()
	#area.body_entered.connect(_on_body_entered)
	look_at(global_position + velocity)
	b_sound.pitch_scale = randfn(1.0, 0.1)
	b_sound.play()
	


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
	destroy_bullet()


func _on_area_2d_body_entered(body):
	if body.name == shooter_name:
		return

	# Check if the collided body is a wall (modify this condition accordingly)
	if body.is_in_group("walls"):
		# Get the collision point in local coordinates of the wall
		var local_collision_point = body.to_local(area.global_position)

		# Trigger point fracture at the collision point
		perform_point_fracture(local_collision_point)

	destroy_bullet()

# Add this function to perform point fracture
func perform_point_fracture(fracture_point: Vector2) -> void:
	# Instantiate the PolygonFracture script
	var fracture_script = preload("res://polygon_fracture/PolygonFracture.gd").new()

	# Call the point fracture method from PolygonFracture
	fracture_script.point_fracture(fracture_point)

	# Destroy the fracture script after use
	fracture_script.queue_free()
