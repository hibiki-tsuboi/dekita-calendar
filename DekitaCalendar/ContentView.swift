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
    @State private var bounceAnimation = false

    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    
    // ポップなカラーパレット
    private let headerGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.6, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 楽しい背景
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.85),
                        Color(red: 0.9, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // 月選択ヘッダー
                    monthHeader

                    // 曜日ヘッダー
                    weekdayHeader

                    // カレンダーグリッド
                    calendarGrid

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedDate != nil },
                set: { if !$0 { selectedDate = nil } }
            )) {
                if let date = selectedDate {
                    DayEventsView(date: date)
                }
            }
        }
        .persistentSystemOverlays(.hidden)
    }

    // MARK: - Views

    private var monthHeader: some View {
        HStack(spacing: 20) {
            Button(action: previousMonth) {
                Image(systemName: "arrow.left.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(headerGradient)
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Text(currentMonthString)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(headerGradient)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(headerGradient)
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 2) {
                    // 曜日の絵文字
                    Text(dayEmoji(for: index))
                        .font(.system(size: 18))
                    
                    Text(day)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            day == "日" ? 
                                LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom) :
                            day == "土" ? 
                                LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.7))
        )
        .padding(.horizontal)
    }
    
    private func dayEmoji(for index: Int) -> String {
        let emojis = ["☀️", "🌙", "🔥", "💧", "🌳", "⭐", "🌈"]
        return emojis[index]
    }

    private var calendarGrid: some View {
        let days = generateDaysInMonth()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedDate = date
                        }
                    } label: {
                        DayCell(
                            date: date,
                            events: eventsForDate(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            isToday: calendar.isDateInToday(date)
                        )
                    }
                    .buttonStyle(DayCellButtonStyle())
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.5))
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
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

// MARK: - Day Cell Button Style

struct DayCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let events: [CalendarEvent]
    let isCurrentMonth: Bool
    let isToday: Bool
    
    @State private var showCelebration = false
    
    private let calendar = Calendar.current

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var allEventsCompleted: Bool {
        !events.isEmpty && events.allSatisfy { $0.isCompleted }
    }
    
    private var weekday: Int {
        calendar.component(.weekday, from: date)
    }
    
    private var isSunday: Bool {
        weekday == 1
    }
    
    private var isSaturday: Bool {
        weekday == 7
    }
    
    private var dayNumberColor: LinearGradient {
        if !isCurrentMonth {
            return LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
        }
        
        if isToday {
            return LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
        }
        
        if isSunday {
            return LinearGradient(colors: [.red], startPoint: .top, endPoint: .bottom)
        }
        
        if isSaturday {
            return LinearGradient(colors: [.blue], startPoint: .top, endPoint: .bottom)
        }
        
        return LinearGradient(colors: [.black], startPoint: .top, endPoint: .bottom)
    }
    
    private var cellGradient: LinearGradient {
        if isToday {
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.8, blue: 1.0), Color(red: 0.8, green: 0.6, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.white, Color(red: 0.98, green: 0.98, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 18, weight: isToday ? .black : .bold, design: .rounded))
                .foregroundStyle(dayNumberColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isToday ? Color.yellow.opacity(0.3) : Color.clear)
                        .overlay(
                            Circle()
                                .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
                        )
                )

            // 全てのイベントが完了したら超大きなキラキラ星を表示
            if allEventsCompleted {
                ZStack {
                    // 輝きエフェクト
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(showCelebration ? 360 : 0))
                        .scaleEffect(showCelebration ? 1.2 : 0.8)
                        .opacity(showCelebration ? 0.8 : 0.4)
                    
                    // メインの星
                    Image(systemName: "star.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 2)
                        .scaleEffect(showCelebration ? 1.1 : 1.0)
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        showCelebration = true
                    }
                }
            } else if !events.isEmpty {
                // イベントインジケーター（未完了がある場合）
                HStack(spacing: 3) {
                    ForEach(events.prefix(3)) { event in
                        Circle()
                            .fill(
                                event.isCompleted ? 
                                    LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: 6, height: 6)
                            .shadow(color: event.isCompleted ? .green.opacity(0.5) : .orange.opacity(0.5), radius: 2)
                    }
                }
                .padding(.bottom, 4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cellGradient)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
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
