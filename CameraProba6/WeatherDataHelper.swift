//
//  WeatherDataHelper.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/6/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import Foundation
import UIKit

class WeatherDataHelper: NSObject {

    var info: WeatherInfo!
    static var progress: Double = 0.0
    var buffer:NSMutableData = NSMutableData()
    var expectedContentLength = 0
    
    func getWeatherData(urlString: String, completion: ((result:WeatherInfo?) -> Void)!) {
        
        let url: NSURL = NSURL(string: urlString)!
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { data, response, error in
            
            self.info = WeatherInfo()
            
            let options: NSJSONReadingOptions = NSJSONReadingOptions()
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: options) as! NSDictionary
                
                //print("\(json)")
                
                if let name = json["name"] as? NSString {
                    self.info.city = name as String
                }
                
                if let weatherSys = json["sys"] as? NSDictionary {
                    self.info.country = weatherSys["country"] as! String
                }
                
                if let weatherJSON = json["weather"] as? NSArray {
                    if let weatherInfo = weatherJSON[0] as? NSDictionary {
                        self.info.weatherType = weatherInfo["main"] as! String
                        self.info.weatherTypeID = weatherInfo["id"] as! Int
                    }
                }
                
                if let main = json["main"] as? NSDictionary {
                    let tmpTemperature = main["temp"] as! Double
                    let celsiusTemp: Double = tmpTemperature - 273.15
                    //let fahrenheitTemp: Float = tmpTemperature * 9/5 - 459.67
                    self.info.temp = "\(celsiusTemp)"
                }
                
                
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(result: self.info)
                    }
                }
                
            }
            catch {
                print("json error")
            }

        }
        
        task.resume()
    }
}