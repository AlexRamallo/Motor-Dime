extends "res://scripts/CtlState.gd"

var track_node:Path;
var track_curve:Curve3D;
var rider_node:Spatial;

func _init(r:Spatial).(r):
	track_node = rider.track_node;
	assert(track_node != null);
	track_curve = track_node.curve;
	assert(track_curve != null);
	rider_node = rider.rider_node;
	assert(rider_node != null);

func update(delta, vp):
	viewport = vp;
	var rider_pos = rider.vehicle_node.global_transform.origin;
	#negative = closer to center, positive = closer to fences
	var target_cross_depth:float = 0.0;
	var cur_offset = track_curve.get_closest_offset(track_node.to_local(rider_pos));
	var fwd_offset = cur_offset + (45 * delta);
	
	var cross_pt = track_node.get_constrained_cross_offset(fwd_offset, target_cross_depth);
	var cross_pt0 = track_node.get_constrained_cross_offset(cur_offset, target_cross_depth);
	
	var newt = Transform.IDENTITY.translated(cross_pt);
	newt.basis.z = (cross_pt0 - cross_pt).normalized();
	vFwd = 1.0;
	rider.vehicle_node.global_transform.origin = rider.vehicle_node.global_transform.interpolate_with(newt, 0.5).origin;
	
	#sleepy > math
	#var zfwd = rider_node.transform.basis.z;
	#var fcross = ((cross_pt - rider_node.global_transform.origin)*Vector3(1,0,1)).normalized();
	#var rcross = fcross.cross(Vector3.UP);
	#
	#vTurn = zfwd.dot(rcross);
	#var fd = zfwd.dot(fcross);
	#vFwd = 0.1 * fd;
	#
	#var dbg1 = rider.get_node("DBG_1") as Spatial;
	#var dbg2 = rider.get_node("DBG_2") as Spatial;
	#var dbg3 = rider.get_node("DBG_3") as Spatial;
	#assert(dbg1 != null);
	#assert(dbg2 != null);
	#assert(dbg3 != null);
	#
	#dbg1.global_transform.origin = rider_node.global_transform.origin;
	#dbg2.global_transform.origin = rider_node.global_transform.origin;
	#
	#dbg1.transform.basis.z = fcross;
	#dbg2.transform.basis.z = rcross;
	#dbg3.global_transform.origin = cross_pt;
	#dbg3.global_transform.origin.y = 4.0;
	
func handle_event(event):
	return;
