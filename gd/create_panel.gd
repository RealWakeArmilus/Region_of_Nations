extends Panel

# ---- UI ----
@onready var regions_node: Node2D
@onready var player_node = $"../../.."
@onready var input_name_company: LineEdit = $body/name_company/input
@onready var select_name_industry: Label = $body/industry/select_name/text
@onready var industry_1: TextureButton = $"body/industry/Scroll/list/1"
@onready var industry_2: TextureButton = $"body/industry/Scroll/list/2"
@onready var industry_3: TextureButton = $"body/industry/Scroll/list/3"
@onready var select_name_specialization: Label = $body/specialization/select_name/text
@onready var specialization_1: TextureButton = $"body/specialization/Scroll/list/1"
@onready var specialization_2: TextureButton = $"body/specialization/Scroll/list/2"
@onready var specialization_3: TextureButton = $"body/specialization/Scroll/list/3"
@onready var specialization_4: TextureButton = $"body/specialization/Scroll/list/4"
@onready var error = $body/error
@onready var create: TextureButton = $body/button/create

# ---- Переменные ----
var db: SQLiteHelper
var player_data: Dictionary
var selected_industry_id: int = -1
var selected_specialization_id: int = -1
var company_speciality_name: String = ''

var icon_path = "res://image/icon/specializations/{0}.png"
var industry_buttons: Array
var specialization_buttons: Array

func _ready():
	regions_node = get_node('/root/map/regions')
	
	# Собираем кнопки в массивы
	industry_buttons = [industry_1, industry_2, industry_3]
	specialization_buttons = [specialization_1, specialization_2, specialization_3, specialization_4]
	
	# Все кнопки изначально затухшие
	_dim_buttons(industry_buttons)
	_dim_buttons(specialization_buttons)
	
	# Кнопка create визуально выключена по умолчанию
	_set_create_enabled(false)
	
	industry_1.pressed.connect(func(): _on_select_industry(2, industry_1))
	industry_2.pressed.connect(func(): _on_select_industry(3, industry_2))
	industry_3.pressed.connect(func(): _on_select_industry(4, industry_3))
	
	# Отслеживаем ввод названия
	input_name_company.text_changed.connect(func(_new_text): _update_create_button())

## Выбор отрасли
func _on_select_industry(industry_id: int, btn: TextureButton):
	db = SQLiteHelper.new()
	selected_industry_id = industry_id
	
	var row = db.find_records("industries", "id", industry_id, ["name"])
	insert_select_name(row, select_name_industry)
	_highlight_selected(btn, industry_buttons)
	_load_specialization(industry_id)
	_update_create_button()

## Загрузка специализаций
func _load_specialization(industry_id: int):
	var specs = db.find_records("specializations", "industry_id", industry_id, ["id", "name"])
	
	for i in range(specialization_buttons.size()):
		var btn = specialization_buttons[i]
		if i < specs.size():
			btn.visible = true
			
			# Загружаем иконку для специализации
			
			var icon_texture = load(icon_path.format([specs[i]["id"]]))
			
			if icon_texture:
				btn.texture_normal = icon_texture
			else:
				btn.visible = false
				push_warning("Не удалось загрузить иконку: {0}".format([icon_path]))
			
			# Привязка выбора специализации
			var spec_id = specs[i]["id"]
			btn.pressed.connect(func(): _on_select_specialization(spec_id, btn))
		else:
			btn.visible = false
	
	_dim_buttons(specialization_buttons)

## Выбор специализации
func _on_select_specialization(spec_id: int, btn: TextureButton):
	selected_specialization_id = spec_id
	
	var row = db.find_records("specializations", "id", spec_id, ["name"])
	company_speciality_name = row[0]['name']
	insert_select_name(row, select_name_specialization)
	_highlight_selected(btn, specialization_buttons)
	_update_create_button()

## Создание активности
func _on_create_pressed():
	var name_company = input_name_company.text.strip_edges()
	
	if name_company == '':
		error.text = 'Введите название компании!'
		return
	if selected_industry_id == -1:
		error.text = 'Выберите отрасль'
		return
	if selected_specialization_id == -1:
		error.text = 'Выберите деятельность'
		return
	
	var company = {
		'name': name_company, 
		'player_id': player_data['id'],
		'speciality_id': selected_specialization_id
	}
	
	if db.create_record("companies", company):
		company['id'] = db.get_last_insert_id()
		view_new_company(company, db)
		_reset_form()
		player_node.menu.create_panel.visible = false
	else:
		push_error("Ошибка при создании компании")
	
	db.close_database()

## Показать созданную компанию
func view_new_company(company_date: Dictionary, database: SQLiteHelper):
	var start = Time.get_ticks_usec()
	if company_speciality_name == '':
		company_speciality_name = (database.find_records("specializations", "id", company_date["speciality_id"], ["name"]))[0]['name']
	
	player_node.menu.company_avatar.texture = load(icon_path.format([company_date["speciality_id"]]))
	player_node.menu.company_name.text = company_date['name']
	player_node.menu.company_speciality.text = company_speciality_name
	player_node.menu.company_info.visible = true
	player_node.menu.create_activity_button.visible = false
	player_node.menu.company_avatar.visible = true
	
	player_node.player_data['company_selected'] = true
	player_node.player_data['company_id'] = company_date['id']
	
	var regions_date: Array = []
	if not regions_node:
		regions_node = get_node('/root/map/regions')
	
	for child in regions_node.get_children():
		regions_date.append(child.get_path_region_node_and_region_id())
	
	var company_deparments = is_open_department_to_company(company_date['id'], regions_date, database)
	
	for company_deparment in company_deparments:
		var region_node = get_node(company_deparment['path_region_node'])
		var is_open = company_deparment['open']
		region_node.data['department_open'] = is_open
		region_node.data['department_id'] = company_deparment['company_department_id']
		get_node(region_node.path_create_branch_button).visible = (not is_open)
	print("Время view_new_company: %d мкс" % (Time.get_ticks_usec() - start))

## Проверка на открытый филиал компании
func is_open_department_to_company(company_id: int, regions_date: Array, database: SQLiteHelper) -> Array:
	var region_ids: Array = []
	var values: Array = [company_id]
	var placeholders: Array = []
	var insert_sql: String = "SELECT id, region_id FROM company_departments WHERE company_id = ? AND region_id IN ("
	var existing: Dictionary = {}   # region_id -> company_department_id
	var company_departments: Array = []
	
	# Собираем region_id
	for region_date in regions_date:
		region_ids.append(region_date["region_id"])
	
	# Плейсхолдеры для IN
	for _i in region_ids.size():
		placeholders.append("?")
	insert_sql += ", ".join(placeholders) + ");"
	
	values.append_array(region_ids)
	
	# Выполняем запрос
	if database.db.query_with_bindings(insert_sql, values):
		for row in database.db.query_result:
			existing[row["region_id"]] = row["id"]
	else:
		push_error("Ошибка SELECT: %s" % database.db.error_message)
	
	# Формируем результат
	for region_date in regions_date:
		var region_id = region_date["region_id"]
		var new_entry = region_date.duplicate()
		new_entry["open"] = region_id in existing
		new_entry["company_department_id"] = existing.get(region_id, -1)
		company_departments.append(new_entry)
	
	return company_departments


#
# Вспомогательные функции
#

## Установка названия
func insert_select_name(row: Array, label: Label):
	if row.size() > 0:
		label.text = row[0]['name']
	else:
		label.text = '?'

## Сброс формы после создания
func _reset_form():
	error.text = ''
	input_name_company.text = ""
	select_name_industry.text = ""
	select_name_specialization.text = ""
	selected_industry_id = -1
	selected_specialization_id = -1
	for btn in [specialization_1, specialization_2, specialization_3, specialization_4]:
		btn.visible = false

## Подсветка выбранной кнопки
func _highlight_selected(selected_btn: TextureButton, all_buttons: Array):
	for btn in all_buttons:
		if btn == selected_btn:
			btn.modulate = Color(1, 1, 1, 1) # яркая (выбранная)
		else:
			btn.modulate = Color(1, 1, 1, 0.4) # затухшая

## Сделать все кнопки затухшими
func _dim_buttons(buttons: Array):
	for btn in buttons:
		btn.modulate = Color(1, 1, 1, 0.4)

## Проверка условий и активация кнопка create
func _update_create_button():
	var name_filled = input_name_company.text.strip_edges() != ''
	var industry_selected = selected_industry_id != -1
	var specialization_selected = selected_specialization_id != -1
	
	_set_create_enabled(name_filled and industry_selected and specialization_selected)

## Вкл / Выкл кнопки create (только визуально)
func _set_create_enabled(enabled: bool):
	if enabled:
		create.modulate = Color(1, 1, 1, 1) # Яркая
	else:
		create.modulate = Color(1, 1, 1, 0.4) # Затухшая
