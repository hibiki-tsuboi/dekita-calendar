//
//  ContentView.swift
//  DekitaCalendar
//
//  Created by Hibiki Tsuboi on 2025/11/12.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [CalendarEvent]
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingDayEvents = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]

    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月選択ヘッダー
                monthHeader

                // 曜日ヘッダー
                weekdayHeader

                // カレンダーグリッド
                calendarGrid

                Spacer()
            }
            .navigationTitle("できたカレンダー")
            .sheet(isPresented: $showingDayEvents) {
                if let date = selectedDate {
                    DayEventsView(date: date, events: eventsForDate(date))
                }
            }
        }
    }

    // MARK: - Views

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }

            Spacer()

            Text(currentMonthString)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
        }
        .padding()
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(day == "日" ? .red : day == "土" ? .blue : .primary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var calendarGrid: some View {
        let days = generateDaysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        events: eventsForDate(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        showingDayEvents = true
                    }
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

    private func generateDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var date = monthFirstWeek.start

        while days.count < 42 { // 6週間分
            days.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }

        return days
    }

    private func eventsForDate(_ date: Date) -> [CalendarEvent] {
        events.filter { event in
            calendar.isDate(event.date, inSameDayAs: date)
        }
    }

    private func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        withAnimation {
            currentMonth = newMonth
        }
    }

    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        withAnimation {
            currentMonth = newMonth
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let isCurrentMonth: Bool
    let isToday: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 16))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isCurrentMonth ? .primary : .gray)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isToday ? Color.blue.opacity(0.2) : Color.clear)
                )

            // イベントインジケーター
            if !events.isEmpty {
                HStack(spacing: 2) {
                    ForEach(events.prefix(3)) { event in
                        Circle()
                            .fill(event.isCompleted ? Color.green : Color.orange)
                            .frame(width: 4, height: 4)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Day Events View

struct DayEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let events: [CalendarEvent]
    @State private var showingAddEvent = false
    @State private var selectedEvent: CalendarEvent?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    Button(action: {
                        selectedEvent = event
                    }) {
                        HStack {
                            Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(event.isCompleted ? .green : .gray)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if !event.notes.isEmpty {
                                    Text(event.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteEvent(event)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            toggleComplete(event)
                        } label: {
                            Label(event.isCompleted ? "未完了" : "完了",
                                  systemImage: event.isCompleted ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(event.isCompleted ? .orange : .green)
                    }
                }
            }
            .navigationTitle(dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddEvent = true }) {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(date: date)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
        }
    }

    private func toggleComplete(_ event: CalendarEvent) {
        withAnimation {
            event.isCompleted.toggle()
        }
    }

    private func deleteEvent(_ event: CalendarEvent) {
        withAnimation {
            modelContext.delete(event)
        }
    }
}

// MARK: - Add Event View

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let date: Date
    @State private var title = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("イベント名", text: $title)

                    DatePicker("日付", selection: .constant(date), displayedComponents: .date)
                        .disabled(true)
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("イベントを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addEvent() {
        let event = CalendarEvent(title: title, date: date, notes: notes)
        modelContext.insert(event)
        dismiss()
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var event: CalendarEvent
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedNotes: String

    init(event: CalendarEvent) {
        self._event = State(initialValue: event)
        self._editedTitle = State(initialValue: event.title)
        self._editedNotes = State(initialValue: event.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isEditing {
                        TextField("イベント名", text: $editedTitle)
                    } else {
                        HStack {
                            Text("イベント名")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(event.title)
                        }
                    }

                    HStack {
                        Text("日付")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.date, format: .dateTime.year().month().day())
                    }

                    HStack {
                        Text("ステータス")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(event.isCompleted ? "完了" : "未完了")
                            .foregroundColor(event.isCompleted ? .green : .orange)
                    }
                }

                Section("メモ") {
                    if isEditing {
                        TextEditor(text: $editedNotes)
                            .frame(height: 100)
                    } else {
                        Text(event.notes.isEmpty ? "メモなし" : event.notes)
                            .foregroundColor(event.notes.isEmpty ? .secondary : .primary)
                    }
                }

                if !isEditing {
                    Section {
                        Button(action: {
                            event.isCompleted.toggle()
                        }) {
                            Label(
                                event.isCompleted ? "未完了にする" : "完了にする",
                                systemImage: event.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }

                        Button(role: .destructive, action: deleteEvent) {
                            Label("イベントを削除", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("イベント詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "キャンセル" : "閉じる") {
                        if isEditing {
                            editedTitle = event.title
                            editedNotes = event.notes
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "完了" : "編集") {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    }
                    .disabled(isEditing && editedTitle.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        event.title = editedTitle
        event.notes = editedNotes
        isEditing = false
    }

    private func deleteEvent() {
        modelContext.delete(event)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CalendarEvent.self, inMemory: true)
}
