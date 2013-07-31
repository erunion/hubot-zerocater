# Description:
#   What is ZeroCater catering us today?
#
# Dependencies:
#   "cheerio": "0.12.x"
#   "moment": "2.0.x"
#
# Configuration:
#   HUBOT_ZEROCATER_MENU_URL - In the format of https://zerocater.com/m/xxxx
#   HUBOT_ZEROCATER_CATERING_TIME - In the format of HH:MM
#
# Commands:
#   hubot zerocater - Pulls your catering menu for today
#   hubot zerocater tomorrow - Tomorrows catering menu
#   hubot zerocater <day of week> - Catering menu for the given day of the week
#
# Author:
#   jonursenbach

moment = require 'moment'
cheerio = require 'cheerio'

module.exports = (robot) =>
  robot.respond /(zerocater|zero cater)( .*)?/i, (msg) ->
    getCatering msg, moment()

getCatering = (msg, date) ->
  if date is false
    return msg.send 'I don\'t know when that is.'

  console.log 'url=' + process.env.HUBOT_ZEROCATER_MENU_URL

  msg.http(process.env.HUBOT_ZEROCATER_MENU_URL)
    .get() (err, res, body) ->
      return msg.send "Sorry, Zero Cater doesn't like you. ERROR:#{err}" if err
      return msg.send "Unable to get a catering menu: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

      $ = cheerio.load(body)

      catering_found = false;
      today = date.format('YYYY-MM-DD');

      $('div.menu[data-date="' + today + '"]').each (i, elem) ->
        menu = $(this)
        header = menu.find('.meal-header')

        if menu.find('.header-time').text().match(process.env.HUBOT_ZEROCATER_CATERING_TIME, 'g') != null
          catering_found = true
          emit = 'Todays catering is provided by: ' + header.find('.vendor').text().trim() + '\n\n';
          menu.find('.item-list .item').each (i, elem) ->
            item = $(this).find('.item-name').text().trim()
            description = $(this).find('.item-description').text().trim()

            emit += item + '\n'
            if (description != '')
              emit += ' - ' + description + '\n'

          msg.send emit

      if (!catering_found)
        msg.send "Sorry, I was unable to find a menu for #{today}."
