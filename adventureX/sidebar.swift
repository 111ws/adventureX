//
//  sidebar.swift
//  adventureX
//
//  Created by 陆氏干饭王 on 24-07-2025.
//
import SwiftUI

extension WhiteboardCanvasView {
    
}

// MARK: - 侧边栏视图 (符合iOS人机交互指南)
struct SidebarView: View {
    @Binding var showSidebar: Bool
  
    let screenWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏 - 符合iOS导航栏设计规范
            headerView
            emptyStateView
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(10) // 在内容周围添加内边距，使其与背景之间产生间距
        .background(sidebarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16)) // 增加圆角半径，更现代
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 0.5)
        )
        .padding(.trailing, 16) // 增加边距
    }
    
    // MARK: - 标题栏 (符合iOS导航栏设计)
    private var headerView: some View {
        HStack(spacing: 16) {
            Text("焦虑笔记")
                .font(.system(size: 20, weight: .bold, design: .rounded)) // 使用圆角字体设计
                .foregroundStyle(.primary)
            
            Spacer()
            // 关闭按钮 - 符合iOS关闭按钮设计
            closeButton
        }
        .padding(.horizontal, 24) // 增加水平边距
        .padding(.vertical, 20) // 增加垂直边距
    }
    // MARK: - 关闭按钮 (符合iOS关闭按钮设计)
    private var closeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSidebar = false
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#8E8E93"))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color(hex: "#F2F2F7"))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
        }
        .accessibilityLabel("关闭侧边栏")
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSidebar)
    }
    
    // MARK: - 空状态视图 (更现代的设计)
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 56, weight: .ultraLight))
        }
        .padding(.vertical, 50)
    }
    // MARK: - 侧边栏背景 (更精致的阴影效果)
    private var sidebarBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white) // 不透明白色背景（与原设计一致）
        
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
