extends Node

signal walk_screen_shake 

var camera: Camera2D
var game_mode : int = 0

var GAME_ENDED = false

var all_players = []
var players = []
var t1 = null
var t2 = null
var t3 = null
var t4 = null

var t1_score = 0
var t2_score = 0
var t3_score = 0
var t4_score = 0


@onready var dom_timer = $dom_timer

func update_score(tm, new):
	GDSync.call_func(update_score,[tm,new])
	if tm == 1:
		t1_score = new
	elif tm == 2:
		t2_score = new
	elif tm == 3:
		t3_score = new
	elif tm == 4:
		t4_score = new

func switch_game_mode(new):
	game_mode = new

func start_game():
	if game_mode == 1:#runs TEST_WORLD (DEFAULT)
		await setup_teams(true)
		get_tree().change_scene_to_file("res://test_world/test_world.tscn")
	if game_mode == 2:#runs DOMINATION
		await setup_teams(true)
		var player_amount = GDSync.get_lobby_player_count()
		if player_amount == 2: 
			get_tree().change_scene_to_file("res://Domination/Domination.tscn")
		elif player_amount == 3:
			#get_tree().change_scene_to_file("res://Domination/Domination_3_Player.gd")
			pass
		elif player_amount == 4:
			pass

#var my_items = [[5, "Potato"], [9, "Rice"], [4, "Tomato"]]
	#my_items.sort_custom(sort_ascending)
	#print(my_items) # Prints [[4, Tomato], [5, Potato], [9, Rice]].
#
	## Descending, lambda version.
	#my_items.sort_custom(func(a, b): return a[0] > b[0])
	#print(my_items) # Prints [[9, Rice], [5, Potato], [4, Tomato]]



var dead_player = false
func player_died():
	dead_player = true
	$dead_player.start()
	print("player died!")

func check_for_kill():
	if dead_player: return true

var biggest_client
var sorted_clients = []
func setup_teams(random=false):
	if random:
		for client in GDSync.get_all_clients():
			sorted_clients.append(client)
		sorted_clients.sort_custom(func(a,b):return a > b)

		for client in sorted_clients:
			if t1 == null:
				t1 = client
				print("t1 filled: ", t1)
				continue
			if t2 == null:
				t2 = client
				print("t2 filled: ", t2)
				continue
			if t3 == null:
				t3 = client
				print("t3 filled: ", t3)
				continue
			if t4 == null:
				t4 = client
				print("t4 filled: ", t4)
				continue

func _ready():
	main_menu_music("on")
	GDSync.expose_func(update_score)
	GDSync.expose_func(check_for_kill)
	GDSync.expose_func(player_died)

func main_menu_music(onoff):
	if onoff == "on":
		$menu_music.play()
	else:
		$menu_music.stop()

func test_level_music(onoff):
	if onoff == "on":
		$test_lvl_music.play()
	else:
		$test_lvl_music.stop()


func _on_dead_player_timeout():
	dead_player = false
