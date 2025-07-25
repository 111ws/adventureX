//
//  extension.swift
//  adventureX
//
//  Created by 陆氏干饭王 on 24-07-2025.
//
import SwiftUI
import UIKit

extension WhiteboardCanvasView {
    
}

// MARK: - 侧边栏视图
struct SidebarView: View {
    @Binding var textNotes: [String]
    @Binding var showSidebar: Bool
    @State private var newNoteText = ""
    let screenWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            addNoteSection
            dividerView
            notesListView
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(sidebarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.trailing, 8)
    }
    
    // 分解复杂视图 - 标题栏
    private var headerView: some View {
        HStack {
            Text("文本笔记")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            closeButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(headerBackground)
    }
    
    // 关闭按钮
    private var closeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.4)) {
                showSidebar = false
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(.quaternary)
                )
        }
    }
    
    // 标题栏背景
    private var headerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.8)
    }
    
    // 添加笔记区域
    private var addNoteSection: some View {
        VStack(spacing: 12) {
            textField
            addButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // 文本输入框
    private var textField: some View {
        TextField("输入新笔记...", text: $newNoteText)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
            )
    }
    
    // 添加按钮
    private var addButton: some View {
        Button("添加笔记") {
            if !newNoteText.isEmpty {
                textNotes.append(newNoteText)
                newNoteText = ""
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue)
        )
        .foregroundColor(.white)
        .font(.system(size: 15, weight: .medium))
    }
    
    // 分割线
    private var dividerView: some View {
        Rectangle()
            .fill(.separator)
            .frame(height: 0.5)
            .padding(.horizontal, 20)
    }
    
    // 笔记列表
    private var notesListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(textNotes.enumerated()), id: \.offset) { index, note in
                    noteRow(note: note, index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    // 单个笔记行
    private func noteRow(note: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            deleteButton(for: index)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary.opacity(0.5))
        )
    }
    
    // 删除按钮
    private func deleteButton(for index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if index < textNotes.count {
                    textNotes.remove(at: index)
                }
            }
        }) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.red)
                .padding(6)
                .background(
                    Circle()
                        .fill(.red.opacity(0.1))
                )
        }
    }
    
    // 侧边栏背景
    private var sidebarBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.regularMaterial)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 5, y: 0)
    }
}
