extends Spatial


onready var anim_player = $AnimationPlayer


func play_anim(anim):
	anim_player.play(anim)
