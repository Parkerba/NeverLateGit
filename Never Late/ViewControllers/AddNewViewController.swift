//
//  AddNewViewController.swift
//  Never Late
//
//  Created by parker amundsen on 7/17/19.
//  Copyright © 2019 Parker Buhler Amundsen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


protocol EventReciever {
    func createEvent(event: Event)
}


class AddNewViewController: UIViewController, UITextFieldDelegate {
    
    deinit {
        print("Memory was released in AddNewViewController. No retain cycles")
    }
    
    // MARK: Properties --------------------------------------------------------------------------------
    var delegate: EventReciever?
    
    var destinationLocation: MKPlacemark?
    
    var startingLocation: CLLocationCoordinate2D?
    
    var locationManager: CLLocationManager?
    
    var displayMap : (() -> Void)!
    
    // colors used
    let mainBackgroundColor = Constants.backGroundColor
    
    let buttonColor = Constants.secondaryColor //BEB490 other complementary colors: E3DCC1,FFFBEE,746943
    
    // UILabel at the top of the view
    let neverLateLabel : UILabel = {
        let label = UILabel()
        label.text = "NeverLate"
        let labelFont: UIFont = UIFont(name: "Copperplate-Bold", size: 30)!
        label.font = labelFont
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let backButton : UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "backArrow"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFill
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(onBackButton), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let eventTitleTextField : UITextField = {
        let field = UITextField()
        field.placeholder = "Title"
        field.font = UIFont(name: "Copperplate-Bold", size: 20)!
        
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    //Line separating the views
    let dividerView : UIView = {
        let retView = UIView()
        retView.backgroundColor = .lightGray
        
        retView.translatesAutoresizingMaskIntoConstraints = false
        return retView
    }()
    
    //Line separating the views
    let secondDividerView : UIView = {
        let retView = UIView()
        retView.backgroundColor = .lightGray
        
        retView.translatesAutoresizingMaskIntoConstraints = false
        return retView
    }()
    
    let eventDescriptionTextField : UITextField = {
        let field = UITextField()
        field.placeholder = "Description"
        field.font = UIFont(name: "Copperplate-Bold", size: 20)!
        
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    let addLocationButton : UIButton = {
        let button = UIButton()
        button.setTitle("Add Location", for: .normal)
        button.addTarget(self, action: #selector(onAddLocationButton) , for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = UIFont(name: "Copperplate-Bold", size: 25)!
        button.titleLabel?.numberOfLines = 2
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let datePicker : UIDatePicker = {
        let datePickerView = UIDatePicker()
        datePickerView.minimumDate = Date()
        datePickerView.backgroundColor = .clear
        
        datePickerView.translatesAutoresizingMaskIntoConstraints = false
        return datePickerView
    }()
    
    let doneButton : UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = UIFont(name: "Copperplate-Bold", size: 25)!
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(onDoneButton), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let reminderTimePickerLabel : UILabel = {
        let label = UILabel()
        label.text = "ALERT ME BEFORE I NEED TO LEAVE: "
        label.font = UIFont(name: "Copperplate-Bold", size: 20)!
        label.backgroundColor = .clear
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 1
        
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let reminderView : ReminderOffsetSelector = {
        let reminderView = ReminderOffsetSelector()
        reminderView.translatesAutoresizingMaskIntoConstraints = false
        reminderView.setUp()
        return reminderView
    }()
    
    
    
    // MARK: LifeCycle --------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = (self.traitCollection.userInterfaceStyle == .dark) ? .black:mainBackgroundColor
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(textFieldShouldReturn(_:))))
        addSubviews()
        setUpUI()
        setDelegates()
    }
    
    private func addSubviews() {
        view.addSubview(backButton)
        view.addSubview(doneButton)
        view.addSubview(datePicker)
        view.addSubview(neverLateLabel)
        view.addSubview(dividerView)
        view.addSubview(secondDividerView)
        view.addSubview(eventTitleTextField)
        view.addSubview(eventDescriptionTextField)
        view.addSubview(addLocationButton)
        view.addSubview(reminderTimePickerLabel)
        view.addSubview(reminderView)
    }
    
    private func setDelegates() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.eventTitleTextField.delegate = self
        self.eventDescriptionTextField.delegate = self
    }
    
    // sets up the Constraints to all the subviews in the view controller
    private func setUpUI() {
        
        neverLateLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 10).isActive = true
        neverLateLabel.heightAnchor.constraint(equalToConstant: view.frame.height/7).isActive = true
        neverLateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        backButton.centerYAnchor.constraint(equalTo: neverLateLabel.centerYAnchor).isActive = true
        backButton.centerXAnchor.constraint(equalTo: datePicker.leadingAnchor).isActive = true
        backButton.heightAnchor.constraint(equalTo: neverLateLabel.heightAnchor).isActive = true
        
        eventTitleTextField.centerYAnchor.constraint(equalTo: neverLateLabel.bottomAnchor, constant: 10).isActive = true
        eventTitleTextField.leadingAnchor.constraint(equalTo: datePicker.leadingAnchor).isActive = true
        eventTitleTextField.widthAnchor.constraint(equalToConstant: datePicker.frame.width).isActive = true
        
        dividerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        dividerView.centerYAnchor.constraint(equalTo: eventTitleTextField.bottomAnchor, constant: 5).isActive = true
        dividerView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        
        secondDividerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        secondDividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        secondDividerView.centerYAnchor.constraint(equalTo: eventDescriptionTextField.bottomAnchor, constant: 5).isActive = true
        secondDividerView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        
        addLocationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        addLocationButton.topAnchor.constraint(equalTo: secondDividerView.bottomAnchor, constant: 10).isActive = true
        addLocationButton.backgroundColor = buttonColor
        addLocationButton.widthAnchor.constraint(lessThanOrEqualToConstant: view.frame.width*0.8).isActive = true
        
        eventDescriptionTextField.topAnchor.constraint(equalTo: eventTitleTextField.bottomAnchor, constant: 10).isActive = true
        eventDescriptionTextField.leadingAnchor.constraint(equalTo: datePicker.leadingAnchor).isActive = true
        eventDescriptionTextField.widthAnchor.constraint(equalToConstant: datePicker.frame.width).isActive = true
        
        reminderTimePickerLabel.leadingAnchor.constraint(equalTo: datePicker.leadingAnchor).isActive = true
        reminderTimePickerLabel.trailingAnchor.constraint(equalTo: datePicker.trailingAnchor).isActive = true
        reminderTimePickerLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 10).isActive = true
        
        reminderView.leadingAnchor.constraint(equalTo: datePicker.leadingAnchor).isActive = true
        reminderView.trailingAnchor.constraint(equalTo: datePicker.trailingAnchor).isActive = true
        reminderView.topAnchor.constraint(equalTo: reminderTimePickerLabel.bottomAnchor, constant: 50).isActive = true        
        
        doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -view.frame.height/20).isActive = true
        doneButton.widthAnchor.constraint(equalToConstant: view.frame.width*0.8).isActive = true
        doneButton.backgroundColor = buttonColor
        
        datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        datePicker.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    
    // MARK: Actions --------------------------------------------------------------------------------
    // Sends the new event to the entryPoint
    @objc private func onDoneButton() {
        var newEvent = Event(datePicked: datePicker.date, eventName: eventTitleTextField.text ?? "", eventLocation: destinationLocation, currentLocation: startingLocation, EventDescription : eventDescriptionTextField.text ?? "")
        newEvent.offset = Int(reminderView.value.rounded())
        delegate?.createEvent(event: newEvent)
        self.navigationController?.popViewController(animated: true)
    }
    
    // Dismisses the addNewEventViewController without creating an event
    @objc private func onBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func onAddLocationButton() {
        displayMap()
    }
}
