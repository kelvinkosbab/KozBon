//
//  EmptyStateProtocol.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit

protocol EmptyStateProtocol {
  var emptyStateTitle: String { get }
  var emptyStateMessage: String { get }
}

extension EmptyStateProtocol where Self : UIViewController {
  
  func showEmptyState(animated: Bool = true, completion: (() -> Void)? = nil) {
    
    // Remove if necessary
    self.hideEmptyState(animated: false) {
      
      // Configure the empty view
      let emptyStateView = EmptyStateView(frame: self.view.bounds)
      emptyStateView.titleLabel?.text = self.emptyStateTitle
      emptyStateView.messageLabel?.text = self.emptyStateMessage
      if let collectionViewController = self as? UICollectionViewController, let collectionView = collectionViewController.collectionView {
        emptyStateView.backgroundColor = collectionView.backgroundColor
      } else if let tableViewController = self as? UITableViewController, let tableView = tableViewController.tableView {
        emptyStateView.backgroundColor = tableView.backgroundColor
      } else {
        emptyStateView.backgroundColor = self.view.backgroundColor
      }
      
      // Add the empty view and set constraints
      emptyStateView.translatesAutoresizingMaskIntoConstraints = false
      emptyStateView.alpha = 0
      self.view.addSubview(emptyStateView)
      let emptyTopConstraint = NSLayoutConstraint(item: emptyStateView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
      let emptyBottomConstraint = NSLayoutConstraint(item: emptyStateView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
      let emptyLeadingConstraint = NSLayoutConstraint(item: emptyStateView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
      let emptyTrailingConstraint = NSLayoutConstraint(item: emptyStateView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
      self.view.addConstraints([ emptyTopConstraint, emptyBottomConstraint, emptyLeadingConstraint, emptyTrailingConstraint ])
      
      // Show the view
      UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
        self.view.layoutIfNeeded()
        emptyStateView.alpha = 1
      }, completion: { (_) in
        completion?()
      })
    }
  }
  
  func hideEmptyState(animated: Bool = true, completion: (() -> Void)? = nil) {
    
    // Find the empty state view
    var emptyStateView: EmptyStateView? = nil
    for view in self.view.subviews {
      if let view = view as? EmptyStateView {
        emptyStateView = view
        break
      }
    }
    
    if let emptyStateView = emptyStateView {
      UIView.animate(withDuration: animated ? 0.2 : 0, animations: {
        emptyStateView.alpha = 0
      }, completion: { (_) in
        emptyStateView.removeFromSuperview()
        completion?()
      })
      
    } else {
      completion?()
    }
  }
}

class EmptyStateView : UIView {
  
  // MARK: - Properties
  
  var titleLabel: UILabel? = nil
  var messageLabel: UILabel? = nil
  
  // MARK: - Init
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    self.commonInit()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.commonInit()
  }
  
  private func commonInit() {
    self.backgroundColor = .clear
    
    // Add title label
    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    self.titleLabel = titleLabel
    titleLabel.textColor = .darkGray
    titleLabel.font = UIFont.systemFont(ofSize: 25)
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    
    // Add constraints for title label
    self.addSubview(titleLabel)
    let titleCenterYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
    let titleLeadingConstraint = NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 10)
    let titleTrailingConstraint = NSLayoutConstraint(item: titleLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 10)
    self.addConstraints([ titleCenterYConstraint, titleLeadingConstraint, titleTrailingConstraint ])
    
    // Add message label
    let messageLabel = UILabel()
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    self.messageLabel = messageLabel
    messageLabel.textColor = .darkGray
    messageLabel.font = UIFont.systemFont(ofSize: 17)
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    
    // Add constraints for title label
    self.addSubview(messageLabel)
    let messageTopConstraint = NSLayoutConstraint(item: messageLabel, attribute: .top, relatedBy: .equal, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 10)
    let messageLeadingConstraint = NSLayoutConstraint(item: messageLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 10)
    let messageTrailingConstraint = NSLayoutConstraint(item: messageLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 10)
    self.addConstraints([ messageTopConstraint, messageLeadingConstraint, messageTrailingConstraint ])
  }
}
