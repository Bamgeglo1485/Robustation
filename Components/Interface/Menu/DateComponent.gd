class_name DateComponent extends Component

var update_timer: Timer

func _ready() -> void:
	update_timer = Timer.new()
	update_timer.wait_time = 1.0
	update_timer.one_shot = true
	update_timer.timeout.connect(_update_datetime)
	add_child(update_timer)
	_update_datetime()

func _update_datetime() -> void:
	update_timer.start()
	var datetime = Time.get_datetime_dict_from_system()
	
	var time_str = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]
	
	var date_str = "%02d.%02d.%04d" % [datetime.day, datetime.month, datetime.year + 1000]
	
	parent.text = "%s\n\n%s" % [time_str, date_str]
