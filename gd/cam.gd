extends Camera2D

@onready var camera_2d: Camera2D = $"."
@onready var match_theme_music: AudioStreamPlayer2D = $match_theme_music

# Настройки камеры
@export var zoom_speed: float = 8.0          # Скорость интерполяции зума
@export var min_zoom: float = 0.7
@export var max_zoom: float = 2.7
@export var zoom_step: float = 0.1           # Шаг зума для колесика мыши
@export var freefly_speed: float = 500       # Базовая скорость перемещения
@export var pan_speed: float = 1.0           # Чувствительность перетаскивания
@export var rotation_speed: float = 1.0
@export var can_pan: bool = true
@export var can_zoom: bool = true
@export var can_rotate: bool = false
@export var can_keyboard: bool = true

# Настройки моря
@export var sea_color: Color = Color("#244D76")

# Переменные состояния
var target_zoom: Vector2 = Vector2.ONE       # Целевой зум для плавного изменения
var touch_points: Dictionary = {}
var start_zoom: Vector2
var start_dist: float
var start_angle: float
var current_angle: float
var last_drag_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func _ready():
	start_zoom = zoom
	target_zoom = zoom  # Инициализируем target_zoom текущим значением
	
	get_tree().root.transparent_bg = false
	get_viewport().transparent_bg = false
	RenderingServer.set_default_clear_color(sea_color)
	
	## Простые волны через периодическое изменение цвета
	#create_simple_waves()

func _physics_process(delta: float) -> void:
	if can_keyboard:
		# Управление с клавиатуры (скорость зависит от текущего зума)
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		position += input_dir * freefly_speed * delta / zoom.x  # Делаем скорость обратно пропорциональной зуму
	
	# Плавное применение зума
	if can_zoom:
		zoom = zoom.lerp(target_zoom, zoom_speed * delta)
		zoom = zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))


# -------------------
# Настройки фона моря
# -------------------
#func create_simple_waves():
	## Анимируем цвет моря для эффекта волн
	#var tween = create_tween()
	#tween.set_loops()
	#tween.tween_method(animate_sea_color, 0.0, 1.0, 2.0)
#
#func animate_sea_color(progress: float):
	## Легкое изменение цвета для эффекта волн
	#var variation = sin(progress * PI * 2) * 0.05
	#var new_color = Color(
		#sea_color.r + variation,
		#sea_color.g + variation * 0.5, 
		#sea_color.b + variation * 0.3,
		#sea_color.a
	#)
	#RenderingServer.set_default_clear_color(new_color)


# -------------------
# Настройки камеры и ее перемещения
# -------------------
func _unhandled_input(event):
	# Обработка ввода только если разрешено
	if not can_pan and not can_zoom:
		return
	
	# Обработка зума колесом мыши
	if event is InputEventMouseButton and can_zoom:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = (target_zoom - Vector2(zoom_step, zoom_step)).clamp(
				Vector2(min_zoom, min_zoom), 
				Vector2(max_zoom, max_zoom))
			get_viewport().set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = (target_zoom + Vector2(zoom_step, zoom_step)).clamp(
				Vector2(min_zoom, min_zoom), 
				Vector2(max_zoom, max_zoom))
			get_viewport().set_input_as_handled()
		
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				last_drag_pos = event.position
				is_dragging = true
			else:
				is_dragging = false
	
	# Обработка перетаскивания мышью (скорость зависит от текущего зума)
	elif event is InputEventMouseMotion and is_dragging and can_pan:
		var drag_offset = (last_drag_pos - event.position) * pan_speed / zoom.x
		position += drag_offset
		last_drag_pos = event.position
		get_viewport().set_input_as_handled()
		set_actual_position_match_theme_music()

	# Обработка сенсорного ввода
	elif event is InputEventScreenTouch:
		_handle_touch(event)
		set_actual_position_match_theme_music()

	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

	if touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		start_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		start_angle = get_angle(touch_point_positions[0], touch_point_positions[1])
		start_zoom = target_zoom
	elif touch_points.size() < 2:
		start_dist = 0

func _handle_drag(event: InputEventScreenDrag):
	touch_points[event.index] = event.position

	if touch_points.size() == 1 and can_pan:
		offset -= event.relative * pan_speed / zoom.x  # Учитываем зум и для сенсорного управления
	elif touch_points.size() == 2:
		var touch_point_positions = touch_points.values()
		var current_dist = touch_point_positions[0].distance_to(touch_point_positions[1])
		current_angle = get_angle(touch_point_positions[0], touch_point_positions[1])

		if can_zoom and start_dist > 0:
			var zoom_factor = start_dist / current_dist
			target_zoom = (start_zoom / zoom_factor).clamp(
				Vector2(min_zoom, min_zoom), 
				Vector2(max_zoom, max_zoom))
		
		if can_rotate:
			rotation -= (current_angle - start_angle) * rotation_speed
			start_angle = current_angle

func get_angle(p1: Vector2, p2: Vector2) -> float:
	var delta = p2 - p1
	return fmod((atan2(delta.y, delta.x) + PI), (2 * PI))


# -------------------
# Настройки музыки
# -------------------

func set_actual_position_match_theme_music():
	match_theme_music.global_position = camera_2d.global_position
