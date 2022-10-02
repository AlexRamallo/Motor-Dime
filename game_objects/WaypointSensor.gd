extends Area

var total_laps:int = 8;

var target_waypoint:int = 0;
var last_waypoint:int = 0;
var lap_count:int = -1;
var lap_time_start:int = 0;

var lap_times:Array;

var rider;

func reset():
	target_waypoint = 0;
	last_waypoint = 0;
	lap_count = -1;
	lap_times = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

func _ready():
	rider = get_node("../../");
	reset();

func get_time() -> int:
	return Time.get_ticks_msec();

func on_pass_waypoint(wp:Spatial):
	if wp.waypoint_id == 0:
		lap_count += 1;
		if lap_count > 0:
			on_lap();
		lap_time_start = get_time();
		
		if lap_count >= total_laps:
			get_tree().current_scene.on_race_end(lap_times, total_laps);

	var cur_time:int = get_time();
	var lap_delta:float = float(cur_time - lap_time_start) / 1000.0;
	print("passed waypoint[", wp.waypoint_id, "] cur time: ", cur_time, "\tlap_delta: ", lap_delta);

	last_waypoint = target_waypoint;
	target_waypoint += 1;
	if target_waypoint > 10:
		target_waypoint = 0;

func on_lap():
	var cur_time:int = get_time();
	var lap_delta:float = float(cur_time - lap_time_start) / 1000.0;
	lap_times[(lap_count-1) % lap_times.size()] = lap_delta;
	print("Finished lap! Time: ", lap_delta, " sec");
	print("\t", lap_times);

	var label = get_tree().current_scene.find_node("lbLaps") as Label;
	var lbTimeA = get_tree().current_scene.find_node("lbTimeA") as Label;
	var lbTimeB = get_tree().current_scene.find_node("lbTimeB") as Label;
	
	label.text = "LAP: " + str(lap_count + 1) + " / " + str(total_laps);
	lbTimeA.text = str(lap_delta) + " s";
	
	lbTimeB.text = "";
	if lap_count > 1:
		var lap_diff = lap_times[lap_count-2] - lap_delta;
		if lap_diff >= 0:
			lbTimeB.text += "+ ";
			lbTimeB.modulate = Color8(0, 255, 0, 255);
		else:
			lbTimeB.modulate = Color8(255, 0, 0, 255);
		lbTimeB.text += str(lap_diff) + " s";
