//
//  PopupUIView.swift
//  SmallGame
//
//  Created by arvin on 2025/6/18.
//

import SwiftUI

// MARK: -
struct TopLoadingView: View {
    @State private var isLoading: Bool = false
    @State private var rotation: Double = 0
    
    @ScaledMetric(relativeTo: .body) var fontSize: CGFloat = 16
    
    var loadingAnimation: Animation {
        Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    }
    
    var normalAnimation: Animation {
        Animation.easeOut(duration: 0.3)
    }
    
    // MARK: -
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image.named("ic_loading")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(rotation))
                    .animation(isLoading ? loadingAnimation : normalAnimation, value: rotation)
                
                Text("game_reload_tips".localized)
                    .foregroundColor(.white)
                    .font(.system(size: fontSize, weight: .bold))
                    .shadow(color: .hex("#000000", 0.25),
                            radius: 1.5)
            }
            
            ZStack {
                Image.named("ic_button_bg2")
                    .resizable()
                    .frame(width: 188, height: 44)
                
                Text("game_btn_ok".localized)
                    .font(.system(size: fontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .hex("#0D6006"),
                            radius: 1.5)
                    .offset(y: -3)
            }
        }
        .onAppear {
            isLoading = true
            withAnimation(loadingAnimation) {
                rotation = 360
            }
        }
        .onDisappear {
            isLoading = false
            withAnimation(normalAnimation) {
                rotation = 0
            }
        }
    }
}

// MARK: -
struct CenterNetTipsView: View {
    @ScaledMetric(relativeTo: .body) var fontSize1: CGFloat = 20
    @ScaledMetric(relativeTo: .body) var fontSize2: CGFloat = 25
    
    var body: some View {
        VStack(spacing: 40) {
            Text("game_network_tips".localized)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: fontSize1, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            ZStack {
                Image.named("ic_button_bg1")
                    .resizable()
                    .frame(width: 233, height: 69)
                
                HStack(spacing: 0) {
                    Image.named("ic_reload")
                        .resizable()
                        .frame(width: 38, height: 38)
                    
                    Text("game_btn_relaod".localized)
                        .font(.system(size: fontSize2, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .shadow(color: .hex("#0D6006"),
                                radius: 1.5)
                }
                .offset(y: -3)
            }
        }
    }
}

// MARK: -
struct BottomTipsView: View {
    @ScaledMetric(relativeTo: .body) var fontSize: CGFloat = 20
    var body: some View {
        Text("game_review_tips".localized)
            .fixedSize(horizontal: false, vertical: true)
            .font(.system(size: fontSize, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .shadow(color: .hex("#000000", 0.25),
                    radius: 1.5)
    }
}
