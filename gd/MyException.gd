class_name MyException
extends MySugar


func check_null(argument):
	if typeof(argument) == 0:
		return true
	else:
		print('{argument} - не является типом null'.format({argument = argument}))
		return false
func check_bool(argument):
	if typeof(argument) == 1:
		return true
	else:
		print('{argument} - не является типом bool'.format({argument = argument}))
		return false
func check_int(argument):
	if typeof(argument) == 2:
		return true
	else:
		print('{argument} - не является типом int'.format({argument = argument}))
		return false
func check_float(argument):
	if typeof(argument) == 3:
		return true
	else:
		print('{argument} - не является типом float'.format({argument = argument}))
		return false
func check_str(argument):
	if typeof(argument) == 4:
		return true
	else:
		print('{argument} - не является типом string'.format({argument = argument}))
		return false
