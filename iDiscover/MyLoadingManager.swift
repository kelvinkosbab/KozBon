//
//  MyLoadingManager.swift
//  iDiscover
//
//  Created by Kelvin Kosbab on 12/30/16.
//  Copyright © 2016 Kozinga. All rights reserved.
//

import Foundation
import UIKit

class MyLoadingManager {
  
  class MyLoadingView: UIView {
  }
  
  class MyActivityIndicator: UIActivityIndicatorView {
  }
  
  class func showLoading(view: UIView, completion: (() -> ())? = nil) {
    
    // Tinted background view
    let loadingView = MyLoadingView()
    loadingView.backgroundColor = UIColor.black
    loadingView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(loadingView)
    
    // Background view constraints
    let topConstraint = NSLayoutConstraint(item: loadingView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
    let bottomConstraint = NSLayoutConstraint(item: loadingView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
    let leadingConstraint = NSLayoutConstraint(item: loadingView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
    let trailingConstraint = NSLayoutConstraint(item: loadingView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
    view.addConstraints([ topConstraint, bottomConstraint, leadingConstraint, trailingConstraint ])
    
    // Activity indicator
    let activityIndicator = MyActivityIndicator()
    activityIndicator.activityIndicatorViewStyle = .whiteLarge
    activityIndicator.color = UIColor.white
    activityIndicator.startAnimating()
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(activityIndicator)
    
    // Activity indicator constraints
    let activityCenterXConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
    let activityCenterYConstraint = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
    view.addConstraints([ activityCenterXConstraint, activityCenterYConstraint ])
    
    // Animations
    view.layoutIfNeeded()
    loadingView.alpha = 0.0
    activityIndicator.alpha = 0.0
    UIView.animate(withDuration: 0.1, animations: {
      loadingView.alpha = 0.5
      activityIndicator.alpha = 1.0
      view.layoutIfNeeded()
    }, completion: { (_) in
      completion?()
    })
  }
  
  class func hideLoading(view: UIView, completion: (() -> ())? = nil) {
    var loadingView: MyLoadingView? = nil
    var activityIndicator: MyActivityIndicator? = nil
    
    // Find the loading view and activity indicator
    for subview in view.subviews {
      if let loading = subview as? MyLoadingView {
        loadingView = loading
      }
      if let activity = subview as? MyActivityIndicator {
        activityIndicator = activity
      }
    }
    
    // Animations
    UIView.animate(withDuration: 0.1, animations: {
      loadingView?.alpha = 0.0
      activityIndicator?.alpha = 0.0
      view.layoutIfNeeded()
    }, completion: { (_) in
      loadingView?.removeFromSuperview()
      activityIndicator?.removeFromSuperview()
      completion?()
    })
  }
  
  class func showLoading(_ completion: (() -> ())? = nil) {
    if let window = AppDelegate.shared.window {
      self.showLoading(view: window, completion: completion)
    }
  }
  
  class func hideLoading(_ completion: (() -> ())? = nil) {
    if let window = AppDelegate.shared.window {
      self.hideLoading(view: window, completion: completion)
    }
  }
}
