//
//  ImageProcessingHelper.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/11/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import Foundation
import UIKit
import Photos

public class ImageProcessingHelper: NSObject {
    
    // MARK: - Properties
    
    static let celsius: String = "\u{02103}"
    //let fahrenheit: String = "\u{02109}"
    
    /* Display the user info for the image */
    class func showImageInfo(imageView: UIImageView, wi: WeatherInfo!, dateTime: String!) -> UIImageView {
        
        UIView.animateWithDuration(0.3,
            animations: {
                imageView.alpha = 1.0
                if wi != nil && wi.weatherType != nil {
                    switch wi.weatherType {
                    case "Clear":
                        imageView.image = UIImage(named: "sun")
                        
                    case "Rain":
                        if wi.weatherTypeID != nil {
                            switch wi.weatherTypeID {
                                
                            case 500:
                                imageView.image = UIImage(named: "lightRain")
                            case 501, 502:
                                imageView.image = UIImage(named: "moderateRain")
                            default:
                                imageView.image = UIImage(named: "rain")
                            }
                        }
                        else {
                            imageView.image = UIImage(named: "moderateRain")
                        }
                        
                    case "Snow":
                        
                        if isNight(dateTime) == true {
                            imageView.image = UIImage(named: "nightSnow")
                        }
                        else {
                            imageView.image = UIImage(named: "snow")
                        }
                        
                        
                    case "Clouds":
                        
                        if wi.weatherTypeID != nil {
                            switch wi.weatherTypeID {
                                
                            case 800:
                                if isNight(dateTime) == true {
                                    imageView.image = UIImage(named: "nightSky")
                                }
                                else {
                                    imageView.image = UIImage(named: "sun")
                                }
                            case 801, 802:
                                imageView.image = UIImage(named: "scatteredClouds")
                            default:
                                if isNight(dateTime) == true {
                                imageView.image = UIImage(named: "nightClouds")
                                }
                                else {
                                    imageView.image = UIImage(named: "overcastClouds")
                                }
                            }
                        }
                        else {
                            imageView.backgroundColor = UIColor.lightGrayColor()
                        }
                        
                    case "Extreme":
                        
                        if wi.weatherTypeID != nil {
                            
                            switch wi.weatherTypeID {
                                
                            case 900,902:
                                imageView.image = UIImage(named: "tornado")
                            case 903:
                                imageView.image = UIImage(named: "cold")
                            case 901,904:
                                imageView.image = UIImage(named: "hot")
                            case 905:
                                imageView.image = UIImage(named: "windy")
                            case 906:
                                imageView.image = UIImage(named: "hail")
                            default:
                                imageView.image = UIImage(named: "overcastClouds")
                            }
                        }
                        else {
                            imageView.backgroundColor = UIColor.lightGrayColor()
                        }
                        
                    case "Drizzle":
                        imageView.image = UIImage(named: "drizzle")
                    case "Thunderstorm":
                        imageView.image = UIImage(named: "thunderstorm")
                    case "Atmosphere":
                        imageView.image = UIImage(named: "fog")
                        
                    default:
                        break
                    }
                }
                else {
                    imageView.backgroundColor = UIColor.lightGrayColor()
                }
                imageView.alpha = 0.6
            }
        )

        
        return imageView
    }
    
    /* Currently not used */
    class func isNight(dateTime: String!) -> Bool {
        
        var night = false
        
        if dateTime != nil {
            
            //            let df = NSDateFormatter()
            //            df.dateStyle = NSDateFormatterStyle.FullStyle
            //            df.locale = NSLocale.systemLocale()
            //            let d = df.dateFromString(dateTime)
            //
            //            print("\(d)")
            
            if let colonRange = dateTime.rangeOfString(":"){
                
                let startIndex = colonRange.startIndex.advancedBy(-2)
                
                let endIndex = colonRange.startIndex.advancedBy(0)
                let tmpTime = Int(dateTime[startIndex..<endIndex])
                
                if tmpTime >= 20 {
                    night = true
                }
            }
            
        }
        
        return false
    }
    
    /* Parse the metadata of the image to get the user info */
    class func parseMetadata(metadata: NSMutableDictionary) -> (dateAndTime: String, wi: WeatherInfo, string: String, userDescription: String) {

        var dateAndTime: String!
        var wi: WeatherInfo!
        var string = "\n\n"
        var userImageDescription = ""
        
        var country: String!
        var city: String!
        
       
        var otherCamImageDateTime: Bool = false

        var weatherType: String!
        var weatherString: String!
        var weatherTypeID: Int!
        var temp: String!
        
        
        var countryNA: Bool = true
        
        
        if let exifDictionary = metadata[kCGImagePropertyExifDictionary as String] as? [String : AnyObject] {
            
            if let tmpDateTime = exifDictionary[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                dateAndTime = tmpDateTime
            }
            
        }
        
        if let iptcDictionary = metadata[kCGImagePropertyIPTCDictionary as String] as? [String : AnyObject] {
            
            if let tmpCountry = iptcDictionary[kCGImagePropertyIPTCProvinceState as String] as? String {
                country = tmpCountry
                string += "\(country)"
                wi = WeatherInfo()
                wi.country = tmpCountry
            }
            else {
                countryNA = true
            }
            
            if let tmpCity = iptcDictionary[kCGImagePropertyIPTCCity as String] as? String {
                city = tmpCity
                string += ", \(city)\n"
                wi.city = tmpCity
            }
            else {
                if countryNA == true {
                    string += "Country and city info not available\n"
                }
            }
        }
        else {
            string += "Country and city info not available\n"
        }
        
        if let tiffDictionary = metadata[kCGImagePropertyTIFFDictionary as String] as? [String : AnyObject] {
            
            if let tiffTmpDateTime = tiffDictionary[kCGImagePropertyTIFFDateTime as String] as? String {
                dateAndTime = tiffTmpDateTime
                otherCamImageDateTime = true
            }
            
            if let tmpImageDescription = tiffDictionary[kCGImagePropertyTIFFImageDescription as String] as? String {
                
                if let dateAndTimeRange = tmpImageDescription.rangeOfString("^") {
                    
                    dateAndTime = tmpImageDescription[tmpImageDescription.startIndex..<dateAndTimeRange.startIndex] as String
                    
                    otherCamImageDateTime = false
                    
                    string += "\(dateAndTime)\n"
                    
                    if let weatherRange = tmpImageDescription.rangeOfString("\(celsius)") {
                        
                        let weatherStringStartIndex = dateAndTimeRange.startIndex.advancedBy(1)
                        
                        weatherString = tmpImageDescription[weatherStringStartIndex...weatherRange.startIndex] as String
                        
                        string += "\(weatherString)\n\n"
                        
                        
                        
                        let typeIDStartIndex = weatherRange.startIndex.advancedBy(1)
                        
                        if let typeIDRange = tmpImageDescription.rangeOfString("±") {
                            
                            weatherTypeID =  Int(tmpImageDescription[typeIDStartIndex..<typeIDRange.startIndex])
                            
                            let userDescStartIndex = typeIDRange.startIndex.advancedBy(1)
                            
                            userImageDescription = tmpImageDescription[userDescStartIndex..<tmpImageDescription.endIndex] as String
                            
                            if userImageDescription != "" {
                                string += "\(userImageDescription)"
                            }
                        }
                        
                        if let weatherTypeRange = weatherString.rangeOfString(",") {
                            weatherType = weatherString[weatherString.startIndex..<weatherTypeRange.startIndex] as
                            String
                            
                            if let tempRange = weatherString.rangeOfString(celsius) {
                                let tempStartIndex = weatherTypeRange.startIndex.advancedBy(1)
                                temp = weatherString[tempStartIndex..<tempRange.startIndex] as String
                                
                                if wi == nil {
                                    wi = WeatherInfo()
                                    
                                    wi.weatherType = weatherType
                                    wi.temp = temp
                                    wi.weatherTypeID = weatherTypeID
                                }
                                else {
                                    wi.weatherType = weatherType
                                    wi.temp = temp
                                    wi.weatherTypeID = weatherTypeID
                                }
                            }
                            
                            if wi == nil {
                                wi = WeatherInfo()
                                
                                wi.weatherType = weatherType
                            }
                            else {
                                wi.weatherType = weatherType
                            }
                            
                            
                        }
                    }
                    else { //WeatherRange to be nil and thus weatherString is nil to
                        if otherCamImageDateTime == true {
                            string += "Taken on \(dateAndTime)\nWeather info not available\n\n"
                        }
                        else {
                            string += "Weather info not available\n\n"
                            
                        }
                        
                        let startIndex = dateAndTimeRange.startIndex.advancedBy(1)
                        
                        let userDesc = tmpImageDescription[startIndex..<tmpImageDescription.endIndex] as String
                        
                        userImageDescription = userDesc
                        
                        string += userDesc
                    }
                }
                else { //DateTime from imageDesc. to be nil thus weatherString is also nil
                    if otherCamImageDateTime == true {
                        string += "Taken on \(dateAndTime)\nWeather info not available\n\n"
                    }
                    else {
                        string += "Weather info not available\n\n"
                    }
                    
                    //Ovde user desc?
                    userImageDescription = tmpImageDescription
                }
            }
            else { //Image Description to be nil => we only got the dateAndTime if it exist in the image metadata
                if otherCamImageDateTime == true {
                    string += "Taken on \(dateAndTime)\nWeather info not available\n\n"
                }
                else {
                    string += "Weather info not available\n\n"
                }
            }
        }
        else { //Tiff dictionary is nil => we only got the dateAndTime if it exist in the image metadata
            if otherCamImageDateTime == true {
                string += "Taken on \(dateAndTime)\nWeather info not available\n\n"
            }
            else {
                string += "Weather info not available\n\n"
            }
        }
        
        if wi == nil {
            wi = WeatherInfo()
        }
        
        return (dateAndTime, wi, string, userImageDescription)
        
    }
    
    /* Add text sublayer with the user info to the image */
    class func addText(var textLayer: CATextLayer!, string: String, wi: WeatherInfo!, dateTime: String, userDescription: String!, view: UIView) -> CATextLayer {
        
        textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        
        // 2
        var stringLocal = "\n\n"

        if wi != nil {
            if wi.country != nil && wi.city != nil {
                stringLocal += "\(wi.country), \(wi.city)\n"
            }
            else {
                stringLocal += "Country and city not available\n"
            }
        }
        else {
            stringLocal += "Country and city not available\n"
        }

        
        if dateTime.rangeOfString("Taken") != nil {
            stringLocal += "\(dateTime)\n"
        }
        else {
            stringLocal += " Taken on \(dateTime)\n"
        }
        
        if wi != nil {
            if wi.weatherType != nil && wi.temp != nil {
                stringLocal += " \(wi.weatherType), \(wi.temp) \(celsius)\n"
            }
            else {
                stringLocal += "Weather information not available\n"
            }
        }
        else {
            stringLocal += "Weather information not available\n"
        }
        
        if userDescription != nil {
            stringLocal += "\n"
            stringLocal += "\(userDescription)"
        }
        
        textLayer.string = stringLocal
        
        let fontSize: CGFloat = 18
        
        // 3
        let fontName: CFStringRef = "Noteworthy-Light"
        textLayer.fontSize = 18
        textLayer.font = CTFontCreateWithName(fontName, fontSize, nil)
        
        // 4
        textLayer.foregroundColor = UIColor.blackColor().CGColor
        textLayer.wrapped = true
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.backgroundColor = UIColor.clearColor().CGColor
        textLayer.contentsScale = UIScreen.mainScreen().scale

        return textLayer
    }
    
}