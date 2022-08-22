const FILE_MODIFIED_DELAY = 120

var entity
var timestamp
var is_write

func _init(entity = '', timestamp = 0, is_write = false):
	self.entity = entity
	self.timestamp = timestamp
	self.is_write = is_write
