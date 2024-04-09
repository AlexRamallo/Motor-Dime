class_name Conduit
extends Spatial

var safezone:Area;
var track_curve:Curve3D;
var track_node:Path;

var lightning;

export var is_conduit_active:bool;
export var freeze_invincibility_time:float = 1.5;
var freeze_detach_timer:float = 0.0;

var freeze_invincibility_target:Spatial;

func _ready():	
	is_conduit_active = true;
	lightning = get_node("Lightning");
	assert(lightning != null);
	
	safezone = get_node("Safezone");
	track_node = get_tree().current_scene.find_node("TrackPath", true, false);
	assert(track_node != null)
	track_curve = track_node.curve;
	assert(track_curve != null)

	#Align to track
	var cur_offset = track_curve.get_closest_offset(track_node.to_local(global_transform.origin));
	var pt0 = (track_curve.interpolate_baked(cur_offset));
	var pt1 = (track_curve.interpolate_baked(cur_offset - 1.0));
	#global_transform.origin = pt0;
	var og = global_transform.origin;
	look_at_from_position(pt1, pt0, Vector3.UP);
	global_transform.origin = og;

func _process(delta):
	for body in safezone.get_overlapping_bodies():
		if body is VehicleBody:
			lightning.target_node = body.rider;
			body.rider.freeze_invincibility = freeze_invincibility_time;
			freeze_invincibility_target = body;
			freeze_detach_timer = freeze_invincibility_time;

	if freeze_detach_timer > 0:
		freeze_detach_timer -= delta;
		if freeze_detach_timer <= 0:
			lightning.target_node = null;
