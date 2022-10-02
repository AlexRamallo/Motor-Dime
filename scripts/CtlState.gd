class_name CtlState

var viewport:Viewport;
var mouse_sensitivity:float = 0.5;
var vFwd:float;
var vTurn:float;
var vPitch:float;
var vYaw:float;
var cam_rot:Vector3 = Vector3(0, 0, 0);

var pressed_handbrake:bool = false;
var pressed_action:bool = false;
var pressed_trick_long:bool = false;
var pressed_trick_short:bool = false;
var pressed_anything:bool = false;

var rider:Spatial;

func _init(r:Spatial):
	rider = r;
	assert(rider != null);

func update(delta, vp):
	viewport = vp;

	vFwd = (Input.get_action_strength("Forward") + Input.get_action_strength("WalkFwd"));
	vFwd -= (Input.get_action_strength("Reverse") + Input.get_action_strength("WalkBack"));
	
	vFwd = clamp(vFwd, -1, 1);
	
	vTurn = Input.get_action_strength("TurnLeft") - Input.get_action_strength("TurnRight");
	vPitch = Input.get_action_strength("LookDown") - Input.get_action_strength("LookUp");
	vYaw = Input.get_action_strength("LookRight") - Input.get_action_strength("LookLeft");
	pressed_handbrake = Input.is_action_pressed("Handbrake");
	pressed_action = Input.is_action_pressed("Action");
	pressed_trick_long = Input.is_action_pressed("TrickLong");
	pressed_trick_short = Input.is_action_pressed("TrickShort");
	
	cam_rot.x -= vYaw * 0.1;
	cam_rot.y -= vPitch * 0.1;
	
	pressed_anything =         \
		pressed_trick_short or \
		pressed_trick_long  or \
		pressed_action      or \
		pressed_handbrake;

func handle_event(event):
	if viewport == null: return;
	if event is InputEventMouseMotion:
		var vp_rect = viewport.get_visible_rect().size * (1.0 - mouse_sensitivity);
		var rot = event.relative;
		cam_rot.x -= rot.x / vp_rect.x;
		cam_rot.y -= rot.y / vp_rect.y;
