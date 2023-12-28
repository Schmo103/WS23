extends CharacterBody2D


@export var bullet_speed = 15000.0

@onready var b_instantiator : Node = $bullet_instantiator

@export var speed = 250
@export var friction = 0.16
@export var acceleration = 0.1


@onready var skin_1 = $skin_1
@onready var skin_2 = $skin_2
@onready var animation_player = $AnimationPlayer  # Reference to the AnimationPlayer node

func _ready():
	if GDSync.is_gdsync_owner(self):
		skin_1.visible = true
		skin_2.visible = false
	else:
		skin_1.visible = false
		skin_2.visible = true
	set_multiplayer_data.call_deferred()


func set_multiplayer_data():
	var client_id : int = name.to_int()
	$user_label.text = GDSync.get_player_data(client_id, "Username", "Unkown")

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
	
	
	var direction = get_input()
	if direction.length() > 0:
		velocity = velocity.lerp(direction.normalized() * speed, acceleration)
		animation_player.play("walk")  # Play the "walk" animation
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		animation_player.play("RESET")  # Stop the animation
	
	# Add rotation towards the mouse
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = position.angle_to_point(mouse_pos)
	rotation = angle_to_mouse - PI +0.13  # Adjust the rotation

	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		shoot()


func shoot() -> void:
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
