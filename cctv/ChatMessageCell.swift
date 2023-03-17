import UIKit

class ChatMessageCell: BaseCollectionViewCell {


    
    enum ChatType: CaseIterable {
        case receive
        case send
    }

    struct Model {
        let message: String
        let chatType: ChatType
    }

    var model: Model? {
        didSet { bind() }
    }

    let messaageTextView: UITextView = {
        let view = UITextView()
        view.font = .systemFont(ofSize: 18.0)
        view.text = "Sample message"
        view.textColor = .black
        view.backgroundColor = .white
        view.layer.cornerRadius = 15.0
        view.layer.masksToBounds = false
        view.isEditable = false
        return view
    }()

    let profileImageView: UIImageView = {
        let Image = UIImage(named: "profile.png")
        var roundedProfileImage: UIImage? {
            return Image?.roundedImage()
        }
        let view = UIImageView(image: roundedProfileImage )
        view.layer.cornerRadius = view.bounds.width / 2
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()

    
    //view들을 세팅
    override func setupViews() {
        super.setupViews()

        contentView.addSubview(messaageTextView)
        messaageTextView.translatesAutoresizingMaskIntoConstraints = false
        messaageTextView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messaageTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        contentView.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
    }

    private func bind() {
        guard let model = model, let font = messaageTextView.font else {
            return
        }
        messaageTextView.text = model.message
        let estimatedFrame = model.message.getEstimatedFrame(with: font)

        messaageTextView.widthAnchor.constraint(equalToConstant: estimatedFrame.width + 16).isActive = true

        if case .send = model.chatType { //보내는 메세지 형태
            messaageTextView.backgroundColor = .systemBlue //파랑
            profileImageView.isHidden = true
            messaageTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        
            
        } else {//받는 메세지 형태
            messaageTextView.backgroundColor = .white //하양
            profileImageView.isHidden = false
            messaageTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16 + profileImageView.bounds.width).isActive = true
            
        }
    }
}

