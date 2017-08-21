//
//  ViewController.swift
//  OrderReports
//
//  Created by Joana Valadao on 14/08/17.
//  Copyright © 2017 Joana Bittencourt. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController {

    // MARK: Properties
    @IBOutlet weak var customerView: UIView!
    var customerViewController : CustomerViewController!
    var productViewController : ProductViewController!
    @IBOutlet weak var productView: UIView!
    
    @IBOutlet weak var customerButton: UIBarButtonItem!
    @IBOutlet weak var productButton: UIBarButtonItem!
    
    var orders : [Order] = []
    var customers : [Customer] = []
    var products : [Product] = []
    
    let url = "https://shopicruit.myshopify.com/admin/orders.json?page=1&access_token=c32313df0d0ef512ca64d5b336a0d7c6"
    
    // MARK: App Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navigation Bar
        let logo = UIImage(named: "logo.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        
        customerView.isHidden = false
        productView.isHidden = true
        
        deleteAllRecords(entity: "Customer")
        deleteAllRecords(entity: "Order")
        deleteAllRecords(entity: "Product")
        deleteAllRecords(entity: "LineOrder")
        
        download(url: url)
    }
 
    
    
    // MARK: Action
    
    @IBAction func customerButtonAction(_ sender: UIBarButtonItem) {
        customerView.isHidden = false
        productView.isHidden = true
        productViewController.productField.resignFirstResponder()
    }
    
    
    @IBAction func productButtonAction(_ sender: UIBarButtonItem) {
        customerView.isHidden = true
        productView.isHidden = false
        customerViewController.customerField.resignFirstResponder()
    }
    
    
    // Mark: Alert
    private func showAlert(title: String, message: String){
        // Create a Modal to receive data form user
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        // Create a button cancel and release the modal
        let okButton = UIAlertAction(title: "Ok", style: .default)
        
        // Adding ... propreties in Modal
        alert.addAction(okButton)
        
        // Show the Modal to the user
        present(alert, animated: true)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CustomerViewController {
            self.customerViewController = viewController
            self.customerViewController.delegate = self
        } else if let viewController = segue.destination as? ProductViewController {
            self.productViewController = viewController
            self.productViewController.delegate = self
        }
    }

    //MARK: Data manipulation
    private func download(url : String) {
        if let requestURL: NSURL = NSURL(string: url) {
            let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL as URL)
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest as URLRequest) {
                (data, response, error) -> Void in
                
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                
                if (statusCode == 200) {
                    // File accessed
                    if let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                            return
                        }
                        
                        let managedContext = appDelegate.persistentContainer.viewContext
                        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                        for case let order in (json?["orders"] as? [[String: Any]])!{
                            
                            // Order
                            let orderObject = Order(context: managedContext)
                            orderObject.id = Int64(((order["id"] as? Int) == nil) ? 0 : order["id"] as! Int)
                            
                            let price = Double(order["total_price"] as! String)
                            orderObject.totalPrice = price!
                            orderObject.currency = order["currency"] as? String ?? ""
                    
                            // Customer
                            let customerData = order["customer"] as? [String: Any]
                            let customerObject = Customer(context: managedContext)
                        
                            let idCustomer = Int64(((customerData?["id"] as? Int) == nil) ? -1 : customerData?["id"] as! Int)
                            
                            let firstNameCustomer : String
                            let lastNameCustomer : String
                            
                            // Client not identified in the file
                            if idCustomer == Int64(-1) {
                                firstNameCustomer = "Client not identified"
                                lastNameCustomer = ""
                            } else {
                                firstNameCustomer = customerData?["first_name"] as? String ?? ""
                                lastNameCustomer = customerData?["last_name"] as? String ?? ""
                            }
                            let emailCustomer = customerData?["email"] as? String ?? ""
                            
                            customerObject.id = idCustomer
                            customerObject.firstName = firstNameCustomer
                            customerObject.lastName = lastNameCustomer
                            customerObject.email = emailCustomer
                        
                            customerObject.addToCustomerOrder(orderObject)
                            
                            //Product
                            for case let orderLine in (order["line_items"] as? [[String: Any]])! {
                                let productObject = Product(context: managedContext)
                                productObject.id = orderLine["product_id"] as! Int64
                                productObject.name = orderLine["title"] as? String
                            
                                let lineObject = LineOrder(context: managedContext)
                                lineObject.id = orderLine["id"] as! Int64
                                lineObject.quantity = orderLine["quantity"] as! Int64
                            
                                productObject.addToProductLine(lineObject)
                    
                                orderObject.addToOrderLine(lineObject)
            
                            }
                            
                            do {
                                try managedContext.save()
                            } catch _ as NSError {
                                DispatchQueue.main.async {
                                    self.showAlert(title: "Error refreshing the data", message: "Please, try again or contact suport")
                                }
                            }
                        }// for
                        if self.load() {
                            DispatchQueue.main.async {
                                self.showAlert(title: "Data updated", message: "")
                            }
                        }
                        
                    } else  {
                        print("Failed")
                    } // else data
                } else {// if statusCode
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error downloading the file", message: "Please, check your internet connection")
                    }
                }
            } //task
            task.resume()
            
        } //if requestURL
        
    } // func

    
    
    func load() -> Bool{
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return false
        }
        
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequestOrder = NSFetchRequest<Order>(entityName: "Order")
        let fetchRequestCustomer = NSFetchRequest<Customer>(entityName: "Customer")
        let fetchRequestProduct = NSFetchRequest<Product>(entityName: "Product")
        
        do {
            self.orders.removeAll()
            self.orders = try managedContext.fetch(fetchRequestOrder)
            self.customers.removeAll()
            self.customers = try managedContext.fetch(fetchRequestCustomer)
            self.products.removeAll()
            self.products = try managedContext.fetch(fetchRequestProduct)

            if orders.count == 0 || customers.count == 0 || products.count == 0 {
                return false
            } else {
                return true
            }
            
        } catch _ as NSError {
            return false
        }
    }
    
    
    func deleteAllRecords(entity : String) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    func find(product idProduct : Int64) -> (Int, Product?){
        for index in 0 ..< products.count{
            if products[index].id == idProduct {
                return (index, products[index])
            }
        }
        
        return (-1, nil)
    }
    
    func find(customer idCustomer : Int64) -> (Int, Customer?){
        for index in 0 ..< customers.count{
            if customers[index].id == idCustomer {
                return (index, customers[index])
            }
        }
        
        return (-1, nil)
    }
    
    private func printData(_ type : String){
        // CoreData
        if type.uppercased() == "COREDATA" {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let fetchRequestOrder = NSFetchRequest<Order>(entityName: "Order")
            do {
                let fetchOrder : [Order] = try managedContext.fetch(fetchRequestOrder)
                print("*** ORDER **********************************\n")
                for order in fetchOrder {
                    print("-------> Order: \(order.value(forKey: "id") as! Int)")
                    print("   price: \(order.totalPrice) \(String(describing: order.currency))")
                    print("   customer: \(String(describing: order.orderCustomer?.firstName)) \(String  (describing: order.orderCustomer?.lastName))")
                    for line in order.orderLine! {
                        if let line = line as? LineOrder {
                            print(" * line: \(line.id)")
                            print("   product: \(String(describing: line.lineProduct?.name))")
                            print("   quantity: \(line.quantity)")
                        }
                    }
                    print("----------------------------\n")
                }
                print("********************************************\n")
            } catch _ as NSError{}
            
            do {
                let fetch : [Product] = try managedContext.fetch(NSFetchRequest<Product>(entityName: "Product"))
                print("*** PRODUCT ********************************\n")
                for product in fetch {
                    print("\(product.id) - \(String(describing: product.name))")
                }
                print("********************************************\n")
            } catch _ as NSError{}
            
            do {
                let fetch2 : [Customer] = try managedContext.fetch(NSFetchRequest<Customer>(entityName: "Customer"))
                print("*** CUSTOMER *******************************\n")
                for customer in fetch2 {
                    print("\(customer.id) - \(String(describing: customer.firstName)) \(String(describing: customer.lastName))")
                }
                print("********************************************\n")
            } catch _ as NSError {}
        } else { // ARRAYS
            print("*** ORDER **********************************\n")
            for order in orders {
                print("-------> Order: \(order.id)")
                print("   price: \(order.totalPrice) \(String(describing: order.currency))")
                print("   customer: \(String(describing: order.orderCustomer?.firstName)) \(String  (describing: order.orderCustomer?.lastName))")
                for line in order.orderLine! {
                    if let line = line as? LineOrder {
                        print(" * line: \(line.id)")
                        print("   product: \(String(describing: line.lineProduct?.name))")
                        print("   quantity: \(line.quantity)")
                    }
                }
                print("----------------------------\n")
            }
            print("********************************************\n")
            print("*** PRODUCT ********************************\n")
            for product in products {
                print("\(product.id) - \(String(describing: product.name))")
            }
            print("********************************************\n")
            print("*** CUSTOMER *******************************\n")
            for customer in customers {
                print("\(customer.id) - \(customer.completeName())")
            }
            print("********************************************\n")
        }
    } // printData
    
}
