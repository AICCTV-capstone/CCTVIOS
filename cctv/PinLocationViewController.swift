import UIKit
import MapKit

class PinLocationViewController: UIViewController {
    var coordinates: [(latitude: Double, longitude: Double)] = []
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if coordinates.isEmpty {
            // Display a default map region when coordinates array is empty
            let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0) // Set default coordinate values as desired
            let coordinateRegion = MKCoordinateRegion(center: defaultCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000) // Adjust the region size as desired
            mapView.setRegion(coordinateRegion, animated: true)
        } else {
            // Calculate average coordinates
            let totalLatitude = coordinates.reduce(0) { $0 + $1.latitude }
            let totalLongitude = coordinates.reduce(0) { $0 + $1.longitude }
            let averageLatitude = totalLatitude / Double(coordinates.count)
            let averageLongitude = totalLongitude / Double(coordinates.count)
            let averageCoordinate = CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude)
            
            // Set initial map region
            let regionRadius: CLLocationDistance = 1000 // Adjust the zoom level as desired
            let coordinateRegion = MKCoordinateRegion(center: averageCoordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
            
            // Add annotations
            for coordinate in coordinates {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                mapView.addAnnotation(annotation)
            }
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            // "Back" button is pressed
            if let navigationController = self.navigationController {
                // Pop to chatViewController
                for viewController in navigationController.viewControllers {
                    if let chatViewController = viewController as? ChatViewController {
                        navigationController.popToViewController(chatViewController, animated: true)
                        break
                    }
                }
            }
        }
    }
}
