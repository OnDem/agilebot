var mongoose = require('mongoose');
var taskSchema = mongoose.Schema({
	name: String,
	text: String
});
var Task = mongoose.model('Task', taskSchema);
mongoose.connect('mongodb://localhost/agilebot');

var api = new (require('teleapi'))('--token--');
var prm = {
	"timeout": 0
}
var helptext = "There are basic commands for agilebot manipulating\n /help - Help\n /listg - List my groups\n /addnewtask - Add a new task\n /createworkgroup - Create a new workgroup\n /addusertogroup - Add telegram user to work group\n /rmuserfromgroup - Remove telegram user from work group\n /listmytasks - List all my actual tasks\n /taketaskfromlist - Take a task from task list of current group\n";

function callback(error, result) {
// if "error" is true to then the result is error object. 
	//console.log(result);
	return true;
}

//api.getMe(callback);
function updateProcessor(item) {
	console.log(item.message.from.id + ' ' + item.message.text);
	// sending hello to OnDem - 62953803
	switch ( item.message.text ) {
		case '/help':
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": helptext,
				"reply_markup": '{"keyboard": [["/addnewtask","/listmytasks"], ["/help", "/createworkgroup"]],"one_time_keyboard": true}'
			}, callback); break;
		case '/createworkgroup':
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": "not implemented",
				"reply_markup": '{"hide_keyboard": true}'
			}, callback); break;
		case '/listg':
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": "not implemented",
				"reply_markup": '{"hide_keyboard": true}'
			}, callback); break;
		case '/addnewtask':
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": "not implemented",
				"reply_markup": '{"hide_keyboard": true}'
			}, callback); break;
		case item.message.text.match(/^(\/task) (.*)/i)[1]:
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": "not implemented",
				"reply_markup": '{"hide_keyboard": true}'
			}, callback); break;
		case '/listmytasks':
			Task.find({ 'name': "startTask" }, function (err, tasks) {
				if (err) {
					console.log(err);
				} else {
					//console.log(tasks);
					var msg = 'Tasks: ',
						i = 0,
						tCount = tasks.length;
					msg = msg + tCount;
					for( i = 0; i < tCount; ) {
						msg = msg + "\n\n" + (i+1) + ". " + tasks[i].name;
						msg = msg + "\n" + "  " + tasks[i].text;
						i = i + 1;
					}
					api.sendMessage({
						"chat_id": item.message.from.id,
						"text": msg,
						"reply_markup": '{"hide_keyboard": true}'
					}, callback); 
				}
			});
			break;
		default:
			api.sendMessage({
				"chat_id": item.message.from.id,
				"text": helptext,
				"reply_markup": '{"keyboard": [["/addnewtask","/listmytasks"], ["/help", "/createworkgroup"]],"one_time_keyboard": true}'
			}, callback);

	}
}

function localactions(error, result) {
	var lastUpdate = result.pop()
	if ( prm['offset'] != lastUpdate.update_id ) {
		prm['offset'] = lastUpdate.update_id
		console.log(prm);
		updateProcessor(lastUpdate);
	}
}

setInterval(function() {
	api.getUpdates(prm,localactions);
}, 600);
