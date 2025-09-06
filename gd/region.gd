extends Area2D

var db: SQLiteHelper
var player_node
var visual_container
var path_region_node
var path_create_branch_button

var data : Dictionary = {
	'id' : 0,
	'name' : '',
	'flag' : {"flag_slot_1": ""},
	'department_open': false,
	'department_id': -1
}


func _ready():
	# Установим нод игрока в каждый регион
	player_node = get_node("/root/map/Player")
	path_region_node = "/root/map/regions/{0}".format([data.get('name')])
	path_create_branch_button = "/root/map/regions/{0}/VisualContainer//City_{0}/create_branch".format([data.get('name')])
	
	# Убедимся, что визуальный контейнер существует
	visual_container = get_node_or_null("VisualContainer")
	if visual_container:
		visual_container.hide()

func _on_input_event(_viewport, event, _shape_idx):
	if not player_node.player_data['company_selected']:
		return
	
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		return
	
	player_node.info_region.body.visible = false
	is_open_department()
	
	if is_new_appeal_to_region():
		db = SQLiteHelper.new("user://game_database.db")
		var region_info = get_region_info(db)
		var company_department_info = get_company_department_workers(db)
		db.close_database()
		
		print('company_department_info: ', company_department_info)
		
		#var flag = get_node('/root/map/Player/UI/INFORegion/background/head/flag') as Control
		#set_flag(flag)
		player_node.info_region.name_region.text = data['name']
		player_node.info_region.total_population.text = 'Население: ' + region_info['total_people']
		player_node.info_region.total_workers_count.text = company_department_info['total_workers']
		player_node.info_region.free_workers_count.text = company_department_info['free_workers']
		player_node.info_region.busy_workers_count.text = company_department_info['busy_workers']
		#var relationship = get_node("/root/map/Player/UI/INFORegion/background/relationship")
		#if base_info_region['name_nation'] == str(get_node("/root/map/Player/UI/Menu/Panel/player_info/nation").text).substr(4):
			#relationship.self_modulate = Color(0.207, 1.0, 0.176)
	
	player_node.camera_2d.can_pan = false
	move_camera_to_target()
	
	# Показываем панель информации
	player_node.info_region.visible = true
	
	# Отладочная информация
	print("Клик по региону: ", data)
	player_node.info_region.data_region = data


#
# Управление камерой
#

## Плавное перемещение камеры к маркеру города
func move_camera_to_target():
	var city_path = "VisualContainer/City_{0}/VisualMarker".format([data.get('name', '')])
	var visual_marker = get_node_or_null(city_path)
	
	if visual_marker:
		# Временно отключаем управление зумом
		player_node.camera_2d.is_dragging = false
		player_node.camera_2d.can_keyboard = false
		
		# Создаем Tween для плавного перемещения
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUINT)
		
		# Анимация перемещения камеры
		tween.tween_property(
			player_node.camera_2d,
			"global_position",
			visual_marker.global_position,
			0.5  # Длительность анимации в секундах
		)
		
		# Параллельная анимация зума (0.5)
		tween.parallel().tween_property(
			player_node.camera_2d,
			"zoom",
			Vector2(1.7, 1.7),  # Равномерный зум по обеим осям
			1  # Длительность анимации в секундах
		)
		
		# По завершении анимации восстанавливаем управление
		tween.tween_callback(func():
			# Восстанавливаем управление, но оставляем can_pan = false
			player_node.camera_2d.target_zoom = player_node.camera_2d.zoom
			
			# Важно: сбрасываем состояние перетаскивания
			player_node.camera_2d.is_dragging = false
			player_node.camera_2d.last_drag_pos = Vector2.ZERO
		)
	else:
		push_warning("Не найден маркер города по пути: %s" % city_path)


#
# Управление кнопками
#

func create_branch():
	if player_node.player_data['company_selected']:
		print("Создаём филиал!")
		db = SQLiteHelper.new("user://game_database.db")
		var response = db.create_company_departments({'id': player_node.player_data['company_id'], 'region_id': data['id'], 'region_name': data['name']})
		db.close_database()
		if response['status'] == 1:
			data['department_open'] = true
			data['department_id'] = response['result']['id']
			get_node(path_create_branch_button).visible = false
			player_node.info_region.basement.visible = true


#
# Установка данных
#

func set_flag(flag: Control):
	# Очищаем предыдущие элементы флага
	for child in flag.get_children():
		child.queue_free()
	
	# Проходим по всем слоям флага из данных
	for flag_slot in data['flag']:
		# Создаем новый TextureRect для слоя флага
		var texture_rect = TextureRect.new()
		
		# Загружаем текстуру флага (если нужно)
		var flag_texture = load("res://image/{0}.svg".format([flag_slot]))
		if flag_texture:
			texture_rect.texture = flag_texture
		
		# Устанавливаем цвет из данных
		var color_code = data['flag'][flag_slot]
		if color_code.is_valid_html_color():
			texture_rect.modulate = Color(color_code)
		
		# Добавляем в контейнер
		flag.add_child(texture_rect)
		
		# Настраиваем параметры отображения
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.size = flag.size
		texture_rect.position = Vector2.ZERO


#
# Возвращание данных
#

## Возвращает всю базовую информацию о регионе
func get_region_info(database: SQLiteHelper):
	var region_info = database.find_records_by_params("regions", {"id": data['id']}, [], 1)
	var population_groups = database.find_records_by_params('population_groups', {'region_id': data['id']})
	
	var total_population = 0
	for population_group in population_groups:
		total_population += population_group['total_people']
	
	return {'region_info': region_info, 'total_people': str(total_population)}

## Возвращает кнопку для установки филлиала компании
func get_path_region_node_and_region_id() -> Dictionary:
	if path_region_node == null and path_create_branch_button == null:
		path_region_node = "/root/map/regions/{0}".format([data.get('name')])
		path_create_branch_button = "/root/map/regions/{0}/VisualContainer//City_{0}/create_branch".format([data.get('name')])
	return {'path_region_node': path_region_node, 'region_id': data['id']}

## Возвращает данные по персоналу филлиала выбранной компании, если такова существует
func get_company_department_workers(database: SQLiteHelper):
	var company_department_record: Dictionary = {}
	var total_workers: int = 0
	var busy_workers: int = 0
	var free_workers: int = 0
	
	if data['department_id'] == -1:
		return {'total_workers': str(total_workers), 'free_workers': str(0), 'busy_workers': str(0)}
	
	company_department_record = (database.find_records_by_params("company_departments", {"id": data['department_id']}, [], 1))[0]
	var tasks = db.find_records('department_tasks', 'company_department_id', data['department_id'])
	
	if tasks.is_empty():
		return {'total_workers': str(total_workers), 'free_workers': str(total_workers), 'busy_workers': str(0)}
		
	for task in tasks:
		var busy_workers_data = JSON.parse_string(task['busy_workers_data'])
		busy_workers += int(busy_workers_data[0][1])
	
	total_workers = company_department_record['total_workers']
	free_workers = total_workers - busy_workers
	
	return {'total_workers': str(total_workers), 'free_workers': str(free_workers), 'busy_workers': str(busy_workers)}

#
# Проверки
#

## Проверка на открытие департамента
func is_open_department():
	if not data['department_open']:
		player_node.info_region.basement.visible = false
		return false
	else:
		player_node.info_region.basement.visible = true
		return true

## Проверка на обращение к региону. Является ли оно новым?
func is_new_appeal_to_region():
	var id = get_node("/root/map/Player/UI/info_region/id")
	if int(id.text) != data['id']:
		#print('новое обращение')
		id.text = str(data['id'])
		return true
	#print('повторное обращение')
	return false
