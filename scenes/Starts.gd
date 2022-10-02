extends Spatial

var spots:Array = [];

func _ready():
	randomize();
	reset_all_riders(6);

func reset_all_riders(r1_spot:int = -1):
	var riders = get_tree().current_scene.find_node("Riders", true, false) as Spatial;
	assert(riders != null);
	
	if r1_spot >= 0:
		var r1 = riders.get_node("r1");
		assert(r1 != null);
		move_to_start(r1, r1_spot);
		return;
		
	var rnodes = [] + riders.get_children();
	var num_spots:int = get_child_count();#min(get_child_count(), riders.get_child_count());
	var idx = [];
	for i in range(num_spots):
		idx.push_back(i);
		
	while rnodes.size() > 0:
		var i = (randi() % num_spots) % idx.size();
		var spot = idx[i];
		idx.remove(i);
		move_to_start(rnodes.pop_back(), spot);

func move_to_start(r:Spatial, spot:int):
	print("moving '", r.name, "' to st", spot+1);
	var dst = get_node("st" + str(spot + 1)) as Spatial;
	assert(dst != null);
	r.global_transform = dst.global_transform;
	r.rotate_y(deg2rad(180));
