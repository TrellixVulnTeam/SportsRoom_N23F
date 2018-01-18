//
//  ChatTableViewCell.swift
//  SportsRoom
//
//  Created by Larry Luk on 2017-12-24.
//  Copyright © 2017 Javier Xing. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var senderLbl: UILabel!
    @IBOutlet weak var messageLbl: UILabel!
    @IBOutlet weak var timestampLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
