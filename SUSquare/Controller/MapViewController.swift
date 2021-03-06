//
//  MapViewController.swift
//  SUSquare
//
//  Created by Marcus Vinicius Kuquert on 01/10/16.
//  Copyright © 2016 AGES. All rights reserved.
//

import UIKit
import MapKit
import SVProgressHUD

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    private var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        User.sharedInstance.location = CLLocationCoordinate2D(latitude: 21.282778, longitude: -157.829444)
//        print(User.sharedInstance.location)
        locationManager.delegate = self
        addButton()
        loadUnits()
    }
    
    func loadUnits() {
        SVProgressHUD.show(withStatus: "Buscando estabelecimentos de saúde...")
        let coordinate: CLLocationCoordinate2D = (locationManager.location?.coordinate)!
        RestManager.requestHealthUnits(byLocation: coordinate, withRange: 10, withBlock: { (units: [HealthUnit]?, error: Error?) in
            if error == nil {
                for unit in units! {
                    let a = HealthUnitMapAnnotation(healthUnit: unit)
                    self.mapView.addAnnotation(a)
                }
                SVProgressHUD.dismiss()
            } else {
                print(error)
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            }
        })
    }
    
    func addButton() {
//        let locationButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
//        self.navigationItem.rightBarButtonItem = locationButtonItem
//        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        btn.titleLabel?.text = "Me acha"
//        btn.backgroundColor = .red
//        btn.setTitle("Me acha", for: .normal)
//        btn.addTarget(self, action: #selector(centerMap), for: UIControlEvents.touchUpInside)
//        self.view.addSubview(btn)
    }
    
    func centerMap() {
        if let location = locationManager.location {
            centerMapOnLocation(location: location)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    
    // MARK: MapView Helpers
    //location manager to authorize user location for Maps app
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 10000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

}
//MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? HealthUnitMapAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.image = UIImage(named: "pin-estabelecimento.jpg")
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            return view
        }
        return nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "healthUnitDetails"{
            let vcDetails = segue.destination as? HealthUnitDetailsViewController
            if let healthUnit = sender as? HealthUnit{
                vcDetails?.healthUnit = healthUnit
            } else {
                print(sender.customMirror.subjectType)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? HealthUnitMapAnnotation {
            if let hu = annotation.healthUnit {
                performSegue(withIdentifier: "healthUnitDetails", sender: hu)
            }
        }
    }
}

//MARK: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        User.sharedInstance.location = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: User.sharedInstance.location!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
    }
}
