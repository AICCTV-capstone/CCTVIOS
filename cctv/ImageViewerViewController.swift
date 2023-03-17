//
//  ImageViewerViewController.swift
//  cctv
//
//  Created by 김도은 on 2023/05/17.
//

import UIKit


class ImageViewerViewController: UIViewController {

    var mapViewController: MapViewController?
    var image: UIImage?
    var imageView: UIImageView?
    var mqtt:MqttClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //mqtt!.subscribe(topic: "jmlee")
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //mapViewController?.selectedCCTV=nil
    }
    

}



