//
//  ProductTableViewCell.swift
//  Dagensvimmerby
//
//  Created by Christoffer Assgård on 2020-08-23.
//  Copyright © 2020 Dagens Vimmerby AB. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if (selected) {
            mainImageView.image = UIImage(named: "check")
        } else {
            mainImageView.image = nil
        }
    }

}
