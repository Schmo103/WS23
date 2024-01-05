extends Control


var is_class_chosen = false
var chosen_class = ""



func _ready():
#	Make sure to handle disconnects!
	GDSync.disconnected.connect(disconnected)
	

func _on_back_pressed():
	GDSync.stop_multiplayer()

func disconnected():
#	Diconnected. Jump back to main menu
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")

func _on_continue_pressed():
	if %Username.text.length() == 0: return
	if !is_class_chosen: return
	
	
#	Set the player's username so it may be displayed in lobbies and games.
	GDSync.set_player_username(%Username.text)
	GDSync.set_player_data("kills",0)
	GDSync.set_player_data("class",chosen_class)
#	Set any other custom player data, in this case the player color
	#GDSync.set_player_data("Color", %Color.color)
	
	get_tree().change_scene_to_file("res://menus/lobby_browsing_menu.tscn")



func _on_auto_pressed():
	is_class_chosen = true
	chosen_class = "auto"


func _on_sniper_pressed():
	is_class_chosen = true
	chosen_class = "sniper"


func _on_heavy_pressed():
	is_class_chosen = true
	chosen_class = "heavy"
