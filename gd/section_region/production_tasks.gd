extends Control

# ---- UI -----
@onready var player_node = $"../../../../../.."
@onready var create_task_button = $head/create_task
@onready var create_task_button_title = $head/create_task/Label
@onready var list_tasks = $scroll/list

@onready var filter_task = $filter_task
@onready var all_tasks_button = $filter_task/all
@onready var in_progress_tasks_button = $filter_task/in_progress
@onready var completed_tasks_button = $filter_task/completed

@onready var stages_created_task = $stages_created_task
@onready var stage_1_button = $"stages_created_task/1"
@onready var stage_2_button = $"stages_created_task/2"
@onready var stage_3_button = $"stages_created_task/3"
@onready var stage_4_button = $"stages_created_task/4"

@onready var info_create_task_container = $info_create_task
@onready var production_volume_total = $info_create_task/production_volume_total/count
@onready var cost_price_product_total = $info_create_task/price_cost_total/count

@onready var details_stage = $details_stage

@onready var material_costs_create_task_container = $material_costs_create_task
@onready var worker_slot_0_container = $material_costs_create_task/w_0
@onready var worker_slot_0_icon = $material_costs_create_task/w_0/icon
@onready var worker_slot_0_required = $material_costs_create_task/w_0/details/required
@onready var material_costs_create_task_slot_1_container = $"material_costs_create_task/1"
@onready var material_costs_create_task_slot_1_icon = $"material_costs_create_task/1/icon"
@onready var material_costs_create_task_slot_1_stock_count = $"material_costs_create_task/1/details/stock_count"
@onready var material_costs_create_task_slot_1_required = $"material_costs_create_task/1/details/required"
@onready var material_costs_create_task_slot_2_container = $"material_costs_create_task/2"
@onready var material_costs_create_task_slot_2_icon = $"material_costs_create_task/2/icon"
@onready var material_costs_create_task_slot_2_stock_count = $"material_costs_create_task/2/details/stock_count"
@onready var material_costs_create_task_slot_2_required = $"material_costs_create_task/2/details/required"
@onready var material_costs_create_task_slot_3_container = $"material_costs_create_task/3"
@onready var material_costs_create_task_slot_3_icon = $"material_costs_create_task/3/icon"
@onready var material_costs_create_task_slot_3_stock_count = $"material_costs_create_task/3/details/stock_count"
@onready var material_costs_create_task_slot_3_required = $"material_costs_create_task/3/details/required"
@onready var material_costs_create_task_slot_4_container = $"material_costs_create_task/4"
@onready var material_costs_create_task_slot_4_icon = $"material_costs_create_task/4/icon"
@onready var material_costs_create_task_slot_4_stock_count = $"material_costs_create_task/4/details/stock_count"
@onready var material_costs_create_task_slot_4_required = $"material_costs_create_task/4/details/required"
@onready var next_stage_button = $details_stage/next_stage
@onready var budget_create_task_count = $details_stage/budget/detaisl/count


# ---- Заготовки экспортируемых сцен ----
var tasks_scene = preload("res://tscn/task.tscn")


# ---- Переменные ----
var db: SQLiteHelper
var active_filter_button = null
var active_stage_button = null
var active_color_button = Color('d9d5c5')
var inactive_color_button = Color("989280")
var stage_current_num = 0
var selected_task_id: String = ""
var selected_task_node: TextureRect

var memory_create_task_data: Dictionary = {
	'stage': [
		{
			'good_id': -1,
			'good_icon_texture': '',
			'good_name': '',
			'good_production_volume': 0,
			#'material_cost_data': [],
			#'workers_data': [],
			'period_production': 0,
			'budget': 0,
			'cost_price_product': {
				1: 0,
				2: 0,
				3: 0,
				4: 0
			}
		},
		[
			{'id': -1, 'texture': '', 'required': 0, 'stock_count': 0, 'cost_price': 0},
			{'id': -1, 'texture': '', 'required': 0, 'stock_count': 0, 'cost_price': 0},
			{'id': -1, 'texture': '', 'required': 0, 'stock_count': 0, 'cost_price': 0},
			{'id': -1, 'texture': '', 'required': 0, 'stock_count': 0, 'cost_price': 0}
		],
		[
			{'id': -1, 'texture': '', 'count': 0, 'salary': 0.1}
		]
	]
}


# ---- Очистка задач ----
## Полная очистка контейнера с задачами
func clear_all_tasks():
	for child in list_tasks.get_children():
		child.queue_free()


# -----------------
# Обновление кнопок
# -----------------

## Обновляет кнопки фильтра задач
func update_active_filter_buttons(button):
	all_tasks_button.self_modulate = inactive_color_button
	in_progress_tasks_button.self_modulate = inactive_color_button
	completed_tasks_button.self_modulate = inactive_color_button

	button.self_modulate = active_color_button
	active_filter_button = button

## Обновляет кнопки этапов создания задачи
func update_active_stages_create_buttons(button):
	stage_1_button.self_modulate = inactive_color_button
	stage_2_button.self_modulate = inactive_color_button
	stage_3_button.self_modulate = inactive_color_button
	stage_4_button.self_modulate = inactive_color_button
	
	button.self_modulate = active_color_button
	active_stage_button = button


#
# Установка данных для списка задзч
#

## Установили созданные задачи
func _set_tasks_to_list(tasks_data: Array):
	var current_time = '{"year": 2024, "month": 6}'
	
	if tasks_data.is_empty():
		return
	
	for task_data in tasks_data:
		var task_instance = tasks_scene.instantiate()
		list_tasks.add_child(task_instance)
		
		task_instance.name = str(task_data['id'])
		
		var material_costs = JSON.parse_string(task_data['material_costs_data'])
		var busy_workers = JSON.parse_string(task_data['busy_workers_data'])
		
		if material_costs == null:
			material_costs = []
		if busy_workers == null:
			busy_workers = []
		
				# Безопасное извлечение данных material_costs
		var material_0_id = 0
		var material_0_qty = 0
		var material_1_id = 1
		var material_1_qty = 0
		var material_2_id = 2
		var material_2_qty = 0
		var material_3_id = 3
		var material_3_qty = 0
		
		if material_costs.size() > 0 and material_costs[0].size() >= 2:
			material_0_id = int(material_costs[0][0])
			material_0_qty = material_costs[0][1]
		if material_costs.size() > 1 and material_costs[1].size() >= 2:
			material_1_id = int(material_costs[1][0])
			material_1_qty = material_costs[1][1]
		if material_costs.size() > 2 and material_costs[2].size() >= 2:
			material_2_id = int(material_costs[2][0])
			material_2_qty = material_costs[2][1]
		if material_costs.size() > 3 and material_costs[3].size() >= 2:
			material_3_id = int(material_costs[3][0])
			material_3_qty = material_costs[3][1]
		
		# Безопасное извлечение данных busy_workers
		var worker_type = 0
		var worker_count = 0
		
		if busy_workers.size() > 0 and busy_workers[0].size() >= 2:
			worker_type = int(busy_workers[0][0])
			worker_count = busy_workers[0][1]
		
		task_instance.selected_mode = 'idle'
		task_instance.set_good_data(
			task_data['good_id'],
			task_data['good_name'],
			task_data['production_volume'],
			task_data['product_cost_price']
		)
		task_instance.set_materials_data(
			task_data['salary_to_task'],
			material_0_id,
			material_0_qty,
			material_1_id,
			material_1_qty,
			material_2_id,
			material_2_qty,
			material_3_id,
			material_3_qty
		)
		task_instance.set_workers_data(
			worker_type,
			worker_count
		)
		task_instance.set_progress_production_data(
			task_data['start_production'], 
			current_time,
			task_data['period_production'],
			task_data['status']
		)

func _set_stage_one_create_task_to_list(tasks_data: Array, good_name: String):
	for task_data in tasks_data:
		
		var task_instance = tasks_scene.instantiate()
		list_tasks.add_child(task_instance)
		
		task_instance.name = str(task_data['id'])
		task_instance.selected_on = true
		task_instance.task_selected.connect(_on_selected_task)
		
		var material_costs = JSON.parse_string(task_data['material_costs_data'])
		var busy_workers = JSON.parse_string(task_data['busy_workers_data'])
		
		if material_costs == null:
			material_costs = []
		if busy_workers == null:
			busy_workers = []
		
		# Безопасное извлечение данных material_costs
		var material_0_id = 0
		var material_0_qty = 0
		var material_1_id = 1
		var material_1_qty = 0
		var material_2_id = 2
		var material_2_qty = 0
		var material_3_id = 3
		var material_3_qty = 0
		
		if material_costs.size() > 0 and material_costs[0].size() >= 2:
			material_0_id = int(material_costs[0][0])
			material_0_qty = material_costs[0][1]
		if material_costs.size() > 1 and material_costs[1].size() >= 2:
			material_1_id = int(material_costs[1][0])
			material_1_qty = material_costs[1][1]
		if material_costs.size() > 2 and material_costs[2].size() >= 2:
			material_2_id = int(material_costs[2][0])
			material_2_qty = material_costs[2][1]
		if material_costs.size() > 3 and material_costs[3].size() >= 2:
			material_3_id = int(material_costs[3][0])
			material_3_qty = material_costs[3][1]
		
		# Безопасное извлечение данных busy_workers
		var worker_type = 0
		var worker_count = 0
		
		if busy_workers.size() > 0 and busy_workers[0].size() >= 2:
			worker_type = int(busy_workers[0][0])
			worker_count = busy_workers[0][1]
		
		task_instance.selected_mode = 'create_task'
		task_instance.set_good_data(
			task_data['good_id'],
			good_name,
			task_data['production_volume']
		)
		task_instance.set_materials_data(
			0,
			material_0_id,
			material_0_qty,
			material_1_id,
			material_1_qty,
			material_2_id,
			material_2_qty,
			material_3_id,
			material_3_qty
		)
		task_instance.set_workers_data(
			worker_type,
			worker_count
		)
		task_instance.set_period_production_data(
			task_data['period_production']
		)

func _set_stage_two_create_task_to_list(tasks_data: Array) -> bool:
	db = SQLiteHelper.new()
	var department_warehouse = db.find_records('department_warehouse', 'company_department_id', player_node.info_region.data_region['department_id'])
	var goods = db.get_all_records('goods')
	db.close_database()
	
	var material_count = 0
	
	for task_data in tasks_data:
		if task_data[0] == null:
			if material_count == 0:
				return false
			else:
				continue
		
		var name_good
		
		for good in goods:
			if good['id'] != int(task_data[0]):
				continue
			name_good = good['name']
		
		var task_instance = tasks_scene.instantiate()
		list_tasks.add_child(task_instance)
		
		task_instance.name = str(int(task_data[0]))
		task_instance.stock_selected.connect(_on_stock_selected)
		
		task_instance.selected_mode = 'create_task'
		task_instance.create_task_stage = 2
		
		task_instance.set_good_data(
			int(task_data[0]),
			name_good,
			int(task_data[2])
		)
		
		for slot_data in department_warehouse:
			if int(task_data[0]) != slot_data['good_id']:
				continue
			
			task_instance.set_stocks_data(
				slot_data['id'],
				slot_data['cost_price'],
				slot_data['count']
			)
		task_instance.update_view()
		material_count += 1
	return true

func _set_stage_three_create_task_to_list():
	var task_instance = tasks_scene.instantiate()
	list_tasks.add_child(task_instance)
	task_instance.name = 'salary_for_task'
	task_instance.salary_input.connect(_on_salary_input)
	task_instance.selected_mode = 'create_task'
	task_instance.create_task_stage = 3
	
	task_instance.set_workers_stage(
		memory_create_task_data['stage'][2][0]['id'],
		'Специалистов',
		memory_create_task_data['stage'][2][0]['count'],
		memory_create_task_data['stage'][2][0]['salary'],
	)
	task_instance.update_salary_input()
	task_instance.update_view()
	budget_create_task_count.text = str(float(task_instance.worker_salary_count_total.text))
	cost_price_product_total.text = str(snapped((float(budget_create_task_count.text) + calculate_total_cost_price_materials_cost()) / int(production_volume_total.text), 0.01))

func _set_stage_4_create_task_to_list():
	var task_instance = tasks_scene.instantiate()
	list_tasks.add_child(task_instance)
	task_instance.name = 'series'
	task_instance.series_flag = true
	task_instance.series_selected.connect(_on_series_selected)
	task_instance.selected_mode = 'create_task'
	task_instance.create_task_stage = 4
	
	task_instance.period_count_total.text = str(memory_create_task_data['stage'][0]['period_production'])
	task_instance.update_series_signal()
	task_instance.update_view()


# ---- Производство ----
# ---- Открыть подразделы ----
## Открыть раздел производство
func _on_production_pressed():
	# Разрешаем открытие если production_tasks не виден ИЛИ кнопка красная (ошибка)
	if (player_node.info_region.production_tasks.visible):
		return
	
	info_create_task_container.hide()
	material_costs_create_task_container.hide()
	details_stage.hide()
	
	player_node.camera_2d.can_zoom = false
	player_node.info_region.body.show()
	player_node.info_region.production_tasks.show()
	player_node.info_region.staff_settings.hide()
	player_node.info_region.staff_info.show()
	player_node.info_region.staff_settings_button.show()
	player_node.info_region.warehouse.hide()
	player_node.info_region.stock.hide()
	
	update_active_filter_buttons(all_tasks_button)
	filter_task.show()
	stages_created_task.hide()
	
	create_task_button.modulate = Color('ffffff')
	create_task_button_title.text = 'Создать задачу'
	create_task_button.mouse_filter = MOUSE_FILTER_PASS
	clear_all_tasks()
	
	db = SQLiteHelper.new()
	var department_tasks = db.find_records('department_tasks', 'company_department_id', player_node.info_region.data_region['department_id'])
	_set_tasks_to_list(department_tasks)
	db.close_database()

## Открыть раздел создания задачи
func _on_create_task_pressed():
	if create_task_button_title.text == 'Создать задачу':
		info_create_task_container.show()
		production_volume_total.text = '0'
		cost_price_product_total.text = '0'
		budget_create_task_count.text = '0'
		details_stage.show()
		next_stage_button.show()
		material_costs_create_task_slot_1_container.hide()
		material_costs_create_task_slot_2_container.hide()
		material_costs_create_task_slot_3_container.hide()
		material_costs_create_task_slot_4_container.hide()
		
		stage_current_num = 0
		
		update_active_stages_create_buttons(stage_1_button)
		filter_task.hide()
		stages_created_task.show()
		
		create_task_button.modulate = Color('909090')
		create_task_button_title.text = 'Запустить задачу'
		create_task_button.mouse_filter = MOUSE_FILTER_IGNORE
		clear_all_tasks()
		selected_task_id = ''
		
		db = SQLiteHelper.new()
		var company = (db.find_records('companies', 'id', player_node.player_data['company_id'], ['speciality_id'], 1))[0]
		var goods = db.find_records('goods', 'speciality_id', company['speciality_id'], ['id', 'name'])
		for good in goods:
			var department_tasks = db.find_records('goods_task_layouts', 'good_id', good['id'])
			_set_stage_one_create_task_to_list(department_tasks, good['name'])
		db.close_database()
		
	elif create_task_button_title.text == 'Запустить задачу':
		# TODO создать задачу через бд
		if int(material_costs_create_task_slot_1_required.text) > int(material_costs_create_task_slot_1_stock_count.text) and \
		int(material_costs_create_task_slot_2_required.text) > int(material_costs_create_task_slot_2_stock_count.text) and \
		int(material_costs_create_task_slot_3_required.text) > int(material_costs_create_task_slot_3_stock_count.text) and \
		int(material_costs_create_task_slot_4_required.text) > int(material_costs_create_task_slot_4_stock_count.text):
			create_task_button_title.text = 'недостаточно запаса'
			create_task_button.modulate = Color("#ff0000")
			await get_tree().create_timer(1.0).timeout
			player_node.info_region.production_tasks.hide()
			_on_production_pressed()
			return
		if memory_create_task_data['stage'][2][0]['count'] > int(player_node.info_region.free_workers_count.text):
			create_task_button_title.text = 'недостаточно сотрудников'
			create_task_button.modulate = Color("#ff0000")
			await get_tree().create_timer(1.0).timeout
			player_node.info_region.production_tasks.hide()
			_on_production_pressed()
			return
		print('запустили задачу')
		pass


# ---- Показать ----
# ---- Задачи производства ----
## Показать все задачи
func _show_all_task_pressed():
	if all_tasks_button.self_modulate != Color('d9d5c5'):
		update_active_filter_buttons(all_tasks_button)
		for task in list_tasks.get_children():
			task.visible = true

## Показать задачи в процессе
func _show_in_progress_task_pressed():
	if in_progress_tasks_button.self_modulate != Color('d9d5c5'):
		update_active_filter_buttons(in_progress_tasks_button)
		for task in list_tasks.get_children():
			task.visible = (task.period_progress_bar_prodution.value < 100)

## Показать задачи завершенные
func _show_completed_task_pressed():
	if completed_tasks_button.self_modulate != Color('d9d5c5'):
		update_active_filter_buttons(completed_tasks_button)
		for task in list_tasks.get_children():
			task.visible = (task.period_progress_bar_prodution.value == 100)


# ---- Этапы установки задачи ----
# ---- 1 Этап ----
## Выбрана задача
func _on_selected_task(task_id: String, task_instance: TextureRect):
	if selected_task_node == task_instance:
		return
	
	disable_task_selection()
	selected_task_id = task_id
	selected_task_node = task_instance
	var task_data = task_instance.get_create_task_stage_two_data()
	memory_create_task_data['stage'][0]['good_id'] = task_data['good_id']
	memory_create_task_data['stage'][0]['good_name'] = selected_task_node.good_name.text
	memory_create_task_data['stage'][0]['good_production_volume'] = task_data['good_count']
	for i in task_data['materials'].size():
		memory_create_task_data['stage'][1][i]['id'] = -1 if task_data['materials'][i][0] == null else task_data['materials'][i][0]
		memory_create_task_data['stage'][1][i]['texture'] = task_data['materials'][i][1]
		memory_create_task_data['stage'][1][i]['required'] = task_data['materials'][i][2]
	memory_create_task_data['stage'][2][0]['id'] = task_data['workers'][0][0]
	memory_create_task_data['stage'][2][0]['texture'] = task_data['workers'][0][1]
	memory_create_task_data['stage'][2][0]['count'] = task_data['workers'][0][2]
	memory_create_task_data['stage'][0]['period_production'] = task_data['period_production']
	memory_create_task_data['stage'][0]['budget'] = 0
	
	production_volume_total.text = str(memory_create_task_data['stage'][0]['good_production_volume'])
	cost_price_product_total.text = str(memory_create_task_data['stage'][0]['cost_price_product'][1])
	
	stage_current_num = 1

## Сбросить выделение всех предыдущих выбранных задач
func disable_task_selection():
	if selected_task_node:
		selected_task_node.modulate = Color.WHITE
	selected_task_id = ""
	selected_task_node = null


# ---- 2 Этап ----
## Перейти на следующий этап создания задачи
func _to_next_stage_create_task_pressed():
	if (stage_current_num == 0) and (selected_task_id == ''):
		return
	
	if stage_current_num == 1:
		update_active_stages_create_buttons(stage_2_button)
		clear_all_tasks()
		
		var selected_task_data = selected_task_node.get_create_task_stage_two_data()
		print('selected_task_data: ', selected_task_data)
		
		material_costs_create_task_container.show()
		worker_slot_0_icon.texture = load(memory_create_task_data['stage'][2][0]['texture'])
		worker_slot_0_required.text = '0'
		worker_slot_0_required.text = str(memory_create_task_data['stage'][2][0]['count'])
		
		if selected_task_data['materials'][0][0]:
			material_costs_create_task_slot_1_container.show()
			material_costs_create_task_slot_1_icon.texture = load(memory_create_task_data['stage'][1][0]['texture'])
			material_costs_create_task_slot_1_stock_count.text = '0'
			material_costs_create_task_slot_1_required.text = str(memory_create_task_data['stage'][1][0]['required'])
		if selected_task_data['materials'][1][1]:
			material_costs_create_task_slot_2_container.show()
			material_costs_create_task_slot_2_icon.texture = load(memory_create_task_data['stage'][1][1]['texture'])
			material_costs_create_task_slot_2_stock_count.text = '0'
			material_costs_create_task_slot_2_required.text = str(memory_create_task_data['stage'][1][1]['required'])
		if selected_task_data['materials'][2][1]:
			material_costs_create_task_slot_3_container.show()
			material_costs_create_task_slot_3_icon.texture = load(memory_create_task_data['stage'][1][2]['texture'])
			material_costs_create_task_slot_3_stock_count.text = '0'
			material_costs_create_task_slot_3_required.text = str(memory_create_task_data['stage'][1][2]['required'])
		if selected_task_data['materials'][3][1]:
			material_costs_create_task_slot_4_container.show()
			material_costs_create_task_slot_4_icon.texture = load(memory_create_task_data['stage'][1][3]['texture'])
			material_costs_create_task_slot_4_stock_count.text = '0'
			material_costs_create_task_slot_4_required.text = str(memory_create_task_data['stage'][1][3]['required'])
		
		if not _set_stage_two_create_task_to_list(selected_task_data['materials']):
			var task_instance = tasks_scene.instantiate()
			list_tasks.add_child(task_instance)
			task_instance.selected_mode = 'notifical_no_material_costs_required'
		
		stage_current_num = 2
	elif stage_current_num == 2:
		if list_tasks.get_children()[0].notifical_container.visible:
			update_active_stages_create_buttons(stage_3_button)
			clear_all_tasks()
			_set_stage_three_create_task_to_list()
			
			stage_current_num = 3
		
		var total_cost_price = 0
		for child in list_tasks.get_children():
			total_cost_price += float(child.cost_price_material_total.text)
		
		if total_cost_price > 0:
			update_active_stages_create_buttons(stage_3_button)
			clear_all_tasks()
			_set_stage_three_create_task_to_list()
			
			stage_current_num = 3
	elif (memory_create_task_data['stage'][2][0]['salary'] > 0.1) and (stage_current_num == 3):
		stage_current_num = 4
		update_active_stages_create_buttons(stage_4_button)
		clear_all_tasks()
		_set_stage_4_create_task_to_list()
		next_stage_button.hide()
		create_task_button.modulate = Color('ffffff')
		create_task_button_title.text = 'Запустить задачу'
		create_task_button.mouse_filter = MOUSE_FILTER_PASS
		stage_current_num = 4
	pass

## Выбрана ячейка расходных материалов из склада
func _on_stock_selected(stock_id: int, cost_price: String, stock_count: String, task_instance: TextureRect, slot_stock_cost_price_materail_node: VBoxContainer):
	selected_task_node = task_instance
	selected_task_node.cost_price_material_total.text = str(float(cost_price) * float(task_instance.good_count.text))
	selected_task_node.update_active_stock_cost_price_material_buttons(slot_stock_cost_price_materail_node)
	
	print('node материала: ', task_instance)
	print('node ячейки из склада: ', slot_stock_cost_price_materail_node)
	print("ID ячейки склада: ", stock_id)
	print("Себестоимость: ", cost_price)
	print("Количество: ", stock_count)
	print('task_instance: ', task_instance.name)
	
	
	if material_costs_create_task_slot_1_container.visible and material_costs_create_task_slot_1_icon.texture.get_rid() == task_instance.good_icon.texture.get_rid():
		material_costs_create_task_slot_1_stock_count.text = str(int(stock_count))
		memory_create_task_data['stage'][1][0]['stock_count'] = int(stock_count)
		memory_create_task_data['stage'][1][0]['cost_price'] = float(cost_price)
	if material_costs_create_task_slot_2_container.visible and material_costs_create_task_slot_2_icon.texture.get_rid() == task_instance.good_icon.texture.get_rid():
		material_costs_create_task_slot_2_stock_count.text = str(int(stock_count))
		memory_create_task_data['stage'][1][1]['stock_count'] = int(stock_count)
		memory_create_task_data['stage'][1][1]['cost_price'] = float(cost_price)
	if material_costs_create_task_slot_3_container.visible and material_costs_create_task_slot_3_icon.texture.get_rid() == task_instance.good_icon.texture.get_rid():
		material_costs_create_task_slot_3_stock_count.text = str(int(stock_count))
		memory_create_task_data['stage'][1][2]['stock_count'] = int(stock_count)
		memory_create_task_data['stage'][1][2]['cost_price'] = float(cost_price)
	if material_costs_create_task_slot_4_container.visible and material_costs_create_task_slot_4_icon.texture.get_rid() == task_instance.good_icon.texture.get_rid():
		material_costs_create_task_slot_4_stock_count.text = str(int(stock_count))
		memory_create_task_data['stage'][1][3]['stock_count'] = int(stock_count)
		memory_create_task_data['stage'][1][3]['cost_price'] = float(cost_price)
	
	cost_price_product_total.text = str(snapped(calculate_total_cost_price_materials_cost() / int(production_volume_total.text), 0.01))


# ---- 3 Этап ----
func _on_salary_input(salary: float, task_instance: TextureRect):
	memory_create_task_data['stage'][2][0]['salary'] = float(salary)
	budget_create_task_count.text = str(float(memory_create_task_data['stage'][2][0]['count'] * memory_create_task_data['stage'][2][0]['salary']))
	task_instance.worker_salary_count_total.text = str(float(memory_create_task_data['stage'][2][0]['count'] * memory_create_task_data['stage'][2][0]['salary']))
	cost_price_product_total.text = str(snapped((float(budget_create_task_count.text) + calculate_total_cost_price_materials_cost()) / int(production_volume_total.text), 0.1))


# ---- 4 этап ----
## Выбран цикл
func _on_series_selected(series_x: int, task_instance: TextureRect):
	production_volume_total.text = str(memory_create_task_data['stage'][0]['good_production_volume'] * series_x)
	worker_slot_0_required.text = str(memory_create_task_data['stage'][2][0]['count'] * series_x)
	material_costs_create_task_slot_1_required.text = str(memory_create_task_data['stage'][1][0]['required'] * series_x)
	material_costs_create_task_slot_2_required.text = str(memory_create_task_data['stage'][1][1]['required'] * series_x)
	material_costs_create_task_slot_3_required.text = str(memory_create_task_data['stage'][1][2]['required'] * series_x)
	material_costs_create_task_slot_4_required.text = str(memory_create_task_data['stage'][1][3]['required'] * series_x)
	budget_create_task_count.text = str(float(memory_create_task_data['stage'][2][0]['count'] * memory_create_task_data['stage'][2][0]['salary'] * series_x))
	var new_period = memory_create_task_data['stage'][0]['period_production'] * series_x
	task_instance.period_count_total.text = str(new_period)


# ------
# Вспомогательные функции 
# ------

func calculate_total_cost_price_materials_cost():
	var cost_price_material_cost_slot_1 = memory_create_task_data['stage'][1][0]['cost_price'] * memory_create_task_data['stage'][1][0]['required']
	var cost_price_material_cost_slot_2 = memory_create_task_data['stage'][1][1]['cost_price'] * memory_create_task_data['stage'][1][1]['required']
	var cost_price_material_cost_slot_3 = memory_create_task_data['stage'][1][2]['cost_price'] * memory_create_task_data['stage'][1][2]['required']
	var cost_price_material_cost_slot_4 = memory_create_task_data['stage'][1][3]['cost_price'] * memory_create_task_data['stage'][1][3]['required']
	return snapped(float(cost_price_material_cost_slot_1 + cost_price_material_cost_slot_2 + cost_price_material_cost_slot_3 + cost_price_material_cost_slot_4), 0.01)
