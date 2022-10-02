extends Control

var lbTotal:Label;
var lbFastest:Label;
var lbSlowest:Label;
var lbFalls:Label;
var lbLaps:Control;

func _ready():
	lbTotal = find_node("lbTotal");
	lbFastest = find_node("lbFastest");
	lbSlowest = find_node("lbSlowest");
	lbFalls = find_node("lbFalls");
	lbLaps = find_node("LapList");
	assert(lbTotal != null);
	assert(lbFastest != null);
	assert(lbSlowest != null);
	assert(lbFalls != null);
	assert(lbLaps != null);

func update_values(num_laps:int, lap_times:Array, fall_count:int):
	var fastest:float = 1000.0;
	var slowest:float = 0.0;
	var total:float = 0.0;
	for i in range(num_laps):
		var time = lap_times[i];
		if time < fastest:
			fastest = time;
		if time > slowest:
			slowest = time;
		total += time;
		var lb = lbLaps.find_node("l" + str(i+1)) as Label;
		assert(lb != null);
		lb.text = "Lap " + str(i+1) + ": " + str(time) + " s";
	
	lbTotal.text   = "Total Time:  " + str(total) + " s";
	lbFastest.text = "Fastest Lap: " + str(fastest) + " s";
	lbSlowest.text = "Slowest Lap: " + str(slowest) + " s";
	lbFalls.text   = "Total Falls: " + str(fall_count);


func _on_BtnRestart_pressed():
	print("Play again!");
	get_tree().change_scene("res://scenes/Test.tscn");
