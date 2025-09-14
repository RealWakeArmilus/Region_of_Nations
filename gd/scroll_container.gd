extends ScrollContainer

enum ScrollDirection {
	VERTICAL,
	HORIZONTAL
}

@export var scroll_direction: ScrollDirection = ScrollDirection.VERTICAL
@export var delete_vertical_scroll_mode = false
@export var drag_speed: float = 1.0
@export var wheel_speed: int = 30

var is_dragging := false
var last_position := Vector2.ZERO



func _ready():
	#print("Управление настроено для:", name)
	
	# Пропускаем события мыши дальше, чтобы родительский ScrollContainer видел их
	mouse_filter = MOUSE_FILTER_PASS
	_attach_input_forwarding(self)
	
	# Настраиваем режимы скролла
	match scroll_direction:
		ScrollDirection.VERTICAL:
			horizontal_scroll_mode = SCROLL_MODE_SHOW_NEVER
			if delete_vertical_scroll_mode:
				vertical_scroll_mode = SCROLL_MODE_SHOW_NEVER
			#print(name, ": Режим вертикального скролла")
		ScrollDirection.HORIZONTAL:
			vertical_scroll_mode = SCROLL_MODE_SHOW_NEVER
			horizontal_scroll_mode = SCROLL_MODE_SHOW_NEVER
			#print(name, ": Режим горизонтального скролла")
	_attach_input_forwarding(self)


func _attach_input_forwarding(node: Node):
	for child in node.get_children():
		if child == self:
			continue
			
		child.mouse_filter = MOUSE_FILTER_IGNORE
		#print('child name: ', child.name)
		#var forward_func = func(event):
			#_gui_input(event, child.name)
		#child.gui_input.connect(forward_func)
		_attach_input_forwarding(child)


func _gui_input(event, name_node = self.name):
	if event is InputEventMouseButton:
		await _process_event_mouse_button_and_drag(event, name_node)
	elif event is InputEventMouseMotion and is_dragging:
		await _process_event_mouse_button(event, name_node)
	elif event is InputEventScreenTouch:
		await _process_event_screen_touch(event, name_node)
	elif event is InputEventScreenDrag and is_dragging:
		await _process_event_screen_drag(event, name_node)

## === Колесо мыши ===
func _process_event_mouse_button_and_drag(event, _name_node):
	if scroll_direction == ScrollDirection.VERTICAL:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_vertical -= wheel_speed
			#print(_name_node, ": Скролл вверх (колесико)")
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_vertical += wheel_speed
			#print(name_node, ": Скролл вниз (колесико)")
			accept_event()

	elif scroll_direction == ScrollDirection.HORIZONTAL:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_horizontal -= wheel_speed
			#print(name_node, ": Скролл влево (колесико)")
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_horizontal += wheel_speed
			#print(name_node, ": Скролл вправо (колесико)")
			accept_event()

	# Нажатие ЛКМ или ПКМ — начинаем drag
	if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		is_dragging = event.pressed
		last_position = event.position
		#if is_dragging:
			#print(name, ": Начало перетаскивания (мышь)")
		#else:
			#print(name, ": Конец перетаскивания (мышь)")
		accept_event()

## Перетаскивание мышью (ПК)
func _process_event_mouse_button(event, _name_node):
	
	var delta = last_position - event.position
	match scroll_direction:
		ScrollDirection.VERTICAL:
			scroll_vertical += delta.y * drag_speed
			#print(name_node, ": Вертикальный скролл (перетаскивание) - delta y:", delta.y)
		ScrollDirection.HORIZONTAL:
			scroll_horizontal += delta.x * drag_speed
			#print(name_node, ": Горизонтальный скролл (перетаскивание) - delta x:", delta.x)
	last_position = event.position
	accept_event()

## Touch (телефон)
func _process_event_screen_touch(event, _name_node):
	is_dragging = event.pressed
	last_position = event.position
	#if event.pressed:
		#print(name_node, ": Начало перетаскивания (тач)")
	#else:
		#print(name_node, ": Конец перетаскивания (тач)")
	accept_event()

## Touch brag (телефон)
func _process_event_screen_drag(event, _name_node):
	var delta = event.position - last_position
	match scroll_direction:
		ScrollDirection.VERTICAL:
			scroll_vertical -= delta.y * drag_speed
			#print(name_node, ": Вертикальный скролл (тач-драг) - delta y:", delta.y)
		ScrollDirection.HORIZONTAL:
			scroll_horizontal -= delta.x * drag_speed
			#print(name_node, ": Горизонтальный скролл (тач-драг) - delta x:", delta.x)
	last_position = event.position
	accept_event()

#extends ScrollContainer
#
#@export var drag_speed = 1.0
#var dragging = false
#var last_pos = Vector2.ZERO
#
#func _ready():
	### Настройка скролла
	#scroll_horizontal = true
	#scroll_vertical = false
	#
#func _input(event):
	## Обработка нажатия
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#dragging = event.pressed
			#last_pos = event.position
			#get_viewport().set_input_as_handled()
	#
	## Обработка движения
	#elif dragging and event is InputEventMouseMotion:
		#var delta_x = event.position.x - last_pos.x
		#scroll_horizontal -= delta_x * drag_speed
		#last_pos = event.position
		#get_viewport().set_input_as_handled()
		#
	#elif dragging and event is InputEventScreenTouch:
		#dragging = event.pressed
		#last_pos = event.position
		#get_viewport().set_input_as_handled()
		#
	#elif dragging and event is InputEventScreenDrag:
		#var delta_x = event.position.x - last_pos.x
		#scroll_horizontal -= delta_x * drag_speed
		#last_pos = event.position
		#get_viewport().set_input_as_handled()
	
	
