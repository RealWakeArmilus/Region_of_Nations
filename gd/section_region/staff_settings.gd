extends Control


# ---- UI ----
@onready var player_node = $"../../../../../.."
@onready var unemployed_count = $unemployed/statistic/count
@onready var workers_input = $unemployed/workers/input/input/LineEdit
@onready var worker_minus = $unemployed/workers/input/HBoxContainer/minus
@onready var worker_plus = $unemployed/workers/input/HBoxContainer/plus

@onready var min_salary_count = $min_salary/statistic/count
@onready var salary_input = $min_salary/salary/input/input/LineEdit
@onready var salary_minus = $min_salary/salary/input/HBoxContainer/minus
@onready var salary_plus = $min_salary/salary/input/HBoxContainer/plus

@onready var error = $error
@onready var notifical_1 = $notifical1
@onready var notifical_2 = $notifical2
@onready var notifical_sms = $notifical_sms


# ---- Стабильные переменные ----
var db: SQLiteHelper
var department_id: int

func _ready():
	salary_input.text_changed.connect(_on_salary_input_changed)
	salary_input.text_submitted.connect(_on_salary_input_submitted)
	
	workers_input.text_changed.connect(_on_workers_input_changed)
	workers_input.text_submitted.connect(_on_workers_input_submitted)


# ----- Управление кнопками ----
## Открыть раздел настройки персонала
func _on_staff_setting_open_pressed():
	error.hide()
	notifical_1.hide()
	notifical_2.hide()
	notifical_sms.hide()
	player_node.info_region.production_tasks.hide()
	player_node.info_region.staff_settings_button.hide()
	player_node.info_region.staff_settings.show()
	
	department_id = int(player_node.info_region.data_region['department_id'])
	
	db = SQLiteHelper.new()
	var total_people_in_professions = get_total_people_in_professions()
	var total_workers_if_professions = get_total_workers_if_professions()
	var min_salary = get_min_salary()
	var salary_department = get_salary_department()
	db.close_database()
	
	var total_unemployed = str(total_people_in_professions - total_workers_if_professions)
	var salary_current = str(salary_department)
	
	unemployed_count.text = total_unemployed
	workers_input.text = str(player_node.info_region.total_workers_count.text)
	workers_input.placeholder_text = str(player_node.info_region.total_workers_count.text)
	
	min_salary_count.text = min_salary
	salary_input.text = salary_current
	salary_input.placeholder_text = salary_current


# ---- Возвращение данных ----
## Возвращает общее количество человек в профессии
func get_total_people_in_professions() -> int:
	var company_info = (db.find_records('companies', 'id', player_node.player_data['company_id'], ['speciality_id'], 1))[0]
	var professions_type = (db.find_records('professions_type', 'speciality_id', company_info['speciality_id'], ['id'], 1))[0]
	var population_groups = db.find_records_by_params("population_groups", {'region_id': int(player_node.info_region.id.text), 'profession_type_id': professions_type['id']}, ['id', 'total_people'])
	
	var total_people_in_professions: int = 0
	for population_group in population_groups:
		total_people_in_professions += population_group['total_people']
	return total_people_in_professions

## Возвращает общее количество рабочих в профессии
func get_total_workers_if_professions() -> int:
	var company_departments = db.find_records('company_departments', 'region_id', int(player_node.info_region.id.text), ['total_workers'])
	
	var total_workers_if_professions: int = 0
	for company_department in company_departments:
		total_workers_if_professions += company_department['total_workers']
	return total_workers_if_professions

## Возвращает МРОТ
func get_min_salary():
	var region = (db.find_records('regions', 'id', int(player_node.info_region.id.text), ['province_id'], 1))[0]
	var province = (db.find_records('provinces', 'id', region['province_id'], ['salary_fix'], 1))[0]
	return str(province['salary_fix'])

## Возвращает текущую зарплату филлиала
func get_salary_department() -> float:
	var company_department = (db.find_records('company_departments', 'id', department_id, ['salary'], 1))[0]
	return company_department['salary']


# ---- Валидация рабочих ----
func _on_workers_input_changed(new_text: String) -> void:
	var filtered_text = ""
	
	# Фильтруем только цифры
	for symbol in new_text:
		if symbol.is_valid_int():
			filtered_text += symbol
	
	# Если текст изменился после фильтрации
	if filtered_text != new_text:
		workers_input.text = filtered_text
		workers_input.caret_column = filtered_text.length()
	
	# Проверяем минимальное значение (0)
	if filtered_text != "":
		var value = int(filtered_text)
		if value < 0:
			workers_input.text = "0"
			workers_input.caret_column = 1

func _on_workers_input_submitted(submitted_text: String) -> void:
	if submitted_text == "" or not submitted_text.is_valid_int():
		workers_input.text = "0"
		return
	
	var value = int(submitted_text)
	if value < 0:
		workers_input.text = "0"


# ---- Валидация зарплаты ----
func _on_salary_input_changed(new_text: String) -> void:
	var filtered_text = ""
	var has_dot = false
	
	# Фильтруем только цифры и одну точку
	for symbol in new_text:
		if symbol.is_valid_int():
			filtered_text += symbol
		elif symbol == "." and not has_dot:
			filtered_text += symbol
			has_dot = true
	
	# Если текст изменился после фильтрации
	if filtered_text != new_text:
		salary_input.text = filtered_text
		salary_input.caret_column = filtered_text.length()
	
	# Проверяем минимальное значение
	if filtered_text.is_valid_float() and filtered_text != "":
		var value = float(filtered_text)
		var min_value = float(min_salary_count.text)
		if value < min_value:
			salary_input.text = min_salary_count.text
			salary_input.caret_column = min_salary_count.text.length()

func _on_salary_input_submitted(submitted_text: String) -> void:
	if submitted_text == "" or not submitted_text.is_valid_float():
		salary_input.text = min_salary_count.text
		return
	
	var value = float(submitted_text)
	var min_value = float(min_salary_count.text)
	if value < min_value:
		salary_input.text = str(min_value)


# ---- Управление сотрудниками ----
## Минус 1 сотрудник
func _on_minus_worker_pressed():
	if int(workers_input.text) <= 0:
		return
	workers_input.text = str(int(workers_input.text) - 1)

## Плюс 1 сотрудник
func _on_plus_worker_pressed():
	workers_input.text = str(int(workers_input.text) + 1)


# ---- Управление зарплатой ----
## Минус 1 $ к зарплате
func _on_minus_salary_pressed():
	var current_value = float(salary_input.text)
	var min_value = float(min_salary_count.text)
	
	if current_value - 1 < min_value:
		salary_input.text = str(min_value)
	else:
		salary_input.text = str(current_value - 1)

## Плюс 1 $ к зарплате
func _on_plus_salary_pressed():
	salary_input.text = str(float(salary_input.text) + 1)


# ---- Сохранить ----
func _on_save_staff_settings_pressed():
	error.hide()
	notifical_1.hide()
	notifical_2.hide()
	notifical_sms.hide()
	
	var error_flag: bool = false
	var notifical_flag: bool = false
	notifical_sms.text = ''
	
	var worker_total = int(player_node.info_region.total_workers_count.text)
	var worker_free = int(player_node.info_region.free_workers_count.text)
	var worker_value = int(workers_input.text)
	var current_value = float(salary_input.text)
	var min_value = float(min_salary_count.text)
	
	var worker_hired: int = 0
	var worker_fire: int = 0
	
	var request_budget_value: float = 0
	
	db = SQLiteHelper.new()
	var total_people_in_professions = get_total_people_in_professions()
	var company_department = (db.find_records('company_departments', 'id', department_id, ['budget', 'salary'], 1))[0]
	
	
	if worker_value == worker_total:
		notifical_sms.text = 'Рабочие - без изменений;\n'
	elif worker_value < worker_total:
		worker_fire = worker_value - worker_total
		if worker_free < worker_fire:
			error_flag = true
			error.text = 'Не хватает свободных рабочих в компании'
		elif worker_free >= worker_fire:
			notifical_flag = true
			notifical_sms.text = 'Было уволено {0};\n'.format([worker_value - worker_total])
	elif worker_value > worker_total:
		worker_hired = worker_value - worker_total
		if total_people_in_professions < worker_hired:
			error_flag = true
			error.text = 'Не хватает профессионалов на рынке труда'
		elif total_people_in_professions >= worker_hired:
			notifical_flag = true
			notifical_sms.text = 'Было нанято {0};\n'.format([worker_hired])
	
	if current_value < min_value:
		error_flag = true
		error.text = 'Зарплата не установлена или ниже МРОТА'
	elif current_value >= min_value:
		print('Зарплата ровна или больше МРОТА')
		request_budget_value = current_value * worker_value
		if request_budget_value > company_department['budget']:
			error_flag = true
			error.text = 'Бюджета у филлиала не хватает'
		elif request_budget_value <= company_department['budget']:
			if current_value == company_department['salary']:
				notifical_sms.text = str(notifical_sms.text, ' Зарплата - без изменений')
			elif current_value < company_department['salary']:
				notifical_flag = true
				notifical_sms.text = str(notifical_sms.text, 'Зарплата - снижена на {0} $.'.format([current_value - company_department['salary']]))
			elif current_value > company_department['salary']:
				notifical_flag = true
				notifical_sms.text = str(notifical_sms.text, 'Зарплата - повышена на {0} $.'.format([current_value - company_department['salary']]))
	
	if error_flag:
		error.show()
		return
	if notifical_flag:
		notifical_1.show()
		notifical_sms.show()
		db.update_records('company_departments', {'total_workers': worker_value, 'salary': current_value}, {'id': department_id})
	else:
		notifical_2.show()
	
	db.close_database()
