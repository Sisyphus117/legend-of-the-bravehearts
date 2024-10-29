extends TouchScreenButton

var finger_index:=-1

const DRAG_RADIUS:=32

var drag_offset:Vector2

@onready var rest_pos:=global_position

func _input(event: InputEvent) -> void:
	var st :=event as InputEventScreenTouch
	if st:
		if st.pressed and finger_index==-1:
			var global_pos=st.position*get_canvas_transform()
			var local_pos=global_pos*get_global_transform()
			var rec=Rect2(Vector2.ZERO,texture_normal.get_size())
			if rec.has_point(local_pos):
				finger_index=st.index
				drag_offset=global_pos-global_position
		elif not st.pressed and finger_index==st.index:
			finger_index=-1
			global_position=rest_pos
			Input.action_release("move_right")
			Input.action_release("move_left")
	var sd :=event as InputEventScreenDrag
	if sd and sd.index==finger_index:
		var wish_pos:=sd.position*get_canvas_transform()-drag_offset
		var movement=(wish_pos-rest_pos).limit_length(DRAG_RADIUS)
		global_position=movement+rest_pos
		
		var dir:Vector2=movement/DRAG_RADIUS
		if dir.x<0:
			Input.action_release("move_right")
			Input.action_press("move_left",-dir.x)
		elif dir.x>0:
			Input.action_release("move_left")
			Input.action_press("move_right",dir.x)
	
