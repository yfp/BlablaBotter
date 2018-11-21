require 'telegram/bot'
require "unicode_utils/titlecase"
require "unicode_utils/downcase"
require_relative 'ruslang'

token = '731014512:AAHLp3k0YivOj5SgrtHit2qPkEGPdKsoVhg'

first_halves = %w[баттер брейнер блаттен буйнер биввис боттокс бубен белкин будкин бродскер бродвей бубба брынзер батлен]
second_halves = %w[хёртер факер пихер бубер шпилер нахер бухер бляхер швайнер роббер биддер винер батхед боннер бройлер]

r_vowels="аяоёуюиэеы"

def split_into_syllabes(word)
    word.split
end


Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    if message.text
        words = message.text.split(' ')
        case words[0]
        when '/bb'
            if words.length > 1
                name = UnicodeUtils.downcase(words[1])
                if name.match(/^\p{Cyrillic}+$/)
                    bname = bbfy(name.encode('utf-8'))
                end
            end
            bname ||= UnicodeUtils.titlecase( first_halves.sample + second_halves.sample )

            bot.api.send_message(chat_id: message.chat.id, text: "Господин #{bname}!")
        end
      end
    end
end