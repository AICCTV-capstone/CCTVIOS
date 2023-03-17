//
//  ChatViewController.swift
//  cctv
//
//  Created by 김도은 on 2023/05/08.
//

import UIKit

class ChatViewController: UIViewController {
    
    
        var messages: [(message: String, chatType: ChatMessageCell.ChatType)] = []
    

        lazy var collectionView: UICollectionView = {
            //레이아웃
            let layout = UICollectionViewFlowLayout()
            layout.minimumLineSpacing = 16.0
            //레이아웃을 적용할 뷰
            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            view.register(ChatMessageCell.self, forCellWithReuseIdentifier: "cell")
            view.delegate = self
            view.dataSource = self
            view.backgroundColor = .lightGray
            return view
        }()

        override func viewDidLoad() {
            //print("jj")
            super.viewDidLoad()
            
            
            messages = Mock.getMockMessages()//메세지 배열가져옴
            print(messages.count)
            print("*****\(view.subviews.count)")
            addSubviews()
            makeConstraints()
            
        }
        
    
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

        }
    
        override func viewDidDisappear(_ animated: Bool) {
            collectionView.removeFromSuperview()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            //collectionView.reloadData()
        }
    

    
    
        private func addSubviews() {
            view.addSubview(collectionView)
        }

        private func makeConstraints() {
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        }
        func reloadData() {
            // do something to reload data in ChatViewController
            messages = Mock.getMockMessages()//메세지 배열가져옴

            collectionView.reloadData()
            collectionView.selectItem(at: IndexPath(row: messages.count-1, section: 0), animated: true, scrollPosition: .bottom)
        }


    

}
extension ChatViewController:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    //메세지 창 개수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            print("+++++\(messages.count)")
            return messages.count
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("-------\(indexPath.row)")
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChatMessageCell //ChatMessgerCell에사 cell 가져오기
            let message = messages[indexPath.row]
            cell.model = .init(message: message.message, chatType: message.chatType)//셀에 데이터 설정(메세지내용,채팅타입) //cell에 mock에 있는 messages배열  내용을 행으로 각각 넣어준다
        
            return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let estimatedFrame = messages[indexPath.row].message.getEstimatedFrame(with: .systemFont(ofSize: 18))
            return CGSize(width: view.bounds.width, height: estimatedFrame.height + 20)
    }
}

