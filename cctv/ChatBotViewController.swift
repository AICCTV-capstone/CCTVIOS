import UIKit
import CoreLocation
import Contacts

class ChatBotViewController: UIViewController{
    
    let geocoder = CLGeocoder()
    
    let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    let apiKey = "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"
    
    @IBOutlet weak var showLocation: UIButton!
    @IBOutlet weak var chatView: UIView!
    
    var lon:Double?
    var lat:Double?

    var coordinates: [(latitude: Double, longitude: Double)]?
    
    var query:String?
    var result: String?
    
    var chatViewController:ChatViewController?
    var pinLocationViewController:PinLocationViewController?
    
    var formattedAddress: String?

    @IBOutlet weak var busBtn: UIButton!
    @IBOutlet weak var convBtn: UIButton!
    @IBOutlet weak var cafeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLocation.layer.cornerRadius = 10 // 조정할 둥글기 정도를 지정합니다
        showLocation.clipsToBounds = true // 버튼 내부의 콘텐츠가 모서리를 넘어가지 않도록 설정합니다
        
        
        convBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)
        busBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)
        cafeBtn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)
        showLocation.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchDown)
        
        changeLonLat()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
       
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chat" {
            chatViewController = segue.destination as! ChatViewController
        }
        if segue.identifier == "map" {
            pinLocationViewController = segue.destination as! PinLocationViewController
            pinLocationViewController?.coordinates = coordinates ?? []
        }
    }

    


    
    @IBAction func queryConvenientStore(_ sender: UIButton) {
        
        query!+=" 편의점 3개 알려줄래?"
        Mock.messages.append(query!)
        chatViewController!.reloadData()
        queryChatGpt()
        chatViewController!.reloadData()
        query = "\(formattedAddress!)에서 가까운"
    }

    
    @IBAction func queryBusStation(_ sender: UIButton) {
        
        query!+=" 버스정류장 3개 알려줄래?"
        Mock.messages.append(query!)
        chatViewController!.reloadData()
        queryChatGpt()
        chatViewController!.reloadData()
        query = "\(formattedAddress!)에서 가까운"
        
        
    }
    
    
    @IBAction func queryCafe(_ sender: UIButton) {
        
        query!+=" 카페 3개 알려줄래?"
        Mock.messages.append(query!)
        chatViewController!.reloadData()
        queryChatGpt()
        chatViewController!.reloadData()
        query = "\(formattedAddress!)에서 가까운"
    }
    
    
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
    
    
    func queryChatGpt() {
        // 1. URLRequest 생성
        guard let url = URL(string: apiEndpoint) else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 2. HTTPBody 설정
        let parameters = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "user", "content": "\(query!) 위도 경도 포함해서"]
            ]
        ] as [String: Any]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        urlRequest.httpBody = httpBody
        
        // 3. URLSession 객체를 이용한 HTTP 요청 및 응답 처리
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid Response")
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let text = choices.first?["message"] as? [String: Any],
                  let content = text["content"] as? String else {
                print("Invalid Data")
                return
            }
            
            self.result = content
            self.coordinates = self.extractCoordinates(from: self.result!)

            Mock.messages.append(self.result!)
            
            DispatchQueue.main.async {
                self.chatViewController?.reloadData()
               
            }
        }
        
        task.resume()
    }



}


//위도경도<->주소 변환관련
extension ChatBotViewController {
    func changeLonLat() {
        let latitude = lat
        let longitude = lon
        // Geocode 요청
        let location = CLLocation(latitude: lat!, longitude: lon!)
        geocoder.reverseGeocodeLocation(location) { [self] (placemarks, error) in
            if let error = error {
                print("Geocode Error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("Invalid Placemark Data")
                return
            }
            
            // 주소 포맷 가공
            if #available(iOS 11.0, *) {
                if let address = placemark.postalAddress {
                    formattedAddress = self.formatAddress(address)
                    query = "\(formattedAddress!)에서 가까운"
                   // print("Address: \(formattedAddress!)")
                } else {
                    print("Postal address not available")
                }
            } else {
                print("Postal address not available")
            }
        }
    }
    
    // 주소 포맷 가공
    func formatAddress(_ address: CNPostalAddress) -> String {
        var components: [String] = []


        if !address.city.isEmpty { //시
            components.append(address.city)
            print("\(address.city)")
        }
        if !address.subLocality.isEmpty { //동
            components.append(address.subLocality)
            print("\(address.subLocality)")
        }
        if !address.street.isEmpty {//도로명
            components.append(address.street)
            print("\(address.street)")
        }
        
        return components.joined(separator: " ")
    }
    
    func extractCoordinates(from string: String) -> [(latitude: Double, longitude: Double)] {
        var coordinates: [(latitude: Double, longitude: Double)] = []
        
        let locationStrings = string.components(separatedBy: "\n\n")
        
        for locationString in locationStrings {
            let components = locationString.components(separatedBy: "\n")
            
            var latitude: Double?
            var longitude: Double?
            
            for component in components {
                if component.contains("위도:") {
                    if let latitudeString = component.split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                       let latitudeValue = Double(latitudeString) {
                        latitude = latitudeValue
                    }
                } else if component.contains("경도:") {
                    if let longitudeString = component.split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                       let longitudeValue = Double(longitudeString) {
                        longitude = longitudeValue
                    }
                }
            }
            
            if let latitude = latitude, let longitude = longitude {
                let coordinate = (latitude, longitude)
                coordinates.append(coordinate)
            }
        }
        
        return coordinates
    }
    
}
extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
