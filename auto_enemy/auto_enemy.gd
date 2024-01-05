extends CharacterBody2D

var SPEED = 300
var accel = 7

@onready var attack_timer = $attack_timer

@onready var nav = $NavigationAgent2D

var players = Global.players

var randomnum

enum {
	ATTACK,
	HIT,
}

var state = ATTACK

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	randomnum = rng.randf()


var target_player
func update_target():
	for player in players:
		if is_instance_valid(player):
			if target_player == null:
				target_player = player
			else:
				if (global_position.distance_to(player.global_position) < (global_position.distance_to(target_player.global_position))):
					target_player = player


func _physics_process(delta):
	update_target()
	
	match state:
		ATTACK:
			move(target_player.global_position, delta)
		HIT:
			move(target_player.global_position, delta)
			print("HIT")
			#Slash ANIM

@warning_ignore("unused_parameter")
func move(target, delta):
	nav.target_position = to_local(target_player.global_position)
	var direction = nav.get_next_path_position()
	direction = direction.normalized() 
	if !avoiding:
		velocity = velocity.lerp(direction*SPEED,accel * delta)
	move_and_slide()


func _on_AttackTimer_timeout():
	state = ATTACK

var avoiding
func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	avoiding = true
	set_velocity(safe_velocity)
