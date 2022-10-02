extends VehicleBody

var track_curve:Curve3D;
var track_node:Path;
var moto_node:Spatial;
var rider:Spatial;

var crash_immune:float = 0;

var snd_idle;
var snd_move;
var snd_crash;
var snd_electric;

var audio_player:AudioStreamPlayer3D;
var audio_player2:AudioStreamPlayer3D;

var is_constrained_to_track:bool = true;

export var impact_threshold:float = 10.0;
export var min_vel_impact:float = 10.0;

func _ready():
	rider = get_parent() as Spatial;
	assert(rider != null);
	moto_node = get_node("moto").find_node("Moto");
	assert(moto_node != null);
	track_node = get_tree().current_scene.find_node("TrackPath", true, false);
	assert(track_node != null)
	track_curve = track_node.curve;
	assert(track_curve != null)
	
	audio_player = get_node("audio_player");
	assert(audio_player != null);
	
	audio_player2 = get_node("audio_player2");
	assert(audio_player2 != null);
	
	snd_idle = load("res://source_assets/sfx/moto_idle.ogg");
	snd_move = load("res://source_assets/sfx/moto_move.ogg");
	snd_crash = load("res://source_assets/sfx/crash.ogg");
	snd_electric = load("res://source_assets/sfx/electricity.ogg");

var lock_angles:Vector3;
var lock_basis:Basis;

var velocity_samples:Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
var velocity_samples_it = 0;

var snd_last_state;

var is_elec:bool = false;

func _physics_process(delta):
	if is_constrained_to_track:
		constrain_to_track(false);

	if rider.freeze_invincibility > 0:
		if !is_elec:
			audio_player2.play(0.0);
			is_elec = true;
			print("play electricity!");
	else:
		if is_elec:
			is_elec = false;
			audio_player2.stop();

	if crash_immune > 0:
		crash_immune -= delta;
	#stop crazy spinning while airborne
	if rider.rider_state == rider.RiderStates.RIDING:
		if global_transform.origin.y > 8.0:
			angular_velocity = Vector3.ZERO;
			#var offset = track_curve.get_closest_offset(track_node.to_local(global_transform.origin + linear_velocity.normalized()));
			#var track_pos = track_node.to_global(track_curve.interpolate_baked(offset));
			#var lt = moto_node.transform.looking_at(track_pos, Vector3.UP);
			#moto_node.transform.basis = moto_node.transform.basis.slerp(lt.basis, 0.1);
	
	if rider.rider_state == rider.RiderStates.GETUP:
		constrain_to_track(true);
		angular_velocity = Vector3.ZERO;
		linear_velocity *= Vector3(0.0, 1.0, 0.0);
	
	if rider.rider_state != snd_last_state:
		snd_last_state = rider.rider_state;
		audio_player.playing = true;
		if rider.rider_state == rider.RiderStates.RIDING:
			audio_player.stream = snd_move;
			audio_player.autoplay = true;
		elif rider.rider_state == rider.RiderStates.RAGDOLL:
			audio_player.stream = snd_crash;
			audio_player.autoplay = false;
		else:
			audio_player.stream = snd_idle;
			audio_player.autoplay = true;
	
	var cur_vel = (linear_velocity * Vector3(1,0,1)).length();
	var sum_vel = 0;
	for v in velocity_samples:
		sum_vel += v;
	var avg_vel = sum_vel / velocity_samples.size();
	
	var delta_vel = avg_vel - cur_vel;
	
	#print("avg_vel: ", avg_vel, "\tcur_vel: ", cur_vel, "\t(delta: ", delta_vel, ")");

	if !crash_immune:
		if delta_vel >= impact_threshold:
			if cur_vel >= min_vel_impact:
				handle_rapid_velocity_change(cur_vel);
			else:
				print("impacted, but too slow! ", cur_vel, " < ", min_vel_impact);
			
		velocity_samples[velocity_samples_it] = cur_vel;
		velocity_samples_it += 1;
		if velocity_samples_it >= velocity_samples.size():
			velocity_samples_it = 0;

func handle_rapid_velocity_change(vel:float):
	#print("Rapid velocity change!!");
	var colliders = get_colliding_bodies();
	if colliders.size() > 0:
		#did collide maybe
		#print("\twith colliders: ", colliders.size());
		
		if colliders.size() == 1:
			if colliders[0].has_method("is_ramp"):
				#print("\t\tcrashed with a ramp!");
				if linear_velocity.y > 0:
					#print("\t\t\tand we flying!!");
					crash_immune = 0.5;
					return; #probably going up a ramp?
		rider.do_ragdoll(linear_velocity);

func constrain_to_track(waypoint:bool):
	var wp:int = -1;
	if waypoint:
		wp = rider.waypoint_sensor.target_waypoint;
	var pos = track_node.constrain_to_track(global_transform.origin, wp);
	if pos != global_transform.origin:
		global_transform.origin = pos;
