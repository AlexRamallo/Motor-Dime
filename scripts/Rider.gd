extends Spatial

const CtlState = preload("res://scripts/CtlState.gd");
const AICtl = preload("res://scripts/AICtl.gd");
const Conduit = preload("res://scripts/conduit.gd");

var speed:float = 50.0;
var handling:float = 0.1;

var vehicle_node:VehicleBody;
var moto_node:Spatial;
var rider_node:Spatial;
var moto_anim:AnimationPlayer;
var rider_anim:AnimationPlayer;
var rider_skeleton:Skeleton;

var onfoot_body:KinematicBody;

var mount_area:Area;
var mount_mesh:MeshInstance;

var waypoint_sensor:Area;

var camera:Spatial;
var springarm:SpringArm;
var sprinarm_start_pos:Vector3;
var screech_particles:Particles;

var track_curve:Curve3D;
var track_node:Path;

var ctl:CtlState;

var freeze_duration:float = 0;
var freeze_origin:Vector3;
var freeze_fall_velocity_threshold:float = 15.0;
var freeze_invincibility:float = 0;

var can_mount:bool = false;

var rider_state = RiderStates.SITTING;
enum RiderStates {
	SITTING,
	RIDING,
	TRICK_A,
	TRICK_B,
	RAGDOLL,
	GETUP,
	ONFOOT,
	MOUNTING
};

func _ready():	
	moto_node = find_node("moto");
	assert(moto_node != null);
	rider_node = find_node("rider");
	assert(rider_node != null);
	camera = find_node("CameraSlot");
	assert(camera != null);
	vehicle_node = find_node("VehicleBody");
	assert(vehicle_node != null);
	springarm = find_node("SpringArm");
	assert(springarm != null);
	onfoot_body = find_node("onfoot_body");
	assert(onfoot_body != null);
	
	mount_mesh = find_node("MountIndicator");
	assert(mount_mesh != null);
	mount_area = mount_mesh.find_node("Area");
	assert(mount_area != null);
	mount_mesh.visible = false;
	
	waypoint_sensor = find_node("WaypointSensor") as Area;
	assert(waypoint_sensor != null);
	
	rider_skeleton = rider_node.find_node("Skeleton");
	assert(rider_skeleton != null);
	
	screech_particles = moto_node.find_node("ScreechParticles");
	assert(screech_particles != null);
	
	sprinarm_start_pos = springarm.transform.origin;
	
	track_node = get_tree().current_scene.find_node("TrackPath", true, false);
	assert(track_node != null)
	track_curve = track_node.curve;
	assert(track_curve != null)
	
	#player 1 should not be constrained
	if name == "r1":
		ctl = CtlState.new(self);
		vehicle_node.is_constrained_to_track = false;
	else:
		ctl = AICtl.new(self);
	
	springarm.add_excluded_object(vehicle_node.get_rid())
	
	moto_anim = moto_node.get_node("AnimationPlayer");
	rider_anim = rider_node.get_node("AnimationPlayer");
	
	moto_anim.get_animation("SitIdle").set_loop(true);
	rider_anim.get_animation("SitIdle").set_loop(true);
	rider_anim.get_animation("Run").set_loop(true);
	rider_anim.get_animation("StandUp").set_loop(false);
	rider_anim.get_animation("TrickLong").set_loop(false);
	rider_anim.get_animation("TrickShort").set_loop(false);
	rider_anim.get_animation("MountL").set_loop(false);
	moto_anim.get_animation("TrickLong").set_loop(false);
	moto_anim.get_animation("TrickShort").set_loop(false);
	moto_anim.get_animation("MountL").set_loop(false);
	
	moto_anim.current_animation = "SitIdle";
	rider_anim.current_animation = "SitIdle";

var did_screech = false;

func orient_bike(delta):
	var flip_factor = Vector3.UP.dot(vehicle_node.transform.basis.y);
	#print("flip: ", flip_factor)
	if flip_factor <= 0.6:
		do_ragdoll();

func _physics_process(delta):
	if rider_state == RiderStates.RIDING:
		orient_bike(delta);

var ragdoll_did_rest:bool = false;
func _process(delta):
	ctl.update(delta, get_viewport());
	
	if freeze_invincibility > 0:
		freeze_invincibility -= delta;
	
	match rider_state:
		RiderStates.SITTING:
			snap_to_moto();
			moto_anim.current_animation = "SitIdle";
			rider_anim.current_animation = "SitIdle";
			
			screech_particles.emitting = false;
			if abs(ctl.vFwd) > 0:
				screech_particles.emitting = true;
				did_screech = false;
				rider_state = RiderStates.RIDING;
		
		RiderStates.RIDING:
			snap_to_moto();
			moto_anim.current_animation = "Ride";
			rider_anim.current_animation = "Ride";
			vehicle_node.engine_force = ctl.vFwd * speed;
			vehicle_node.steering = ctl.vTurn * handling;
			
			var vel_length = vehicle_node.linear_velocity.length();
			var screech_threshold = speed * 0.1;
			
			if !did_screech:
				if vel_length >= screech_threshold:
					did_screech = true;
					screech_particles.emitting = false;
			else:
				if ctl.vFwd <= 0:
					did_screech = true;
				if vel_length < screech_threshold:
					screech_particles.emitting = false;
			
			if ctl.pressed_handbrake:
				#do_ragdoll();
				vehicle_node.brake = 2.5;
				if vel_length >= screech_threshold:
					screech_particles.emitting = true;
				else:
					screech_particles.emitting = false;
					
					if vel_length <= 0.1 and vehicle_node.global_transform.origin.y < 3.0:
						vehicle_node.linear_velocity = Vector3.ZERO;
			else:
				vehicle_node.brake = 0;
				if vel_length < screech_threshold and ctl.vFwd > 0:
					screech_particles.emitting = true;
				else:
					screech_particles.emitting = false;
			
			if abs(ctl.vFwd) == 0 and vel_length <= 0.1:
				rider_state = RiderStates.SITTING;
		
		RiderStates.RAGDOLL:
			var root_bone:PhysicalBone = rider_skeleton.get_node("Physical Bone root") as PhysicalBone;
			assert(root_bone != null);
			var root_bone_velocity = PhysicsServer.body_get_state(root_bone.get_rid(), PhysicsServer.BODY_STATE_LINEAR_VELOCITY);
			#print(root_bone_velocity.length())
			if root_bone_velocity.length() <= 0.15:
				ragdoll_did_rest = true;
			
			var ragdollcam = rider_skeleton.get_node("RagdollCamera");
			
			waypoint_sensor.global_transform.origin = ragdollcam.global_transform.origin;
			
			if ragdoll_did_rest:
				if ctl.pressed_anything:
					rider_state = RiderStates.GETUP;
					rider_anim.current_animation = "TPose"
					rider_skeleton.physical_bones_stop_simulation();
					onfoot_body.global_transform.origin = ragdollcam.global_transform.origin;
					rider_node.global_transform.origin = ragdollcam.global_transform.origin;
					rider_node.look_at(
						rider_node.global_transform.origin + (camera.transform.basis.z * Vector3(1,0,1)).normalized(),
						Vector3.UP
					)
					rider_anim.play("StandUp");
		
		RiderStates.GETUP:
			if !rider_anim.is_playing():
				rider_state = RiderStates.ONFOOT;
				onfoot_body.enable(self);
				
		RiderStates.ONFOOT:
			rider_node.transform = onfoot_body.transform;
			waypoint_sensor.global_transform.origin = onfoot_body.global_transform.origin;
		
		RiderStates.MOUNTING:
			waypoint_sensor.transform = Transform.IDENTITY;
			rider_node.transform = vehicle_node.transform;
			if !rider_anim.is_playing():
				rider_state = RiderStates.SITTING;
		_:
			pass
	
	if freeze_duration > 0:
		freeze_duration -= delta;
		vehicle_node.linear_velocity = Vector3.ZERO;
		vehicle_node.angular_velocity = Vector3.ZERO;
		vehicle_node.global_transform.origin = freeze_origin;
	
	update_camera(delta);
	
func do_freeze(t:float = 0.5):
	freeze_origin = vehicle_node.global_transform.origin;
	var vel = vehicle_node.linear_velocity.length();
	
	if rider_state != RiderStates.RIDING:
		return;

	if freeze_invincibility > 0:
		return
	
	if freeze_origin.y < 3.0 and vel > freeze_fall_velocity_threshold:
		print("going too fast during freeze: ", vel);
		freeze_duration = t;
		var damp = 0.6;
		do_ragdoll(vehicle_node.linear_velocity * Vector3(1, 0.2, 1) * damp);

func do_ragdoll(launch_vec:Vector3 = Vector3(0,0,0)):
	if rider_state == RiderStates.RAGDOLL:
		return;
	get_tree().current_scene.fall_counter += 1;
	print("fall count: ", get_tree().current_scene.fall_counter);
	rider_skeleton.physical_bones_start_simulation();
	rider_state = RiderStates.RAGDOLL;
	ragdoll_did_rest = false;
	var root_bone:PhysicalBone = rider_skeleton.get_node("Physical Bone root") as PhysicalBone;
	assert(root_bone != null);
	set_all_bone_velocities(launch_vec);
	screech_particles.emitting = false;
	mount_mesh.visible = true;
	vehicle_node.engine_force = 0;
	vehicle_node.steering = 0;

func set_all_bone_velocities(set_vel:Vector3):
	print("set_all_bone_vel: ", set_vel);
	for child in rider_skeleton.get_children():
		var bone:PhysicalBone = child as PhysicalBone;
		if bone != null:
			PhysicsServer.body_set_state(
				bone.get_rid(),
				PhysicsServer.BODY_STATE_LINEAR_VELOCITY,
				set_vel
			);

func update_camera(delta):
	match rider_state:
		RiderStates.SITTING:
			do_orbit_cam(delta);
		RiderStates.RAGDOLL:
			do_orbit_cam(delta, true);
		RiderStates.ONFOOT:
			if ctl.pressed_handbrake:
				do_lookat_cam(delta, vehicle_node.global_transform.origin);
			else:
				do_orbit_cam(delta, false);
		_:
			do_follow_cam(delta);

func do_lookat_cam(delta, target:Vector3):
	ctl.cam_rot.x = clamp(ctl.cam_rot.x, -0.5, 0.5);
	ctl.cam_rot.y = clamp(ctl.cam_rot.y, -0.15, 0.15);	
	ctl.cam_rot.x *= 0.9;
	
	var dt = target - rider_node.global_transform.origin;
	springarm.look_at_from_position(
		(rider_node.global_transform.origin + sprinarm_start_pos) + dt.normalized(),
		target,
		Vector3.UP
	);
	camera.look_at(target, Vector3.UP);

func do_orbit_cam(delta, ragdoll:bool = false):
	ctl.cam_rot.y = clamp(ctl.cam_rot.y, -0.70, 0.40);
	var origin = springarm.transform.origin;
	
	var target:Vector3;
	if ragdoll:
		target = rider_skeleton.get_node("RagdollCamera").global_transform.origin;
	else:
		target = rider_node.global_transform.origin;
	
	springarm.transform = Transform.IDENTITY.rotated(
		Vector3.UP,
		ctl.cam_rot.x
	).rotated(
		springarm.transform.basis.x,
		ctl.cam_rot.y
	);
	if ragdoll:
		springarm.global_transform.origin = target + (Vector3.UP * 2.5);
	else:
		springarm.transform.origin = origin;
	camera.look_at(target + (Vector3.UP * 2.5), Vector3.UP);
	
func do_follow_cam(delta):
	ctl.cam_rot.x = clamp(ctl.cam_rot.x, -0.5, 0.5);
	ctl.cam_rot.y = clamp(ctl.cam_rot.y, -0.15, 0.15);	
	ctl.cam_rot.x *= 0.9;
	springarm.transform = moto_node.transform.rotated(Vector3.UP, ctl.cam_rot.x);
	springarm.transform.origin = sprinarm_start_pos + moto_node.transform.origin + (moto_node.transform.basis.z);
	camera.look_at(rider_node.global_transform.origin, Vector3.UP);
	
func _input(event):
	ctl.handle_event(event);

func snap_to_moto():
	rider_node.global_transform = moto_node.global_transform;
