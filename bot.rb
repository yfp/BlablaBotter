require 'telegram/bot'
require "unicode_utils/titlecase"
require "unicode_utils/downcase"
require 'open-uri'
require_relative 'ruslang'

token = ENV["BICHER_BOT_API_TOKEN"]


r_vowels="аяоёуюиэеы"

module BName
  @@first_halves = %w[боинг брахен вротбрам барден блёндер брибен брейтен шмукель бандер бехер крюхен штрих румпель бантех батер бруден булькен бибер брельтен бредо брахтен брумгель гельбдер брайден бертен бриден бульбул брувень блудвер гиберль боейтен бихел бурден блиндел бутерброд бриттен брумдель зильбель шляхер шмихель блюдвер бендер бретен бритен брумтель биркин жритен браттен бринден бредень бред блюда брикл трахтен бехен бриндн штукен штрех блютнер блюндер блейтель шмаль бриктен бордюр блядь бранден бурбум брундер бренбин бричка зильбер берген брудер бандир брайтон бьютин бургер бреген брейден бледно блэкстар вертел беттер бриндер шнайдер брумбум бальзам брендон шикль брайтен бреттен брейда бульдер брихен брубель бремпен грейт шлюхен тлюстен буртан бюндер барбер бульбрын пинкман бредэнд бредэн берпер брюхен блендер братем шпрехен брюмбель боттокс биввис]
  @@second_halves = %w[брехель блюдер крюгер бургец трихтер дихер бихер блюмер шопер брюхер бахтер хребихер бриххер бумбекхер бичер бихрев блюхер бихен бляхер трахер бихел брунер брюк шнайдер бридер брюгер бихтер нахтер брейкер блихер махкхер мухер бехер хабль штицхен стицхен дирхен шафтер шафнер берефин брехер шухер вель бехкль бухер битнер бурхер швальцар брихер пихарь швальцен жмухер бибер бихель бункер бойлер бургер бейхер брех бюхер бикер лятор биккер блохер бергер грубер штихер бейкер бритейн штукер байхер шмахер битер бельзен биртхнер хохнер брехен бахер бичев брюхин брюхен нахер штрахтер берхин хёртер факер пихер бубер шпилер нахер бухер бляхер швайнер роббер биддер винер батхед боннер бройлер]

  def self.create_default_bname
    UnicodeUtils.titlecase( @@first_halves.sample + @@second_halves.sample )
  end
end


def run_bot(token)
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
          bname ||= BName.create_default_bname

          bot.api.send_message(chat_id: message.chat.id, text: "Господин #{bname}!")
        end
      end
      if message.photo and message.photo.length > 0
        photo = message.photo.max_by(&:width)
        result = bot.api.get_file(file_id: photo.file_id)
        if result['ok']
          print result['result']
          url = "https://api.telegram.org/file/bot#{token}/#{result['result']['file_path']}"
          open("photos/input/#{photo.file_id}.png", 'wb') do |file|
            file << open(url).read
          end
        end
        # print file
        # open("photos/#{photo.file_id}.png", 'wb') do |file|
        #   file << open('http://example.com/image.png').read
        # end
      end
    end
  end
end

while true
  begin
    print "Connection starts\n"
    run_bot(token)
  rescue Faraday::ConnectionFailed
    print "Restarting connection...\n"
  end
end
