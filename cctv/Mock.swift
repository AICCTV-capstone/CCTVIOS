import Foundation

class Mock {
    
    static var messages=[String]()
    static func getMockMessages() -> [(message: String, chatType: ChatMessageCell.ChatType)] {
        return messages.map { (message) in
            if message.contains("알려줄래?") {
                return (message, .send)
            } else {
                return (message, .receive)
            }
        }
    }
}

