extends Node

signal database_initialized(success: bool)

@onready var default_data: Node

var generation_username: GenerationUsername
var generation_company_name: GenerationCompanyName
var db: SQLiteHelper
var path_data_match: String = "res://maps/"


#
# ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ
#

func initialize_database():
	## Установка НОДА с дефолтными данными
	default_data = $"../default_data"
	generation_username = GenerationUsername.new()
	generation_company_name = GenerationCompanyName.new()
	
	# Инициализация базы данных с помощью SQLiteHelper
	db = SQLiteHelper.new()
	
	var match_id : int
	
	if CurrentData.match_id == 1:
		match_id = CurrentData.match_id
	
	## Проверка на существование таблицы и записи
	var exist_result: Dictionary = exist_match_info(match_id)
	print('exist_result {0}'.format([exist_result['details']]))
	
	if exist_result["status"] == 0:
		print("Очищаем данные матча.")
		clear_match_data(match_id)
	
	## 2. Создаем таблицы заново с чистыми определениями
	if not create_tables_if_not_exist():
		print("Ошибка: не удалось создать базовую информацию.")
		db.close_database()
		emit_signal("database_initialized", false)
		return
	
	print('match_id: ', match_id)
	
	## 3. загрузка данных карты
	path_data_match += str(match_id) + "/data_match.txt"
	var data_match = load_file_definitions(path_data_match)
	
	if exist_result['status'] == -1:
		## 4.1 Создание матча
		match_id = create_record_match(exist_result['match_id'], data_match)
		
		## Обработка ошибок создания матча
		if match_id < 0:
			var errors = {
				-1: 'Матч уже существует',
				-2: 'При создании матча случилась ошибка',
				-3: 'Не удалось получить ID созданного матча'
			}
			push_error(errors.get(match_id, 'Неизвестная ошибка при создании матча'))
			db.close_database()
			emit_signal("database_initialized", false)
			return
	
	## 4.2 Создание динамичных данных матча
	create_dinamic_date_match(exist_result['match_id'], data_match)
	
	db.close_database()
	emit_signal("database_initialized", true)


#
# ФУНКЦИИ ОЧИСТКИ ТАБЛИЦ ОТ ВСЕХ ЗАПИСЕЙ
#

# Проверка на существование данных матча
func exist_match_info(match_id: int) -> Dictionary:
	var check_query := "SELECT name FROM sqlite_master WHERE type='table' AND name='match_info'"
	
	if not db.db.query(check_query):
		return {
			"status": -3,
			"match_id": match_id,
			"details": "База данных не существует"
		}
	
	if db.db.query_result.is_empty():
		return {
			"status": -2,
			"match_id": match_id,
			"details": "Таблица match_info не найдена"
		}
	
	var result = db.find_records("match_info", "id", match_id, ["id"], 1)
	
	if result.is_empty():
		var new_id = db.get_all_records("match_info", ["id"]).size()
		return {
			"status": -1,
			"match_id": new_id + 1,
			"details": "Матч не существует, новый ID сгенерирован"
		}
	
	return {
		"status": 0,
		"match_id": match_id,
		"details": "Матч существует"
	}


func clear_match_data(match_id: int) -> void:
	var start = Time.get_ticks_usec()
	
	db.db.query("BEGIN;") # Запускаем транзакцию
	
	# 1. Удаляем департаменты компаний
	db.db.query("""
		DELETE FROM company_departments
		WHERE company_id IN (
			SELECT c.id FROM companies c
			JOIN players pl ON c.player_id = pl.id
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = %d
		);
	""" % match_id)
	
	# 3. Удаляем компании
	db.db.query("""
		DELETE FROM companies
		WHERE player_id IN (
			SELECT id FROM players
			WHERE nation_id IN (
				SELECT id FROM nations WHERE match_id = %d
			)
		);
	""" % match_id)

	# 4. Удаляем профессии
	db.db.query("""
		DELETE FROM professions
		WHERE country_id IN (
			SELECT id FROM countries
			WHERE player_id IN (
				SELECT id FROM players
				WHERE nation_id IN (
					SELECT id FROM nations WHERE match_id = %d
				)
			)
		);
	""" % match_id)

	## 5. Удаляем зарплаты, прибыль и регионы
	#db.db.query("""
		#DELETE FROM salaries_in_regions
		#WHERE region_id IN (
			#SELECT r.id FROM regions r
			#JOIN provinces p ON r.province_id = p.id
			#JOIN countries c ON p.country_id = c.id
			#JOIN players pl ON c.player_id = pl.id
			#JOIN nations n ON pl.nation_id = n.id
			#WHERE n.match_id = %d
		#);
	#""" % match_id)
#
	#db.db.query("""
		#DELETE FROM profitability_of_goods_in_regions
		#WHERE region_id IN (
			#SELECT r.id FROM regions r
			#JOIN provinces p ON r.province_id = p.id
			#JOIN countries c ON p.country_id = c.id
			#JOIN players pl ON c.player_id = pl.id
			#JOIN nations n ON pl.nation_id = n.id
			#WHERE n.match_id = %d
		#);
	#""" % match_id)

	db.db.query("""
		DELETE FROM population_groups
		WHERE region_id IN (
			SELECT r.id FROM regions r
			JOIN provinces p ON r.province_id = p.id
			JOIN countries c ON p.country_id = c.id
			JOIN players pl ON c.player_id = pl.id
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = %d
		);
	""" % match_id)

	db.db.query("""
		DELETE FROM regions
		WHERE province_id IN (
			SELECT p.id FROM provinces p
			JOIN countries c ON p.country_id = c.id
			JOIN players pl ON c.player_id = pl.id
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = %d
		);
	""" % match_id)

	# 6. Удаляем провинции
	db.db.query("""
		DELETE FROM provinces
		WHERE country_id IN (
			SELECT c.id FROM countries c
			JOIN players pl ON c.player_id = pl.id
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = %d
		);
	""" % match_id)

	# 7. Удаляем страны
	db.db.query("""
		DELETE FROM countries
		WHERE player_id IN (
			SELECT pl.id FROM players pl
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = %d
		);
	""" % match_id)

	# 8. Удаляем игроков
	db.db.query("""
		DELETE FROM players
		WHERE nation_id IN (
			SELECT id FROM nations WHERE match_id = %d
		);
	""" % match_id)

	# 9. Удаляем нации
	db.db.query("""
		DELETE FROM nations WHERE match_id = %d;
	""" % match_id)

	db.db.query("COMMIT;") # Завершаем транзакцию

	print("Время пакетного удаления clear_match_data: %d мкс" % (Time.get_ticks_usec() - start))


#
# ФУНКЦИИ СОЗДАНИЯ ТАБЛИЦ И БАЗОВЫХ ЗАПИСЕЙ
#

## Создает таблицы и заполняет их базовыми записями. если они не существуют
func create_tables_if_not_exist() -> bool:
	for table_name in default_data.TABLE_DEFINITIONS:
		# Проверяем существование таблицы с помощью прямого запроса
		var query = "SELECT name FROM sqlite_master WHERE type='table' AND name='%s';" % table_name
		if db.db.query(query):
			if db.db.query_result.is_empty():
				# Таблица не существует, создаем
				var table_def = default_data.get_table_definition(table_name)
				if not db.db.create_table(table_name, table_def):
					push_error("Failed to create table: %s" % table_name)
					return false
				
				# Добавляем статичные данные, если они есть для этой таблицы
				var static_data = default_data.get_static_data(table_name)
				if static_data.size() > 0:
					if not db.create_multiple_records(table_name, static_data):
						push_error("Failed to insert static data for table: %s" % table_name)
						return false
	
	return true


#
# ФУНКЦИИ СОЗДАНИЯ УНИКАЛЬНЫХ ЗАПИСЕЙ
#

## Создает запись матча
func create_record_match(match_id: int, data_match: Dictionary):
	var match_info = CurrentData.match_info
	CurrentData.match_info['match_id'] = match_id
	
	print('
	\ncreate_match <<\n\n
	
	match_info: {0}\n
	CurrentData.match_info[match_id]: {1}\n
	data_match: {2}\n\n
	
	>>\n
	'.format([match_info, CurrentData.match_info['match_id'], data_match]))
	
	# Проверяем, существует ли уже похожая запись
	if record_exists("match_info", {"id": match_id, "is_campaign": match_info['is_campaign']}):
		print('Матч кампании уже существует')
		return -1
	
	# Вставляем новую запись
	if not db.create_record("match_info", match_info):
		print("Ошибка при создании матча")
		return -2
	
	match_id = db.get_last_insert_id()
	if match_id <= 0:
		print("Не удалось получить ID созданного матча")
		return -3
	
	print('Матч успешно создан, ID: ', match_id)
	return match_id

## Создает динамичные данные матча
func create_dinamic_date_match(match_id: int, data_match: Dictionary):
	print('\nсоздаем динамические данные матча.\n')
	var start = Time.get_ticks_usec()
	
	var data_nations = data_match['maps']['nations']
	var professions_type = db.get_all_records("professions_type")
	var goods = db.get_all_records("goods", ['id', 'name'])
	var specializations = db.get_all_records("specializations")
	var count_company = 200000
	
	# Создаем массив корутин
	var tasks = []
	
	for date_nation in data_nations:
		var task = _generate_nation_data.bind(match_id, data_match, date_nation, professions_type, goods, specializations, count_company)
		tasks.append(task)
	
	# Запускаем все корутины
	for task in tasks:
		await task.call()
	
	add_player(match_id)
	print("Время генерации динамических данных: %d мкс" % (Time.get_ticks_usec() - start))


# Отдельная функция для генерации данных конкретной нации
func _generate_nation_data(match_id: int, _data_match: Dictionary, date_nation: Dictionary, professions_type: Array, _goods: Array, specializations: Array, count_company: int):
	var nation = create_nation(match_id, date_nation['name'])
	if nation['status'] == 'continue':
		return
	
	create_nations_effects(match_id, nation['record'])
	var records_countries = create_countries(match_id, date_nation['countries'], nation['record'])
	
	for record_country in records_countries:
		create_profession(match_id, professions_type, record_country)
		
		for data_country in date_nation['countries']:
			var records_provinces = create_provinces(match_id, data_country['provinces'], record_country, nation['record'])
			
			for record_province in records_provinces:
				for data_province in data_country['provinces']:
					var records_regions = create_regions(match_id, data_province['regions'], record_province)
					#create_salaries_in_regions_batch(match_id, data_match['date']['general']['salaries_in_regions'], records_regions, goods_type)
					#create_profitability_of_goods_in_regions_batch(match_id, data_match['date']['general']['profitability_of_goods_in_regions'], records_regions, goods_type)
					#print('records_professions: ', records_professions)
					#print('professions_type: ', professions_type)
					create_population_groups_batch(match_id, records_regions, nation['record'], professions_type)
					for _i in range(0, 10):
						var records_companies = create_company_batch(match_id, count_company, nation['record'], specializations)
						count_company += 100000
						var _records_company_departments = create_company_departments_batch(match_id, records_companies, records_regions)
	print('Завершена генерация для нации: ', date_nation['name'])
	#pass

#
# ПАКЕТНОЕ СОЗДАНИЕ ДИНАМИЧЕСКИХ ДАННЫХ
#

### Создание стандартов лимитов зарплаты для регионов пачками
#func create_salaries_in_regions_batch(match_id: int, data_salaries_in_regions: Dictionary, records_regions: Array, goods_type: Array) -> Array:
	#var start = Time.get_ticks_usec()
	#var salaries_in_regions: Array = []
	#var values: Array = []
	#var placeholders: Array = []
	#
	#db.db.query("BEGIN") # Начало транзакции
	#
	#for record_region in records_regions:
		#for good_type in goods_type:
			## Проверка на существование
			#if record_exists("salaries_in_regions", {
				#"region_id": record_region['id'],
				#"good_type_id": good_type['id']
			#}):
				#print('Стандарты лимитов зарплаты для товара {0} в регионе {1} уже существуют в матче {2}'.format([
					#good_type['name'], record_region['name'], match_id
				#]))
				#continue
			#
			## Добавляем в пакет вставки
			#placeholders.append("(?, ?, ?, ?)")
			#values.append(record_region['id'])
			#values.append(good_type['id'])
			#values.append(data_salaries_in_regions['min_salary'])
			#values.append(data_salaries_in_regions['max_salary'])
			#
			#salaries_in_regions.append({
				#"region_id": record_region['id'],
				#"good_type_id": good_type['id'],
				#"min_salary": data_salaries_in_regions['min_salary'],
				#"max_salary": data_salaries_in_regions['max_salary']
			#})
	#
	## Выполняем пакетную вставку, если есть данные
	#if not values.is_empty():
		#var insert_sql = "INSERT INTO salaries_in_regions (region_id, good_type_id, min_salary, max_salary) VALUES " + ", ".join(placeholders) + " RETURNING id;"
		#
		#if db.db.query_with_bindings(insert_sql, values):
			#var returned_ids = db.db.query_result
			#for i in range(salaries_in_regions.size()):
				#salaries_in_regions[i]["id"] = returned_ids[i]["id"]
		#else:
			#push_error("Ошибка пакетной вставки лимитов зарплаты: %s" % db.db.error_message)
	#
	#db.db.query("COMMIT") # Конец транзакции
	#
	#print("Время create_salaries_in_regions_batch: %d мкс" % (Time.get_ticks_usec() - start))
	#return salaries_in_regions
#
### Создание лимитов прибыльности товаров для регионов пачками
#func create_profitability_of_goods_in_regions_batch(match_id: int, data_profitability_of_goods_in_regions: Dictionary, records_regions: Array, goods_type: Array) -> Array:
	#var start = Time.get_ticks_usec()
	#var profitability_of_goods_in_regions: Array = []
	#var values: Array = []
	#var placeholders: Array = []
	#
	#db.db.query("BEGIN") # Начало транзакции
	#
	#for record_region in records_regions:
		#for good_type in goods_type:
			## Проверка на существование
			#if record_exists("profitability_of_goods_in_regions", {
				#"region_id": record_region['id'],
				#"good_type_id": good_type['id']
			#}):
				#print('Лимиты прибыльности товаров {0} для региона {1} уже существуют в матче {2}'.format([
					#good_type['name'], record_region['name'], match_id
				#]))
				#continue
			#
			## Добавляем данные в пакет
			#placeholders.append("(?, ?, ?)")
			#values.append(record_region['id'])
			#values.append(good_type['id'])
			#values.append(data_profitability_of_goods_in_regions['procent'])
			#
			#profitability_of_goods_in_regions.append({
				#"region_id": record_region['id'],
				#"good_type_id": good_type['id'],
				#"procent": data_profitability_of_goods_in_regions['procent']
			#})
	#
	## Выполняем пакетную вставку
	#if not values.is_empty():
		#var insert_sql = "INSERT INTO profitability_of_goods_in_regions (region_id, good_type_id, procent) VALUES " + ", ".join(placeholders) + " RETURNING id;"
		#
		#if db.db.query_with_bindings(insert_sql, values):
			#var returned_ids = db.db.query_result
			#for i in range(profitability_of_goods_in_regions.size()):
				#profitability_of_goods_in_regions[i]["id"] = returned_ids[i]["id"]
		#else:
			#push_error("Ошибка пакетной вставки лимитов прибыльности товаров: %s" % db.db.error_message)
	#
	#db.db.query("COMMIT") # Конец транзакции
	#
	#print("Время create_profitability_of_goods_in_regions_batch: %d мкс" % (Time.get_ticks_usec() - start))
	#return profitability_of_goods_in_regions

## Создание групп населения для каждого региона и профессии пачками
func create_population_groups_batch(match_id: int, records_regions: Array, record_nation: Dictionary, professions_type: Array) -> Array:
	var start = Time.get_ticks_usec()
	var population_groups: Array = []
	var values: Array = []
	var placeholders: Array = []
	
	db.db.query("BEGIN") # Начинаем транзакцию
	
	for record_region in records_regions:
		for profession_type in professions_type:
			# Проверка на существование
			if record_exists("population_groups", {
				"region_id": record_region['id'],
				"nation_id": record_nation['id'],
				"profession_type_id": profession_type['id']
			}):
				print('Группа населения профессии {0} для региона {1} и нации {2} уже существует в матче {3}'.format([
					profession_type['id'], record_region['name'], record_nation['name'], match_id
				]))
				continue
			
			# Добавляем данные для вставки
			placeholders.append("(?, ?, ?, ?)")
			values.append(record_region['id'])
			values.append(record_nation['id'])
			values.append(profession_type['id'])
			values.append(100) # total_people по умолчанию
			
			population_groups.append({
				"region_id": record_region['id'],
				"nation_id": record_nation['id'],
				"profession_type_id": profession_type['id'],
				"total_people": 100
			})
	
	# Выполняем пакетную вставку, если есть что вставлять
	if not values.is_empty():
		var insert_sql = "INSERT INTO population_groups (region_id, nation_id, profession_type_id, total_people) VALUES " + ", ".join(placeholders) + " RETURNING id;"
		
		if db.db.query_with_bindings(insert_sql, values):
			var returned_ids = db.db.query_result
			for i in range(population_groups.size()):
				population_groups[i]["id"] = returned_ids[i]["id"]
		else:
			push_error("Ошибка пакетной вставки групп населения: %s" % db.db.error_message)
	
	db.db.query("COMMIT") # Завершаем транзакцию
	
	print("Время create_population_groups_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return population_groups

## Создание компаний пачками (не с уникалньными ботами)
func create_company_batch(match_id: int, count_company: int, record_nation: Dictionary, specializations: Array) -> Array:
	var start = Time.get_ticks_usec()
	var companies: Array
	var values: Array
	var placeholders: Array
	var insert_sql: String = 'INSERT INTO companies (name, player_id, speciality_id) VALUES '
	var current_id = count_company
	
	db.db.query('BEGIN') # Начинаем транзации
	
	var bot = create_bots({'username': 'null', "unique_id": str(current_id)}, record_nation, false)
	current_id += 1
	for speciality in specializations:
		if speciality['id'] == 1:
			continue
		
		var name_company = generation_company_name.get_random_name(speciality['id'])
		
		if bot['status'] == 'continue':
			continue
		
		if record_exists("companies", {"name": name_company, "player_id": bot['record']['id']}):
			print('Компания "{0}" уже существует, в матче {2}'.format([ name_company, match_id ]))
			continue
		
		# Добавляем данные для вставки
		placeholders.append('(?, ?, ?)')
		values.append(name_company)
		values.append(bot['record']['id'])
		values.append(speciality['id'])
		
		companies.append({
			'name': name_company,
			'player_id': bot['record']['id'],
			'speciality_id': speciality['id'],
			'record_bot': bot['record']
		})
			
			
	if not values.is_empty():
		insert_sql += ', '.join(placeholders) + ' RETURNING id;'
		#
		#print('SQL insert: ', insert_sql)
		#print('value: ', values)
		
		var result = db.db.query_with_bindings(insert_sql, values)
		#print('DB ERROR: ', db.db.error_message)
		#print('\nresult: ', result)
		#print('\nquery_result: ', db.db.query_result)
		
		# Выполняем вставку пачкой с возвратом ID
		if result:
			var returned_ids = db.db.query_result
			for i in range(companies.size()):
				companies[i]['id'] = returned_ids[i]['id']
		else:
			push_error('Ошибка пакетной вставки компаний: {0}'.format([ db.db.error_message ]))
	
	db.db.query('COMMIT') # Завершение транзации
	
	print("Время create_company_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return companies

### Создание ботов пачками с возвратом ID
#func create_bots_batch(bots_data: Array, record_nation: Dictionary, is_expansion_of_power: bool = false) -> Array:
	#var bots: Array = []
	#var values: Array = []
	#var placeholders: Array = []
	#var insert_sql: String = "INSERT INTO players (is_bot, unique_id, username, nation_id, is_expansion_of_power) VALUES "
	#
	#db.db.query("BEGIN") # Начало транзакции
	#
	#for bot_data in bots_data:
		#var username_bot: String = bot_data['username']
		#var unique_id: String = bot_data['unique_id']
		#
		#if not is_expansion_of_power:
			#username_bot = generation_username.get_random_name()
		#
		## Проверка на существование
		#if record_exists("players", {
			#"username": username_bot,
			#"unique_id": unique_id,
			#"nation_id": record_nation['id']
		#}):
			#print('Бот "{0}" уже существует в матче {1}'.format([username_bot, record_nation['match_id']]))
			#continue
		#
		#placeholders.append("(?, ?, ?, ?, ?)")
		#values.append(1) # is_bot
		#values.append(unique_id)
		#values.append(username_bot)
		#values.append(record_nation['id'])
		#values.append(is_expansion_of_power)
		#
		#bots.append({
			#"is_bot": 1,
			#"unique_id": unique_id,
			#"username": username_bot,
			#"nation_id": record_nation['id'],
			#"is_expansion_of_power": is_expansion_of_power
		#})
	#
	#if not values.is_empty():
		#insert_sql += ", ".join(placeholders) + " RETURNING id;"
		#
		#if db.db.query_with_bindings(insert_sql, values):
			#var returned_ids = db.db.query_result
			#for i in range(bots.size()):
				#bots[i]["id"] = returned_ids[i]["id"]
		#else:
			#push_error("Ошибка пакетной вставки ботов: %s" % db.db.error_message)
	#
	#db.db.query("COMMIT") # Конец транзакции
	#
	#return bots

#
### Создание компаний пачками с возвратом ID (с пакетным созданием ботов)
#func create_company_batch_finish(match_id: int, count_company: int, records_regions: Array, record_nation: Dictionary, specializations: Array) -> Array:
	#var companies: Array = []
	#var companies_values: Array = []
	#var companies_placeholders: Array = []
	#var bots_to_create: Array = []
	#var bot_index_map: Array = [] # Связь компаний с ботами
	#
	#var current_id = count_company
	#
	## 1. Собираем данные для всех ботов
	#for record_region in records_regions:
		#for speciality in specializations:
			#if speciality['id'] == 1:
				#continue
			#
			#var name_company = generation_company_name.get_random_name(speciality['id'])
			#var unique_id = str(current_id)
			#
			## Проверка на существование бота
			#if record_exists("companies", {"name": name_company}):
				#print('Компания "{0}" уже существует (проверка по имени), пропускаем'.format([name_company]))
				#continue
			#
			## Добавляем бота в список на создание
			#bots_to_create.append({
				#"username": "null",
				#"unique_id": unique_id,
				#"speciality_id": speciality['id'],
				#"name_company": name_company
			#})
			#current_id += 1
	#
	## 2. Создаём всех ботов пачкой
	#var created_bots = create_bots_batch(bots_to_create, record_nation, false)
	#
	## 3. Готовим массив компаний для пакетной вставки
	#for i in range(created_bots.size()):
		#var bot_info = created_bots[i]
		#var company_info = bots_to_create[i]
		#
		#companies_placeholders.append("(?, ?, ?)")
		#companies_values.append(company_info["name_company"])
		#companies_values.append(bot_info["id"])
		#companies_values.append(company_info["speciality_id"])
		#
		#companies.append({
			#"name": company_info["name_company"],
			#"player_id": bot_info["id"],
			#"speciality_id": company_info["speciality_id"],
			#"record_bot": bot_info
		#})
	#
	## 4. Вставляем компании пачкой
	#if not companies_values.is_empty():
		#var insert_sql = "INSERT INTO companies (name, player_id, speciality_id) VALUES " + ", ".join(companies_placeholders) + " RETURNING id;"
		#
		#db.db.query("BEGIN")
		#if db.db.query_with_bindings(insert_sql, companies_values):
			#var returned_ids = db.db.query_result
			#for i in range(companies.size()):
				#companies[i]["id"] = returned_ids[i]["id"]
		#else:
			#push_error("Ошибка пакетной вставки компаний: %s" % db.db.error_message)
		#db.db.query("COMMIT")
	#
	#return companies

## Создание департаментов компаний пачками
func create_company_departments_batch(match_id: int, records_companies: Array, records_regions: Array) -> Array:
	var start = Time.get_ticks_usec()
	var company_departments: Array
	var values: Array
	var placeholders: Array
	var insert_sql: String = 'INSERT INTO company_departments (company_id, region_id) VALUES '
	
	db.db.query('BEGIN') # Начинаем транзации
	
	for record_company in records_companies:
		for record_region in records_regions:
			if record_exists("company_departments", {"company_id": record_company['id'], "region_id": record_region['id']}):
				print('Департамент компании "{0}" уже существует в регионе {1}, в матче {2}'.format([ record_company['name'], record_region['name'], match_id ]))
				continue
				
			# Добавляем данные для вставки
			placeholders.append('(?, ?)')
			values.append(record_company['id'])
			values.append(record_region['id'])
			
			company_departments.append({
				'company_id': record_company['id'],
				'region_id': record_region['id']
			})
			
	if not values.is_empty():
		insert_sql += ', '.join(placeholders) + ' RETURNING id;'
		
		# Выполняем вставку пачкой с возвратом ID
		if db.db.query_with_bindings(insert_sql, values):
			var returned_ids = db.db.query_result
			for i in range(company_departments.size()):
				company_departments[i]['id'] = returned_ids[i]['id']
		else:
			push_error('Ошибка пакетной вставки департаментов компаний: {0}'.format([ db.db.error_message ]))
	
	db.db.query('COMMIT') # Завершение транзации
	
	print("Время create_company_departments_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return company_departments

## Создание ветки развития товаров для компаний
func create_good_batch(match_id: int, records_companies: Array, goods_type: Array) -> Array:
	var start = Time.get_ticks_usec()
	var goods: Array
	var values: Array
	var placeholders: Array
	var insert_sql: String = 'INSERT INTO goods (good_type_id, company_id) VALUES '

	db.db.query('BEGIN') # Начинаем транзации
	
	for record_company in records_companies:
		for good_type in goods_type:
			if record_exists("goods", {"good_type_id": good_type['id'], "company_id": record_company['id']}):
				print('Продукт компании "{0}" уже существует в регионе {1}, в матче {2}'.format([ good_type['name'], record_company['name'], match_id ]))
				continue
				
			# Добавляем данные для вставки
			placeholders.append('(?, ?)')
			values.append(good_type['id'])
			values.append(record_company['id'])
			
			goods.append({
				'good_type_id': good_type['id'],
				'company_id': record_company['id']
			})
			
	if not values.is_empty():
		insert_sql += ', '.join(placeholders) + ' RETURNING id;'
		
		# Выполняем вставку пачкой с возвратом ID
		if db.db.query_with_bindings(insert_sql, values):
			var returned_ids = db.db.query_result
			for i in range(goods.size()):
				goods[i]['id'] = returned_ids[i]['id']
		else:
			push_error('Ошибка пакетной вставки ветки товара для компании: {2}'.format([ db.db.error_message ]))
	
	db.db.query('COMMIT') # Завершение транзации
	
	print("Время create_good_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return goods

#
# ОДИНАРНОЕ СОЗДАНИЕ ДИНАМИЧЕСКИХ ДАННЫХ
#

## Создает нации
func create_nation(match_id: int, name_nation: String) -> Dictionary:
	var start = Time.get_ticks_usec()
	
	if record_exists("nations", {"name": name_nation, "match_id": match_id}):
		print('Нация "{0}" уже существует в матче {1}'.format([ name_nation, match_id ]))
		var existing = db.select_record("nations", {"name": name_nation, "match_id": match_id})
		return {'status': 'continue', 'record': existing}
	
	var nation = {
		"name": name_nation,
		"match_id": match_id
	}
	
	# Если не существует - создаем
	if not db.create_record("nations", nation):
		push_error("Ошибка при создании нации %s: %s" % [ name_nation, db.db.error_message ])
		return {'status': 'error'}
	else:
		#print('Нация успешно создана: ', name_nation)
		nation['id'] = db.get_last_insert_id()
		print("Время create_nation: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'go', 'record': nation}

## Создание эффектов для каждой нации отдельно
func create_nations_effects(match_id: int, record_nation: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var nations_effects_type = db.get_all_records("nations_effects_type")
	var nations_effects: Array = []
	
	for nation_effects_type in nations_effects_type:
		if record_exists("nations_effects", {"nation_id": record_nation['id'], "nation_effects_type_id": nation_effects_type['id']}):
			print('Эффект для нации "{0}" уже существует в матче {1}'.format([record_nation['name'], match_id]))
			continue
		
		var nation_effects = {
			"nation_effects_type_id": nation_effects_type['id'],
			"nation_id": record_nation['id'],
			"received_points": 0,
			"open": 1 if nation_effects_type['required_points'] == 0 else 0
		}
		
		# Если не существует - создаем
		if not db.create_record("nations_effects", nation_effects):
			push_error("Ошибка при создании Эффекта для нации {0}: {1}".format([record_nation['name'], db.db.error_message]))
		else:
			#print('Эффект для нации {0} успешно создан: {1}'.format([record_nation['name'], nation_effects_type['name']]))
			nation_effects['id'] = db.get_last_insert_id()
			nations_effects.append(nation_effects)
	print("Время create_nations_effects: %d мкс" % (Time.get_ticks_usec() - start))
	return nations_effects

## Создает ботов
func create_bots(data_bot: Dictionary, record_nation: Dictionary, is_expansion_of_power: bool = false) -> Dictionary:
	var start = Time.get_ticks_usec()
	var username_bot: String = data_bot['username']
	var unique_id: String = data_bot['unique_id']
	
	if not is_expansion_of_power:
		username_bot = generation_username.get_random_name()
		
	if record_exists("players", {"username": username_bot, "unique_id": unique_id, "nation_id": record_nation['id']}):
		print('Бот "{0}" уже существует в матче {1}'.format([ username_bot, record_nation['match_id'] ]))
		return {'status': 'continue'}
	
	var bot = {
		"is_bot": 1,
		"unique_id": unique_id,
		"username": username_bot,
		"nation_id": record_nation['id'],
		"is_expansion_of_power": is_expansion_of_power
	}
	
	# Если не существует - создаем
	if not db.create_record("players", bot):
		push_error("Ошибка при создании бота {0}: {1}".format([ username_bot, db.db.error_message ]))
		return {'status': 'error'}
	else:
		#print('Бот успешно создан: ', username_bot)
		bot['id'] = db.get_last_insert_id()
		print("Время create_bots: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'go', 'record': bot}

## Создает государства
func create_countries(match_id: int, data_countries: Array, record_nation: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var countries: Array = []
	
	for data_country in data_countries:
		var bot = create_bots(data_country['ruler'], record_nation, true)
		if bot['status'] == 'go':
			if record_exists("countries", {"name": data_country['name']}):
				print('Государство "{0}" уже существует в матче {1}'.format([ data_country['name'], match_id ]))
				continue
				
			var country = {
				"name": data_country['name'],
				"player_id": bot['record']['id']
			}
			
			# Если не существует - создаем
			if not db.create_record("countries", country):
				push_error("Ошибка при создании Государства {0}: {1}".format([ data_country['name'], db.db.error_message ]))
			else:
				#print('Государство успешно создан: {0}'.format([ data_country['name'] ]))
				country['id'] = db.get_last_insert_id()
				country['record_bot'] = bot['record']
				countries.append(country)
	print("Время create_countries: %d мкс" % (Time.get_ticks_usec() - start))
	return countries

## Создает области
func create_provinces(match_id: int, data_provinces: Array, record_country: Dictionary, record_nation: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var bot: Dictionary = {}
	var provinces: Array = []
	
	for data_province in data_provinces:
		if (data_province['government']['username'] == record_country['record_bot']['username']) and (data_province['government']['unique_id'] == record_country['record_bot']['unique_id']):
			bot = {'status': 'go', 'record': record_country['record_bot']}
		elif (data_province['government']['username'] != record_country['record_bot']['username']) and (data_province['government']['unique_id'] != record_country['record_bot']['unique_id']):
			bot = create_bots(data_province['government'], record_nation, true)
			
		if bot['status'] == 'go':
			if record_exists("provinces", {"name": data_province['name'], "player_id": bot['record']['id'], 'country_id': record_country['id']}):
				print('Область "{0}" уже существует в матче {1}'.format([ data_province['name'], match_id]))
				continue
				
			var province = {
				"name": data_province['name'],
				"player_id": bot['record']['id'],
				"country_id": record_country['id']
			}
			
			# Если не существует - создаем
			if not db.create_record("provinces", province):
				push_error("Ошибка при создании Область {0}: {1}".format([ data_province['name'], db.db.error_message]))
			else:
				#print('Область успешно создан: {0}'.format([ data_province['name'] ]))
				province['id'] = db.get_last_insert_id()
				province['record_bot'] = bot['record']
				provinces.append(province)
	print("Время create_provinces: %d мкс" % (Time.get_ticks_usec() - start))
	return provinces

## Создает регионы
func create_regions(match_id: int, data_regions: Array, record_province: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var regions: Array = []

	for data_region in data_regions:
		if record_exists("regions", {"name": data_region['name'], "province_id": record_province['id'], "color_recognition": data_region["color_recognition"]}):
			print('Регион "{0}" уже существует в матче {1}'.format([data_region['name'], match_id]))
			continue
		
		var region = {
			"name": data_region['name'],
			"color_recognition": data_region["color_recognition"],  # Формат #RRGGBB
			"color_view": data_region['color_view'], # Формат #RRGGBB
			"flag": data_region["flag"],
			"budget": data_region['budget'],
			"province_id": record_province['id']
		}
		
		# Если не существует - создаем
		if not db.create_record("regions", region):
			push_error("Ошибка при создании региона {0}: {1}".format([ data_region['name'], db.db.error_message ]))
		else:
			#print('Регион успешно создана: ', data_region['name'])
			region['id'] = db.get_last_insert_id()
			regions.append(region)
	print("Время create_regions: %d мкс" % (Time.get_ticks_usec() - start))
	return regions

## Создание стандартов лимитов зарплаты для регионов
func create_salaries_in_regions(match_id: int, data_salaries_in_regions: Dictionary, records_regions: Array, goods_type: Array) -> Array:
	var start = Time.get_ticks_usec()
	var salaries_in_regions: Array = []
	
	for record_region in records_regions:
		for good_type in goods_type:
			if record_exists("salaries_in_regions", {"region_id": record_region['id'], "good_type_id": good_type['id']}):
				print('Стандарты лимитов зарплаты для производства товара {0} для региона {1} уже существует в матче {2}'.format([ good_type['name'], record_region['name'], match_id]))
				continue
			
			var salary_in_region = {
				"region_id": record_region['id'],
				"good_type_id": good_type['id'],
				"min_salary": data_salaries_in_regions['min_salary'],
				"max_salary": data_salaries_in_regions['max_salary']
			}
			
			# Если не существует - создаем
			if not db.create_record("salaries_in_regions", salary_in_region):
				push_error("Ошибка при создании Стандартов лимитов зарплаты для производства товара {0} для региона {1}: {2}".format([ good_type['name'], record_region['name'], db.db.error_message]))
			else:
				#print('Стандарты лимитов зарплаты для производства товара {0} успешно создан: {1}'.format([ good_type['name'], record_region['name'] ]))
				salary_in_region['id'] = db.get_last_insert_id()
				salaries_in_regions.append(salary_in_region)
	print("Время create_salaries_in_regions: %d мкс" % (Time.get_ticks_usec() - start))
	return salaries_in_regions

## Создание лимитов прибыльности товаров для регионов
func create_profitability_of_goods_in_regions(match_id: int, data_profitability_of_goods_in_regions: Dictionary, records_regions: Array, goods_type: Array) -> Array:
	var start = Time.get_ticks_usec()
	var profitability_of_goods_in_regions: Array = []
	
	for record_region in records_regions:
		for good_type in goods_type:
			if record_exists("profitability_of_goods_in_regions", {"region_id": record_region['id'], "good_type_id": good_type['id']}):
				print('Лимиты прибыльности товаров {0} для региона {1} уже существует в матче {2}'.format([ good_type['name'], record_region['name'], match_id]))
				continue
			
			var profitability_of_good_in_regions = {
				"region_id": record_region['id'],
				"good_type_id": good_type['id'],
				"procent": data_profitability_of_goods_in_regions['procent']
			}
			
			# Если не существует - создаем
			if not db.create_record("profitability_of_goods_in_regions", profitability_of_good_in_regions):
				push_error("Ошибка при создании Лимитов прибыльности товаров {0} для региона {1}: {2}".format([ good_type['name'], record_region['name'], db.db.error_message]))
			else:
				#print('Лимит прибыльности товара {0} успешно создан: {1}'.format([ good_type['name'], record_region['name'] ]))
				profitability_of_good_in_regions['id'] = db.get_last_insert_id()
				profitability_of_goods_in_regions.append(profitability_of_good_in_regions)
	print("Время create_profitability_of_goods_in_regions: %d мкс" % (Time.get_ticks_usec() - start))
	return profitability_of_goods_in_regions

## Создает дерево профессий для каждой государства отдельно
func create_profession(match_id: int, professions_type: Array, record_country: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var professions: Array = []
	
	# Создаем профессии для государства
	for profession_type in professions_type:
		if record_exists("professions", {"country_id": record_country['id'], "profession_type_id": profession_type["id"]}):
			push_error('Профессия "{0}" для государства - {1} уже существует в матче {2}'.format([ profession_type["name"], record_country['name'], match_id ]))
			continue
		
		if profession_type["required_points"] == 0 and profession_type["learn"] == 0:
			continue
		
		var profession = {
			"profession_type_id": profession_type["id"],
			"country_id": record_country['id'],
			"open": 1 if profession_type["required_points"] == 0 and profession_type["learn"] == 1 else 0
		}
		
		# Если не существует - создаем
		if not db.create_record("professions", profession):
			push_error("Ошибка при создании профессии %s: %s" % [ profession_type["name"], db.db.error_message ])
		else:
			#print("Профессия успешно создана: '{0}', для государства - '{1}'".format([ profession_type["name"], record_country['name'] ]))
			profession['id'] = db.get_last_insert_id()
			professions.append(profession)
	print("Время create_profession: %d мкс" % (Time.get_ticks_usec() - start))
	return professions

## Создает группы населения для каждого региона, учитывая начальную нацию
func create_population_groups(match_id: int, records_regions: Array, record_nation: Dictionary, records_professions: Array) -> Array:
	var start = Time.get_ticks_usec()
	var population_groups: Array = []
	
	for record_region in records_regions:
		for record_profession in records_professions:
			if record_exists("population_groups", {"region_id": record_region['id'], "nation_id": record_nation['id'], "profession_id": record_profession['id']}):
				print('Группа населения профессии {0} для региона {1} и нации {2} уже существует в матче {3}'.format([ record_profession['id'], record_region['name'], record_nation['name'], match_id]))
				continue
				
			var population_group = {
				"region_id": record_region['id'],
				"nation_id": record_nation['id'],
				"profession_id": record_profession['id'],
				"total_people": 100
			}
			
			# Если не существует - создаем
			if not db.create_record("population_groups", population_group):
				push_error("Ошибка при создании Группы населения профессии {0} для региона {1} и нации {2}: {3}".format([ record_profession['id'], record_region['name'], record_nation['name'], db.db.error_message]))
			else:
				#print('Группа населения профессии {0} для региона {1} и нации {2} успешно создан!'.format([ record_profession['id'], record_region['name'], record_nation['name'] ]))
				population_group['id'] = db.get_last_insert_id()
				population_groups.append(population_group)
	print("Время create_population_groups: %d мкс" % (Time.get_ticks_usec() - start))
	return population_groups

## Создание компаний
func create_company(match_id: int, count_company: int, records_regions: Array, record_nation: Dictionary, specializations: Array) -> Array:
	var start = Time.get_ticks_usec()
	var name_company: String = ''
	var current_id = count_company
	var companies: Array = []
	
	for record_region in records_regions:
		for speciality in specializations:
			if speciality['id'] == 1:
				continue
				
			name_company = generation_company_name.get_random_name(speciality['id'])
			var bot = create_bots({'username': 'null', "unique_id": str(current_id)}, record_nation, false)
			if bot['status'] == 'go':
				if record_exists("companies", {"name": name_company, "player_id": bot['record']['id']}):
					print('Компания "{0}" уже существует в регионе {1}, в матче {2}'.format([ name_company, record_region['name'], match_id ]))
					continue
				
				var company = {
					"name": name_company,
					"player_id": bot['record']['id'],
					"speciality_id": speciality['id']
				}
				
				# Если не существует - создаем
				if not db.create_record("companies", company):
					push_error("Ошибка при создании Компании {0}, для региона - '{1}'. Ошибка '{2}'".format([ name_company, record_region['name'], db.db.error_message]))
				else:
					#print('Компания "{0}" в регионе {1}, в матче {2} - успешно создана!'.format([ name_company, record_region['name'], match_id ]))
					company['id'] = db.get_last_insert_id()
					company['record_bot'] = bot['record']
					companies.append(company)
					current_id += 1
	print("Время create_companies: %d мкс" % (Time.get_ticks_usec() - start))
	return companies

## Создание департаментов
func create_company_departments(match_id: int, records_companies: Array):
	var start = Time.get_ticks_usec()
	var company_departments: Array = []
	
	for record_company in records_companies:
		if record_exists("company_departments", {"company_id": record_company['id'], "region_id": record_company['region_id']}):
			print('Департамент компании "{0}" уже существует в регионе {1}, в матче {2}'.format([ record_company['id'], record_company['region_name'], match_id ]))
			continue
		
		var department = {
			"company_id": record_company['id'],
			"region_id": record_company['region_id']
		}
		
		# Если не существует - создаем
		if not db.create_record("company_departments", department):
			push_error("Ошибка при создании Департамента компании {0}, в регионе - '{1}'. Ошибка '{2}'".format([ record_company['id'], record_company['region_name'], db.db.error_message]))
		else:
			#print('Департамент компании "{0}" в регионе {1}, в матче {2} - успешно создана!'.format([ record_company['id'], record_company['region_name'], match_id ]))
			department['id'] = db.get_last_insert_id()
			company_departments.append(department)
	print("Время create_company_departments: %d мкс" % (Time.get_ticks_usec() - start))
	return company_departments

## Создание конкретной ветки развития товара для конкретной компании
func create_good_for_company():
	pass



## Создает потребности у группы населения
func create_needs(population_group_id: int, total_people: int, local_professions: Array) -> void:
	var open_profession_type_ids := []
	
	# Получаем profession_type_id для всех открытых профессий
	for profession in local_professions:
		if profession.has("open") and profession["open"]:
			var profession_id = profession["id"]
			var result = db.find_records("professions", "id", profession_id, ["profession_type_id"])
			if not result.is_empty():
				open_profession_type_ids.append(result[0]["profession_type_id"])

	#print("Открытые профессии (типовые ID) для группы населения %d: %s" % [population_group_id, str(open_profession_type_ids)])

	var needs_types = db.get_all_records("needs_type", ["id", "required_professions_type", "count_on_one_people"])

	for need_type in needs_types:
		if not need_type.has("required_professions_type"):
			continue

		var parsed = JSON.parse_string(need_type["required_professions_type"])
		if parsed == null or typeof(parsed) != TYPE_ARRAY:
			#push_error("Ошибка парсинга required_professions_type: %s" % str(need_type["required_professions_type"]))
			continue

		var required_professions: Array = parsed
		#print("Потребность %d требует профессии (типовые ID): %s" % [need_type["id"], str(required_professions)])

		var has_required_profession := false
		for profession_type_id in required_professions:
			if open_profession_type_ids.has(int(profession_type_id)):
				has_required_profession = true
				break

		if not has_required_profession:
			#print("Пропущена потребность %d — нет нужной профессии" % need_type["id"])
			continue

		var count_required_need = total_people * need_type["count_on_one_people"]
		if count_required_need <= 0:
			#print("Пропущена потребность %d — итоговое количество = %f" % [need_type["id"], count_required_need])
			continue

		var need = {
			"population_group_id": population_group_id,
			"needs_type_id": need_type["id"],
			"count_required_need": count_required_need
		}

		if record_exists("needs", {
			"population_group_id": population_group_id,
			"needs_type_id": need_type["id"]
		}):
			print("Потребность уже существует: %d для группы %d" % [need_type["id"], population_group_id])
			continue

		if not db.create_record("needs", need):
			push_error("Ошибка при создании потребности %d для группы %d: %s" % [
				need_type["id"], population_group_id, db.db.error_message
			])
		else:
			print("Потребность %d успешно создана для группы населения %d" % [
				need_type["id"], population_group_id
			])



## добавить игрока
func add_player(match_id: int):
	var player = CurrentData.player
	
	var matches = db.find_records('match_info', 'id', match_id, ['id'], 1)
	var nations = db.find_records_by_params('nations', {'match_id': matches[0]['id'], 'name': str(player['nation_name']).capitalize()}, ['id'], 1)
	
	player = {
		"is_bot": false,
		"unique_id": player['unique_id'],  # Формат #RRGGBB
		"username": player['username'],
		"nation_id": nations[0]['id']
	}
	
	if record_exists("players", {"is_bot": player['is_bot'], "unique_id": player['unique_id'], "username": player['username'], "nation_id": nations[0]['id']}):
		print('Игрок "{0}" уже существует в матче {1}'.format([player['username'], match_id]))
		return
			
	# Если не существует - создаем
	if not db.create_record("players", player):
		push_error("Ошибка при добавлении игрока {0}: {1}".format([player['username'], db.db.error_message]))
	else:
		print('Игрок успешно добавлен: ', player['username'])
		return db.get_last_insert_id()

#
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
#

## Проверяет на существование записи, для избежания дубликатов
func record_exists(table: String, conditions: Dictionary) -> bool:
	return not db.find_records_by_params(table, conditions).is_empty()


func load_file_definitions(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open regions data file: " + path)
		return {}
	
	var json = JSON.parse_string(file.get_as_text())
	if json == null:
		push_error("JSON parse error")
		return {}
	
	file.close()
	return json


## Функция для получения ID последней добавленной игры
#static func get_last_match_id() -> int:
	#var db_manager = DatabaseManager.new()
	#db_manager.db = SQLite.new()
	#db_manager.db.path = "user://game_database.db"
	#db_manager.db.open_db()
	#
	#db_manager.db.query("SELECT id FROM match ORDER BY id DESC LIMIT 1;")
	#var last_id = 0
	#if not db_manager.db.query_result.is_empty():
		#last_id = db_manager.db.query_result[0]["id"]
	#
	#db_manager.db.close_db()
	#db_manager.queue_free()
	#return last_id
#
## Функция для получения ID игрока по unique_id
#static func get_player_id(unique_id: String) -> int:
	#var db_manager = DatabaseManager.new()
	#db_manager.db = SQLite.new()
	#db_manager.db.path = "user://game_database.db"
	#db_manager.db.open_db()
	#
	#db_manager.db.query_with_bindings("SELECT id FROM players WHERE unique_id = ?;", [unique_id])
	#var player_id = 0
	#if not db_manager.db.query_result.is_empty():
		#player_id = db_manager.db.query_result[0]["id"]
	#
	#db_manager.db.close_db()
	#db_manager.queue_free()
	#return player_id
