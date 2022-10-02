extends Control

var timer_back:Sprite;
var timer_hand:Sprite;

var hand_rot_offset:float;

var rider;

var info_foot1;
var info_foot2;
var info_drive;

var spd_start;
var spd_end;
var spd_safe;
var spd_arrow;

func _ready():
	timer_back = find_node("TimerBack");
	timer_hand = find_node("TimerHand");
	
	rider = get_tree().current_scene.find_node("r1", true, false);
	assert(rider != null);
	
	info_foot1 = find_node("InfoFoot") as Sprite;
	assert(info_foot1 != null)
	info_foot2 = find_node("InfoFoot2") as Sprite;
	assert(info_foot2 != null)
	info_drive = find_node("InfoDrive") as Sprite;
	assert(info_drive != null)
	
	spd_start = find_node("speed_start") as Control;
	assert(spd_start != null)
	spd_end = find_node("speed_end") as Control;
	assert(spd_end != null)
	spd_safe = find_node("speed_safe") as Control;
	assert(spd_safe != null)
	spd_arrow = find_node("SpeedArrow") as Sprite;
	assert(spd_arrow != null)
	
	hand_rot_offset = timer_hand.rotation;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var parent = get_parent();
	var rot = 1.0 - (parent.freeze_countdown / parent.freeze_countdown_time);
	
	var rider_speed = rider.vehicle_node.linear_velocity.length();
	var rider_max_speed = rider.speed * 2;
	var speed_f = clamp(rider_speed / rider_max_speed, 0.0, 1.0);
	if rider_speed <= rider.freeze_fall_velocity_threshold:
		speed_f = clamp(rider_speed / rider.freeze_fall_velocity_threshold, 0.0, 1.0);
		spd_arrow.position.y = spd_start.rect_position.y - ((spd_start.rect_position.y - spd_safe.rect_position.y) * speed_f);
		spd_arrow.modulate = Color8(0, 255, 0, 255);
	else:
		spd_arrow.position.y = spd_start.rect_position.y - ((spd_start.rect_position.y - spd_end.rect_position.y) * speed_f);
		spd_arrow.modulate = Color8(255, 0, 0, 255);
	
	if rider.rider_state == rider.RiderStates.RIDING or rider.rider_state == rider.RiderStates.SITTING:
		info_drive.visible = true;
	else:
		info_drive.visible = false;
		
	if rider.rider_state == rider.RiderStates.ONFOOT:
		if rider.can_mount:
			info_foot2.visible = true;
			info_foot1.visible = false;
		else:
			info_foot2.visible = false;
			info_foot1.visible = true;
	else:
		info_foot2.visible = false;
		info_foot1.visible = false;
	
	rot = floor(rot * 10.0) / 10.0;
	var target_angle = (rot * PI * 2.0) + hand_rot_offset;
	timer_hand.rotation = lerp(timer_hand.rotation, target_angle, 0.2);
	
	if parent.freeze_countdown <= 0:
		timer_hand.modulate.a = 0.24;
		timer_back.modulate.a = 0.24;
	else:
		timer_hand.modulate.a = 1.0;
		timer_back.modulate.a = 1.0;
