extends Node


@onready var health_display = $CanvasLayer/Control/TextureProgressBar
@onready var overheat_display = $CanvasLayer/Control/overheat
# Called when the node enters the scene tree for the first time.
func _ready():
	GDSync.expose_node(health_display)
	GDSync.expose_func(update_display)
	if !GDSync.is_gdsync_owner(self): health_display.visible = false
	if !GDSync.is_gdsync_owner(self): overheat_display.visible = false
	#$CanvasLayer/Control/health_low.set_modulate(Color(255.0,255.0,255.0,0.0))

func update_display(new):
	health_display.value = new


func _on_player_health_changed(target, new):
		GDSync.call_func_on(target,update_display,[new])

