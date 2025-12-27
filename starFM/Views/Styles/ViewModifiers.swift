//
//  ViewModifiers.swift
//   
//
//  Created by Johncarlos Lunardini on 12/12/25.
//

import SwiftUI

struct ConditionalZoomTransition: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        #if os(visionOS)
        content
        #else
        if #available(iOS 18.0, macOS 15.0, *) {
            content
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
        #endif
    }
}

extension View {
    func conditionalZoomTransition(
        sourceID id: AnyHashable,
        in namespace: Namespace.ID
    ) -> some View {
        modifier(ConditionalZoomTransition(id: id, namespace: namespace))
    }
}


struct ConditionalMatchedTransitionSource: ViewModifier {
    let id: AnyHashable
    let namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        #if os(visionOS)
        content
        #else
        if #available(iOS 18.0, macOS 15.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
        #endif
    }
}

extension View {
    func conditionalMatchedTransitionSource(
        sourceID id: AnyHashable,
        in namespace: Namespace.ID
    ) -> some View {
        modifier(ConditionalMatchedTransitionSource(id: id, namespace: namespace))
    }
}

