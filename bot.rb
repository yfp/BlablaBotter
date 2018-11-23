require 'telegram/bot'
require "unicode_utils/titlecase"
require "unicode_utils/downcase"
require 'open-uri'
require 'time'
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

def get_greeting(name: nil, gender: :male)
  title = if gender == :male
    "Господин"
  else "Госпожа" end
  if name
    name.gsub!(/[^\p{Cyrillic}]+/, "")
  else name = "" end
  bname = if name == ""
    BName.create_default_bname
  else
    bbfy(UnicodeUtils.downcase(name)) || BName.create_default_bname
  end
  "#{title} #{bname}!"
end

def run_bot(token)
  photo_waiting_list = []
  Telegram::Bot::Client.run(token) do |bot|

    bot.listen do |message|
      if message.text and not message.forward_from
        words = UnicodeUtils.downcase(message.text).split(' ')
        if words[0] == '/joinchat'
          # link = if words.length>1 then words[1] else "" end
          # print bot.messages.importChatInvite
        elsif words[0] == '/bb'
          name = nil
          if words.length > 1 and words[1].match(/^\p{Cyrillic}+$/)
            name = words[1]
          end
          text = get_greeting(name: name)
          bot.api.send_message(chat_id: message.chat.id, text: text)
        elsif words[0] == '/bbface'
          photo_waiting_list.push( user_id: message.from.id,
            chat_id: message.chat.id, timestamp: Time.now() )
          name = "#{message.from.first_name}#{message.from.last_name}"
          bname = get_greeting(name: name)
          bot.api.send_message(chat_id: message.chat.id,
            text: "Отлично, г#{bname[1..-1]} Я жду Вашей фотокарточки!")
        elsif 
          pos = words.find_index{ |e| e.match(/госпо(дин(а|у|е|ом)?|ж(а|у|е|ой)?)/) }
          if pos
            print message.text + "\n"
            name = if pos < words.length - 1
              words[pos+1]
            else nil end
            gender = if words[pos].match /ж/ then :female else :male end
            text = get_greeting(name: name, gender: gender)
            bot.api.send_message(chat_id: message.chat.id, text: text)
          end
        end
      end
      if message.photo and message.photo.length > 0
        pwl_pos = photo_waiting_list.find_index {|e| e[:user_id] == message.from.id and e[:chat_id] == message.chat.id }
        if pwl_pos
          photo_waiting_list.delete_at pwl_pos
          photo = message.photo.max_by(&:width)
          result = bot.api.get_file(file_id: photo.file_id)
          if result['ok']
            url = "https://api.telegram.org/file/bot#{token}/#{result['result']['file_path']}"
            ext = result['result']['file_path'].split('.')[-1]
            input_filename = "photos/input/#{photo.file_id}.#{ext}"
            output_filename = "photos/output/#{photo.file_id}.#{ext}"
            open(input_filename, 'wb') do |file|
              file << open(url).read
            end
            %x( python face-processor/util.py -i #{input_filename} -o #{output_filename} )
            # bot.api.send_message(chat_id: message.chat.id, text: "Обработано!")
            if File.file?(output_filename)
              bot.api.send_photo(chat_id: message.chat.id,
                photo: Faraday::UploadIO.new(output_filename, result['result']['mime_type']))
            else
              bname = get_greeting()
              bot.api.send_message(chat_id: message.chat.id,
                text: "У меня не получился г#{bname[1..-1]}")
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
end

while true
  begin
    print "Connection starts\n"
    run_bot(token)
  rescue Faraday::ConnectionFailed
    print "Restarting connection...\n"
  end
end
