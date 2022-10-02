extends Path

var track_width:float = 78.0;
var track_hwidth:float = track_width / 2.0;
var waypoints:Spatial;

func _ready():
	waypoints = get_tree().current_scene.find_node("Waypoints") as Spatial;
	assert(waypoints != null);

func constrain_to_track(point:Vector3, waypoint:int = -1) -> Vector3:
	var pt = point * Vector3(1.0, 0.0, 1.0);
	var offset = curve.get_closest_offset(to_local(pt));
	
	#additionally make sure we don't pass the given waypoint
	if waypoint >= 0:
		var wp = waypoints.get_node("wp" + str(waypoint)) as Area;
		assert(wp != null);
		var waypoint_offset = curve.get_closest_offset(to_local(wp.global_transform.origin));
		if offset > waypoint_offset:
			offset = waypoint_offset;
	
	var closest_track_pos = to_global(curve.interpolate_baked(offset));
	closest_track_pos.y = 0;
	
	var dt = pt - closest_track_pos;
	
	if dt.length() < track_hwidth:
		return point;
		
	var ret = closest_track_pos + (dt.normalized() * (track_hwidth - 5.0));
	
	ret.y = point.y;
	return ret;

#returns a point on the curve offset on the cross axis by 'cross_offset' world units
func get_constrained_cross_offset(offset:float, cross_offset:float) -> Vector3:
	var center_pos0 = to_global(curve.interpolate_baked(offset - 0.1));
	var center_pos1 = to_global(curve.interpolate_baked(offset + 0.1));
	var cross_axis = Vector3.UP.cross((center_pos0 - center_pos1).normalized());
	var center_pos = to_global(curve.interpolate_baked(offset));
	return center_pos + (cross_axis * cross_offset);
