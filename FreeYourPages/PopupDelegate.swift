//
//  PopupDelegate.swift
//  Scribd Exporer
//
//  Created by Nathaniel Higgins on 28/12/2016.
//  Copyright © 2016 Nathaniel Higgins. All rights reserved.
//

import UIKit

protocol PopupDelegate: class {
    func didFinish(sender: UIViewController)
    func didCancel(sender: UIViewController)
}
