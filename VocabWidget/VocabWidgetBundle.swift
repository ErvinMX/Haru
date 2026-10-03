//
//  VocabWidgetBundle.swift
//  VocabWidget
//
//  Created by Ervin Sng on 6/9/26.
//

import WidgetKit
import SwiftUI

@main
struct VocabWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocabWidget()
        VocabWidgetControl()
    }
}
