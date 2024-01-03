extends Node

signal walk_screen_shake 

var camera: Camera2D


func _ready():
	main_menu_music("on")

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
