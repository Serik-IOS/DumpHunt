//
//  GoogleMapsVC.swift
//  DumpHunt
//
//  Created by Serik on 22.11.2019.
//  Copyright © 2019 Serik_Klement. All rights reserved.
//

import UIKit
import GoogleMaps

fileprivate let ArkhangelskLatitude: Double = 64.542227
fileprivate let ArkhangelskLongitude: Double = 40.563143

protocol CreateReportVCDelegate: class {
    func setCurrentCoordinate(latitude: Double?, longitude: Double?)
}

final class GoogleMapsVC: BaseVC {
    
    enum TypeVC: Int {
        case open = 0
        case show
    }
    // MARK: - Properties

    var mapView = GMSMapView()
    var currentMarker = GMSMarker()
    var isLocation: Bool = true
    var latitude: Double?
    var longitude: Double?
    var typeVC: TypeVC = .open
    weak var delegate: CreateReportVCDelegate?

    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.distanceFilter = 10.0
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.startMonitoringSignificantLocationChanges()
        
        return _locationManager
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch typeVC {
        case .show:
            getLocation()
            break
        case .open:
            showMapView()
        }
    }
    
    // Mark: Actions
    
    override func leftButtonAction(_ button: UIBarButtonItem) {
        super.leftButtonAction(button)
        
        delegate?.setCurrentCoordinate(latitude: latitude,
                                       longitude: longitude)
    }
    
    // Mark: Methods
    
    private func getLocation() {
        
        if CLLocationManager.locationServicesEnabled() {
                        
            switch CLLocationManager.authorizationStatus() {
                
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
                locationManager.startUpdatingLocation()
                break
                
            case .denied, .restricted:
                showDisabledLocationAlert()
                break
                
            case .authorizedAlways, .authorizedWhenInUse:
                isLocation = true
                locationManager.startUpdatingLocation()
                break
                
            default:
                break
            }
        } else {
            showDisabledLocationAlert()
        }
    }
    
    private func showMapView() {
        
        let latitude = self.latitude ?? ArkhangelskLatitude
        let longitude = self.longitude ?? ArkhangelskLongitude
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude,
                                              longitude: longitude,
                                              zoom: 9)
        
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.delegate = self
        mapView.animate(toLocation: CLLocationCoordinate2D(latitude: latitude,
                                                           longitude: longitude))
        
        currentMarker.isDraggable = true
        currentMarker.position.latitude = latitude
        currentMarker.position.longitude = longitude
        currentMarker.map = mapView
        
        view = mapView
    }
    
    private func showDisabledLocationAlert() {
        
        let accessAlert = UIAlertController(title: Constants.positioningDisabled,
                                            message: Constants.enableSettings,
                                            preferredStyle: .alert)
        
        accessAlert.addAction(UIAlertAction(title: Constants.ok,
                                            style: .default,
                                            handler: nil))
        
        accessAlert.addAction(UIAlertAction(title: Constants.cancel,
                                            style: .cancel,
                                            handler: nil))
        
        present(accessAlert, animated: true, completion: nil)
    }
    
}

// MARK: - CLLocationManagerDelegate

extension GoogleMapsVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if isLocation {
            isLocation = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard let coordinate: CLLocationCoordinate2D = self.locationManager.location?.coordinate else { return }
                self.locationManager.stopUpdatingLocation()
                self.latitude = coordinate.latitude
                self.longitude = coordinate.longitude
                
                self.showMapView()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.isLocation = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Utill.printInTOConsole(error)
    }
    
}

// MARK: GMSMapViewDelegate

extension GoogleMapsVC: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        latitude = marker.position.latitude
        longitude = marker.position.longitude
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        
        currentMarker.position = coordinate
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }
    
}

