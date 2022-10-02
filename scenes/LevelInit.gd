extends Spatial

const luna:String = "03000000491900001a04000001010000,Amazon Luna Controller,a:b0,b:b1,x:b2,y:b3,back:b6,guide:b8,start:b7,leftshoulder:b4,rightshoulder:b5,leftstick:b9,rightstick:b10,dpup:h0.1,dpleft:h0.8,dpdown:h0.4,dpright:h0.2,-leftx:-a0,+leftx:+a0,-lefty:-a1,+lefty:+a1,-rightx:-a3,+rightx:+a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,";

var riders:Spatial;

var did_start:bool = false;

var freeze_countdown:float = 0;
var freeze_countdown_time:float = 10.0;
var freeze_reset_time:float = 3.0;
var freeze_reset_countdown:float = freeze_reset_time;

var fall_counter:int = 0;

var cam;
var end_cam;
var menu_cam;

var r1;

var menu_wait:float = 1.0;

func _ready():
	Input.add_joy_mapping(luna, true);
	
	cam = find_node("Camera");
	assert(cam != null);
	cam.set_target($Riders/r1);
	
	end_cam = find_node("EndCamera") as Camera;
	assert(end_cam != null);
	
	menu_cam = find_node("MenuCamera") as Camera;
	assert(menu_cam != null);
	
	riders = find_node("Riders") as Spatial;
	assert(riders != null)
	
	r1 = riders.find_node("r1");
	assert(r1 != null);

func _process(delta):
	if !did_start:
		menu_cam.current = true;
		if menu_wait > 0:
			menu_wait -= delta;
		if r1.ctl.pressed_anything and menu_wait <= 0:
			did_start = true;
			var menuui = find_node("UI_Menu") as Control;
			assert(menuui != null);
			menuui.visible = false;
			
			var raceui = find_node("UI_Race") as Control;
			assert(raceui != null);
			raceui.visible = true;
			
		return;
	else:
		menu_cam.current = false;
		
	if end_cam.current:
		Input.set_mouse_mode(0);
	else:
		if Input.is_key_pressed(KEY_ESCAPE):
			Input.set_mouse_mode(0);
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	
	if freeze_countdown > 0:
		freeze_countdown -= delta;
		if freeze_countdown <= 0:
			do_freeze();
			freeze_reset_countdown = freeze_reset_time;
	
	if freeze_reset_countdown > 0:
		freeze_reset_countdown -= delta;
		if freeze_reset_countdown <= 0:
			freeze_countdown = freeze_countdown_time;

func do_freeze():
	print("freeze!");
	for c in riders.get_children():
		c.do_freeze();

func on_race_end(lap_times, lap_count):
	find_node("UI_Race").visible = false;
	var endui = find_node("UI_End");
	endui.update_values(lap_count, lap_times, fall_counter);
	endui.visible = true;
	
	cam.current = false;
	end_cam.current = true;
