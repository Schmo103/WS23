extends Node

@onready var control = $CanvasLayer/pause_menu
var game_paused = false
# Called when the node enters the scene tree for the first time.
func _ready():
	resume_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if game_paused:
			resume_game()
		elif game_paused == false:
			pause_game()
			print("pasing")


func _on_main_menu_pressed():
	GDSync.leave_lobby()
	get_tree().change_scene_to_file("res://menus/lobby_browsing_menu.tscn")


func _on_resume_pressed():
	resume_game()
	game_paused = false


func pause_game():
	control.show()
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color.WHITE, 0.3)
	game_paused = true

func resume_game():
	var tween := create_tween()
	tween.tween_property(control, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(control.hide)
	game_paused = false
