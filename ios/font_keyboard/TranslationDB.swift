// MARK: - TranslationDB (새로 정리된 버전)
// 한→영, 영→한: 양방향
// 나머지 언어: 외국어→한국어 (역방향)
// 비속어/오번역 없이 검증된 문구만

import Foundation

struct TranslationDB {

    // MARK: - DB 조회
    static func lookup(text: String, from src: String, to tgt: String) -> String? {
        var key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }

        // 반복 문자 정규화
        let repeatPatterns: [(String, String)] = [
            ("ㅋㅋㅋㅋ", "ㅋㅋ"), ("ㅋㅋㅋ", "ㅋㅋ"),
            ("ㅎㅎㅎㅎ", "ㅎㅎ"), ("ㅎㅎㅎ", "ㅎㅎ"),
            ("ㅠㅠㅠ", "ㅠㅠ"), ("ㅜㅜㅜ", "ㅜㅜ"),
        ]
        for (from, to) in repeatPatterns { key = key.replacingOccurrences(of: from, with: to) }

        // 한→영
        if (src.contains("한국어") || src.contains("Korean")) && tgt.contains("English") {
            return stepLookup(key, in: koEn)
        }

        // 영→한
        if src.contains("English") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            let lower = key.lowercased()
            return stepLookup(lower, in: enKo) ?? stepLookup(key, in: enKo)
        }

        // 일→한
        if src.contains("Japanese") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: jaKo)
        }

        // 중→한
        if src.contains("Chinese") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: zhKo)
        }

        // 스페인어→한
        if src.contains("Spanish") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: esKo)
        }

        // 불어→한
        if src.contains("French") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: frKo)
        }

        // 독일어→한
        if src.contains("German") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: deKo)
        }

        // 베트남어→한
        if src.contains("Vietnamese") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: viKo)
        }

        // 태국어→한
        if src.contains("Thai") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: thKo)
        }

        // 인니어→한
        if src.contains("Indonesian") && (tgt.contains("Korean") || tgt.contains("한국어")) {
            return stepLookup(key, in: idKo)
        }

        return nil
    }

    private static func stepLookup(_ key: String, in map: [String: String]) -> String? {
        if let result = map[key] { return result }
        var stripped = key
        while let last = stripped.last, "?!~。？！".contains(last) {
            stripped.removeLast()
            if let result = map[stripped] { return result }
        }
        return nil
    }

    // MARK: - 한→영 (koEn)
    static let koEn: [String: String] = [
        "안녕": "Hi.",
        "안녕하세요": "Hello.",
        "잘 자": "Good night.",
        "좋은 아침": "Good morning.",
        "잘 지내?": "How are you?",
        "오랜만이야": "Long time no see.",
        "반가워": "Nice to meet you.",
        "잘 있어": "Goodbye.",
        "나중에 봐": "See you later.",
        "내일 봐": "See you tomorrow.",
        "또 봐": "See you again.",
        "감사해": "Thank you.",
        "감사합니다": "Thank you.",
        "고마워": "Thank you.",
        "정말 감사해": "Thank you so much.",
        "미안해": "I'm sorry.",
        "죄송해요": "I'm sorry.",
        "괜찮아": "It's okay.",
        "사랑해": "I love you.",
        "보고싶어": "I miss you.",
        "보고싶다": "I miss you.",
        "좋아해": "I like you.",
        "많이 사랑해": "I love you so much.",
        "항상 응원해": "I'm always cheering for you.",
        "최고야": "You're the best.",
        "대단해": "You're amazing.",
        "잘했어": "Good job.",
        "멋있어": "You're cool.",
        "예뻐": "You're beautiful.",
        "귀여워": "You're cute.",
        "행복해": "I'm happy.",
        "슬퍼": "I'm sad.",
        "기뻐": "I'm glad.",
        "설레": "I'm excited.",
        "걱정 마": "Don't worry.",
        "힘내": "You got this.",
        "잘 될 거야": "It'll work out.",
        "축하해": "Congratulations.",
        "생일 축하해": "Happy birthday.",
        "밥 먹었어?": "Have you eaten?",
        "뭐해?": "What are you doing?",
        "어디야?": "Where are you?",
        "나 지금 가는 중": "I'm on my way.",
        "곧 도착해": "I'll be there soon.",
        "잠깐만": "Just a moment.",
        "알겠어": "I understand.",
        "그래": "Okay.",
        "맞아": "That's right.",
        "진짜?": "Really?",
        "대박": "Wow!",
        "재밌어": "It's fun.",
        "배고파": "I'm hungry.",
        "졸려": "I'm sleepy.",
        "피곤해": "I'm tired.",
        "응원해": "I'm cheering for you.",
        "파이팅": "Fighting!",
        "열심히 해": "Do your best.",
        "건강 챙겨": "Take care of yourself.",
        "행복하게 해줘서 고마워": "Thank you for making me happy.",
        "너를 응원해": "I support you.",
    ]

    // MARK: - 영→한 (enKo)
    static let enKo: [String: String] = [
        "hi.": "안녕.",
        "hi": "안녕.",
        "hello.": "안녕하세요.",
        "hello": "안녕하세요.",
        "good night.": "잘 자.",
        "good night": "잘 자.",
        "good morning.": "좋은 아침.",
        "good morning": "좋은 아침.",
        "how are you?": "잘 지내?",
        "long time no see.": "오랜만이야.",
        "nice to meet you.": "반가워.",
        "see you later.": "나중에 봐.",
        "see you tomorrow.": "내일 봐.",
        "goodbye.": "잘 있어.",
        "bye.": "잘 있어.",
        "bye": "잘 있어.",
        "thank you.": "감사해.",
        "thank you": "감사해.",
        "thanks.": "감사해.",
        "thanks": "감사해.",
        "thank you so much.": "정말 감사해.",
        "i'm sorry.": "미안해.",
        "i'm sorry": "미안해.",
        "sorry.": "미안해.",
        "sorry": "미안해.",
        "it's okay.": "괜찮아.",
        "it's okay": "괜찮아.",
        "i love you.": "사랑해.",
        "i love you": "사랑해.",
        "i miss you.": "보고싶어.",
        "i miss you": "보고싶어.",
        "i like you.": "좋아해.",
        "i like you": "좋아해.",
        "i love you so much.": "많이 사랑해.",
        "you're the best.": "최고야.",
        "you're amazing.": "대단해.",
        "good job.": "잘했어.",
        "you're cool.": "멋있어.",
        "you're beautiful.": "예뻐.",
        "you're cute.": "귀여워.",
        "i'm always cheering for you.": "항상 응원해.",
        "i'm happy.": "행복해.",
        "i'm sad.": "슬퍼.",
        "i'm glad.": "기뻐.",
        "i'm excited.": "설레.",
        "don't worry.": "걱정 마.",
        "you got this.": "힘내.",
        "it'll work out.": "잘 될 거야.",
        "congratulations.": "축하해.",
        "happy birthday.": "생일 축하해.",
        "congratulations!": "축하해!",
        "happy birthday!": "생일 축하해!",
        "have you eaten?": "밥 먹었어?",
        "what are you doing?": "뭐해?",
        "where are you?": "어디야?",
        "i'm on my way.": "나 지금 가는 중.",
        "i'll be there soon.": "곧 도착해.",
        "just a moment.": "잠깐만.",
        "i understand.": "알겠어.",
        "okay.": "그래.",
        "okay": "그래.",
        "ok.": "그래.",
        "ok": "그래.",
        "really?": "진짜?",
        "wow!": "대박!",
        "it's fun.": "재밌어.",
        "i'm hungry.": "배고파.",
        "i'm sleepy.": "졸려.",
        "i'm tired.": "피곤해.",
        "fighting!": "파이팅!",
        "do your best.": "열심히 해.",
        "take care of yourself.": "건강 챙겨.",
        "i support you.": "응원해.",
        "i'm cheering for you.": "응원해.",
    ]

    // MARK: - 일→한 (jaKo)
    static let jaKo: [String: String] = [
        "こんにちは": "안녕하세요.",
        "やあ": "안녕.",
        "おやすみ": "잘 자.",
        "おはよう": "좋은 아침.",
        "元気？": "잘 지내?",
        "久しぶり": "오랜만이야.",
        "久しぶり！": "오랜만이야!",
        "会えて嬉しい": "반가워.",
        "ありがとう": "감사해.",
        "ありがとうございます": "감사합니다.",
        "ごめん": "미안해.",
        "申し訳ありません": "죄송합니다.",
        "大丈夫": "괜찮아.",
        "愛してる": "사랑해.",
        "会いたい": "보고싶어.",
        "好きだよ": "좋아해.",
        "最高": "최고야.",
        "最高！": "최고야!",
        "よくやった": "잘했어.",
        "かわいい": "귀여워.",
        "きれい": "예뻐.",
        "幸せ": "행복해.",
        "悲しい": "슬퍼.",
        "心配しないで": "걱정 마.",
        "頑張って": "힘내.",
        "頑張って！": "힘내!",
        "おめでとう": "축하해.",
        "誕生日おめでとう": "생일 축하해.",
        "誕生日おめでとう！": "생일 축하해!",
        "ご飯食べた？": "밥 먹었어?",
        "何してる？": "뭐해?",
        "今向かってるよ": "나 지금 가는 중.",
        "わかった": "알겠어.",
        "本当に？": "진짜?",
        "すごい": "대박.",
        "すごい！": "대박!",
        "応援してるよ": "응원해.",
        "体に気をつけて": "건강 챙겨.",
        "いつも応援してるよ": "항상 응원해.",
        "さようなら": "잘 있어.",
        "またね": "또 봐.",
    ]

    // MARK: - 중→한 (zhKo)
    static let zhKo: [String: String] = [
        "你好": "안녕하세요.",
        "嗨": "안녕.",
        "晚安": "잘 자.",
        "早安": "좋은 아침.",
        "早上好": "좋은 아침.",
        "你好吗？": "잘 지내?",
        "好久不见": "오랜만이야.",
        "好久不见！": "오랜만이야!",
        "很高兴见到你": "반가워.",
        "谢谢": "감사해.",
        "谢谢你": "감사해.",
        "非常感谢": "정말 감사해.",
        "对不起": "미안해.",
        "没关系": "괜찮아.",
        "我爱你": "사랑해.",
        "想你": "보고싶어.",
        "我喜欢你": "좋아해.",
        "你最棒": "최고야.",
        "你最棒！": "최고야!",
        "做得好": "잘했어.",
        "做得好！": "잘했어!",
        "好可爱": "귀여워.",
        "好漂亮": "예뻐.",
        "很幸福": "행복해.",
        "很伤心": "슬퍼.",
        "别担心": "걱정 마.",
        "加油": "힘내.",
        "加油！": "힘내!",
        "恭喜": "축하해.",
        "恭喜！": "축하해!",
        "生日快乐": "생일 축하해.",
        "生日快乐！": "생일 축하해!",
        "吃饭了吗？": "밥 먹었어?",
        "你在干嘛？": "뭐해?",
        "我在路上": "나 지금 가는 중.",
        "好的": "알겠어.",
        "真的吗？": "진짜?",
        "哇": "대박.",
        "哇！": "대박!",
        "我支持你": "응원해.",
        "保重身体": "건강 챙겨.",
        "永远支持你": "항상 응원해.",
        "再见": "잘 있어.",
        "拜拜": "또 봐.",
    ]

    // MARK: - 스페인어→한 (esKo)
    static let esKo: [String: String] = [
        "Hola": "안녕하세요.",
        "Hola.": "안녕하세요.",
        "Buenas noches": "잘 자.",
        "Buenas noches.": "잘 자.",
        "Buenos días": "좋은 아침.",
        "Buenos días.": "좋은 아침.",
        "¿Cómo estás?": "잘 지내?",
        "¡Cuánto tiempo!": "오랜만이야!",
        "Mucho gusto": "반가워.",
        "Gracias": "감사해.",
        "Gracias.": "감사해.",
        "Muchas gracias": "정말 감사해.",
        "Lo siento": "미안해.",
        "Lo siento.": "미안해.",
        "Está bien": "괜찮아.",
        "Está bien.": "괜찮아.",
        "Te amo": "사랑해.",
        "Te amo.": "사랑해.",
        "Te extraño": "보고싶어.",
        "Te extraño.": "보고싶어.",
        "Me gustas": "좋아해.",
        "¡Eres el mejor!": "최고야!",
        "¡Buen trabajo!": "잘했어!",
        "Qué lindo": "귀여워.",
        "Soy feliz": "행복해.",
        "Estoy triste": "슬퍼.",
        "No te preocupes": "걱정 마.",
        "¡Ánimo!": "힘내!",
        "¡Felicidades!": "축하해!",
        "¡Feliz cumpleaños!": "생일 축하해!",
        "¿En serio?": "진짜?",
        "¡Increíble!": "대박!",
        "¡Vamos!": "파이팅!",
        "Te apoyo": "응원해.",
        "Cuídate": "건강 챙겨.",
        "Adiós": "잘 있어.",
        "Hasta luego": "나중에 봐.",
    ]

    // MARK: - 불어→한 (frKo)
    static let frKo: [String: String] = [
        "Salut": "안녕.",
        "Salut.": "안녕.",
        "Bonjour": "안녕하세요.",
        "Bonjour.": "안녕하세요.",
        "Bonne nuit": "잘 자.",
        "Bonne nuit.": "잘 자.",
        "Comment ça va ?": "잘 지내?",
        "Ça fait longtemps !": "오랜만이야!",
        "Enchanté": "반가워.",
        "Merci": "감사해.",
        "Merci.": "감사해.",
        "Merci beaucoup": "정말 감사해.",
        "Désolé": "미안해.",
        "Désolé.": "미안해.",
        "C'est bon": "괜찮아.",
        "Je t'aime": "사랑해.",
        "Je t'aime.": "사랑해.",
        "Tu me manques": "보고싶어.",
        "Tu me manques.": "보고싶어.",
        "Je t'aime bien": "좋아해.",
        "T'es le meilleur !": "최고야!",
        "Bien joué !": "잘했어!",
        "T'es trop mignon": "귀여워.",
        "Je suis heureux": "행복해.",
        "Je suis triste": "슬퍼.",
        "T'inquiète pas": "걱정 마.",
        "Courage !": "힘내!",
        "Félicitations !": "축하해!",
        "Joyeux anniversaire !": "생일 축하해!",
        "Vraiment ?": "진짜?",
        "Incroyable !": "대박!",
        "Allez !": "파이팅!",
        "Je te soutiens": "응원해.",
        "Prends soin de toi": "건강 챙겨.",
        "Au revoir": "잘 있어.",
        "À plus": "나중에 봐.",
    ]

    // MARK: - 독일어→한 (deKo)
    static let deKo: [String: String] = [
        "Hallo": "안녕하세요.",
        "Hallo.": "안녕하세요.",
        "Gute Nacht": "잘 자.",
        "Gute Nacht.": "잘 자.",
        "Guten Morgen": "좋은 아침.",
        "Guten Morgen.": "좋은 아침.",
        "Wie geht's?": "잘 지내?",
        "Lange nicht gesehen!": "오랜만이야!",
        "Schön dich kennenzulernen": "반가워.",
        "Danke": "감사해.",
        "Danke.": "감사해.",
        "Vielen Dank": "정말 감사해.",
        "Tut mir leid": "미안해.",
        "Tut mir leid.": "미안해.",
        "Ist okay": "괜찮아.",
        "Ich liebe dich": "사랑해.",
        "Ich liebe dich.": "사랑해.",
        "Ich vermisse dich": "보고싶어.",
        "Ich vermisse dich.": "보고싶어.",
        "Ich mag dich": "좋아해.",
        "Du bist der Beste!": "최고야!",
        "Gut gemacht!": "잘했어!",
        "Du bist süß": "귀여워.",
        "Ich bin glücklich": "행복해.",
        "Ich bin traurig": "슬퍼.",
        "Mach dir keine Sorgen": "걱정 마.",
        "Kopf hoch!": "힘내!",
        "Herzlichen Glückwunsch!": "축하해!",
        "Alles Gute zum Geburtstag!": "생일 축하해!",
        "Wirklich?": "진짜?",
        "Wahnsinn!": "대박!",
        "Los!": "파이팅!",
        "Ich unterstütze dich": "응원해.",
        "Pass auf dich auf": "건강 챙겨.",
        "Auf Wiedersehen": "잘 있어.",
        "Bis später": "나중에 봐.",
    ]

    // MARK: - 베트남어→한 (viKo)
    static let viKo: [String: String] = [
        "Xin chào": "안녕하세요.",
        "Xin chào.": "안녕하세요.",
        "Ngủ ngon": "잘 자.",
        "Ngủ ngon.": "잘 자.",
        "Chào buổi sáng": "좋은 아침.",
        "Bạn khỏe không?": "잘 지내?",
        "Lâu rồi không gặp!": "오랜만이야!",
        "Rất vui được gặp bạn": "반가워.",
        "Cảm ơn": "감사해.",
        "Cảm ơn.": "감사해.",
        "Cảm ơn rất nhiều": "정말 감사해.",
        "Xin lỗi": "미안해.",
        "Xin lỗi.": "미안해.",
        "Không sao": "괜찮아.",
        "Không sao.": "괜찮아.",
        "Anh yêu em": "사랑해.",
        "Em yêu anh": "사랑해.",
        "Nhớ bạn": "보고싶어.",
        "Nhớ bạn.": "보고싶어.",
        "Mình thích bạn": "좋아해.",
        "Bạn tuyệt vời nhất!": "최고야!",
        "Làm tốt lắm!": "잘했어!",
        "Dễ thương quá": "귀여워.",
        "Mình hạnh phúc": "행복해.",
        "Mình buồn": "슬퍼.",
        "Đừng lo lắng": "걱정 마.",
        "Cố lên!": "힘내!",
        "Chúc mừng!": "축하해!",
        "Chúc mừng sinh nhật!": "생일 축하해!",
        "Thật không?": "진짜?",
        "Tuyệt vời!": "대박!",
        "Mình ủng hộ bạn": "응원해.",
        "Giữ gìn sức khỏe nhé": "건강 챙겨.",
        "Tạm biệt": "잘 있어.",
        "Hẹn gặp lại": "나중에 봐.",
    ]

    // MARK: - 태국어→한 (thKo)
    static let thKo: [String: String] = [
        "สวัสดี": "안녕하세요.",
        "ราตรีสวัสดิ์": "잘 자.",
        "อรุณสวัสดิ์": "좋은 아침.",
        "เป็นยังไงบ้าง?": "잘 지내?",
        "ไม่ได้เจอกันนานเลย!": "오랜만이야!",
        "ยินดีที่ได้รู้จัก": "반가워.",
        "ขอบคุณ": "감사해.",
        "ขอบคุณมาก": "정말 감사해.",
        "ขอโทษ": "미안해.",
        "ไม่เป็นไร": "괜찮아.",
        "ฉันรักเธอ": "사랑해.",
        "คิดถึง": "보고싶어.",
        "ฉันชอบเธอ": "좋아해.",
        "เยี่ยมมาก!": "최고야!",
        "ทำได้ดีมาก!": "잘했어!",
        "น่ารักมาก": "귀여워.",
        "มีความสุข": "행복해.",
        "เศร้า": "슬퍼.",
        "ไม่ต้องกังวล": "걱정 마.",
        "สู้ๆ!": "힘내!",
        "ยินดีด้วย!": "축하해!",
        "สุขสันต์วันเกิด!": "생일 축하해!",
        "จริงเหรอ?": "진짜?",
        "ว้าว!": "대박!",
        "เป็นกำลังใจให้": "응원해.",
        "ดูแลสุขภาพด้วยนะ": "건강 챙겨.",
        "ลาก่อน": "잘 있어.",
        "แล้วเจอกัน": "나중에 봐.",
    ]

    // MARK: - 인니어→한 (idKo)
    static let idKo: [String: String] = [
        "Halo": "안녕하세요.",
        "Halo.": "안녕하세요.",
        "Selamat malam": "잘 자.",
        "Selamat malam.": "잘 자.",
        "Selamat pagi": "좋은 아침.",
        "Selamat pagi.": "좋은 아침.",
        "Apa kabar?": "잘 지내?",
        "Lama tidak bertemu!": "오랜만이야!",
        "Senang bertemu denganmu": "반가워.",
        "Terima kasih": "감사해.",
        "Terima kasih.": "감사해.",
        "Terima kasih banyak": "정말 감사해.",
        "Maaf": "미안해.",
        "Maaf.": "미안해.",
        "Tidak apa-apa": "괜찮아.",
        "Tidak apa-apa.": "괜찮아.",
        "Aku cinta kamu": "사랑해.",
        "Aku cinta kamu.": "사랑해.",
        "Aku kangen kamu": "보고싶어.",
        "Aku kangen kamu.": "보고싶어.",
        "Aku suka kamu": "좋아해.",
        "Kamu yang terbaik!": "최고야!",
        "Bagus sekali!": "잘했어!",
        "Imut sekali": "귀여워.",
        "Aku bahagia": "행복해.",
        "Aku sedih": "슬퍼.",
        "Jangan khawatir": "걱정 마.",
        "Semangat!": "힘내!",
        "Selamat!": "축하해!",
        "Selamat ulang tahun!": "생일 축하해!",
        "Serius?": "진짜?",
        "Luar biasa!": "대박!",
        "Aku dukung kamu": "응원해.",
        "Jaga kesehatan ya": "건강 챙겨.",
        "Sampai jumpa": "잘 있어.",
        "Sampai nanti": "나중에 봐.",
    ]
}
