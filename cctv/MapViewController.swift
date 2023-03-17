//  Created by 김도은 on 2023/04/07.

import UIKit
import MapKit
import CoreLocation



class MapViewController: UIViewController{
    
    var imageView:UIImageView?
    var annotation:MKPointAnnotation!
    let originalCCTVImage = UIImage(named: "CCTV.png")
    var roundedCCTVImage: UIImage? {
        return originalCCTVImage?.roundedImage()
    }
    let originalRedCCTVImage = UIImage(named: "redCCTV.png")
    var roundedRedCCTVImage: UIImage? {
        return originalRedCCTVImage?.roundedImage()
    }
    let chatImage = UIImage(named: "ChatBot.png")
    var roundedchatImage: UIImage? {
        return chatImage?.roundedImage()
    }
    
    var locationManager: CLLocationManager = CLLocationManager() // location manager
    var currentLocation: CLLocation! // 내 위치 저장
    
    var mqttClient: MqttClient!
    var locations = [[37.5822338,127.0099677],[37.5814749,127.0100350],[37.5830056,127.0106048],[37.5819364,127.0118407]]
    var names=["연구관","상상빌리지","우촌관","한성여중"]
    var nameDict=["연구관":0,"상상빌리지":1,"우촌관":2,"한성여중":3]
    var annotationViews: [CustomAnnotationView?] = [nil,nil,nil,nil]
    var annotationViews2: [CustomAnnotationView?] = [] //viewfor 에서 받아서 append할 배열
    var annotationViews3: [CustomAnnotationView?] = [nil,nil,nil,nil] //annotationViews2를 locations따라 재정렬할 배열
    
    var selectedCCTV:Int?
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var myBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    
    var latitude:Double = 0.0
    var longitude:Double = 0.0
    
    var btnCount:Int = 0
    var region: MKCoordinateRegion? //cctv 중간 위치
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBestForNavigation //정확도를 최고로 설정
        locationManager.requestWhenInUseAuthorization()//사용자에게 위치정보 승인 요청
        locationManager.startUpdatingLocation()//위치 업데이트 시작
        locationManager.startMonitoringSignificantLocationChanges()

        
        myMap.delegate=self
        
        var sumLongitude: Double = 0.0
        var sumLatitude: Double = 0.0

        for location in locations {
            sumLongitude += location[1]
            sumLatitude += location[0]
        }
        let averageLongitude = sumLongitude / Double(locations.count)
        let averageLatitude = sumLatitude / Double(locations.count)
        
        let initialLocation = CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude) // 원하는 위치의 위도(latitude)와 경도(longitude)로 좌표 설정
        let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)// 지도의 초기 위치에서 보여줄 범위 설정
        region = MKCoordinateRegion(center: initialLocation, span: span)// 초기 지도 영역 설정

        // 설정된 영역으로 지도 이동
        myMap.setRegion(region!, animated: true)
        
        
        myBtn.layer.cornerRadius =  myBtn.frame.height / 2
        myBtn.clipsToBounds = true
        myBtn.setTitle("", for: .normal)
        myBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)

    
        chatBtn.translatesAutoresizingMaskIntoConstraints = false
        chatBtn.layer.cornerRadius = chatBtn.frame.height / 2
        chatBtn.clipsToBounds = true
        chatBtn.setImage(roundedchatImage, for: .normal)
        chatBtn.setTitle("", for: .normal)
        chatBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)

        view.addSubview(chatBtn)
        
        NSLayoutConstraint.activate([
            chatBtn.widthAnchor.constraint(equalToConstant: 65),
            chatBtn.heightAnchor.constraint(equalToConstant: 65),
            chatBtn.leadingAnchor.constraint(equalTo:view.leadingAnchor , constant: 50),
            chatBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])

        for i in 0..<locations.count { //cctv 설정
            let location = locations[i]
            let pinLocation = CLLocationCoordinate2D(latitude: location[0], longitude: location[1])
            let annotation = CustomAnnotation(coordinate: pinLocation, title: names[i], subtitle: "", customProperty: "")
            
            myMap.addAnnotation(annotation)
            
        }

    }
   

    
    override func viewDidAppear(_ animated: Bool) {//view가 화면에 나타난 후
        super.viewDidAppear(animated)
        
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
                let alert = UIAlertController(title: "오류 발생", message: "위치 서비스 기능이 꺼져있음", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
            }
        } else {
            let alert = UIAlertController(title: "오류 발생", message: "위치 서비스 제공 불가", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
        connectMqtt()
    }

}


extension MapViewController{ //채팅관련
    @IBAction func chatBtn(_ sender: UIButton) {
        performSegue(withIdentifier: "GotoChat", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GotoChat" {
            let chatBotViewController = segue.destination as! ChatBotViewController
            chatBotViewController.lat=latitude
            chatBotViewController.lon=longitude
        }
    }
}

extension MapViewController: CLLocationManagerDelegate{//지도 맵 관련
    
    @IBAction func setMyLocation(_ sender: UIButton) {
        
        if btnCount == 0{//현재위치로 돌아온다
            self.myMap.showsUserLocation = true
            self.myMap.setUserTrackingMode(.follow, animated: true)
            btnCount+=1
        }
        else{
            myMap.setRegion(region!, animated: true) //처음위치로 돌아간다
            btnCount=0
        }

        
    }
    
   // MARK : 위치 허용 선택했을 때 처리
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined :
            manager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            self.firstSetting()
            break
        case .authorizedAlways:
            self.firstSetting()
            break
        case .restricted :
            break
        case .denied :
            break
        default:
            break
        }

    }
    func firstSetting(){

        self.currentLocation = locationManager.location

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager = manager
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            currentLocation = locationManager.location
            //현재위치의 위도와 경도
            latitude = currentLocation.coordinate.latitude
            longitude = currentLocation.coordinate.longitude
            
        }
    }
    
}

extension   MapViewController{ //  mqtt 관련
    
    func connectMqtt(){
        let ipAddress = "43.201.14.40"
        if let mqttClient = mqttClient{ //이미 연결되어있으면
            mqttClient.disconnect()
        }
        
        mqttClient = MqttClient(brokerAdress: ipAddress)
        mqttClient.onMessage(completion: onMessage)
        
        _ = mqttClient.connect(){
            //이미지
            self.mqttClient.subscribe(topic: "cmlee")//이미지 names[0]
            self.mqttClient.subscribe(topic: "jmlee")//이미지 names[1]
            self.mqttClient.subscribe(topic: "kmlee")//이미지 names[2]
            self.mqttClient.subscribe(topic: "gmlee")//이미지 names[3]
        
            //문자열
            self.mqttClient.subscribe(topic: "cmlee1")
            self.mqttClient.subscribe(topic: "jmlee1")
            self.mqttClient.subscribe(topic: "kmlee1")
            self.mqttClient.subscribe(topic: "gmlee1")

        }
    }
    
    func onMessage(topic: String, payload: [UInt8]){
        
        let raw = Data(bytes: payload, count: payload.count)
        let data = Data(base64Encoded: raw)
        
        //print("onMessage")
        
        if topic=="cmlee"{//연구관
            
            if let image = UIImage(data: data!) {
                let resizedImage = image.resized(to: CGSize(width: 160, height: 120))
                if let annotationView = annotationViews[0]{
                    annotationView.image = resizedImage
                }
                if let selected = selectedCCTV{
                    if selected == 0{
                        if let imageView = imageView{
                            imageView.image = image
                        }
                    }
                }
            }
        }
        else if topic=="jmlee"{ //상상빌리지
            print("jmlee")
            if let image = UIImage(data: data!) {
                let resizedImage = image.resized(to: CGSize(width: 160, height: 120))
                if let annotationView = annotationViews[1]{
                    annotationView.image = resizedImage
                }
                if let selected = selectedCCTV{
                    if selected == 1{
                        if let imageView = imageView{
                            imageView.image = image
                        }
                    }
                }

            }
        }
        else if topic=="kmlee"{//우촌관
            if let image = UIImage(data: data!) {
                //print("kmlee")
                let resizedImage = image.resized(to: CGSize(width: 160, height: 120))
                if let annotationView = annotationViews[2]{
                    annotationView.image = resizedImage
                }
                if let selected = selectedCCTV{
                    if selected == 2{
                        if let imageView = imageView{
                            imageView.image = image
                        }
                    }
                }

            }
        }
        else if topic=="gmlee"{//한성여중
            if let image = UIImage(data: data!) {
                //print("gmlee")
                let resizedImage = image.resized(to: CGSize(width: 160, height: 120))
                if let annotationView = annotationViews[3]{
                    annotationView.image = resizedImage
                }
                if let selected = selectedCCTV{
                    if selected == 3{
                        if let imageView = imageView{
                            imageView.image = image
                        }
                    }
                }

            }
        }
        else if topic=="cmlee1"{//연구관
            print("cmlee1")
            if let string = String(data: raw, encoding: .utf8) {
                let cmlee_count=Int(string)
                if(cmlee_count!>=4){
                    print("cmlee1사람수:\(string)")
                    if annotationViews[0] == nil{//어노테이션이 안눌린상태
                        annotationViews3[0]?.image=roundedRedCCTVImage
                    }
                }
                else{
                    if annotationViews[0] == nil{//어노테이션이 안눌린상태
                        annotationViews3[0]?.image=roundedCCTVImage
                    }
                }
            }
        }
        else if topic=="jmlee1"{//상상빌리지
            if let string = String(data: raw, encoding: .utf8) {

                //print("222222222\(annotationViews3[1]!)")
                let jmlee_count=Int(string)
                if jmlee_count!>=4{
                    print("jmlee1사람수:\(string)")
                    if annotationViews[1] == nil{
                        annotationViews3[1]?.image=roundedRedCCTVImage
                    }
                }
                else{
                    if annotationViews[1] == nil{
                        annotationViews3[1]?.image=roundedCCTVImage
                    }
                }
            }
        }
        else if topic=="kmlee1"{//우촌관
            if let string = String(data: raw, encoding: .utf8) {

                let kmlee_count=Int(string)
                if(kmlee_count! >= 4){
                    print("kmlee1사람수:\(string)")
                    if annotationViews[2] == nil{
                        annotationViews3[2]?.image=roundedRedCCTVImage
                        
                    }
                }
                else{
                    if annotationViews[2] == nil{
                        annotationViews3[2]?.image=roundedCCTVImage
                        
                    }
                }
            }
        }
        else if topic=="gmlee1"{//한성여중
            if let string = String(data: raw, encoding: .utf8) {

                let gmlee_count=Int(string)
                if(gmlee_count!>=4){
                    print("gmlee1사람수:\(string)")
                    if annotationViews[3] == nil{
                        annotationViews3[3]?.image=roundedRedCCTVImage
                        
                    }
                }
                else{
                    if annotationViews[3] == nil{
                        annotationViews3[3]?.image=roundedCCTVImage
                        
                    }
                }
            }
        }
       
    }
 
}




extension MapViewController: MKMapViewDelegate{ //mapView 관련
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let customAnnotation = annotation as? CustomAnnotation else {
            
            return nil
        }
        print("viewFor=\(customAnnotation.title)")
        
        var index: Int? = nameDict[customAnnotation.title!]

        let reuseIdentifier = "jmlee"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? CustomAnnotationView
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(annotation: customAnnotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = false
            annotationView?.detailCalloutAccessoryView = nil
            
            annotationView?.image = roundedCCTVImage
        } else {
            annotationView?.annotation = customAnnotation
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            annotationView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                annotationView?.transform = .identity
            }
        })
        
        annotationViews2.append(annotationView)
        if let index = index{
            annotationViews3[index] = annotationView
        }
        
        return annotationView
    }
    

    
    func mapView(_ mapView: MKMapView, didSelect selectedView: MKAnnotationView) {
        print("annotation didSelect")
        
        guard let customAnnotationView = selectedView as? CustomAnnotationView,
            let annotation = customAnnotationView.annotation as? CustomAnnotation,
            let selectedViewTitle = annotation.title else { //현재 선택된 어노테이션의 타이틀 저장
                return
        }
        
        if var cctvIndex = names.firstIndex(of: selectedViewTitle) { //selectedViewTitle과 일치하는 (처음발견한)인덱스
            if annotationViews[cctvIndex] == nil { // 어노테이션이 아직 안눌렸을때 누르면
                annotationViews[cctvIndex] = customAnnotationView
                //selectedCCTV = cctvIndex //imageView 에 띄울 index 설정
                addLongPressGesture(to: customAnnotationView, index: cctvIndex)
                
            }
            else { // 어노테이션이 눌린 상태에서 누르면 (CCTV 송출 중)
                annotationViews[cctvIndex] = nil
                //selectedCCTV = nil //imageView 에 띄울 index 초기화
                //cctvIndex = 0
                customAnnotationView.image = roundedCCTVImage // 원래 CCTV 아이콘으로 돌아감
                
            }
        }
        
        mapView.deselectAnnotation(selectedView.annotation, animated: true) // 어노테이션 선택 해제
    }
    

}
extension MapViewController{//long press 관련
    func addLongPressGesture(to view: CustomAnnotationView, index: Int) {
        print("addLongPressGesture")
        let longPressGesture = DoeunLongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.2
        longPressGesture.pressedIndex = index
        view.addGestureRecognizer(longPressGesture)
    }

    func removeLongPressGesture(from view: CustomAnnotationView) {
        if let gestureRecognizers = view.gestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                if let longPressGesture = gestureRecognizer as? UILongPressGestureRecognizer {
                    view.removeGestureRecognizer(longPressGesture)
                }
            }
        }
    }

    @objc func handleLongPress(_ gestureRecognizer: DoeunLongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {

            let imageViewerViewController = ImageViewerViewController() // 표시할 이미지 뷰 컨트롤러 인스턴스 생성
            imageViewerViewController.mapViewController = self
            
            selectedCCTV = gestureRecognizer.pressedIndex
            // 필요에 따라 imageViewController의 속성 설정
            imageViewerViewController.view.backgroundColor = UIColor.black
            // 이미지 생성 및 설정
            imageView = UIImageView()
            imageView?.contentMode = .scaleAspectFit
            imageView?.frame = imageViewerViewController.view.bounds
            imageView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageViewerViewController.view.addSubview(imageView!)
            imageViewerViewController.mqtt = mqttClient
        
            navigationController?.pushViewController(imageViewerViewController, animated: true)
        }
    }
}

extension UIImage {  //아이콘 이미지를 동그랗게 하기위함
    func roundedImage() -> UIImage? {
        let imageWidth = size.width * scale
        let imageHeight = size.height * scale
        let radius = min(imageWidth, imageHeight) / 2.0
        let rect = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        context?.beginPath()
        context?.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2.0, clockwise: true)
        context?.closePath()
        context?.clip()
        draw(in: rect)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return output
    }
    func resized(to size:CGSize) -> UIImage{
        return UIGraphicsImageRenderer(size: size).image{_ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
}

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var customProperty: String // 추가적인 속성
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, customProperty: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.customProperty = customProperty
    }
}

class CustomAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension MapViewController{
    //버튼 애니메이션(탭하면 약간커진다)
    @objc private func buttonTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        })
    }
    
}

