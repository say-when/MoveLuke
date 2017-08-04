//
//  MainViewController.swift
//  BoundsTest
//
//  Created by Scott Grant on 8/3/17.
//  Copyright © 2017 Scott Grant. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentSizeLabel: UILabel!
    @IBOutlet var contentOffsetLabel: UILabel!
    @IBOutlet var scrollXTextField: UITextField!
    @IBOutlet var scrollYTextField: UITextField!
    @IBOutlet var boundsLabel: UILabel!
    
    var containerLayer:CALayer!
    var dataTask:URLSessionDataTask!
    var maxX:CGFloat = 0
    var maxY:CGFloat = 0
    let initialPosition = CGPoint(x:563, y:365) // Center on the face...
    
    // This may be a link to someone from a galaxy far, far away...
    let lukeURL = "https://vignette1.wikia.nocookie.net/disney/images/b/b6/Old_Luke_Skywalker.jpeg/revision/latest?cb=20160405220659"
    
    
    //
    // MARK: View Lifecycle Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up our scrollView with Luke's image...
        guard let url = URL(string:self.lukeURL) else {
            self.showError(title: "kDifficultAlertTitle",
                           message: "kDifficultAlertMessage")
            // Note: We could exit here, or in the network calls to the showError method, by providing a completion block
            // for the alert (and adding a completion block param to showError) and then use the block to call something 
            // like the AppDelegate applicationWillTerminate method and put an exit(0) or abort() in there.
            //
            // However, it's considered bad form in iOS, and by Apple, for an app to terminate itself,
            // nevertheless many developers (including yours truly) interpret that as a guideline not
            // a rule and they do it for certain conditions where they want the user out of the app...
            return
        }
        
        // Use the URLSession to try and download the image, using all the session defaults.
        // We don't need to hold on to the data task reference, returned by the call, for this simple operation...
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) -> Void in
            if let err = error {
                // Do UI operations on the main queue...
                DispatchQueue.main.async {
                    self?.showError(title:"kDifficultAlertTitle",
                              message:"kDifficultNetworkAlertMessage" + " Error: \(err.localizedDescription)")
                }
                return
            }
            
            if let imgData = data,
                let image = UIImage(data: imgData) {
                DispatchQueue.main.async {
                    self?.setupScrollView(withImage: image)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError(title: "kDifficultAlertTitle",
                              message: "kDifficultNoDataAlertMessage")
                }
            }
        }).resume()
    }
    
    //
    // MARK: Setup UIScrollView
    //
    func setupScrollView(withImage image:UIImage) {
        
        // Our main view is going to be a little basic but functional, enough for what we're doing...
        self.scrollView.contentSize = image.size
        let imgView = UIImageView(image: image)
        imgView.frame = CGRect(x:0, y:0, width:image.size.width, height:image.size.height)
        imgView.contentMode = .center
        
        // We can't set the contentOffset beyond the maxium size (contentSize, the size of the full image and scroll view area)
        // minus the size of our visible scroll view's frame...
        self.maxX = self.scrollView.contentSize.width - self.scrollView.frame.size.width
        self.maxY = self.scrollView.contentSize.height - self.scrollView.frame.size.height
        self.scrollView.addSubview(imgView)
        
        // Set Luke's initial position
        self.scrollView.contentOffset = self.initialPosition
        
        self.view.backgroundColor = UIColor.lightGray
        self.scrollView.layer.borderWidth = 2
        self.scrollView.layer.borderColor = UIColor.red.cgColor
        self.scrollView.layer.cornerRadius = 8
        self.scrollView.delegate = self
        
        
        // Set the initial scrollView values in our labels...
        let offset = self.scrollView.contentOffset
        let content = self.scrollView.contentSize
        let bounds = self.scrollView.bounds
        self.contentOffsetLabel.text = "x: \(offset.x), y: \(offset.y)"
        self.contentSizeLabel.text = "w: \(content.width), h: \(content.height)"
        self.boundsLabel.text = "x: \(bounds.origin.x), y: \(bounds.origin.y), w: \(bounds.size.width), h: \(bounds.size.height)"
    }

    // 
    // MARK: Button Action
    //
    @IBAction func clickedChangeBounds(_ sender: Any) {
        // Get current text field values, and if they
        // aren't nil then try turning them into float values...
        guard let strX = self.scrollXTextField.text,
            let strY = self.scrollYTextField.text,
            let x = NumberFormatter().number(from: strX)?.floatValue,
            let y = NumberFormatter().number(from: strY)?.floatValue else {
                // We're simplifying here, but we could break the x and y check down further and
                // see if they entered numbers vs. alpha characters, etc...
                self.showError(title:"kFailAlertTitle", message: "kFailAlertMessage")
                return
        }
        
        /***
          Did the user set an x or y value that is beyond the minimum or maxium sizes?
         ***/
        
        // We get our current contentOffset and initialize our update x & y values...
        let currentOffset = self.scrollView.contentOffset
        var updateX:CGFloat = 0
        var updateY:CGFloat = 0
        
        // Calculate new temporary values based on what they entered...
        let tmpX = CGFloat(ceilf(x)) + currentOffset.x
        let tmpY = CGFloat(ceilf(y)) + currentOffset.y
        
        var showError = false // Show the error alert for any out of range values
        
        // If the tmp values are greater than zero set them, otherwise we leave
        // them set to zero (for negative values). If the update values are greater
        // than the max values, set them to the max values...
        if tmpX > 0 {
            updateX = tmpX
            if updateX > self.maxX {
                showError = true
                updateX = self.maxX
            }
        } else {
            showError = true
        }
        
        
        if tmpY > 0 {
            updateY = tmpY
            if updateY > self.maxY {
                showError = true
                updateY = self.maxY
            }
        } else {
            showError = true
        }
        
        // Update the scrollView...
        self.scrollView.setContentOffset(CGPoint(x:updateX, y:updateY), animated: true)
        
        // Had an out of range value, alert the user...
        if showError {
            self.showError(title:"kSizeAlertTitle", message:"kSizeAlertMessage")
        }
    }
    
    //
    // MARK: UIScrollViewDelegate Methods
    //
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateLabels(for: scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.updateLabels(for: scrollView)
    }
    
    //
    // MARK: Helper Methods
    //
    func updateLabels(for:UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        self.contentOffsetLabel.text = "x: \(offset.x), y: \(offset.y)"
        self.boundsLabel.text = "x: \(bounds.origin.x), y: \(bounds.origin.y), w: \(bounds.size.width), h: \(bounds.size.height)"
    }
    
    func showError(title: String, message: String) {
        let alert = self.createAlert(title: NSLocalizedString(title, comment:""),
                                     message: NSLocalizedString(message, comment:""),
                                     completion: nil)
        self.present(alert, animated: true)
    }
    
    func createAlert(title:String, message:String, completion:((UIAlertAction) -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("kOKButtonText", comment:""),
                                   style: .default,
                                   handler: completion)
        alert.addAction(action)
        return alert
    }
}

