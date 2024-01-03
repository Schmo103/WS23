extends CharacterBody2D


signal health_changed(target,new)
signal player_died(player)


@export var bullet_speed = 15000.0

@onready var b_instantiator : Node = $bullet_instantiator

@export var overheat_time_limit : float = 2.5
@export var overheat_timer : float = 0.0
@export var cooldown_time : float = 5
@export var cooldown_timer : float = 0.0
@export var cooldown_factor : float = 3.0
var overheated = false
var weapon_charged = true

@onready var cooldown_timer_node = $cooldown_timer

@export var speed = 350
@export var friction = 0.16
@export var acceleration = 0.1

@export var full_health = 85
@export var health = 85
@export var min_health = 20

@onready var skin_1 = $visuals/skin_1
@onready var skin_2 = $visuals/skin_2
@onready var animation_player = $public_animations  # Reference to the AnimationPlayer node
@onready var p_animation_player = $private_animations


func _ready():
	if !GDSync.is_gdsync_owner(self): $player_ui/CanvasLayer/Control/health_low.visible = false
	if !GDSync.is_gdsync_owner(self): $player_ui/CanvasLayer/Control/damage.visible = false
	if GDSync.is_gdsync_owner(self):
		skin_1.visible = true
		skin_2.visible = false
	else:
		skin_1.visible = false
		skin_2.visible = true
	
	
	
	GDSync.expose_func(damage)
	#GDSync.expose_func(death)
	set_multiplayer_data.call_deferred()


func set_multiplayer_data():
	var client_id : int = name.to_int()
	$user_label.text = GDSync.get_player_data(client_id, "Username", "Unkown")
	if !GDSync.is_gdsync_owner(self): return
	print("player client id is: =")
	print(client_id)

func get_input():
	var input = Vector2()
	if Input.is_action_pressed("player_right"):
		input.x += 1
	if Input.is_action_pressed("player_left"):
		input.x -= 1
	if Input.is_action_pressed("player_down"):
		input.y += 1
	if Input.is_action_pressed("player_up"):
		input.y -= 1
	return input


func _physics_process(delta):
	if !GDSync.is_gdsync_owner(self): return
	
	#print("Overheat Timer:", overheat_timer)
	#print("Cooldown Timer:", cooldown_timer)
	#print("Shooting:", shooting)
	
	if Input.is_action_just_pressed("pause"):
		if !paused:
			pause()
		else:
			unpause()
	
	if dead:
		if Input.is_action_just_pressed("respawn"):
			respawn()
	
	if !dead:
		var direction = get_input()
		if direction.length() > 0:
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
			animate("walk")
		else:
			velocity = velocity.lerp(Vector2.ZERO, friction)
			animate("RESET")  # Stop the animation
		
		# Add rotation towards the mouse
		var mouse_pos = get_global_mouse_position()
		var angle_to_mouse = position.angle_to_point(mouse_pos)
		$visuals.rotation = angle_to_mouse - PI +0.13  # Adjust the rotation
		$CollisionPolygon2D.rotation = angle_to_mouse - PI +0.13  # Adjust the rotation

		move_and_slide()
		
		if Input.is_action_pressed("shoot") and !overheated and !shooting and weapon_charged:
			shoot()
		#if !overheated and !weapon_charged:
			#overheat_timer = min(overheat_time_limit, overheat_timer + delta)
		#if !overheated and weapon_charged:
			#overheat_timer = max(0, overheat_timer - delta)
		if !overheated:
			if weapon_charged:
				overheat_timer = max(0, overheat_timer - delta)
			else:
				overheat_timer = min(overheat_time_limit, overheat_timer + delta)
		
		if overheat_timer >= overheat_time_limit:
			overheated = true
			$"player_ui/CanvasLayer/Control/overheated!".visible = true
			cooldown_timer_node.start(cooldown_time)
			overheat_timer = 0
			$overheat_sound.play()
		
		update_progress_bar()
		shooting = false
		


var shooting = false
func shoot() -> void:
	shooting = true
#	Instantiate a bullet using the NodeInstantiator
#	The NodeInstantiator will automatically spawn it on all other clients
	var bullet : Node = b_instantiator.instantiate_node()
	
#	Set all bullet properties. The NodeInstantiator will automatically detect
#	all changes made to the bullet in this frame and synchronize them
	bullet.shooter_name = name
	var origin := global_position + Vector2.UP
	# Add rotation towards the mouse
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = position.angle_to_point(mouse_pos)
	# Convert the angle to a Vector2 and multiply by bullet_speed
	bullet.velocity = Vector2.RIGHT.rotated(angle_to_mouse) * bullet_speed
	bullet.distance_limit = 14.0
	bullet.global_position = origin
	Global.emit_signal("walk_screen_shake")
	animate("shoot")
	weapon_charged = false
	$shoot_timer.start()



var old
var new
var taking_dmg = false
var low_health = false
func damage(dmg):
	print("damage taken: ",dmg)
	old = health
	health -= dmg
	new = health
	if new <= min_health:
		if !dying:
			health = min_health
			new = min_health
			old = min_health
			death()
			#GDSync.call_func(death)
	if health <= 30:
		if !low_health:
			low_health = true
			private_animate("low_health")
	else:
		health_changed.emit(name.to_int(), new)
		taking_dmg = true
		animate("damage")

var dying = false
func death():
	if GDSync.is_gdsync_owner(self):
		animation_player.play("death")
		dying = true
		private_animate("full_health")

func animate(request):
	if !GDSync.is_gdsync_owner(self): return
	if request == "walk":
		if !shooting:
			animation_player.play("walk")
	elif request == "shoot":
		if !taking_dmg:
			animation_player.play("shoot")
	elif request == "damage":
		if !dying:
			if low_health:
				shooting = false
				animation_player.queue("damage")
			else:
				shooting = false
				animation_player.play("damage")
	elif request == "RESET":
		if !dying:
			if !taking_dmg:
				if !shooting:
					animation_player.play("RESET")  # Stop the animation
	#animation_player.queue(request)

func private_animate(request):
	if !GDSync.is_gdsync_owner(self): return
	if request == "low_health":
		p_animation_player.play("low_health")
	if request == "full_health":
		p_animation_player.play("full_health")


var dead = false
var death_position
func _on_animation_player_animation_finished(anim_name):
	if GDSync.is_gdsync_owner(self):
		if anim_name == "death":
			dying = false
			death_position = position
			emit_signal("player_died",self)
			$player_ui/CanvasLayer/Control/death_label.visible = true
			dead = true
		if anim_name == "damage":
			taking_dmg = false
		#if anim_name == "shoot":
			#shooting = false
			##update_progress_bar()


func update_progress_bar():
	var progress_value = 0.0

	if overheat_timer > 0:
		progress_value = min(1.0, overheat_timer / overheat_time_limit)
		#print("overheat_timer > 0")
	elif cooldown_timer > 0:
		progress_value = 1.0 - min(1.0, cooldown_timer / cooldown_time)
		#print("cooldown_timer > 0")

 # Consider values close to 0 as 0
	if abs(progress_value) < 0.0001:
		progress_value = 0.0

	# Update the progress bar
	$player_ui/CanvasLayer/Control/overheat.value = (progress_value * 10)
	#print(progress_value)

func respawn():
	if GDSync.is_gdsync_owner(self):
		dead = false
		dying = false
		low_health = false
		$player_ui/CanvasLayer/Control/death_label.visible = false
		#$player_ui/CanvasLayer/Control/TextureRect.visible = false
		health = full_health
		new = full_health
		old = full_health
		position = death_position
		health_changed.emit(name.to_int(), new)
		taking_dmg = false
		animate("RESET")
		#private_animate("full_health")


var paused = false
func pause():
	paused = true
	

func unpause():
	paused = false
	


func _on_cooldown_timer_timeout():
	overheated = false
	overheat_timer = 0
	$"player_ui/CanvasLayer/Control/overheated!".visible = false
	print("cooldown_timer_timeout")
	$cooldown_sound.play()


func _on_shoot_timer_timeout():
	weapon_charged = true
	#print("weapon charged")


func _on_resume_pressed():
	unpause()
