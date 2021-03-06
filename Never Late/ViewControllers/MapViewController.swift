//
//  MapView.swift
//  Never Late
//
//  Created by parker amundsen on 8/3/19.
//  Copyright © 2019 Parker Buhler Amundsen. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    deinit {
        print("Memory was released in mapkit. No retain cycles")
    }
    
    // MARK: Properties --------------------------------------------------------------------------------
    
    var sendEvent : ((MKPlacemark, CLLocationCoordinate2D?) -> Void)?
    // An array of localSearchCompletion to populate searchSuggestion
    var results : [MKLocalSearchCompletion]? = nil
    
    var response : [MKMapItem]? = nil
    
    let locationManager = CLLocationManager()
    
    var startingLocation: CLLocationCoordinate2D?
    
    var destinationLocation: MKPlacemark?
    
    private var isUpdatingDestination: Bool?
    
    private var destinationSearchBarYConstraint : NSLayoutConstraint?
    
    private var startingAnnotation: MapViewAnnotation?
    
    let toggleLabel: UILabel = {
        let label = UILabel()
        label.text = "Leave From Here"
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let startingLocationToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = Constants.secondaryColor
        toggle.setOn(true, animated: true)
        toggle.addTarget(self, action: #selector(changeStartingLocation), for: .valueChanged)
        
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    // Only visible if startingLocationToggle is toggled
    let startingLocationSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Starting Location"
        searchBar.layer.cornerRadius = 10
        searchBar.backgroundColor = .clear
        searchBar.searchBarStyle = UISearchBar.Style(rawValue: 2)!
        searchBar.isHidden = true
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    
    // Used to search for the destination location
    let destinationSearchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Destination"
        searchBar.layer.cornerRadius = 10
        searchBar.backgroundColor = .clear
        searchBar.searchBarStyle = UISearchBar.Style(rawValue: 2)!
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    let backButton: UIButton = {
        let backButton = UIButton();
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.adjustsFontSizeToFitWidth = true
        backButton.layer.cornerRadius = 10
        backButton.backgroundColor = Constants.secondaryColor
        backButton.addTarget(self, action: #selector(onBackButton), for: .touchUpInside)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        return backButton;
    }()
    
    
    
    // TableView to give the user suggestions based on the text typed in the searchBar
    let searchSuggestion: UITableView = {
        let searchResults = UITableView()
        searchResults.isHidden = true
        searchResults.layer.opacity = 0.8
        searchResults.layer.cornerRadius = 5
        searchResults.backgroundColor = .clear
        searchResults.register(UITableViewCell.self, forCellReuseIdentifier: Constants.mapVCCellIdentifier)
        
        searchResults.translatesAutoresizingMaskIntoConstraints = false
        return searchResults
    }()
    
    // searchCompleter populates the results array with suggested
    // locations based on the text inputted by the user
    let searchCompleter : MKLocalSearchCompleter =  {
        let completer = MKLocalSearchCompleter()
        
        return completer
    }()
    
    let map: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        return map
    }()
    
    let doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont(name: "Copperplate-Bold", size: 25)!
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(onDoneButton), for: .touchUpInside)
        button.backgroundColor = Constants.secondaryColor
        button.isHidden = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: LifeCycle --------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubviews()
        setUpDelegates()
        setUpUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkLocationServices()
    }
    
    private func addSubviews() {
        view.addSubview(map)
        view.addSubview(startingLocationToggle)
        view.addSubview(toggleLabel)
        view.addSubview(backButton)
        view.addSubview(startingLocationSearchBar)
        view.addSubview(destinationSearchBar)
        view.addSubview(searchSuggestion)
        view.addSubview(doneButton)
    }
    
    private func setUpDelegates() {
        startingLocationSearchBar.delegate = self
        destinationSearchBar.delegate = self
        map.delegate = self
        searchSuggestion.dataSource = self
        searchSuggestion.delegate = self
    }
    
    func setUpUI() {
        map.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        map.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        map.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        map.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        startingLocationToggle.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 20).isActive = true
        startingLocationToggle.leadingAnchor.constraint(equalTo: backButton.leadingAnchor).isActive = true
        
        toggleLabel.widthAnchor.constraint(equalToConstant: startingLocationToggle.frame.width*1.2).isActive = true
        toggleLabel.centerXAnchor.constraint(equalTo: startingLocationToggle.centerXAnchor).isActive  = true
        toggleLabel.topAnchor.constraint(equalTo: startingLocationToggle.bottomAnchor).isActive = true
        
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height/10).isActive = true
        backButton.contentEdgeInsets.left = 5
        backButton.contentEdgeInsets.right = 5
        backButton.contentEdgeInsets.top = 5
        backButton.contentEdgeInsets.bottom = 5
        
        destinationSearchBarYConstraint = destinationSearchBar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        destinationSearchBarYConstraint?.isActive = true
        destinationSearchBar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 10).isActive = true
        destinationSearchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
        searchSuggestion.centerXAnchor.constraint(equalTo: destinationSearchBar.centerXAnchor).isActive = true
        searchSuggestion.topAnchor.constraint(equalTo: destinationSearchBar.bottomAnchor).isActive = true
        searchSuggestion.heightAnchor.constraint(equalToConstant: view.frame.height/4).isActive = true
        searchSuggestion.widthAnchor.constraint(equalTo: destinationSearchBar.widthAnchor).isActive = true
        searchSuggestion.rowHeight = view.frame.height/10
    }
    
    
    // MARK: Actions --------------------------------------------------------------------------------
    @objc private func onBackButton() {
        self.navigationController?.popViewController(animated: true)
        locationManager.stopUpdatingLocation()
    }
    
    @objc private func changeStartingLocation() {
        if (!startingLocationToggle.isOn) {
            startingLocationSearchBar.isHidden = false
            startingLocationSearchBar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor).isActive = true
            startingLocationSearchBar.leadingAnchor.constraint(equalTo: destinationSearchBar.leadingAnchor).isActive = true
            startingLocationSearchBar.trailingAnchor.constraint(equalTo: destinationSearchBar.trailingAnchor).isActive = true
            
            destinationSearchBarYConstraint?.isActive = false
            destinationSearchBarYConstraint = destinationSearchBar.centerYAnchor.constraint(equalTo: startingLocationToggle.centerYAnchor)
            destinationSearchBarYConstraint?.isActive = true
        }
        else {
            destinationSearchBarYConstraint?.isActive = false
            destinationSearchBarYConstraint = destinationSearchBar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
            destinationSearchBarYConstraint?.isActive = true
            startingLocationSearchBar.isHidden = true
            startingLocation = nil
        }
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func doneButtonAnimation() {
        doneButton.isHidden = false
        doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.frame.height/20).isActive = true
        doneButton.widthAnchor.constraint(equalToConstant: view.frame.width*0.8).isActive = true
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func presentDestinationNotSetMessage() {
        let invalidAddress = UIAlertController(title: "Destination Location Not Set", message: "Set a destination to include a location in your event.", preferredStyle: .alert)
        invalidAddress.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(invalidAddress, animated: true, completion: nil)
        return
    }
    
    @objc private func onDoneButton() {
        guard let sendEvent = sendEvent else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        guard let destinationLocation = destinationLocation else {
            return presentDestinationNotSetMessage()
        }
        sendEvent(destinationLocation, startingLocation ?? locationManager.location?.coordinate)
        locationManager.stopUpdatingLocation()
        self.navigationController?.popViewController(animated: true)
    }
    
    // This will center the map on the users location
    private func centerViewOnUser() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 2000, longitudinalMeters: 2000)
            map.setRegion(region, animated: true)
        }
    }
    
    // Given a placemarker this will center the map on the placemarker
    private func centerViewOnPlaceMarker(placeMarker: MKPlacemark) {
        let region = MKCoordinateRegion.init(center: placeMarker.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        map.setRegion(region, animated: true)
    }
}
// MARK: Search Bar delegate methods --------------------------------------------------------------------------------
extension MapViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print ("editing")
    }
    
    func isResponseInvalid() -> Bool {
        if (response == nil || response!.count == 0) {
            return true
        }
        return false
    }
    
    func presentInvalidResponseMessage() {
        let invalidAddress = UIAlertController(title: "Invalid Location", message: "The location you searched for cannot be found, please try again.", preferredStyle: .alert)
        invalidAddress.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(invalidAddress, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
        
        if isResponseInvalid() {
            presentInvalidResponseMessage()
        }
        else {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = searchBar.text ?? ""
            searchRequest.region = searchCompleter.region
            let search = MKLocalSearch(request: searchRequest)
            search.start { [weak self] response, error in
                if let self = self {
                    guard let response = response else {
                        self.map.removeAnnotations(self.map.annotations)
                        self.searchSuggestion.isHidden = true
                        return
                    }
                    if (searchBar === self.startingLocationSearchBar) {
                        self.startingLocation = response.mapItems[0].placemark.coordinate
                    }
                    self.map.removeAnnotations(self.map.annotations)
                    for item in response.mapItems {
                        let annotation = MapViewAnnotation(title: "\(item.name ?? ""), \(item.placemark.locality ?? "")", subtitle: item.placemark.title ?? "", coordinate: item.placemark.coordinate, placemark: item.placemark)
                        self.map.addAnnotation(annotation)
                    }
                    self.map.showAnnotations(self.map.annotations, animated: true)
                    self.centerViewOnPlaceMarker(placeMarker: response.mapItems[0].placemark)
                    self.searchSuggestion.isHidden = true
                }
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isUpdatingDestination = (searchBar === destinationSearchBar)
        searchCompleter.region = MKCoordinateRegion.init(center: map.centerCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        searchCompleter.queryFragment = searchBar.text!
        results = searchCompleter.results
        searchSuggestion.isHidden = false
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text ?? ""
        searchRequest.region = searchCompleter.region
        
        let search = MKLocalSearch(request: searchRequest)
        #warning("Usage of unowned may not be safe")
        search.start { [unowned self] response, error in
            guard let response = response else {
                return
            }
            self.response = response.mapItems
            if self.response?.count == 0 {
                self.searchSuggestion.isHidden = true
            }
            self.searchSuggestion.reloadData()
        }
    }
}

// MARK: Location handling --------------------------------------------------------------------------------
extension MapViewController: CLLocationManagerDelegate {
    func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            centerViewOnUser()
            break
        case .denied:
            presentLocationServicesError()
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted:
            presentLocationServicesError()
            break
        case .authorizedAlways:
            centerViewOnUser()
            break
        @unknown default:
            return
        }
    }
    
    func checkLocationServices() {
        if (CLLocationManager.locationServicesEnabled()) {
            setUpLocationManager()
            checkAuthorization()
        } else {
            presentLocationServicesError()
        }
    }
    
    func presentLocationServicesError() {
        let alert  =  UIAlertController(title: "Location Services are not enabled",
                                        message: "place go to: \n Settings->Privacy->Location Services\n and enable for NeverLate",
                                        preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkAuthorization()
    }
}

// MARK: Search completion --------------------------------------------------------------------------------
extension MapViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
}

extension MapViewController : MKMapViewDelegate {
    private func showMaproute() {
        let directionRequest = MKDirections.Request()
        let locationManager = CLLocationManager()
        var startOfRoute: MKPlacemark?
        guard let endOfRoute = destinationLocation else {return}
        startOfRoute = startingAnnotation?.placemark
        if (startOfRoute == nil) {
            if let location = locationManager.location?.coordinate {
                startOfRoute = MKPlacemark(coordinate: location)
            } else {
                return
            }
        } else {
            map.addAnnotation(startingAnnotation!)
        }
        directionRequest.source = MKMapItem(placemark: startOfRoute!)
        let region = MKCoordinateRegion.init(center: startOfRoute!.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        map.setRegion(region, animated: true)
        
        
        directionRequest.destination = MKMapItem(placemark: endOfRoute)
        
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            var route : MKRoute
            route = response.routes[0]
            self.map.removeOverlays(self.map.overlays)
            self.map.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            
            
            var rect = route.polyline.boundingMapRect
            rect.size = MKMapSize(width: rect.size.width + 100000, height: rect.size.height + 100000)
            rect.origin = MKMapPoint(x: rect.origin.x - 50000, y: rect.origin.y - 50000)
            
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 4
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
         view.canShowCallout = true
         view.leftCalloutAccessoryView = UIView()
         view.leftCalloutAccessoryView?.frame = CGRect(origin: view.center, size: CGSize(width: 10, height: 10))
         let myAnnotation = view.annotation as! MapViewAnnotation
         let placeMarker = myAnnotation.placemark
         self.centerViewOnPlaceMarker(placeMarker: placeMarker)
         if (isUpdatingDestination!) {
            self.destinationLocation = placeMarker
            showMaproute()
            doneButtonAnimation()
         }
         else {
            startingAnnotation = myAnnotation
            startingLocation = placeMarker.coordinate
            if destinationLocation != nil {
                showMaproute()
            }
         }
     }
}
// MARK: Table View --------------------------------------------------------------------------------
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let size = response?.count ?? 0
        return size
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.mapVCCellIdentifier, for: indexPath)
        cell.backgroundColor = (self.traitCollection.userInterfaceStyle == .dark) ? .black:.white
        cell.textLabel?.numberOfLines = 2
        if (indexPath.row < response?.count ?? 0) {
            cell.textLabel?.text = " \(response![indexPath.row].name ?? "") \n \(response![indexPath.row].placemark.title ?? "")"
        }
        else {
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = response?[indexPath.row].name
        let address = response?[indexPath.row].placemark.title ?? response?[indexPath.row].placemark.name ?? destinationSearchBar.text
        
        if (isUpdatingDestination!) {
            destinationSearchBar.text = "\(name ?? "") \(address ?? "")"
            searchBarSearchButtonClicked(destinationSearchBar)
        } else {
            startingLocationSearchBar.text = "\(name ?? "") \(address ?? "")"
            searchBarSearchButtonClicked(startingLocationSearchBar)
        }
    }
}


