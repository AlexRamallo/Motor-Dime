extends Camera

var target_rider:Spatial;
var target_rider_cam:Spatial;

func _ready():
	pass

func set_target(rider):
	target_rider = rider;
	if target_rider != null:
		target_rider_cam = target_rider.find_node("CameraSlot");

func _process(delta):
	if target_rider != null:
		transform = transform.interpolate_with(target_rider_cam.global_transform, 0.1);
