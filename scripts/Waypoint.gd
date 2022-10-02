extends Area

const WaypointSensor = preload("res://game_objects/WaypointSensor.gd");

var waypoint_id:int = -1;

func _ready():
	waypoint_id = int(self.name.substr(2));
	assert(waypoint_id >= 0 and waypoint_id <= 10);
	print("waypoint_id: ", waypoint_id);
	
func _process(delta):
	var overlapping = get_overlapping_areas();
	for node in overlapping:
		var sensor = node as WaypointSensor;
		if sensor != null:
			if sensor.target_waypoint == waypoint_id:
				sensor.on_pass_waypoint(self);
