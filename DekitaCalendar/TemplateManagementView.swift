//
//  TemplateManagementView.swift
//  DekitaCalendar
//
//  Created by Hibiki Tsuboi on 2025/11/20.
//

import SwiftUI
import SwiftData

struct TemplateManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EventTemplate.createdAt) private var templates: [EventTemplate]

    @State private var isAddingNew = false
    @State private var editingTemplate: EventTemplate?
    @State private var newTitle = ""
    @State private var newEmoji = "📝"
    @State private var editTitle = ""
    @State private var editEmoji = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case newTitle
        case editTitle
    }

    private let headerGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.6, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let emojiOptions = ["📝", "📚", "✏️", "🎨", "🎯", "⚡", "🌟", "🎵", "🏃", "💪", "🧠", "❤️"]

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.85),
                        Color(red: 0.9, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // ヘッダー
                    Text("よく使う項目")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.top)

                    // よく使う項目リスト
                    ScrollView {
                        VStack(spacing: 12) {
                            if templates.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(templates) { template in
                                    if editingTemplate?.id == template.id {
                                        editingTemplateView(template)
                                    } else {
                                        templateRow(template)
                                    }
                                }
                            }

                            // 新規追加エリア
                            if isAddingNew {
                                newTemplateView
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(headerGradient)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAddingNew = true
                            focusedField = .newTitle
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(headerGradient)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("よく使う項目がありません")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.6))

            Text("右上の ＋ ボタンから追加しよう！")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
    }

    private func templateRow(_ template: EventTemplate) -> some View {
        HStack(spacing: 12) {
            // 絵文字
            Text(template.emoji)
                .font(.system(size: 32))

            // タイトル
            Button {
                startEditing(template)
            } label: {
                Text(template.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // 削除ボタン
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    deleteTemplate(template)
                }
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .pink], startPoint: .top, endPoint: .bottom)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }

    private func editingTemplateView(_ template: EventTemplate) -> some View {
        VStack(spacing: 16) {
            // タイトル入力
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(headerGradient)

                TextField("タイトル", text: $editTitle)
                    .focused($focusedField, equals: .editTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }

            // 絵文字選択
            VStack(alignment: .leading, spacing: 8) {
                Text("絵文字")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                editEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(editEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(editEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }

            // ボタン
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        editingTemplate = nil
                    }
                } label: {
                    Text("キャンセル")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                }

                Button {
                    saveEdit(template)
                } label: {
                    Text("保存")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(headerGradient)
                        .clipShape(Capsule())
                        .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(editTitle.isEmpty)
                .opacity(editTitle.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 4)
        )
    }

    private var newTemplateView: some View {
        VStack(spacing: 16) {
            // タイトル入力
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(headerGradient)

                TextField("新しい項目", text: $newTitle)
                    .focused($focusedField, equals: .newTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }

            // 絵文字選択
            VStack(alignment: .leading, spacing: 8) {
                Text("絵文字")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.black.opacity(0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                newEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(newEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(newEmoji == emoji ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
            }

            // ボタン
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAddingNew = false
                        resetNewTemplateFields()
                    }
                } label: {
                    Text("キャンセル")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(Capsule())
                }

                Button {
                    addNewTemplate()
                } label: {
                    Text("追加")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(headerGradient)
                        .clipShape(Capsule())
                        .shadow(color: .pink.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(newTitle.isEmpty)
                .opacity(newTitle.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .purple.opacity(0.2), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Helper Methods

    private func addNewTemplate() {
        let template = EventTemplate(title: newTitle, emoji: newEmoji)
        withAnimation {
            modelContext.insert(template)
            isAddingNew = false
            resetNewTemplateFields()
        }
    }

    private func startEditing(_ template: EventTemplate) {
        withAnimation {
            editingTemplate = template
            editTitle = template.title
            editEmoji = template.emoji
            focusedField = .editTitle
        }
    }

    private func saveEdit(_ template: EventTemplate) {
        withAnimation {
            template.title = editTitle
            template.emoji = editEmoji
            editingTemplate = nil
        }
    }

    private func deleteTemplate(_ template: EventTemplate) {
        withAnimation {
            modelContext.delete(template)
        }
    }

    private func resetNewTemplateFields() {
        newTitle = ""
        newEmoji = "📝"
    }
}

#Preview {
    TemplateManagementView()
        .modelContainer(for: EventTemplate.self, inMemory: true)
}
