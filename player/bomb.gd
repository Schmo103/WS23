extends RigidBody2D

signal bomb_hit

var shooter_name : String = ""
var bomb_damage = 50

func _ready():
	GDSync.expose_func(destroy_bomb)
	GDSync.expose_func(queue_free)
	GDSync.expose_func(blow_up)
	
func launch(speed,direction):
	var impulse = Vector2(speed, 0).rotated(direction)
	apply_impulse(impulse, Vector2.ZERO)
	print("launched")


@warning_ignore("unused_parameter")
func _integrate_forces(state):
	pass

func blow_up():
	GDSync.call_func(blow_up)
	var raycast = $does_hit  # Assuming the RayCast2D node is a child of the current node
	var player_hit  # Get the object the raycast is colliding with
	for body in $damage_zone.get_overlapping_bodies():
		if body.is_in_group("damageables"):
			#if body.name == shooter_name:
				#break
			# Set the raycast target position to the player
			raycast.target_position = to_local(body.global_position)
			raycast.force_raycast_update()
			player_hit  = raycast.get_collider()
			if body == player_hit:  # Only deal damage if the raycast hits the player
				if body in $kill_zone.get_overlapping_bodies():  # Check if the player is in the kill zone
					raycast.force_raycast_update()
					body.damage(bomb_damage * 2)  # Deal double damage
					print(body)
					print("normal dmg times two")
					emit_signal("bomb_hit")
				else:
					raycast.force_raycast_update()
					print(body)
					body.damage(bomb_damage)
					print("normal dmg")
					emit_signal("bomb_hit")
			else:
				print("body, player_hit: ", body,", ", player_hit)

	$AnimationPlayer.play("explode")
	$Timer.start()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "explode":
		destroy_bomb()

func destroy_bomb():
	queue_free()
	GDSync.call_func(queue_free)

@warning_ignore("unused_parameter")
func damage(amnt):
	blow_up()

func _on_timer_timeout():
	destroy_bomb()
