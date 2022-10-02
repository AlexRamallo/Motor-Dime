extends Camera

var track_node;
var track_curve;
var start_off;

var t_offset:float = 0.0;

func _ready():
	track_node = get_tree().current_scene.find_node("TrackPath", true, false);
	assert(track_node != null)
	track_curve = track_node.curve;
	assert(track_curve != null)
	
	start_off = global_transform.origin;

func _process(delta):
	t_offset += 1;	
	var pos = track_node.to_global(track_curve.interpolate_baked(t_offset));
	#global_transform.origin = pos + start_off;
	#transform = transform.interpolate_with(target_rider_cam.global_transform, 0.1);
	
	var target_trans = Transform.IDENTITY.translated(pos + start_off).looking_at(Vector3(0,0,0), Vector3.UP);	
	transform = transform.interpolate_with(target_trans, delta);
	#look_at_from_position(pos + start_off, Vector3(0, 0, 0), Vector3.UP);
