extends KinematicBody

const CtlState = preload("res://scripts/CtlState.gd");
const Rider = preload("res://scripts/Rider.gd");

var gravity:Vector3 = Vector3(0, -9.8, 0);

var rider:Spatial;
var hitbox:Area;

func disable():
	transform.origin = Vector3(-999,-999,-999);
	rider = null;

func enable(r:Spatial):
	rider = r;
	assert(rider != null);

func _ready():
	disable();
	hitbox = get_node("Area");
	assert(hitbox != null);

func _physics_process(delta):
	if rider == null:
		return;
	
	if rider.rider_state != Rider.RiderStates.ONFOOT:
		disable();
		return;
	
	for node in hitbox.get_overlapping_bodies():
		if node.rider:
			var vel = node.linear_velocity.length();
			if vel > 1.0:
				var dir = (node.global_transform.origin - global_transform.origin).normalized()
				rider.do_ragdoll(dir * vel);
	
	rider.can_mount = false;
	if self in rider.mount_area.get_overlapping_bodies():
		rider.can_mount = true;
		if rider.ctl.pressed_action:
			rider.rider_state = rider.RiderStates.MOUNTING;
			rider.rider_anim.current_animation = "MountL";
			rider.moto_anim.current_animation = "MountL";
			rider.rider_skeleton.transform = Transform.IDENTITY;
			rider.mount_mesh.visible = false;
			disable();
			return;
	
	var movevec = Vector3(0,0,0);
	var lookvec = (rider.camera.global_transform.basis.z * Vector3(1,0,1)).normalized();

	if abs(rider.ctl.vFwd) > 0 or abs(rider.ctl.vTurn) > 0:
		rider.rider_anim.current_animation = "Run";
		movevec = lookvec * rider.ctl.vFwd;
		movevec += rider.camera.global_transform.basis.x * rider.ctl.vTurn;
		movevec = movevec.normalized() * -20.0;
		rider.rider_node.global_transform.origin = global_transform.origin;
	else:
		rider.rider_anim.current_animation = "StandIdle";
	
	if movevec.length_squared() > 0:
		var ltarg = rider.rider_node.global_transform.origin + movevec;
		rider.rider_skeleton.look_at(ltarg, Vector3.UP);
	
	movevec += gravity;
	move_and_slide(movevec, Vector3.UP, false, 4, 0.785398, false);
