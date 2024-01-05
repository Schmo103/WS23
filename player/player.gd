extends CharacterBody2D


signal health_changed(target,new)
signal player_died(player)


@export var bullet_speed = 15000.0
@onready var snipe_bullet_speed = bullet_speed * 2
@onready var bomb_speed = 1000

@onready var b_instantiator : Node = $bullet_instantiator
@onready var snipe_b_instantiator : Node = $snipe_bullet_instantiator
@onready var bomb_instantiator : Node = $bomb_instantiator

@export var overheat_time_limit : float = 2.5
@export var overheat_timer : float = 0.0
@export var cooldown_time : float = 3.5
@export var snipe_cooldown_time : float = 2.5
@export var bomb_cooldown_time : float = 1.5
@export var cooldown_timer : float = 0.0
@export var cooldown_factor : float = 3.0

@onready var cooldown_timer_node = $cooldown_timer

@export var speed = 350
@export var friction = 0.16
@export var acceleration = 0.1

@export var full_health = 85
@export var health = 85
@export var min_health = 0
@export var danger_health = 30

@onready var auto_skin = $visuals/animationer/auto
@onready var sniper_skin = $visuals/animationer/sniper
@onready var heavy_skin = $visuals/animationer/heavy
@onready var animation_player = $public_animations  # Reference to the AnimationPlayer node
@onready var p_animation_player = $private_animations

@onready var bomb_spawn_pos = %bomb_spawn

# This represents the player's inertia.
var push_force = 80.0

var overheated = false
var weapon_charged = true

var shooting = false
var bomb_launched = false
var detonating = false

var KILL_COUNT = 0

var old
var new
var taking_dmg = false
var low_health = false

var dying = false

var dead = false
var death_position

var dom_game_time = 300
var dm_game_time = 60

var player_class

func _ready():
	if !GDSync.is_gdsync_owner(self): $player_ui/CanvasLayer/Control/health_low.visible = false
	if !GDSync.is_gdsync_owner(self): $player_ui/CanvasLayer/Control/damage.visible = false
	
	if Global.game_mode == 2:#DOMINATION
		#%Panel.visible = true
		#%domination.visible = true
		%time.text = str(dom_game_time)
		Global.dom_timer.start(dom_game_time)
		%domination.visible = true
		%deathmatch.visible = false
	
	if Global.game_mode == 1:
		%time.text = str(dm_game_time)
		Global.dom_timer.start(dm_game_time)
		%domination.visible = false
		%deathmatch.visible = true
	
	Global.all_players.append(self)
	
	death_position = position
	
	GDSync.expose_func(damage)
	GDSync.expose_func(detonate_bomb)
	GDSync.expose_func(sync_impulses)
	GDSync.expose_func(board_update)
	#GDSync.expose_func(death)
	set_multiplayer_data.call_deferred()

func set_multiplayer_data():
	var client_id : int = name.to_int()
	$user_label.text = GDSync.get_player_data(client_id, "Username", "Unkown")
	player_class = GDSync.get_player_data(client_id,"class")
	#if !GDSync.is_gdsync_owner(self): return
	if player_class == "auto":
		auto_skin.visible = true
		sniper_skin.visible = false
		heavy_skin.visible = false
	elif player_class == "sniper":
		auto_skin.visible = false
		sniper_skin.visible = true
		heavy_skin.visible = false
	elif player_class == "heavy":
		auto_skin.visible = false
		sniper_skin.visible = false
		heavy_skin.visible = true

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

func board_update(tm,new_score):
	#print(GDSync.get_client_id()," board update")
	#print("new: ", new_score," tm: ", tm)
	if tm == 1:
		%t1_score.text = str(new_score)
		#print("1, ",new_score)
	elif tm == 2:
		%t2_score.text = str(new_score)
		#print("2, ",new_score)
	elif tm == 3:
		%t3_score.text = str(new_score)
	elif tm == 4:
		%t4_score.text = str(new_score)
	else:
		print("bogus, client id: ",GDSync.get_client_id())
	#%t1_score.text = str(Global.t1_score)
	#%t2_score.text = str(Global.t2_score)

func other_score(player):
	if !Global.GAME_ENDED:
		if !GDSync.is_gdsync_owner(self): return
		#print("client ", GDSync.get_client_id(), "  OTHER scored!")
		if Global.t1 == GDSync.get_client_id():
			#Global.t1_score = int(%t1_score.text) + plus
			#Global.update_score(1,(int(%t1_score.text) + plus))
			board_update(2,(int(%t2_score.text) + plus))
			#print("other score counted as tm1")
			#GDSync.call_func(board_update,[1,(int(%t1_score.text) + plus)],true)
		if Global.t2 == GDSync.get_client_id():
			#Global.t2_score = int(%t2_score.text) + plus
			#Global.update_score(2,(int(%t2_score.text) + plus))
			board_update(1,(int(%t1_score.text) + plus))
			#print("other score counted as tm2")
			#GDSync.call_func(board_update,[2,(int(%t2_score.text) + plus)],true)
		if Global.t3 == GDSync.get_client_id():
			board_update(3,(int(%t3_score.text) + plus))
			#GDSync.call_func(board_update,[3,(int(%t3_score.text) + plus)])
		if Global.t4 == GDSync.get_client_id():
			board_update(4,(int(%t4_score.text) + plus))
			#GDSync.call_func(board_update,[4,(int(%t4_score.text) + plus)])

var plus = 1
func score():
	if !Global.GAME_ENDED:
		if !GDSync.is_gdsync_owner(self): return
		
		#print("client ", GDSync.get_client_id(), " scored!")
		if Global.t1 == GDSync.get_client_id():
			#Global.t1_score = int(%t1_score.text) + plus
			#Global.update_score(1,(int(%t1_score.text) + plus))
			board_update(1,(int(%t1_score.text) + plus))
			#GDSync.call_func(board_update,[1,(int(%t1_score.text) + plus)],true)
		if Global.t2 == GDSync.get_client_id():
			#Global.t2_score = int(%t2_score.text) + plus
			#Global.update_score(2,(int(%t2_score.text) + plus))
			board_update(2,(int(%t2_score.text) + plus))
			#GDSync.call_func(board_update,[2,(int(%t2_score.text) + plus)],true)
		if Global.t3 == GDSync.get_client_id():
			board_update(3,(int(%t3_score.text) + plus))
			#GDSync.call_func(board_update,[3,(int(%t3_score.text) + plus)])
		if Global.t4 == GDSync.get_client_id():
			board_update(4,(int(%t4_score.text) + plus))
			#GDSync.call_func(board_update,[4,(int(%t4_score.text) + plus)])

func overide_score(new_tm1,new_tm2):
	%t1_score.text = str(new_tm1)
	%t2_score.text = str(new_tm2)

func save_my_score():
	if !GDSync.is_gdsync_owner(self): return
	GDSync.set_player_data("kill_count", KILL_COUNT)

var king_slayer
func compare_all_scores():
	var highest_kills = null
	for client in Global.sorted_clients:
		#if is_instance_valid(client):
			print("comparing player_data")
			var client_kills = GDSync.get_player_data(client,"kill_count")
			if highest_kills == null:
				highest_kills = client_kills
				king_slayer = client
			else:
				if is_instance_valid(client):
					if client_kills > highest_kills:
						highest_kills = client_kills
						king_slayer = client
						print("king_slayer = client")

func victory():
	if !GDSync.is_gdsync_owner(self): return
	if Global.game_mode == 2:
		%loss.visible = false
		var tween := create_tween()
		tween.tween_property(%win, "modulate", Color.WHITE, 0.3)
		#get_tree().paused = true
		Global.GAME_ENDED = true
	else:
		%loss.visible = false
		%kills.visible = true
		var tween := create_tween()
		tween.tween_property(%win, "modulate", Color.WHITE, 0.3)
		var tween2 := create_tween()
		tween2.tween_property(%kills, "modulate", Color.WHITE, 0.3)
		#get_tree().paused = true
		Global.GAME_ENDED = true

func defeat():
	if !GDSync.is_gdsync_owner(self): return
	if Global.game_mode == 2:
		%win.visible = false
		var tween := create_tween()
		tween.tween_property(%loss, "modulate", Color.WHITE, 0.3)
		#get_tree().paused = true
		Global.GAME_ENDED = true
	else:
		%win.visible = false
		%kills.visible = true
		var tween := create_tween()
		tween.tween_property(%loss, "modulate", Color.WHITE, 0.3)
		var tween2 := create_tween()
		tween2.tween_property(%kills, "modulate", Color.WHITE, 0.3)
		#get_tree().paused = true
		Global.GAME_ENDED = true

func set_kill_count():
	if !GDSync.is_gdsync_owner(self): return
	if !dead:
		%kills.text = str(KILL_COUNT)

func game_over():
	if !GDSync.is_gdsync_owner(self): return
	if Global.game_mode == 2:
		dead = true
		var team
		if Global.t1 == GDSync.get_client_id():
			team = 1
		elif Global.t2 == GDSync.get_client_id():
			team = 2
		if int(%t1_score.text) > int(%t2_score.text):
			if team == 1:
				victory()
			else:
				defeat()
		else:
			if team == 2:
				victory()
			else:
				defeat()
	else:
		set_kill_count()
		save_my_score()
		compare_all_scores()
		if king_slayer == GDSync.get_client_id():
			victory()
			print("victory")
		else:
			defeat()
			print("defeat")
		dead = true

func _format_seconds(time : float, use_milliseconds : bool) -> String:
	var minutes := time / 60
	var seconds := fmod(time, 60)
	if not use_milliseconds:
		return "%02d:%02d" % [minutes, seconds]
	var milliseconds := fmod(time, 1) * 100
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func _physics_process(delta):
	if !GDSync.is_gdsync_owner(self): return
	
	%time.text = str(_format_seconds(Global.dom_timer.time_left,false))
	if Global.dom_timer.time_left == 0:
		game_over()
	#if !GDSync.is_host():
		#shoot()
	
	if dead:
		if Input.is_action_just_pressed("respawn"):
			respawn()
	
	if !dead:
		if !dying:
			var direction = get_input()
			if direction.length() > 0:
				velocity = velocity.lerp(direction.normalized() * speed, acceleration)
				animate("walk")
			else:
				velocity = velocity.lerp(Vector2.ZERO, friction)
				if !overheated:
					animate("RESET")  # Stop the animation
			
			# Add rotation towards the mouse
			var mouse_pos = get_global_mouse_position()
			var angle_to_mouse = position.angle_to_point(mouse_pos)
			$visuals.rotation = angle_to_mouse - PI +0.13  # Adjust the rotation
			$CollisionPolygon2D.rotation = angle_to_mouse - PI +0.13  # Adjust the rotation

			move_and_slide()
			
			sync_impulses()
			GDSync.call_func(sync_impulses)
			
			if player_class == "auto":
				if Input.is_action_pressed("shoot") and !overheated and !shooting and weapon_charged:
					shoot()
				if !overheated:
					if weapon_charged:
						overheat_timer = max(0, overheat_timer - delta * cooldown_factor)
					else:
						overheat_timer = min(overheat_time_limit, overheat_timer + delta)
				
				if overheat_timer >= overheat_time_limit:
					overheated = true
					$"player_ui/CanvasLayer/Control/overheated!".visible = true
					cooldown_timer_node.start(cooldown_time)
					overheat_timer = 0
					$overheat_sound.play()
					animate("overheat")
				
				update_progress_bar()
				shooting = false
				
			elif player_class == "sniper":
				# Sniper code
				if Input.is_action_pressed("shoot") and not overheated and not shooting and weapon_charged:
					# The player must hold down the "shoot" button for sniper
					if not shooting:
						shooting = true
						snipe()  # Call the snipe function when shooting starts
				elif shooting:
					# Stop shooting and trigger overheat when the shoot button is released
					shooting = false
					overheated = true
					$"player_ui/CanvasLayer/Control/overheated!".visible = true
					cooldown_timer_node.start(snipe_cooldown_time)
					overheat_timer = 0
					$overheat_sound.play()
					animate("overheat")

				# Overheat right after snipe() is called
				if shooting and overheat_timer >= overheat_time_limit:
					overheated = true
					$"player_ui/CanvasLayer/Control/overheated!".visible = true
					cooldown_timer_node.start(cooldown_time)
					overheat_timer = 0
					$overheat_sound.play()
					animate("overheat")

				update_progress_bar()
			
			elif player_class == "heavy":
				if Input.is_action_just_pressed("shoot") and !overheated and !shooting and weapon_charged:
					if !detonating or !is_instance_valid(bomb):
							if !is_instance_valid(bomb):
								detonating = false
								bomb = null
								bomb_launched = false
					if not bomb_launched:
							launch_bomb()  # Call the launch_bomb function when shooting starts
							bomb_launched = true
							overheated = true
							$"player_ui/CanvasLayer/Control/overheated!".visible = true
							cooldown_timer_node.start(bomb_cooldown_time)
							overheat_timer = 0
							$overheat_sound.play()
							animate("overheat")
					else:
						if detonating:
							detonate_bomb() 
							GDSync.call_func(detonate_bomb) # Detonate the bomb if one has been launc
							detonating = false

					# Overheat right after detonate_bomb() is called
					if shooting and overheat_timer >= overheat_time_limit:
						overheated = true
						$"player_ui/CanvasLayer/Control/overheated!".visible = true
						cooldown_timer_node.start(cooldown_time)
						overheat_timer = 0
						$overheat_sound.play()
						animate("overheat")

				update_progress_bar()
				shooting = false

func sync_impulses():
	for i in get_slide_collision_count():
				var c = get_slide_collision(i)
				if c.get_collider() is RigidBody2D:
					c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func shoot():
	shooting = true
#	Instantiate a bullet using the NodeInstantiator
#	The NodeInstantiator will automatically spawn it on all other clients
	var bullet : Node = b_instantiator.instantiate_node()
	bullet.bullet_hit.connect(on_bullet_hit)
#	Set all bullet properties. The NodeInstantiator will automatically detect
#	all changes made to the bullet in this frame and synchronize them
	bullet.shooter_name = name
	var origin := global_position + Vector2.UP
	# Add rotation towards the mouse
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = position.angle_to_point(mouse_pos)
	# Convert the angle to a Vector2 and multiply by bullet_speed
	bullet.velocity = Vector2.RIGHT.rotated(angle_to_mouse) * bullet_speed
	bullet.global_position = origin
	Global.emit_signal("walk_screen_shake",20)
	animate("shoot")
	weapon_charged = false
	$shoot_timer.start()

func on_bullet_hit():
	if !GDSync.is_gdsync_owner(self): return
	var kill = Global.check_for_kill()
	GDSync.call_func(Global.check_for_kill)
	print("bullet kill = ",kill)
	if kill == true:
		KILL_COUNT += 1
		set_kill_count()
		#print("kill")
		var tween := create_tween()
		tween.tween_property(%kills, "modulate", Color.WHITE, 0.3)
		$just_killed.start()
		print("bullet just killed")

func snipe():
	if !bomb_launched:
		shooting = true
	#	Instantiate a bullet using the NodeInstantiator
	#	The NodeInstantiator will automatically spawn it on all other clients
		var bullet : Node = snipe_b_instantiator.instantiate_node()
		bullet.sniper_bullet_hit.connect(on_snipe_hit)
	#	Set all bullet properties. The NodeInstantiator will automatically detect
	#	all changes made to the bullet in this frame and synchronize them
		bullet.shooter_name = name
		var origin := global_position + Vector2.UP
		# Add rotation towards the mouse
		var mouse_pos = get_global_mouse_position()
		var angle_to_mouse = position.angle_to_point(mouse_pos)
		# Convert the angle to a Vector2 and multiply by bullet_speed
		bullet.velocity = Vector2.RIGHT.rotated(angle_to_mouse) * snipe_bullet_speed
		bullet.global_position = origin
		Global.emit_signal("walk_screen_shake",55)
		animate("shoot")
		weapon_charged = false
		$snipe_timer.start()

func on_snipe_hit():
	if !GDSync.is_gdsync_owner(self): return
	var kill = Global.check_for_kill()
	GDSync.call_func(Global.check_for_kill)
	print("bullet kill = ",kill)
	if kill == true:
		KILL_COUNT += 1
		set_kill_count()
		#print("kill")
		var tween := create_tween()
		tween.tween_property(%kills, "modulate", Color.WHITE, 0.3)
		$just_killed.start()
		print("bullet just killed")

var bomb : Node
func launch_bomb():
	shooting = true
	detonating = true
#	Instantiate a bullet using the NodeInstantiator
#	The NodeInstantiator will automatically spawn it on all other clients
	bomb = bomb_instantiator.instantiate_node()
	bomb.bomb_hit.connect(on_bomb_hit)
#	Set all bullet properties. The NodeInstantiator will automatically detect
#	all changes made to the bullet in this frame and synchronize them
	bomb.shooter_name = name
	var origin := global_position + Vector2.UP
	# Add rotation towards the mouse
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = position.angle_to_point(mouse_pos)
	# Convert the angle to a Vector2 and multiply by bullet_speed
	bomb.launch(bomb_speed, angle_to_mouse)
	bomb.global_position = %bomb_spawn.global_position
	Global.emit_signal("walk_screen_shake",55)
	animate("shoot")
	weapon_charged = false
	$bomb_timer.start()

func detonate_bomb():
	if bomb_launched:
		if bomb != null and is_instance_valid(bomb):
			bomb.blow_up()
			#GDSync.call_func(detonate_bomb)
			bomb = null
			bomb_launched = false

func on_bomb_hit():
	if !GDSync.is_gdsync_owner(self): return
	var kill = Global.check_for_kill()
	GDSync.call_func(Global.check_for_kill)
	print("bullet kill = ",kill)
	if kill == true:
		KILL_COUNT += 1
		set_kill_count()
		#print("kill")
		var tween := create_tween()
		tween.tween_property(%kills, "modulate", Color.WHITE, 0.3)
		$just_killed.start()
		print("bullet just killed")

func damage(dmg):
	#print("hi")
	if !GDSync.is_gdsync_owner(self): return
	#print("hi2")
	if !dying:
		#print("client id: ",GDSync.get_client_id(),", damage taken: ",dmg)
		old = health
		health -= dmg
		new = health
		if new <= min_health:
			health = min_health
			new = min_health
			old = min_health
			death()
			#GDSync.call_func(death)
		if health <= danger_health:
			if !low_health:
				low_health = true
				private_animate("low_health")
		else:
			taking_dmg = true
		animate("damage")
		health_changed.emit(name.to_int(), new)
		#print("client id: ", GDSync.get_client_id(),", health: ", health)

func death():
	if GDSync.is_gdsync_owner(self):
		dying = true
		Global.player_died()
		GDSync.call_func(Global.player_died)
		animate("death")
		private_animate("full_health")
		#print("client id: ", GDSync.get_client_id(), " just DIED with ", health, " health")

var gaining_point = false
func animate(request):
	if !GDSync.is_gdsync_owner(self): return
	if request == "death":
		dying = true
		animation_player.play("death")
	elif !dying:
		if request == "point":
			gaining_point = true
			animation_player.play("point")
		if !gaining_point:
			if request == "walk":
				if !shooting:
					if !overheated:
						animation_player.play("walk")
			elif request == "shoot":
				if !taking_dmg:
					shooting = true
					animation_player.play("shoot")
			elif request == "damage":
				shooting = false
				animation_player.play("damage")
			elif request == "overheat":
				animation_player.play("overheat")
			elif request == "RESET":
				if !taking_dmg:
					if !shooting:
						if !overheated:
							animation_player.play("RESET")  # Stop the animation'
						else:
							print("cant play RESET because of overheat true")


func private_animate(request):
	if !GDSync.is_gdsync_owner(self): return
	if request == "low_health":
		p_animation_player.play("low_health")
	if request == "full_health":
		p_animation_player.play("full_health")

func _on_animation_player_animation_finished(anim_name):
	if GDSync.is_gdsync_owner(self):
		if anim_name == "point":
			gaining_point = false
		if anim_name == "death":
			dying = false
			#death_position = position
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
		$pos_sync.pause_interpolation(0.1)
		position = death_position
		health_changed.emit(name.to_int(), new)
		taking_dmg = false
		animate("RESET")
		private_animate("full_health")

func _on_cooldown_timer_timeout():
	overheated = false
	overheat_timer = 0
	$"player_ui/CanvasLayer/Control/overheated!".visible = false
	#print("cooldown_timer_timeout")
	$cooldown_sound.play()

func _on_shoot_timer_timeout():
	weapon_charged = true
	#print("weapon charged")

func _on_snipe_timer_timeout():
	weapon_charged = true

func _on_bomb_timer_timeout():
	weapon_charged = true


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://menus/lobby_browsing_menu.tscn")


func _on_just_killed_timeout():
	var tween := create_tween()
	tween.tween_property(%kills, "modulate", Color.TRANSPARENT, 0.3)
