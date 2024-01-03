extends Camera2D

## You need to:
## 1. Create a Global signal -> in your Global file: signal walk_screen_shake 
## 2. Emit signal when to shake -> globals.emit_signal('walk_screen_shake')
# you can just replace walk_screen_shake with any other name you want 

### Attached to: Camera2D ###
## Child -> shake_timer [Timer] ##

## Variables ##
@onready var shake_timer = $shake_timer
@onready var shake_intensity = 0 
var default_offset = offset

@export var walk_shake_intensity = 15

################################################################################
## Functions ##

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.walk_screen_shake.connect(walk_screen_shake) ## Signal from player [player_animation]
	set_process(false)
	randomize()


# When Process is running, screen will be shaking
func _process(delta):
	var shake_vector = Vector2(randf_range(-1,1) * shake_intensity, randf_range(-1,1) * shake_intensity)
	var tween = create_tween()
	tween.tween_property(self, "offset", shake_vector, 0.1)

func shake(intensity):
	shake_intensity = intensity
	set_process(true) # runs _process
	shake_timer.start()
	

func _on_shake_timer_timeout():
	set_process(false) # stops _process
	# TWEEN TO SET BACK TO NORMAL #
	var tween = create_tween()
	tween.tween_property(self, "offset", default_offset, 0.1)
	

################################################################################
## Signal Functions ##

func walk_screen_shake():
	shake(walk_shake_intensity)
