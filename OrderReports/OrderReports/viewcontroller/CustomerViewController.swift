//
//  CustomerViewController.swift
//  OrderReport
//
//  Created by Joana Valadao on 14/08/17.
//  Copyright © 2017 Joana Bittencourt. All rights reserved.
//

import UIKit

class CustomerViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: Properties
    var delegate : MainViewController!
    var selectedCustomer : Customer?
    
    let pickerView : UIPickerView = UIPickerView()
    
    @IBOutlet weak var customerField: UITextField!
    @IBOutlet weak var totalField: UILabel!
    
    // MARK: App Funcions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customerField.delegate = self

        //pickerview
        pickerView.delegate = self
        customerField.inputView = pickerView
        
        self.addDoneButtonOnKeyboard(customerField)
        
    }
    
    // MARK: Controllers
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let (row, customer) = delegate.find(customer: 4953626051)
        if row >= -1 {
            pickerView.selectRow(row, inComponent: 0, animated: true)
            selectedCustomer = customer
        }
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return delegate.customers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return delegate.customers[row].completeName()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("----------> \(delegate.customers[row].completeName())")
        selectedCustomer = delegate.customers[row]
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide the keyboard, resigning the first-responder status
        textField.resignFirstResponder()
        
        // indicates that the text field should respond to the user pressiong the "Return key"
        return true
    }

    
    //MARK: Private functions
    private func addDoneButtonOnKeyboard(_ textField : UITextField)
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(CustomerViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
        
        
    }
    
    @objc private func doneButtonAction(){
        customerField.resignFirstResponder()
        
        if selectedCustomer == nil,
            delegate.customers.count > 0 {
            selectedCustomer = delegate.customers[0]
        }
        
        if let customerName = selectedCustomer?.completeName() {
            customerField.text = customerName
        } else {
            customerField.text = ""
        }
        
        calculateData()
    }
    
    private func calculateData(){
        
        var totalAmount : Double = 0.0
        guard let idSelectedCustomer = selectedCustomer?.id else {
            return
        }
        
        for order in delegate.orders {
            totalAmount += order.orderCustomer?.id == idSelectedCustomer ? order.totalPrice : 0.0
        }
        
        totalField.text = "$\(totalAmount) CAD"
        
    }

}
