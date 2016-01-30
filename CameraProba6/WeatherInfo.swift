//
//  WeatherInfo.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/7/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import Foundation

class WeatherInfo {
    
    var city: String!
    var country: String!
    var weatherType: String!
    var weatherTypeID: Int!
    var temp: String!
    
    let celsius: String = "\u{02103}"
    let fahrenheit: String = "\u{02109}"
    
    var description: String {
        return "\(country), \(city)\n\(weatherType), \(temp) \(celsius)"
    }
}