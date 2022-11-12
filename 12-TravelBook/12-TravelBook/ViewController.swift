//
//  ViewController.swift
//  12-TravelBook
//
//  Created by Berk Kaya on 7.11.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    
    //konum işlemlerinde kullanmak icin gerekli olan obje.
    var locationManager = CLLocationManager()
    var chosenLongitude = Double()
    var chosenLatitude = Double()
    
    //Secilen yer bos ise yeni yer ekleme algoritmasi calisacak, ici doluysa secilen yeri acacak
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //mapkiti cagirip delegate olarak belirtiyoruz tableview gibi.
        mapView.delegate = self
        locationManager.delegate = self
        //konumun verisinin ne kadar keskinlik ile tahmin edilecegini yaziyoruz. ne kadar iyi tahmin = o kadar pil kullanımı.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanici api kullanirken konumunu almak icin izin istiyoruz. Ve konumunu almaya başlıyoruz.
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        //uzun basinca gelisecek gesture olusturuyoruz
        //icine bir adet gesturerecognizer parametresi aliyor.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        //dokunma saniyesi
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            //Coredatadan cekme islemi yapacaz
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                            }
                            if let latitude = result.value(forKey: "latitude") as? Double {
                                annotationLatitude = latitude
                            }
                            if let longitude = result.value(forKey: "longitude") as? Double {
                                annotationLongitude = longitude
                                
                                let annotation = MKPointAnnotation()
                                annotation.title = annotationTitle
                                annotation.subtitle = annotationSubtitle
                                let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                annotation.coordinate = coordinate
                                mapView.addAnnotation(annotation)
                                nameText.text = annotationTitle
                                commentText.text = annotationSubtitle
                                
                                locationManager.stopUpdatingLocation()
                                
                                let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                let region = MKCoordinateRegion(center: coordinate, span: span )
                                mapView.setRegion(region, animated: true)
                            }
                        }
                    }
                }
                
            } catch {
                print("Error")
            }
           
        } else {
            
        }
    }
    
    //Update edilen konumlari aldiktan sonra ne yapacagimizi yazacagimiz fonksiyon. (array icerisinde veriyor)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            //Enlem boylam olarak aliyoruz (su anki konumumuzun)
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //zoomlanacak olan span. ne kadar kücültürsek o kadar zoomlar.
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
        
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        //aldigi parametre sayesinde o gesture islemi basladigi an dokunulan pointi ve konumunu olusturuyoruz.
        if(nameText.text != ""){
            if gestureRecognizer.state == .began {
                let touchedPoint = gestureRecognizer.location(in: self.mapView)
                let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                
                //Pin olusturmak.
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchedCoordinates
                annotation.title = nameText.text
                annotation.subtitle = commentText.text
                self.mapView.addAnnotation(annotation)
                
                //secili koordinatlari savebutonda kullanmak icin yukarda olusturdugumuz degiskenlere atiyoruz.
                self.chosenLatitude = touchedCoordinates.latitude
                self.chosenLongitude = touchedCoordinates.longitude
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Pin name cannot be empty", preferredStyle: UIAlertController.Style.alert)
            self.present(alert,animated: true)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
            alert.addAction(okButton)
        }
       
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
             
                
            }
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appdelegate.persistentContainer.viewContext
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Success")
            
        } catch{
                print("Error")
            }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
    
    }
    

}

