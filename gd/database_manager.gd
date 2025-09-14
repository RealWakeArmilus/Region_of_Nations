extends Node

signal database_initialized(success: bool)

@onready var default_data: Node

var db: SQLiteHelper


#
# ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ
#

func initialize_database():
	## Установка НОДА с дефолтными данными
	default_data = $"../default_data"
	
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
		db.clear_match_data(match_id)
	
	## 2. Создаем таблицы заново с чистыми определениями
	if not create_tables_if_not_exist():
		print("Ошибка: не удалось создать базовую информацию.")
		db.close_database()
		emit_signal("database_initialized", false)
		return
	
	print('match_id: ', match_id)
	
	if exist_result['status'] == -1:
		## 4.1 Создание матча
		match_id = create_record_match(exist_result['match_id'])
		
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
	create_dinamic_date_match(exist_result['match_id'])
	
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
func create_record_match(match_id: int):
	var match_info = CurrentData.match_info
	CurrentData.match_info['match_id'] = match_id
	
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
func create_dinamic_date_match(match_id: int):
	print('\nсоздаем динамические данные матча.\n')
	var start = Time.get_ticks_usec()
	
	var match_info = (db.find_records('match_info', 'id', match_id, [], 1))[0]
	var map_info = (db.find_records('maps', 'id', match_info['map_id'], [], 1))[0]
	var nations_type = db.find_records('nations_type', 'map_id', map_info['id'], [])
	
	var professions_type = db.get_all_records("professions_type")
	var goods = db.get_all_records("goods", ['id', 'name'])
	var specializations = db.get_all_records("specializations")
	var count_company = 200000
	
	# Создаем массив корутин
	var tasks = []
	
	for nation_type in nations_type:
		var task = _generate_nation_data.bind(match_id, nation_type, professions_type, goods, specializations, count_company)
		tasks.append(task)
	
	# Запускаем все корутины
	for task in tasks:
		await task.call()
	
	add_player_from_my_client(match_id)
	print("Время генерации динамических данных: %d мкс" % (Time.get_ticks_usec() - start))


# Отдельная функция для генерации данных конкретной нации
func _generate_nation_data(match_id: int, nation_type: Dictionary, professions_type: Array, _goods: Array, specializations: Array, _count_company: int):
	var nation = db.create_nation(match_id, nation_type['name'])
	print('nation: ', nation)
	if nation['status'] == 'continue':
		return
	
	var countries_type = db.find_records('countries_type', 'nation_type_id', nation_type['id'], [])
	var records_countries = db.create_countries(match_id, countries_type, nation['record'])
	print('records_countries: ', records_countries)
	
	for record_country in records_countries:
		#var records_professions = create_profession(match_id, professions_type, record_country)
		#print('records_professions: ', records_professions)
		
		var records_provinces = db.create_provinces(match_id, record_country, nation['record'])
		print('records_provinces: ', records_provinces)
		
		for record_province in records_provinces:
			
			var records_regions = db.create_regions(match_id, record_province)
			print("records_regions: ", records_regions)
			##create_salaries_in_regions_batch(match_id, data_match['date']['general']['salaries_in_regions'], records_regions, goods_type)
			##create_profitability_of_goods_in_regions_batch(match_id, data_match['date']['general']['profitability_of_goods_in_regions'], records_regions, goods_type)
			
			print('professions_type: ', professions_type)
			var population_groups = db.create_population_groups_batch(match_id, records_regions, nation['record'], professions_type)
			#print('population_groups: ', population_groups)
			for _i in range(0, 10):
				var records_companies = db.create_company_batch(match_id, nation['record'], specializations)
				var _records_company_departments = db.create_company_departments_batch(match_id, records_companies, records_regions)
	print('Завершена генерация для нации: ', nation_type['name'])
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



### Создание эффектов для каждой нации отдельно
#func create_nations_effects(match_id: int, record_nation: Dictionary) -> Array:
	#var start = Time.get_ticks_usec()
	#var nations_effects_type = db.get_all_records("nations_effects_type")
	#var nations_effects: Array = []
	#
	#for nation_effects_type in nations_effects_type:
		#if record_exists("nations_effects", {"nation_id": record_nation['id'], "nation_effects_type_id": nation_effects_type['id']}):
			#print('Эффект для нации "{0}" уже существует в матче {1}'.format([record_nation['name'], match_id]))
			#continue
		#
		#var nation_effects = {
			#"nation_effects_type_id": nation_effects_type['id'],
			#"nation_id": record_nation['id'],
			#"received_points": 0,
			#"open": 1 if nation_effects_type['required_points'] == 0 else 0
		#}
		#
		## Если не существует - создаем
		#if not db.create_record("nations_effects", nation_effects):
			#push_error("Ошибка при создании Эффекта для нации {0}: {1}".format([record_nation['name'], db.db.error_message]))
		#else:
			##print('Эффект для нации {0} успешно создан: {1}'.format([record_nation['name'], nation_effects_type['name']]))
			#nation_effects['id'] = db.get_last_insert_id()
			#nations_effects.append(nation_effects)
	#print("Время create_nations_effects: %d мкс" % (Time.get_ticks_usec() - start))
	#return nations_effects




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

### Создание компаний
#func create_company(match_id: int, count_company: int, records_regions: Array, record_nation: Dictionary, specializations: Array) -> Array:
	#var start = Time.get_ticks_usec()
	#var name_company: String = ''
	#var current_id = count_company
	#var companies: Array = []
	#
	#for record_region in records_regions:
		#for speciality in specializations:
			#if speciality['id'] == 1:
				#continue
				#
			#name_company = generation_company_name.get_random_name(speciality['id'])
			#var bot = create_bot('', record_nation)
			#if bot['status'] == 'go':
				#if record_exists("companies", {"name": name_company, "player_id": bot['record']['id']}):
					#print('Компания "{0}" уже существует в регионе {1}, в матче {2}'.format([ name_company, record_region['name'], match_id ]))
					#continue
				#
				#var company = {
					#"name": name_company,
					#"player_id": bot['record']['id'],
					#"speciality_id": speciality['id']
				#}
				#
				## Если не существует - создаем
				#if not db.create_record("companies", company):
					#push_error("Ошибка при создании Компании {0}, для региона - '{1}'. Ошибка '{2}'".format([ name_company, record_region['name'], db.db.error_message]))
				#else:
					##print('Компания "{0}" в регионе {1}, в матче {2} - успешно создана!'.format([ name_company, record_region['name'], match_id ]))
					#company['id'] = db.get_last_insert_id()
					#company['record_bot'] = bot['record']
					#companies.append(company)
					#current_id += 1
	#print("Время create_companies: %d мкс" % (Time.get_ticks_usec() - start))
	#return companies

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


## добавить игрока из моего клиента
func add_player_from_my_client(match_id: int):
	var matches = db.find_records('match_info', 'id', match_id, ['id'], 1)
	var nations = (db.find_records_by_params('nations', {'match_id': matches[0]['id'], 'name': str(CurrentData.player['nation_name']).capitalize()}, ['id'], 1))[0]
	
	var client = (db.get_all_records('client', [], 1))[0]
	
	var player = {
		"is_my_client": true,
		"username": client['username'],
		"unique_id": client['id'],
		"nation_id": nations['id'],
		"brain": 50,
		"budget": 50_000
	}
	
	if record_exists("players", {"is_my_client": true, "unique_id": client['id'], "nation_id": nations['id']}):
		print('Игрок "My Client - {0}" уже существует в матче {1}'.format([client['username'], match_id]))
		return
			
	# Если не существует - создаем
	if not db.create_record("players", player):
		push_error('Ошибка при добавлении игрока "My Client - {0}": {1}'.format([client['username'], db.db.error_message]))
	else:
		print('Игрок "My Client - {0}" успешно добавлен!'.format([client['username']]))
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
