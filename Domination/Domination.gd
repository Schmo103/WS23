extends Node2D


var PLAYER_SCENE : PackedScene = load("res://player/player.tscn")

#var team_one_score = 0
#var team_two_score = 0

func _ready():
	Global.main_menu_music("off")
	Global.test_level_music("on")

func _enter_tree():
#	Connect all relevant signals. Make sure to handle disconnects!
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)
	GDSync.disconnected.connect(disconnected)
	
#	Add player models for all clients already ingame
	for id in GDSync.get_all_clients():
		client_joined(id)

func disconnected():
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func give_score_to_client():
	if !Global.GAME_ENDED:
		var all_players = []
		for player in Global.all_players:
			all_players.append(player)
		var player_count = []
		for player in $score_detector.get_overlapping_bodies():
			if player.is_in_group("scoring"):
				player_count.append(player)
				all_players.erase(player)
				#if player.dead == true:
					#player_count.erase(player)
					#print("dead player erased")
		if player_count.size() == 1:
			if player_count[0].dead != true:
				player_count[0].score()
				$score_sound.play()
				player_count[0].animate("point")
			if player_count[0]!= all_players[0]:
				#if all_players[0].dead != true:
					all_players[0].other_score(all_players[0])
			else:
				print("BAD")
		$score_time.start()
	

func client_joined(client_id : int):
#	Instantiate a player
	var player : Node = PLAYER_SCENE.instantiate()
	
#	Make the ID their name for easy identification
	player.name = str(client_id)
	add_child(player)
	Global.players.append(player)
	player.player_died.connect(_on_player_died)
	if Global.t1 == client_id:
		player.position = $spawn1.position
	elif Global.t2 == client_id:
		player.position = $spawn2.position
	elif Global.t3 == client_id:
		pass
	elif Global.t4 == client_id:
		pass
	print(Global.t1)
	print(client_id)


#	Make sure to make the client the owner of their own player controller
	GDSync.set_gdsync_owner(player, client_id)

func client_left(client_id : int):
#	When a client leaves, delete their player controller
	var player_string : String = str(client_id)
	if has_node(player_string):
		get_node(player_string).queue_free()

func _on_player_died(player):
	player.position = $respawn.position


func _on_score_time_timeout():
	give_score_to_client()
	
