extends Spatial

func _ready():
	for child in get_children():
		var anim = child.get_node("AnimationPlayer") as AnimationPlayer;
		if anim == null:
			continue;
		
		anim.get_animation("cheer").set_loop(true);
		anim.current_animation = "cheer";
