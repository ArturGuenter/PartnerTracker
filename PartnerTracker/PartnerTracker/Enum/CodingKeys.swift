//
//  CodingKeys.swift
//  PartnerTracker
//
//  Created by Artur Günter on 21.07.25.
//

import Foundation
enum CodingKeys: String, CodingKey {
    case id, title, isDone, ownerId, groupId, createdAt, resetInterval, lastResetAt, completedBy
}
