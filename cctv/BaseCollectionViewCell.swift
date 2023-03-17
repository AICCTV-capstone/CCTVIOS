//
//  BaseCollectionViewCell.swift
//  cctv
//
//  Created by 김도은 on 2023/05/10.
//

import UIKit

class BaseCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
            super.init(frame: frame)
            setupViews()
        }

        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupViews() {}
    
}

