_ = require 'lodash'
Telegram = require 'telegram-bot'

mongoose = require 'mongoose'
taskSchema = mongoose.Schema
  user: String
  name: String
  text: String
  stat: String
Task = mongoose.model 'Task', taskSchema 
mongoose.connect 'mongodb://localhost/agilebot'

sessions = {}
main_keyboard = '{"keyboard": [["/addnewtask","/listmytasks"], ["/help", "/createworkgroup"]],"one_time_keyboard": true}'
yn_keyboard = '{"keyboard": [["Yes","No"]],"one_time_keyboard": true}'
done_keyboard = '{"keyboard": [["Done","Next"]],"one_time_keyboard": true}'

map =
  listusers: (msg) ->
    Task.find().distinct 'user', (err, data) ->
      if err
        console.log err
      else
        userList = "Users:\n"
        for d in data
          userList = "#{userList}\n - #{d}"
        msg.reply
          text: userList
          reply_markup: yn_keyboard

  listmytasks: (msg) ->
    Task.find(user:msg.chat.id).exec (err, data) ->
      if err
        console.log err
      else
        taskList = "Task list:\n"
        for d in data
          statSymbol = '-'
          if d.stat == 'done'
            statSymbol = '√'
          taskList = "#{taskList}\n #{statSymbol} #{d.text}"
        msg.reply
          text: taskList
          reply_markup: main_keyboard

  marktasksdone: (msg) ->
    sessions[msg.chat.id] = (msg) ->
      text = String(msg.text).trim()
      if text == 'Done'
        Task.where(user:msg.chat.id).update({$set: stat: 'done'}).exec (err,data) ->
          if err
            console.log err
          else
            for d in data
              msg.reply
                text: 'done'
      delete sessions[msg.chat.id]

    Task.find(user:msg.chat.id,stat:'new').exec (err, data) ->
      if err
        console.log err
      else
        for d in data
          taskMsg = "Task: #{d.text}"
          msg.reply
            text: taskMsg
            reply_markup: done_keyboard

  addnewtask: (msg) ->
    sessions[msg.chat.id] = (msg) ->
      text = String(msg.text).trim()

      newTask = new Task
        user: msg.chat.id
        name: 'newTask'
        text: text
        stat: 'new'
      newTask.save (err) ->
        if err
          console.log err
        else  
          msg.reply
            text: "Task created: #{newTask.text}"
            reply_markup:main_keyboard

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

        See details on http://www.agilebot.pro and follow us on twitter @agilebotpro
      """
      reply_markup: main_keyboard

  start: (msg) ->
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

        See details on http://www.agilebot.pro and follow us on twitter @agilebotpro
      """
      reply_markup: main_keyboard


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
