require "unicode_utils/downcase"

r_vowels="аяоёуюиэеы"

def just_split_into_syllabes(word)
	syllabes = word.split(/(?<=[аяоёуюиэеы])/)
	for i in 0...syllabes.length-1
		if syllabes[i+1].length >= 3
			syllabes[i] += syllabes[i+1][0]
			syllabes[i+1] = syllabes[i+1][1..-1]
		end
	end
	if syllabes[-1].match /[аяоёуюиэеы]/
		return syllabes
	else
		syllabes[-2] += syllabes[-1]
		return syllabes[0..-2]
	end
end

def syllike(syl)
	ss = syl.split(/(?<=[аяоёуюиэеы])/)
	if ss.length == 1
		[ss[0][0..-2], ss[0][-1], ""]
	else
		[ss[0][0..-2], ss[0][-1], ss[1]]
	end
end

def create1(s, v, e)
	if s == ''
		s = 'Б'
	elsif s[0].match /[лрнздт]/
		s = 'Б' + s
	else
		s[0] = 'Б'
	end
	s + v + e
end

def create2(s, v, e)
	s + v + e
end

def create3(s, v, e)
	if s != 'б'
		s += 'б'
	end
	s +  v + e
end

def bbfy(name)
	# name = "Кудряшова"
	syllabes =  just_split_into_syllabes(name)
	if syllabes.length == 1
		syllabes[1] = "нер"
	end
	if syllabes.length == 2
		syllabes[2] = "и"
	end
	bname = create1(*syllike(syllabes[0])) \
		 + create2(*syllike(syllabes[1])) \
		 + create3(*syllike(syllabes[2])) + %w[хер тер тор нер].sample
end

bbfy(UnicodeUtils.downcase("галиакберов").encode('utf-8'))