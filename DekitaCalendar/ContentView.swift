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
                    DayEventsView(date: date)
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

    private var allEventsCompleted: Bool {
        !events.isEmpty && events.allSatisfy { $0.isCompleted }
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

            // 全てのイベントが完了したら大きな星マークを表示
            if allEventsCompleted {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 3)
            } else if !events.isEmpty {
                // イベントインジケーター（未完了がある場合のみ表示）
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
    @Query private var allEvents: [CalendarEvent]

    let date: Date
    @State private var events: [CalendarEvent] = []
    @State private var editingEvent: CalendarEvent?
    @State private var editingTitle: String = ""
    @State private var isAddingNew = false
    @State private var newEventTitle = ""
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case newTitle
        case editTitle(CalendarEvent)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func loadEvents() {
        events = allEvents
            .filter { event in
                Calendar.current.isDate(event.date, inSameDayAs: date)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                // イベントリスト
                Section {
                    if events.isEmpty {
                        Text("イベントがありません")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(events) { event in
                            if editingEvent?.id == event.id {
                                // 編集モード
                                VStack(spacing: 8) {
                                    HStack {
                                        TextField("イベント名", text: $editingTitle)
                                            .focused($focusedField, equals: .editTitle(event))
                                            .textFieldStyle(.plain)
                                            .font(.headline)
                                        
                                        Toggle("", isOn: Binding(
                                            get: { event.isCompleted },
                                            set: { newValue in
                                                withAnimation {
                                                    event.isCompleted = newValue
                                                }
                                            }
                                        ))
                                        .labelsHidden()
                                    }
                                    
                                    HStack {
                                        Button("キャンセル") {
                                            withAnimation {
                                                editingEvent = nil
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Spacer()
                                        
                                        Button("保存") {
                                            saveEdit(event)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(editingTitle.isEmpty)
                                    }
                                }
                                .padding(.vertical, 4)
                            } else {
                                // 表示モード
                                HStack {
                                    Button(action: {
                                        startEditing(event)
                                    }) {
                                        Text(event.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Toggle("", isOn: Binding(
                                        get: { event.isCompleted },
                                        set: { newValue in
                                            withAnimation {
                                                event.isCompleted = newValue
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEvent(event)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 新規イベント追加セクション（インライン）
                if isAddingNew {
                    Section {
                        VStack(spacing: 8) {
                            TextField("イベント名", text: $newEventTitle)
                                .focused($focusedField, equals: .newTitle)
                                .textFieldStyle(.plain)
                                .font(.headline)
                            
                            HStack {
                                Button("キャンセル") {
                                    withAnimation {
                                        isAddingNew = false
                                        newEventTitle = ""
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button("追加") {
                                    addNewEvent()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newEventTitle.isEmpty)
                            }
                        }
                        .padding(.vertical, 4)
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
                    Button(action: {
                        withAnimation {
                            isAddingNew = true
                            focusedField = .newTitle
                        }
                    }) {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                loadEvents()
            }
            .onChange(of: allEvents) {
                loadEvents()
            }
        }
    }

    private func addNewEvent() {
        let event = CalendarEvent(title: newEventTitle, date: date, notes: "")
        withAnimation {
            modelContext.insert(event)
            isAddingNew = false
            newEventTitle = ""
        }
    }

    private func startEditing(_ event: CalendarEvent) {
        withAnimation {
            editingEvent = event
            editingTitle = event.title
            focusedField = .editTitle(event)
        }
    }

    private func saveEdit(_ event: CalendarEvent) {
        withAnimation {
            event.title = editingTitle
            editingEvent = nil
        }
    }

    private func deleteEvent(_ event: CalendarEvent) {
        withAnimation {
            modelContext.delete(event)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CalendarEvent.self, inMemory: true)
}
