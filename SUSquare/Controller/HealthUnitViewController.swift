//
//  HealthUnitViewController.swift
//  SUSquare
//
//  Created by Luis Filipe Campani on 01/10/16.
//  Copyright © 2016 AGES. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SVProgressHUD

class HealthUnitViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var searchBar : CustomSearchBar?
    
    var shouldShowSearchResults : Bool = false
    var healthUnits = [HealthUnit]()
    
    var filteredHealthUnits = [HealthUnit]()
    
    var locationManager : CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        loadUnits()
        if let location = locationManager.location{
            SVProgressHUD.show(withStatus: "Loading HealthUnits")
            let coordinate : CLLocationCoordinate2D = location.coordinate
            User.sharedInstance.location = coordinate
            RestManager.sharedInstance.requestHealthUnits(byLocation: coordinate, withRange: 10, withBlock: { (units: [HealthUnit]?, error: Error?) in
                if error == nil {
                    for unit in units! {
                        if let _ = unit.unitName {
                            self.healthUnits.append(unit)
                            self.tableView.reloadData()
                        }
                    }
                    SVProgressHUD.dismiss()
                } else {
                    print(error)
                    SVProgressHUD.showError(withStatus: error?.localizedDescription)
                }
            })
        }
        locationManager.stopUpdatingLocation()
        
        
        self.configureSearchBar(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50), font: UIFont(name: "Verdana", size: 16.0)!, textColor: UIColor.white, bgColor: UIColor(red: 71, green: 186, blue: 251))
        
        tableView.tableHeaderView = self.searchBar
        self.searchBar?.delegate = self
        // Do any additional setup after loading the view.
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        checkLocationAuthorizationStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadUnits() {
        SVProgressHUD.show(withStatus: "Loading HealthUnits")
        let coordinate: CLLocationCoordinate2D = (locationManager.location?.coordinate)!
        RestManager.sharedInstance.requestHealthUnits(byLocation: coordinate, withRange: 10, withBlock: { (units: [HealthUnit]?, error: Error?) in
            if error == nil {
                for unit in units! {
                    let a = HealthUnitMapAnnotation(healthUnit: unit)
                    self.mapView.addAnnotation(a)
                    self.healthUnits.append(unit)
                    //self.tableView.reloadData()
                }
                SVProgressHUD.dismiss()
            } else {
                print(error)
                SVProgressHUD.showError(withStatus: error?.localizedDescription)
            }
        })
        centerMap()
    }
    
    func centerMap() {
        if let location = locationManager.location {
            centerMapOnLocation(location: location)
        }
    }
    
    //MARK: SearchBar
    func configureSearchBar(frame: CGRect, font: UIFont, textColor: UIColor, bgColor: UIColor) {
        searchBar = CustomSearchBar(frame: frame, font: font , textColor: textColor)
        
        searchBar?.barTintColor = bgColor
        searchBar?.tintColor = textColor
        searchBar?.showsBookmarkButton = false
        searchBar?.showsCancelButton = true
//        searchBar?.setImage(UIImage(named: "StarFlat"), for: .search, state: .normal)
        
        searchBar?.placeholder = "Buscar Posto de Saúde"
        searchBar?.setScopeBarButtonBackgroundImage(UIImage(named: "StarFlat"), for: .normal)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterHealthUnitsForSearchText(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.filterHealthUnitsForSearchText("")
        shouldShowSearchResults = false
        self.view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !shouldShowSearchResults {
            shouldShowSearchResults = true
            tableView.reloadData()
        }
        
        searchBar.resignFirstResponder()
    }
    
    func filterHealthUnitsForSearchText(_ searchText: String, scope: String = "All") {
        self.filteredHealthUnits = healthUnits.filter { healthUnits in
            print(healthUnits.unitName?.lowercased())
            print(searchText.lowercased())
            return (healthUnits.unitName?.lowercased().contains(searchText.lowercased()))!
        }
        
        if self.filteredHealthUnits.isEmpty {
            shouldShowSearchResults = false
        }
        
        print(filteredHealthUnits)
        
        self.tableView.reloadData()
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
    
    func calcDistanceToHealthUnit(healthUnitLocation : CLLocationCoordinate2D) -> String {
        let userLocation = CLLocation(latitude: (User.sharedInstance.location?.latitude)!, longitude: (User.sharedInstance.location?.longitude)!)
        let unitLocation = CLLocation(latitude: healthUnitLocation.latitude, longitude: healthUnitLocation.longitude)
        
        let distanceInMeters = Int((userLocation.distance(from: unitLocation)))
        
        let distanceInKilometers = distanceInMeters/1000
        
        print("IN M: \(distanceInMeters) ----- IN KM:\(distanceInKilometers)")
        
        
        return "\(distanceInKilometers)km"
    }
}

extension HealthUnitViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "healthUnitDetails", sender: healthUnits[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension HealthUnitViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowSearchResults{
            return filteredHealthUnits.count
        } else {
            return healthUnits.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "healthUnitIdentifier", for: indexPath) as! HealthUnitTableViewCell
        
        let healthUnit : HealthUnit
        
        if shouldShowSearchResults{
            healthUnit = filteredHealthUnits[indexPath.row]
        }else {
            healthUnit = healthUnits[indexPath.row]
        }
        cell.lblDistance.text = self.calcDistanceToHealthUnit(healthUnitLocation: healthUnit.location!)
        cell.lblHealthUnit.text = healthUnit.unitName
        
        return cell
    }
}

//MARK: MKMapViewDelegate
extension HealthUnitViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? HealthUnitMapAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? HealthUnitMapAnnotation {
            if let hu = annotation.healthUnit {
                performSegue(withIdentifier: "healthUnitDetails", sender: hu)
            }
        }
    }
}

//MARK: CLLocationManagerDelegate
extension HealthUnitViewController: CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let location = locations.last as! CLLocation
        
        User.sharedInstance.location = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: User.sharedInstance.location!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
    }
}

extension HealthUnitViewController : UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController){
        filterHealthUnitsForSearchText(searchController.searchBar.text!)
    }
}
