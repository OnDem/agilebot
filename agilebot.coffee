_ = require 'lodash'
Telegram = require 'telegram-bot'

mongoose = require 'mongoose'
taskSchema = mongoose.Schema
  user: String
  name: String
  text: String
Task = mongoose.model 'Task', taskSchema 
mongoose.connect 'mongodb://localhost/agilebot'

sessions = {}
keyboard = '{"keyboard": [["/addnewtask","/listmytasks"], ["/help", "/createworkgroup"]],"one_time_keyboard": true}'

map =
  listmytasks: (msg) ->
    Task.find(user:msg.chat.id).exec (err, data) ->
      if err
        console.log err
      else
        taskList = "Task list:\n"
        for d in data
          taskList = "#{taskList}\n - #{d.text}"
        msg.reply
          text: taskList
          reply_markup:
            keyboard

  addnewtask: (msg) ->
    sessions[msg.chat.id] = (msg) ->
      text = String(msg.text).trim()

      newTask = new Task
        user: msg.chat.id
        name: 'newTask'
        text: text
      newTask.save (err) ->
        if err
          console.log err
        else  
          msg.reply
            text: "Task created: #{newTask.text}"
            reply_markup:
              keyboard

      delete sessions[msg.chat.id]

    msg.reply
      text: 'Put here some text'
      reply_markup:
        force_reply: true

  help: (msg) ->
    msg.reply
      text: """
        There are basic commands for agilebot manipulating
        /help - Help
        /listg - List my groups
        /addnewtask - Add a new task
        /createworkgroup - Create a new workgroup
        /addusertogroup - Add telegram user to work group
        /rmuserfromgroup - Remove telegram user from work group
        /listmytasks - List all my actual tasks
        /taketaskfromlist - Take a task from task list of current group
      """
      reply_markup:
        keyboard


tg = new Telegram(process.env.TELEGRAM_BOT_TOKEN)
tg.on 'message', (msg) ->
  console.log "#{msg.date} #{msg.from.username || msg.from.first_name}: #{msg.text}"
  text = String(msg.text).trim()
  msg.reply = (options) ->
    tg.sendMessage _.defaults options,
      reply_to_message_id: @message_id
      chat_id: @chat.id

  cmd = String(text.match(/^\/([a-zA-Z0-9]*)(@agilebot)?/i)?[1]).toLowerCase()
  return map[cmd](msg) if cmd && map[cmd]

  sessions[msg.chat.id](msg) if sessions[msg.chat.id]

tg.start()
