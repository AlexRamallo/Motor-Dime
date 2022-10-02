extends Spatial

var Rider;

var target_node;

export var jitter:float = 1.0;
export var thick:float = 5.0;

export var overlap:float = 1.0;

var arc_influence:Vector3 = Vector3(0, -5.0, 0);

var geo:ImmediateGeometry;

var segments:int = 6;

func _ready():
	Rider = load("res://scripts/Rider.gd");
	geo = get_node("ImmediateGeometry");

func _process(delta):
	if target_node == null:
		visible = false;
		return;
	else:
		visible = true;
	
	assert(target_node != null);
	var target_pos;
	
	if target_node is Rider:
		target_pos = target_node.vehicle_node.global_transform.origin + (Vector3.UP * 2.0);
	else:
		target_pos = target_node.global_transform.origin;
	
	geo.clear();
	geo.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	var seg_last = Vector3.ZERO;
	var seg_step = to_local(target_pos).length() / segments;
	var seg_step_dir = to_local(target_pos).normalized();
	
	var arcfs = [];
	for i in range(segments - 1):
		var arc_f:float = (float(i) / float(segments-1)) - 0.5;
		var seg_end = seg_last + (seg_step_dir * seg_step);
		seg_end += jitter * ((arc_influence * arc_f) + Vector3(
			((randf() - 0.5) * 2.0),
			((randf() - 0.5) * 2.0),
			((randf() - 0.5) * 2.0)
		));
		var overlap_offset = (seg_last - seg_end).normalized() * overlap;
		mk_line(seg_last + overlap_offset, seg_end - overlap_offset, thick);
		seg_last = seg_end;
		
	mk_line(seg_last, to_local(target_pos), thick);
	geo.end();

func mk_line(from:Vector3, to:Vector3, thick:float):
	var th:float = thick / 2.0;
	
	var dir = (to - from).normalized();
	var prp = dir.cross(Vector3(dir.y, dir.z, dir.x)).normalized();
	var prp2 = prp.cross(dir).normalized();

	var f_1 = from + (prp * th);
	var f_2 = from + (prp * -th);
	var t_1 = to + (prp * th);
	var t_2 = to + (prp * -th);

	var f2_1 = from + (prp2 * th);
	var f2_2 = from + (prp2 * -th);
	var t2_1 = to + (prp2 * th);
	var t2_2 = to + (prp2 * -th);

	#line body
	geo.set_uv(Vector2(0.0, 0.0));
	geo.add_vertex(Vector3(f_1.x, f_1.y, f_1.z))
	geo.set_uv(Vector2(1.0, 0.0));
	geo.add_vertex(Vector3(f_2.x, f_2.y, f_2.z))
	geo.set_uv(Vector2(0.0, 1.0));
	geo.add_vertex(Vector3(t_1.x, t_1.y, t_1.z))
	geo.set_uv(Vector2(0.0, 1.0));
	geo.add_vertex(Vector3(t_1.x, t_1.y, t_1.z))
	geo.set_uv(Vector2(1.0, 0.0));
	geo.add_vertex(Vector3(t_2.x, t_2.y, t_2.z))
	geo.set_uv(Vector2(1.0, 1.0));
	geo.add_vertex(Vector3(f_2.x, f_2.y, f_2.z))

	#line body 2
	geo.set_uv(Vector2(0.0, 0.0));
	geo.add_vertex(Vector3(f2_1.x, f2_1.y, f2_1.z))
	geo.set_uv(Vector2(1.0, 0.0));
	geo.add_vertex(Vector3(f2_2.x, f2_2.y, f2_2.z))
	geo.set_uv(Vector2(0.0, 1.0));
	geo.add_vertex(Vector3(t2_1.x, t2_1.y, t2_1.z))
	geo.set_uv(Vector2(0.0, 1.0));
	geo.add_vertex(Vector3(t2_1.x, t2_1.y, t2_1.z))
	geo.set_uv(Vector2(1.0, 0.0));
	geo.add_vertex(Vector3(t2_2.x, t2_2.y, t2_2.z))
	geo.set_uv(Vector2(1.0, 1.0));
	geo.add_vertex(Vector3(f2_2.x, f2_2.y, f2_2.z))
