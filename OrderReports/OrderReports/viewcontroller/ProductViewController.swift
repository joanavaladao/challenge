//
//  CustomerViewController.swift
//  OrderReport
//
//  Created by Joana Valadao on 14/08/17.
//  Copyright © 2017 Joana Bittencourt. All rights reserved.
//

import UIKit

class ProductViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    // Properties
    var delegate : MainViewController!
    var selectedProduct : Product?
    
    @IBOutlet weak var productField: UITextField!
    @IBOutlet weak var quantityField: UILabel!

    let pickerView : UIPickerView = UIPickerView()
    
    //MARK: App Function
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productField.delegate = self

        //pickerview
        
        productField.inputView = pickerView
        pickerView.delegate = self
        pickerView.dataSource = self
        
        self.addDoneButtonOnKeyboard(productField)
    }
    
    //MARK: Controllers
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let (row, product) = delegate.find(product: 2759139395)
        if row >= -1 {
            pickerView.selectRow(row, inComponent: 0, animated: true)
            selectedProduct = product
        }
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return delegate.products.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return delegate.products[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        print("----------> \(delegate.customers[row].completeName())")
        selectedProduct = delegate.products[row]
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide the keyboard, resigning the first-responder status
        textField.resignFirstResponder()
        
        // indicates that the text field should respond to the user pressiong the "Return key"
        return true
    }

    //MARK: Private Functions
    func addDoneButtonOnKeyboard(_ textField : UITextField)
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(ProductViewController.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        textField.inputAccessoryView = doneToolbar
    }
    
    @objc private func doneButtonAction(){
        productField.resignFirstResponder()
        
        if selectedProduct == nil,
            delegate.products.count > 0 {
            selectedProduct = delegate.products[0]
        }
        
        if let productName = selectedProduct?.name {
            productField.text = productName
        } else {
            productField.text = ""
        }
        
        calculateData()
    }
    
    private func calculateData(){
        
        var totalQuantity = Int64(0)
        guard (selectedProduct?.id) != nil else {
            return
        }
        
        for order in delegate.orders {
            if let orderLines = order.orderLine {
                for line in orderLines {
                    if let line = line as? LineOrder {
                        totalQuantity += line.lineProduct?.id == selectedProduct?.id ? line.quantity : Int64(0)
                    }
                }
            }
        }
        
        quantityField.text = String(totalQuantity)        
    }
}
