//
//  InternetReachability.swift
//  CameraProba6BackUp3
//
//  Created by Jovan Ivanovski on 9/8/15.
//  Copyright © 2015 Jovan Ivanovski. All rights reserved.
//

import Foundation
import SystemConfiguration

public class InternetReachability {
   
    class func isConnectedToNetwork() -> Bool {
        
        var Status:Bool = false
        let url = NSURL(string: "http://google.com/")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: NSURLResponse?
        
        do {
            _ = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response) as NSData?
        }
        catch {
            print("Not connected to the internet: \(error)")
        }
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        
        return Status
    }
    
}