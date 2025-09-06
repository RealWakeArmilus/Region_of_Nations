extends TextureRect

#
# Signals
#

signal task_selected(task_id, task_instance)
signal stock_selected(stock_id: int, cost_price: String, count: String, task_instance: TextureRect, slot_stock_cost_price_material: VBoxContainer)
signal salary_input(salary: float, task_instance: TextureRect)
signal series_selected(series_node: String)

#
# Export
#

@export var selected_on: bool = false

@export_enum("idle", "create_task", "error_raw_materials_out_of_stock", "error_insufficient_funds", "notifical_no_material_costs_required") var selected_mode: String = "idle":
	set(value):
		selected_mode = value
		if value == "create_task":
			create_task_stage = 1
		update_view()
	get:
		return selected_mode
		
@export_range(1, 4) var create_task_stage: int = 1

@export var material_slot_0_icon: Texture2D

@export var icon_goods_path: String
@export var icon_specializations_path: String

@export var series_flag: bool = false


# 
# UI
#

# ---- MODES ----
@onready var idle
@onready var error

# ---- IDLE UI ----
@onready var good_container
@onready var good_icon: TextureRect
@onready var good_name: Label
@onready var good_count: Label

@onready var cost_price_container
@onready var good_cost_price_count: Label

@onready var material_costs_container
@onready var material_costs_slot_0_container
@onready var material_costs_slot_0_icon
@onready var material_costs_slot_0_count
@onready var material_costs_slot_1_container
@onready var material_costs_slot_1_icon
@onready var material_costs_slot_1_count
@onready var material_costs_slot_2_container
@onready var material_costs_slot_2_icon
@onready var material_costs_slot_2_count
@onready var material_costs_slot_3_container
@onready var material_costs_slot_3_icon
@onready var material_costs_slot_3_count
@onready var material_costs_slot_4_container
@onready var material_costs_slot_4_icon
@onready var material_costs_slot_4_count

@onready var workers_container
@onready var workers_slot_1_container
@onready var workers_slot_1_icon
@onready var workers_slot_1_count

@onready var progress_container
@onready var period_progress_bar_prodution
@onready var period_in_months_current_count
@onready var period_in_months_required

@onready var action_container
@onready var cansel_button
@onready var resert_button

@onready var period_production_container
@onready var period_production_count

@onready var stocks_container
@onready var stocks_list
@onready var cost_price_material_container
@onready var cost_price_material_total

@onready var notifical_container

@onready var workers_stage
@onready var worker_icon
@onready var worker_name
@onready var workers_count_input
@onready var worker_salary_count_input
@onready var worker_salary_count_total

@onready var series_stage
@onready var series_list
@onready var period_count_total


# ---- Статичные Переменные ----
var db: SQLiteHelper
var player_node
var active_stock_cost_price_material_button = null
var active_color_button = Color('d9d5c5')
var inactive_color_button = Color("989280")


func _ready():
	player_node = _get_node_or_null('/root/map/Player')
	idle = _get_node_or_null('modes/idle')
	error = _get_node_or_null('modes/error')
	good_container = _get_node_or_null('modes/idle/good')
	good_icon = _get_node_or_null('modes/idle/good/icon')
	good_name = _get_node_or_null('modes/idle/good/details/name')
	good_count = _get_node_or_null('modes/idle/good/details/count/text')
	cost_price_container = _get_node_or_null('modes/idle/good/details/cost_price')
	good_cost_price_count = _get_node_or_null('modes/idle/good/details/cost_price/text')
	material_costs_container = _get_node_or_null('modes/idle/material_costs')
	material_costs_slot_0_container = _get_node_or_null('modes/idle/material_costs/0')
	material_costs_slot_0_icon = _get_node_or_null('modes/idle/material_costs/0/icon')
	material_costs_slot_0_count = _get_node_or_null('modes/idle/material_costs/0/count')
	material_costs_slot_1_container = _get_node_or_null('modes/idle/material_costs/1')
	material_costs_slot_1_icon = _get_node_or_null('modes/idle/material_costs/1/icon')
	material_costs_slot_1_count = _get_node_or_null('modes/idle/material_costs/1/count')
	material_costs_slot_2_container = _get_node_or_null('modes/idle/material_costs/2')
	material_costs_slot_2_icon = _get_node_or_null('modes/idle/material_costs/2/icon')
	material_costs_slot_2_count = _get_node_or_null('modes/idle/material_costs/2/count')
	material_costs_slot_3_container = _get_node_or_null('modes/idle/material_costs/3')
	material_costs_slot_3_icon = _get_node_or_null('modes/idle/material_costs/3/icon')
	material_costs_slot_3_count = _get_node_or_null('modes/idle/material_costs/3/count')
	material_costs_slot_4_container = _get_node_or_null('modes/idle/material_costs/4')
	material_costs_slot_4_icon = _get_node_or_null('modes/idle/material_costs/4/icon')
	material_costs_slot_4_count = _get_node_or_null('modes/idle/material_costs/4/count')
	workers_container = _get_node_or_null('modes/idle/workers')
	workers_slot_1_container = _get_node_or_null('modes/idle/workers/1')
	workers_slot_1_icon = _get_node_or_null('modes/idle/workers/1/speciality')
	workers_slot_1_count = _get_node_or_null('modes/idle/workers/1/count')
	progress_container = _get_node_or_null('modes/idle/progress')
	period_progress_bar_prodution = _get_node_or_null('modes/idle/progress/details/progress_bar')
	period_in_months_current_count = _get_node_or_null('modes/idle/progress/details/period_in_months/current')
	period_in_months_required = _get_node_or_null('modes/idle/progress/details/period_in_months/required')
	action_container = _get_node_or_null('modes/idle/action')
	cansel_button = _get_node_or_null('modes/idle/action/cansel')
	resert_button = _get_node_or_null('modes/idle/action/resert')
	period_production_container = _get_node_or_null('modes/idle/period_production')
	period_production_count = _get_node_or_null('modes/idle/period_production/details/count')
	stocks_container = _get_node_or_null('modes/idle/stocks')
	stocks_list = _get_node_or_null('modes/idle/stocks/list')
	cost_price_material_container = _get_node_or_null('modes/idle/cost_price_material')
	cost_price_material_total = _get_node_or_null('modes/idle/cost_price_material/details/money/count')
	notifical_container = _get_node_or_null('modes/notifical')
	workers_stage = _get_node_or_null('modes/workers_stage')
	worker_icon = _get_node_or_null('modes/workers_stage/personal/icon')
	worker_name = _get_node_or_null('modes/workers_stage/personal/details/name')
	workers_count_input = _get_node_or_null('modes/workers_stage/personal/details/count')
	worker_salary_count_input = _get_node_or_null('modes/workers_stage/salary/count')
	worker_salary_count_total = _get_node_or_null('modes/workers_stage/salary_total/details/money/count')
	series_stage = _get_node_or_null('modes/series')
	series_list = _get_node_or_null('modes/series/x/list')
	period_count_total = _get_node_or_null('modes/series/period_total/details/months/count')
	
	self.gui_input.connect(_gui_input)


# Обработчик кликов
func _gui_input(event):
	if selected_on:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
			emit_signal("task_selected", name, self)
			modulate = Color(0.8, 0.8, 1.0)  # Легкое выделение синим

func _get_node_or_null(path: String) -> Node:
	if has_node(path):
		return get_node(path)
	return null

## Обновили все настройки задачи
func update_view():
	idle.hide()
	error.hide()
	good_container.hide()
	cost_price_container.hide()
	material_costs_container.hide()
	workers_container.hide()
	progress_container.hide()
	action_container.hide()
	period_production_container.hide()
	stocks_container.hide()
	cost_price_material_container.hide()
	notifical_container.hide()
	workers_stage.hide()
	series_stage.hide()
	
	if selected_mode == 'idle':
		idle.show()
		good_container.show()
		cost_price_container.show()
		material_costs_container.show()
		workers_container.show()
		progress_container.show()
		action_container.show()
	elif selected_mode == 'create_task':
		if create_task_stage == 1:
			idle.show()
			good_container.show()
			material_costs_container.show()
			workers_container.show()
			period_production_container.show()
		elif create_task_stage == 2:
			idle.show()
			good_container.show()
			stocks_container.show()
			cost_price_material_container.show()
			for slot in stocks_list.get_children():
				if slot.name == 'default':
					continue
				slot.modulate = Color('989280')
		elif create_task_stage == 3:
			workers_stage.show()
			worker_salary_count_total.text = str(int(workers_count_input.text) * float(worker_salary_count_input.text))
		elif create_task_stage == 4:
			series_stage.show()
	elif selected_mode == 'notifical_no_material_costs_required':
		notifical_container.show()

## Обновили сигнал зарплаты
func update_salary_input():
	worker_salary_count_input.text_changed.connect(_on_salary_input_changed.bind(self))

## Обновили сигнал циклов
func update_series_signal():
	if series_flag:
		db = SQLiteHelper.new()
		var player = (db.find_records_by_params('players', {'is_bot': false, 'id': player_node.player_data['id']}, ['is_expansion_of_power'], 1))[0]
		db.close_database()
		
		for series in series_list.get_children():
			if player['is_expansion_of_power']:
				series.gui_input.connect(_on_series_selected.bind(series, self))
				series.mouse_filter = MOUSE_FILTER_PASS
				series.modulate = Color("ffffff")
			else:
				series.mouse_filter = MOUSE_FILTER_IGNORE
				series.modulate = Color("989280")


#
# Установка данных
#

## Установка данных продукта
func set_good_data(icon: int, g_name: String, count: int, price_count: float = 0.0):
	good_icon.texture = _load_texture(icon_goods_path.format([icon]))
	good_name.text = g_name
	good_count.text = str(count)
	if price_count != 0.0: good_cost_price_count.text = str(price_count)

## Установка требуемых материалов
func set_materials_data(salary: float, icon_1: int, count_1: float, icon_2: int, count_2: float, icon_3: int, count_3: float, icon_4: int, count_4: float):
	material_costs_slot_0_container.hide()
	material_costs_slot_1_container.hide()
	material_costs_slot_2_container.hide()
	material_costs_slot_3_container.hide()
	material_costs_slot_4_container.hide()
	
	if salary > 0:
		material_costs_slot_0_container.show()
		material_costs_slot_0_icon.texture = material_slot_0_icon
		material_costs_slot_0_count.text = str(salary)
	if count_1 > 0:
		material_costs_slot_1_container.show()
		material_costs_slot_1_icon.texture = _load_texture(icon_goods_path.format([icon_1]))
		material_costs_slot_1_count.text = str(count_1)
	if count_2 > 0:
		material_costs_slot_2_container.show()
		material_costs_slot_2_icon.texture = _load_texture(icon_goods_path.format([icon_2]))
		material_costs_slot_2_count.text = str(count_2)
	if count_3 > 0:
		material_costs_slot_3_container.show()
		material_costs_slot_3_icon.texture = _load_texture(icon_goods_path.format([icon_3]))
		material_costs_slot_3_count.text = str(count_3)
	if count_4 > 0:
		material_costs_slot_4_container.show()
		material_costs_slot_4_icon.texture = _load_texture(icon_goods_path.format([icon_4]))
		material_costs_slot_4_count.text = str(count_4)

## Установка требуемых рабочих
func set_workers_data(icon_1: int, count_1: float):
	workers_slot_1_container.hide()
	
	if count_1 > 0:
		workers_slot_1_container.show()
		workers_slot_1_icon.texture = _load_texture(icon_specializations_path.format([icon_1]))
		workers_slot_1_count.text = str(count_1)

## Установка прогресса производства
func set_progress_production_data(start_production: String, current_time: String, period_in_months: int, status: bool):
	cansel_button.hide()
	resert_button.hide()
	progress_container.hide()
	period_production_container.hide()
	
	if selected_mode == 'idle':
		progress_container.show()
		var period = calculate_elapsed_months(start_production, current_time)
		period_in_months_current_count.text = str(period)
		period_in_months_required.text = str(period_in_months)
		period_progress_bar_prodution.value = (float(period) / period_in_months) * 100
		if status and period_progress_bar_prodution.value == 100:
			resert_button.show()
		else:
			cansel_button.show()

## Установка периода производства
func set_period_production_data(period_production: int):
	progress_container.hide()
	period_production_container.hide()
	
	if selected_mode == 'create_task' and create_task_stage == 1:
		period_production_container.show()
		period_production_count.text = str(period_production)

## Установка слотов себестоимости на складе
func set_stocks_data(stock_id: int, cost_price: float, count: float):
	# Создаем основной контейнер
	var slot = VBoxContainer.new()
	slot.custom_minimum_size = Vector2(60, 60)
	slot.set("theme_override_constants/separation", 4)
	
	# Создаем панель для цены
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(60, 45)
	panel.gui_input.connect(_on_price_cost_gui_input.bind(stock_id, str(cost_price), str(count), self, slot))
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(panel)
	
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(60, 45)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set("theme_override_constants/separation", 1)
	panel.add_child(box)
	
	# Создаем лейбл для цены
	var cost_price_label = Label.new()
	cost_price_label.text = str(cost_price)
	cost_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_price_label.add_theme_font_size_override("font_size", 12)
	box.add_child(cost_price_label)
	
	var title = Label.new()
	title.text = str(cost_price)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	title.text = 'ед.'
	box.add_child(title)
	
	# Создаем лейбл для количества
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 10)

	var text_color = Color("#413E35")
	count_label.add_theme_color_override("font_color", text_color)
	
	slot.add_child(count_label)
	
	# Добавляем созданный слот в stocks_list
	stocks_list.add_child(slot)
	slot.name = str(stock_id)


# ---- Обработчик кликов ----
## Обработчик клика по себестоимости материала
func _on_price_cost_gui_input(event: InputEvent, stock_id: int, cost_price: String, count: String, task_instance: TextureRect, slot_stock_cost_price_material: VBoxContainer):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stock_selected.emit(stock_id, cost_price, count, task_instance, slot_stock_cost_price_material)

## Обработчик клика по циклу
func _on_series_selected(event: InputEvent, series_node: Button, task_instance: TextureRect):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		series_selected.emit(int(series_node.name), task_instance)

## Обработчик ввода зарплаты
func _on_salary_input_changed(new_text: String, task_instance: TextureRect):
	var filtered_text = ""
	var has_dot = false
	
	for symbol in new_text:
		if symbol.is_valid_int():
			filtered_text += symbol
		elif symbol == "." and not has_dot:
			filtered_text += symbol
			has_dot = true
	
	# Если текст изменился после фильтрации
	if filtered_text != new_text:
		worker_salary_count_input.text = filtered_text
		worker_salary_count_input.caret_column = filtered_text.length()
	
	# Emit только если текст валидный
	if filtered_text.is_valid_float() and filtered_text != "":
		salary_input.emit(float(filtered_text), task_instance)
	else:
		salary_input.emit(0.0, task_instance)

## Установить данные по третьему этапу (персонал)
func set_workers_stage(w_icon: int, w_name: String, w_count_input: int, w_salary_count_input: float):
	worker_icon.texture = _load_texture(icon_specializations_path.format([w_icon]))
	worker_name.text = w_name
	workers_count_input.text = str(w_count_input)
	#workers_count_input.text = str(w_count_input)
	#workers_count_input.placeholder_text = str(w_count_input)
	worker_salary_count_input.text = str(w_salary_count_input)
	worker_salary_count_input.placeholder_text = str(w_salary_count_input)
	worker_salary_count_total.text = str(int(workers_count_input.text) * float(worker_salary_count_input.text))


#
# Возвращение данных
#

func get_create_task_stage_two_data():
	var good_id = get_material_path(good_icon).get_file().get_basename()
	
	var materials_path: Array = []
	var material_ids: Array = []
	
	# Заполняем массив путей
	materials_path.append(get_material_path(material_costs_slot_1_icon))
	materials_path.append(get_material_path(material_costs_slot_2_icon))
	materials_path.append(get_material_path(material_costs_slot_3_icon))
	materials_path.append(get_material_path(material_costs_slot_4_icon))
	
	for material_path in materials_path:
		if material_path == '':
			material_ids.append(null)
			continue
		material_ids.append(material_path.get_file().get_basename())
	
	var workers_id = get_material_path(workers_slot_1_icon).get_file().get_basename()
	
	return {
		'good_id': int(good_id),
		'good_count': int(good_count.text),
		'materials': [
			[material_ids[0], get_material_path(material_costs_slot_1_icon), int(material_costs_slot_1_count.text)], 
			[material_ids[1], get_material_path(material_costs_slot_2_icon), int(material_costs_slot_2_count.text)], 
			[material_ids[2], get_material_path(material_costs_slot_3_icon), int(material_costs_slot_3_count.text)], 
			[material_ids[3], get_material_path(material_costs_slot_4_icon), int(material_costs_slot_4_count.text)]
		],
		'workers': [
			[int(workers_id), get_material_path(workers_slot_1_icon), int(workers_slot_1_count.text)],
		],
		'period_production': int(period_production_count.text)
	}


#
# Вспомогательные функции
#

# Функция для расчета сколько месяцев прошло между началом производства и текущим временем
func calculate_elapsed_months(start_production_json: String, current_time_json: String = "") -> int:
	# Парсим JSON времени начала производства
	var start_data = JSON.parse_string(start_production_json)
	if start_data == null:
		print("Ошибка парсинга start_production_json")
		return 0
	
	# Получаем текущее время (если не передано, используем системное)
	var current_data
	if current_time_json.is_empty():
		# Используем текущее системное время
		var now = Time.get_datetime_dict_from_system()
		current_data = {"year": now["year"], "month": now["month"]}
	else:
		# Парсим переданное текущее время
		current_data = JSON.parse_string(current_time_json)
		if current_data == null:
			print("Ошибка парсинга current_time_json")
			return 0
	
	# Проверяем наличие необходимых полей
	if not start_data.has("year") or not start_data.has("month"):
		print("Неверный формат start_production_json: отсутствуют year или month")
		return 0
	
	if not current_data.has("year") or not current_data.has("month"):
		print("Неверный формат current_time_json: отсутствуют year или month")
		return 0
	
	var start_year = int(start_data["year"])
	var start_month = int(start_data["month"])
	var current_year = int(current_data["year"])
	var current_month = int(current_data["month"])
	
	# Проверяем валидность дат
	if start_year <= 0 or start_month < 1 or start_month > 12:
		print("Неверная дата начала: год=", start_year, " месяц=", start_month)
		return 0
	
	if current_year <= 0 or current_month < 1 or current_month > 12:
		print("Неверная текущая дата: год=", current_year, " месяц=", current_month)
		return 0
	
	# Проверяем, чтобы текущая дата не была раньше начальной
	if current_year < start_year or (current_year == start_year and current_month < start_month):
		print("Текущая дата раньше даты начала производства")
		return 0
	
	# Вычисляем разницу в месяцах
	var elapsed_months = (current_year - start_year) * 12 + (current_month - start_month)
	
	print("Начало: ", start_year, "-", start_month, " | Текущее: ", current_year, "-", current_month, " | Прошло месяцев: ", elapsed_months)
	
	return elapsed_months

# Безопасная загрузка текстур
func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	print("Текстура не найдена: ", path)
	return null

# Создаем вспомогательную функцию
func get_material_path(texture_rect: TextureRect) -> String:
	if texture_rect.texture != null and texture_rect.texture.resource_path != "res://image/point.png":
		return texture_rect.texture.resource_path
	return ''

func update_active_stock_cost_price_material_buttons(button):
	for i_button in stocks_list.get_children():
		if i_button == button:
			i_button.modulate = active_color_button
		else:
			i_button.modulate = inactive_color_button
	
	#active_stock_cost_price_material_button = button
