extends RefCounted
class_name SQLiteHelper

var db: SQLite

func _init(database_path: String = "user://game_database.db"):
	db = SQLite.new()
	db.path = database_path
	if not db.open_db():
		push_error("Failed to open database: " + db.error_message)

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

#
# ЗАКРЫТИЕ БАЗЫ ДАННЫХ
#

# Закрытие базы данных
func close_database():
	if db != null:
		db.close_db()
		db = null


#
# готовые решения
#

## Создание департаментов
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
