extends RefCounted
class_name SQLiteHelper

var db: SQLite

func _init(database_path: String = "user://game_database.db"):
	db = SQLite.new()
	db.path = database_path
	if not db.open_db():
		push_error("Failed to open database: " + db.error_message)

## Создание таблицы client
func create_client_table() -> bool:
	var query = """
		CREATE TABLE IF NOT EXISTS client (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			username TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL
		)
	"""
	return db.query(query)

# 1. Создание новой записи
func create_record(table: String, data: Dictionary) -> bool:
	return db.insert_row(table, data)

# 1. Создание записи с множеством параметров (аналогично предыдущему, просто другое название)
func create_record_with_params(table: String, params: Dictionary) -> bool:
	return db.insert_row(table, params)

# 2. Поиск записей по одному параметру
func find_records(table: String, column: String, value, columns: Array = [], limit: int = 0) -> Array:
	var where = "%s = ?" % column
	var params = [value]
	return _select_rows(table, where, params, columns, limit)

# 2. Поиск записей по множеству параметров
func find_records_by_params(table: String, conditions: Dictionary, columns: Array = [], limit: int = 0) -> Array:
	var where_parts = []
	var params = []
	for key in conditions.keys():
		where_parts.append("%s = ?" % key)
		params.append(conditions[key])
	var where = " AND ".join(where_parts)
	return _select_rows(table, where, params, columns, limit)

# 3. Получение ID последней созданной записи
func get_last_insert_id() -> int:
	return db.last_insert_rowid

# 4. Получение всех записей
func get_all_records(table: String, columns: Array = [], limit: int = 0) -> Array:
	return _select_rows(table, "", [], columns, limit)

# 4. Получение записей с параметрами
func get_records(table: String, conditions: Dictionary = {}, columns: Array = [], limit: int = 0) -> Array:
	if conditions.is_empty():
		return get_all_records(table, columns, limit)
	else:
		return find_records_by_params(table, conditions, columns, limit)

# 5. Создание множества записей
func create_multiple_records(table: String, records: Array) -> bool:
	return db.insert_rows(table, records)

# 6. Удаление записей
func delete_records(table: String, conditions: Dictionary = {}, limit: int = 0) -> bool:
	var where = ""
	var params = []
	
	if not conditions.is_empty():
		var where_parts = []
		for key in conditions.keys():
			where_parts.append("%s = ?" % key)
			params.append(conditions[key])
		where = " AND ".join(where_parts)
	
	var query = "DELETE FROM %s" % table
	if not where.is_empty():
		query += " WHERE " + where
	if limit > 0:
		query += " LIMIT " + str(limit)
	
	return db.query_with_bindings(query, params)

# 7. Обновление записей
func update_records(table: String, updates: Dictionary, conditions: Dictionary = {}, limit: int = 0) -> bool:
	if updates.is_empty():
		return false
	
	var set_parts = []
	var params = []
	
	# Подготовка SET части
	for key in updates.keys():
		set_parts.append("%s = ?" % key)
		params.append(updates[key])
	
	var where = ""
	# Подготовка WHERE части
	if not conditions.is_empty():
		var where_parts = []
		for key in conditions.keys():
			where_parts.append("%s = ?" % key)
			params.append(conditions[key])
		where = " AND ".join(where_parts)
	
	var query = "UPDATE %s SET %s" % [table, ", ".join(set_parts)]
	if not where.is_empty():
		query += " WHERE " + where
	if limit > 0:
		query += " LIMIT " + str(limit)
	
	return db.query_with_bindings(query, params)

#
# Пакетное создание записей
#

# Пакетное создание записей с проверкой существования
func create_batch_with_check(table: String, records: Array, unique_columns: Array) -> bool:
	if records.is_empty():
		return true
	
	# Проверяем существующие записи
	var existing = []
	for column in unique_columns:
		var values = records.map(func(r): return r.get(column))
		var placeholders = ", ".join(values.map(func(_v): return "?"))
		var query = "SELECT %s FROM %s WHERE %s IN (%s)" % [column, table, column, placeholders]
		if db.query_with_bindings(query, values):
			existing += db.query_result.map(func(r): return r[column])
	
	# Фильтруем только новые записи
	var new_records = []
	for record in records:
		var is_new = true
		for column in unique_columns:
			if record.get(column) in existing:
				is_new = false
				break
		if is_new:
			new_records.append(record)
	
	if new_records.is_empty():
		return true
	
	return db.insert_rows(table, new_records)

# Выполнение в транзакции
func execute_in_transaction(operations: Array) -> bool:
	if not db.query("BEGIN TRANSACTION"):
		return false
	
	var success = true
	for op in operations:
		if not op.call():
			success = false
			break
	
	if success:
		return db.query("COMMIT")
	else:
		db.query("ROLLBACK")
		return false

#
# Вспомогательные функции 
#

# Вспомогательная функция для выполнения запросов SELECT
func _select_rows(table: String, where: String, params: Array, columns: Array, limit: int) -> Array:
	var columns_str = "*"
	if not columns.is_empty():
		columns_str = ", ".join(columns)
	
	var query = "SELECT %s FROM %s" % [columns_str, table]
	if not where.is_empty():
		query += " WHERE " + where
	if limit > 0:
		query += " LIMIT " + str(limit)
	
	if db.query_with_bindings(query, params):
		return db.query_result
	else:
		push_error("Query failed: " + db.error_message)
		return []

# Утилита для проверки перед удалением
func log_count(table: String, where_sql: String, params: Array = []):
	var query = "SELECT COUNT(*) as cnt FROM %s WHERE %s" % [table, where_sql]
	if db.query_with_bindings(query, params):
		var cnt = db.query_result[0]["cnt"]
		print("Таблица %s → найдено %d для удаления" % [table, cnt])
	else:
		print("Ошибка проверки таблицы %s: %s" % [table, db.error_message])

#
# ЗАКРЫТИЕ БАЗЫ ДАННЫХ
#

# Закрытие базы данных
func close_database():
	if db != null:
		db.close_db()
		db = null


#
# Готовые решения
#


# ---- Одиночное создание ------
## Создает одного бота
func create_bot(bot_name: String, record_nation: Dictionary) -> Dictionary:
	var start = Time.get_ticks_usec()
	var username_bot: String = bot_name
	
	if username_bot == '':
		var generation_username = GenerationUsername.new()
		username_bot = generation_username.get_random_name()
	
	if not find_records_by_params("bots", {"username": username_bot, "nation_id": record_nation['id']}).is_empty():
		print('Бот "{0}" уже существует в матче {1}'.format([ username_bot, record_nation['match_id'] ]))
		return {'status': 'continue'}
	
	var bot = {
		"username": username_bot,
		"nation_id": record_nation['id'],
	}
	
	# Если не существует - создаем
	if not create_record("bots", bot):
		push_error("Ошибка при создании бота {0}: {1}".format([ username_bot, db.error_message ]))
		return {'status': 'error'}
	else:
		#print('Бот успешно создан: ', username_bot)
		bot['id'] = get_last_insert_id()
		print("Время create_bots: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'go', 'record': bot}

## Создает одну нацию
func create_nation(match_id: int, name_nation: String) -> Dictionary:
	var start = Time.get_ticks_usec()
	
	if not find_records_by_params("nations", {"match_id": match_id, "name": name_nation}).is_empty():
		print_debug('Нация "{0}" уже существует в матче {1}'.format([ name_nation, match_id ]))
		var existing = db.select_record("nations", {"match_id": match_id, "name": name_nation})
		return {'status': 'continue', 'record': existing}
	
	var nation = {
		"name": name_nation,
		"match_id": match_id
	}
	
	# Если не существует - создаем
	if not create_record("nations", nation):
		push_error("Ошибка при создании нации %s: %s" % [ name_nation, db.error_message ])
		return {'status': 'error'}
	else:
		#print('Нация успешно создана: ', name_nation)
		nation['id'] = get_last_insert_id()
		print("Время create_nation: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'go', 'record': nation}

## Создание одного департамента
func create_company_departments(company_data: Dictionary):
	var start = Time.get_ticks_usec()
	if not find_records_by_params("company_departments", {"company_id": company_data['id'], "region_id": company_data['region_id']}).is_empty():
		return {'status': -1, 'result': {}, 'details': 'Департамент компании "{0}" уже существует в регионе {1}'.format([ company_data['id'], company_data['region_name'] ])}
	
	var department = {
		"company_id": company_data['id'],
		"region_id": company_data['region_id']
	}
	
	# Если не существует - создаем
	if not create_record("company_departments", department):
		return {'status': -2, 'result': {}, 'details': 'Ошибка при создании Департамента компании {0}, в регионе - {1}: Ошибка {2}'.format([ company_data['id'], company_data['region_name'], db.db.error_message ])}
	else:
		department['id'] = get_last_insert_id()
	print("Время create_company_departments: %d мкс" % (Time.get_ticks_usec() - start))
	return {'status': 1, 'result': department, 'details': 'Успешно создан департамент компании {0}, в регионе - {1}'.format([ company_data['id'], company_data['region_name'] ])}


# ----- Множественное создание -----
## Создает множество государств - последовательно
func create_countries(match_id: int, countries_type: Array, record_nation: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	var countries: Array = []
	
	for country_type in countries_type:
		
		var bot = create_bot(country_type['ruler'], record_nation)
		if bot['status'] != 'go':
			continue
		
		if not find_records_by_params("countries", {"name": country_type['name']}).is_empty():
			print_debug('Государство "{0}" уже существует в матче {1}'.format([ country_type['name'], match_id ]))
			continue
			
		var country = {
			"name": country_type['name'],
			"player_id": -1,
			"bot_id": bot['record']['id']
		}
		
		# Если не существует - создаем
		if not create_record("countries", country):
			push_error("Ошибка при создании Государства {0}: {1}".format([ country_type['name'], db.error_message ]))
		else:
			#print('Государство успешно создан: {0}'.format([ data_country['name'] ]))
			country['id'] = get_last_insert_id()
			country['record_bot'] = bot['record']
			country['country_type_id'] = country_type['id']
			countries.append(country)
	print("Время create_countries: %d мкс" % (Time.get_ticks_usec() - start))
	return countries

## Создает множество областей - последовательно
func create_provinces(match_id: int, record_country: Dictionary, record_nation: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	
	var provinces_type = find_records('provinces_type', 'country_type_id', record_country['country_type_id'], [])
	print('provinces_type: ', provinces_type)
	
	var bot: Dictionary = {}
	var provinces: Array = []
	
	for province_type in provinces_type:
		print('province_type: ', province_type)
		if province_type['government'] == record_country['record_bot']['username']:
			bot = {'status': 'go', 'record': record_country['record_bot']}
		elif province_type['government'] != record_country['record_bot']['username']:
			bot = create_bot(province_type['government'], record_nation)
			
		if bot['status'] != 'go':
			continue
			
		if  not find_records_by_params("provinces", {"name": province_type['name'], 'country_id': record_country['id']}).is_empty():
			print('Область "{0}" уже существует в матче {1}'.format([ province_type['name'], match_id]))
			continue
			
		var province = {
			"name": province_type['name'],
			"player_id": -1,
			"bot_id": bot['record']['id'],
			"country_id": record_country['id']
		}
		
		# Если не существует - создаем
		if not create_record("provinces", province):
			push_error("Ошибка при создании Область {0}: {1}".format([ province_type['name'], db.error_message]))
		else:
			#print('Область успешно создан: {0}'.format([ province_type['name'] ]))
			province['id'] = get_last_insert_id()
			province['record_bot'] = bot['record']
			provinces.append(province)
			province['province_type_id'] = province_type['id']
	print("Время create_provinces: %d мкс" % (Time.get_ticks_usec() - start))
	return provinces

## Создает множество регионов - последовательно
func create_regions(match_id: int, record_province: Dictionary) -> Array:
	var start = Time.get_ticks_usec()
	
	var regions_type = find_records('regions_type', 'province_type_id', record_province['province_type_id'], [])
	
	var regions: Array = []
	
	for region_type in regions_type:
		if not find_records_by_params("regions", {"name": region_type['name'], "province_id": record_province['id'], "color_recognition": region_type["color_recognition"]}).is_empty():
			print('Регион "{0}" уже существует в матче {1}'.format([region_type['name'], match_id]))
			continue
		
		var region = {
			"name": region_type['name'],
			"color_recognition": region_type["color_recognition"],  # Формат #RRGGBB
			"color_view": region_type['color_view'], # Формат #RRGGBB
			#"flag": region_type["flag"],
			#"budget": region_type['budget'], # по умолчанию 1 млн
			"province_id": record_province['id']
		}
		
		# Если не существует - создаем
		if not create_record("regions", region):
			push_error("Ошибка при создании региона {0}: {1}".format([ region_type['name'], db.error_message ]))
		else:
			#print('Регион успешно создана: ', region_type['name'])
			region['id'] = get_last_insert_id()
			regions.append(region)
	print("Время create_regions: %d мкс" % (Time.get_ticks_usec() - start))
	return regions


# ---- Пакетное создание -----
## Создание групп населения для каждого региона и профессии пачками
func create_population_groups_batch(match_id: int, records_regions: Array, record_nation: Dictionary, professions_type: Array) -> Array:
	var start = Time.get_ticks_usec()
	var population_groups: Array = []
	var values: Array = []
	var placeholders: Array = []
	
	db.query("BEGIN") # Начинаем транзакцию
	
	for record_region in records_regions:
		for profession_type in professions_type:
			# Проверка на существование
			if not find_records_by_params("population_groups", {
				"region_id": record_region['id'],
				"nation_id": record_nation['id'],
				"profession_type_id": profession_type['id']
			}).is_empty():
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
		
		if db.query_with_bindings(insert_sql, values):
			var returned_ids = db.query_result
			for i in range(population_groups.size()):
				population_groups[i]["id"] = returned_ids[i]["id"]
		else:
			push_error("Ошибка пакетной вставки групп населения: %s" % db.error_message)
	
	db.query("COMMIT") # Завершаем транзакцию
	
	print("Время create_population_groups_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return population_groups

## Создание компаний пачками (не с уникалньными ботами)
func create_company_batch(match_id: int, record_nation: Dictionary, specializations: Array) -> Array:
	var start = Time.get_ticks_usec()
	var companies: Array
	var values: Array
	var placeholders: Array
	var insert_sql: String = 'INSERT INTO companies (name, player_id, bot_id, speciality_id) VALUES '
	
	db.query('BEGIN') # Начинаем транзации
	
	var bot = create_bot('', record_nation)
	for speciality in specializations:
		if speciality['id'] == 1:
			continue
		
		var generation_company_name = GenerationCompanyName.new()
		var name_company = generation_company_name.get_random_name(speciality['id'])
		
		if bot['status'] == 'continue':
			continue
		
		if not find_records_by_params("companies", {
			"name": name_company, 
			"bot_id": bot['record']['id']
		}).is_empty():
			print('Компания "{0}" уже существует, в матче {2}'.format([ name_company, match_id ]))
			continue
		
		# Добавляем данные для вставки
		placeholders.append('(?, ?, ?, ?)')
		values.append(name_company)
		values.append(-1)
		values.append(bot['record']['id'])
		values.append(speciality['id'])
		
		companies.append({
			'name': name_company,
			'player_id': -1,
			'bot_id': bot['record']['id'],
			'speciality_id': speciality['id'],
			'record_bot': bot['record']
		})
			
			
	if not values.is_empty():
		insert_sql += ', '.join(placeholders) + ' RETURNING id;'
		#
		#print('SQL insert: ', insert_sql)
		#print('value: ', values)
		
		var result = db.query_with_bindings(insert_sql, values)
		#print('DB ERROR: ', db.db.error_message)
		#print('\nresult: ', result)
		#print('\nquery_result: ', db.db.query_result)
		
		# Выполняем вставку пачкой с возвратом ID
		if result:
			var returned_ids = db.query_result
			for i in range(companies.size()):
				companies[i]['id'] = returned_ids[i]['id']
		else:
			push_error('Ошибка пакетной вставки компаний: {0}'.format([ db.error_message ]))
	
	db.query('COMMIT') # Завершение транзации
	
	print("Время create_company_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return companies

## Создание департаментов компаний пачками
func create_company_departments_batch(match_id: int, records_companies: Array, records_regions: Array) -> Array:
	var start = Time.get_ticks_usec()
	var company_departments: Array
	var values: Array
	var placeholders: Array
	var insert_sql: String = 'INSERT INTO company_departments (company_id, region_id) VALUES '
	
	db.query('BEGIN') # Начинаем транзации
	
	for record_company in records_companies:
		for record_region in records_regions:
			if not find_records_by_params("company_departments", {
				"company_id": record_company['id'], 
				"region_id": record_region['id']
			}).is_empty():
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
		if db.query_with_bindings(insert_sql, values):
			var returned_ids = db.query_result
			for i in range(company_departments.size()):
				company_departments[i]['id'] = returned_ids[i]['id']
		else:
			push_error('Ошибка пакетной вставки департаментов компаний: {0}'.format([ db.error_message ]))
	
	db.query('COMMIT') # Завершение транзации
	
	print("Время create_company_departments_batch: %d мкс" % (Time.get_ticks_usec() - start))
	return company_departments


# ------ Пакетное удаление -----
## Удаление всей информации о конкретном матче
func clear_match_data(match_id: int) -> void:
	var start = Time.get_ticks_usec()
	db.query("BEGIN;") # Запуск транзакции

	# 1. Склады департаментов
	log_count("department_warehouse", "company_department_id IN (SELECT cd.id FROM company_departments cd JOIN companies c ON cd.company_id = c.id LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM department_warehouse
		WHERE company_department_id IN (
			SELECT cd.id
			FROM company_departments cd
			JOIN companies c ON cd.company_id = c.id
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 2. Задания департаментов
	log_count("department_tasks", "company_department_id IN (SELECT cd.id FROM company_departments cd JOIN companies c ON cd.company_id = c.id LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM department_tasks
		WHERE company_department_id IN (
			SELECT cd.id
			FROM company_departments cd
			JOIN companies c ON cd.company_id = c.id
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 3. Департаменты компаний
	log_count("company_departments", "company_id IN (SELECT c.id FROM companies c LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM company_departments
		WHERE company_id IN (
			SELECT c.id
			FROM companies c
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 4. Компании
	log_count("companies", "player_id IN (SELECT id FROM players WHERE nation_id IN (SELECT id FROM nations WHERE match_id = ?)) OR bot_id IN (SELECT id FROM bots WHERE nation_id IN (SELECT id FROM nations WHERE match_id = ?))", [match_id, match_id])
	db.query_with_bindings("""
		DELETE FROM companies
		WHERE player_id IN (
			SELECT id FROM players WHERE nation_id IN (
				SELECT id FROM nations WHERE match_id = ?
			)
		) OR bot_id IN (
			SELECT id FROM bots WHERE nation_id IN (
				SELECT id FROM nations WHERE match_id = ?
			)
		);
	""", [match_id, match_id])

	# 5. Профессии
	log_count("professions", "country_id IN (SELECT c.id FROM countries c LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM professions
		WHERE country_id IN (
			SELECT c.id
			FROM countries c
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 6. Группы населения
	log_count("population_groups", "nation_id IN (SELECT id FROM nations WHERE match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM population_groups
		WHERE nation_id IN (
			SELECT id FROM nations WHERE match_id = ?
		);
	""", [match_id])

	# 7. Регионы
	log_count("regions", "province_id IN (SELECT p.id FROM provinces p JOIN countries c ON p.country_id = c.id LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM regions
		WHERE province_id IN (
			SELECT p.id
			FROM provinces p
			JOIN countries c ON p.country_id = c.id
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 8. Провинции
	log_count("provinces", "country_id IN (SELECT c.id FROM countries c LEFT JOIN players pl ON c.player_id = pl.id LEFT JOIN bots b ON c.bot_id = b.id JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id WHERE n.match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM provinces
		WHERE country_id IN (
			SELECT c.id
			FROM countries c
			LEFT JOIN players pl ON c.player_id = pl.id
			LEFT JOIN bots b ON c.bot_id = b.id
			JOIN nations n ON COALESCE(pl.nation_id, b.nation_id) = n.id
			WHERE n.match_id = ?
		);
	""", [match_id])

	# 9. Страны
	log_count("countries", "player_id IN (SELECT pl.id FROM players pl JOIN nations n ON pl.nation_id = n.id WHERE n.match_id = ?) OR bot_id IN (SELECT b.id FROM bots b JOIN nations n ON b.nation_id = n.id WHERE n.match_id = ?)", [match_id, match_id])
	db.query_with_bindings("""
		DELETE FROM countries
		WHERE player_id IN (
			SELECT pl.id FROM players pl
			JOIN nations n ON pl.nation_id = n.id
			WHERE n.match_id = ?
		) OR bot_id IN (
			SELECT b.id FROM bots b
			JOIN nations n ON b.nation_id = n.id
			WHERE n.match_id = ?
		);
	""", [match_id, match_id])

	# 10. Боты
	log_count("bots", "nation_id IN (SELECT id FROM nations WHERE match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM bots
		WHERE nation_id IN (
			SELECT id FROM nations WHERE match_id = ?
		);
	""", [match_id])

	# 11. Игроки
	log_count("players", "nation_id IN (SELECT id FROM nations WHERE match_id = ?)", [match_id])
	db.query_with_bindings("""
		DELETE FROM players
		WHERE nation_id IN (
			SELECT id FROM nations WHERE match_id = ?
		);
	""", [match_id])

	# 12. Нации
	log_count("nations", "match_id = ?", [match_id])
	db.query_with_bindings("""
		DELETE FROM nations WHERE match_id = ?;
	""", [match_id])

	db.query("COMMIT;")
	print("Время пакетного удаления clear_match_data: %d мкс" % (Time.get_ticks_usec() - start))
