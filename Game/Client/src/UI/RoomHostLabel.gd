extends Label


func _ready():
	Server.connect('receive_host_name', self, 'change_host_name_text')
	if Globals.host_name:
		change_host_name_text(Globals.host_name)
		
	else:
		Server.request_host_name()

func change_host_name_text(host_name):
	self.text = 'Host: %s' % host_name

