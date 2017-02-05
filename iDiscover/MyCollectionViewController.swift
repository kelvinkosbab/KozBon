//
//  MyCollectionViewController.swift
//  KozBon
//
//  Created by Kelvin Kosbab on 2/4/17.
//  Copyright © 2017 Kozinga. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol MyCollectionViewReorderProtocol {
  func didMoveItem(from: IndexPath, to: IndexPath)
}

class MyCollectionViewController : UICollectionViewController, UICollectionViewDelegateFlowLayout, EmptyStateProtocol, NSFetchedResultsControllerDelegate, PresentableController, MyViewControllerIdentifierProtocol {
  
  // MARK: - PresentableController
  
  var presentedMode: PresentationMode = .navStack
  var transitioningDelegateReference: UIViewControllerTransitioningDelegate? = nil
  
  // MARK: - CommonCollectionViewReorderProtocol
  
  var reorderDelegate: MyCollectionViewReorderProtocol? = nil
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = self.defaultViewTitle
    
    self.navigationItem.backBarButtonItem = UIBarButtonItem(text: "")
    
    self.view.backgroundColor = UIColor.groupTableViewBackground
    self.collectionView?.backgroundColor = UIColor.groupTableViewBackground
    
    // Setting this flag sets the navigation item elements
    self.isEditing = false
    self.updateNavigationAndTabBar()
    
    self.collectionView?.delegate = self
    self.collectionView?.dataSource = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.reloadData()
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    
    self.updateContentInsets(size: self.collectionView?.bounds.size ?? self.view.bounds.size)
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    self.updateContentInsets(size: size)
  }
  
  // MARK: - NSFetchedResultsControllerDelegate
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    self.reloadData()
  }
  
  // MARK: - Content
  
  func reloadData() {
    self.collectionView?.reloadData()
//    self.updateEmptyState() // TODO: Fix this
  }
  
  // MARK: - EmptyStateProtocol
  
  var emptyStateTitle: String {
    return NSLocalizedString("None Present", comment: "None Present empty state title")
  }
  
  var emptyStateMessage: String {
    return ""
  }
  
  func updateEmptyState() {
    
    guard let collectionView = self.collectionView else {
      self.hideEmptyState()
      return
    }
    
    // Check for empty state
    if self.numberOfSections(in: collectionView) == 0 || (self.numberOfSections(in: collectionView) == 1 && self.collectionView(collectionView, numberOfItemsInSection: 0) == 0) {
      // Show empty state
      self.showEmptyState()
    } else {
      // Hide empty state
      self.hideEmptyState()
    }
  }
  
  // MARK: - Content Insets
  
  var defaultPadCellWidth: CGFloat {
    return 300
  }
  
  func updateContentInsets(size: CGSize) {
    self.collectionView?.contentInset = self.getContentInsets(width: size.width)
  }
  
  func getContentInsets(width: CGFloat? = nil) -> UIEdgeInsets {
    let collectionWidth = width ?? self.collectionView?.bounds.width ?? self.view.bounds.width
    if self.isConststrainedWidth(view: self.collectionView ?? self.view) {
      return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      
    } else if collectionWidth < 630 {
      return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    } else {
      let space = collectionWidth - (self.defaultPadCellWidth * 2) - 10;
      return UIEdgeInsets(top: 0, left: space/2, bottom: 0, right: space/2)
    }
  }
  
  // MARK: - UICollectionView
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 0
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    return UICollectionReusableView()
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 0
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return UICollectionViewCell()
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  func isConststrainedWidth(view: UIView) -> Bool {
    return UIDevice.isPhone || view.frame.width < 600
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 50)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 50)
  }
  
  func sizeForItemAt(indexPath: IndexPath, collectionView: UICollectionView) -> CGSize {
    var width: CGFloat = self.defaultPadCellWidth
    let collectionWidth = collectionView.frame.width
    if self.isConststrainedWidth(view: collectionView) {
      width = collectionWidth
      
    } else if collectionWidth < 630 {
      width = collectionWidth - 20
    }
    return CGSize(width: width, height: UIDevice.isPhone ? 55 : 80)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return self.sizeForItemAt(indexPath: indexPath, collectionView: collectionView)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    if self.isConststrainedWidth(view: collectionView) {
      return 1
    }
    return 10
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    if self.isConststrainedWidth(view: collectionView) {
      return 1
    }
    return 10
  }
  
  // MARK: - Editing Mode
  
  var defaultViewTitle: String? {
    return nil
  }
  
  var isEditingViewTitle: String? {
    return nil
  }
  
  var defaultLeftBarButtonItems: [UIBarButtonItem] {
    return []
  }
  
  var isEditingLeftBarButtonItems: [UIBarButtonItem] {
    return []
  }
  
  var defaultRightBarButtonItems: [UIBarButtonItem] {
    return []
  }
  
  var isEditingRightBarButtonItems: [UIBarButtonItem] {
    return [ UIBarButtonItem(text: NSLocalizedString("Done", comment: "Done action"), target: self, action: #selector(self.isEditingDoneSelected)) ]
  }
  
  override var isEditing: Bool {
    didSet {
      self.updateNavigationAndTabBar(hasEditingChanged: self.isEditing != oldValue)
    }
  }
  
  func updateNavigationAndTabBar(hasEditingChanged hasChanged: Bool = false) {
    self.collectionView?.reloadData()
    
    if self.isEditing {
      self.navigationItem.title = self.isEditingViewTitle
      self.navigationItem.leftBarButtonItems = self.isEditingLeftBarButtonItems
      self.navigationItem.rightBarButtonItems = self.isEditingRightBarButtonItems
      self.navigationItem.hidesBackButton = true
      
    } else {
      self.navigationItem.title = self.defaultViewTitle
      self.navigationItem.hidesBackButton = false
      if let viewControllers = self.navigationController?.viewControllers, let index = viewControllers.index(of: self), index > 0 {
        self.navigationItem.leftBarButtonItems = nil
      } else {
        self.navigationItem.leftBarButtonItems = self.defaultLeftBarButtonItems
      }
      self.navigationItem.rightBarButtonItems = self.defaultRightBarButtonItems
    }
    
    if hasChanged {
      // Update tab bar
      if self.isEditing {
        self.hideTabBar()
      } else {
        self.showTabBar()
      }
    }
  }
  
  @objc func isEditingDoneSelected() {
    self.isEditing = !self.isEditing
  }
  
  // MARK: - Drag Reordering
  
  var isReorderEnabled: Bool {
    return false
  }
  
  var isReorderAcrossSectionsAllowed: Bool {
    return false
  }
  
  override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    return self.isEditing && self.isReorderEnabled
  }
  
  override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    
    guard !self.isReorderAcrossSectionsAllowed && sourceIndexPath.section == destinationIndexPath.section else {
      collectionView.moveItem(at: destinationIndexPath, to: sourceIndexPath)
      return
    }
    
    self.reorderDelegate?.didMoveItem(from: sourceIndexPath, to: destinationIndexPath)
  }
}
