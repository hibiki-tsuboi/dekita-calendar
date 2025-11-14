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

    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.6, blue: 0.8), Color(red: 0.6, green: 0.8, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private var allEventsCompleted: Bool {
        !events.isEmpty && events.allSatisfy { $0.isCompleted }
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
            ZStack {
                // ポップな背景
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
                    VStack(spacing: 8) {
                        Text(dateString)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            )

                        // 全部完了している場合のお祝いメッセージ
                        if allEventsCompleted {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("すべて完了！")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.white)
                                    .shadow(color: .orange.opacity(0.3), radius: 8)
                            )
                        }
                    }
                    .padding(.top)

                    // イベントリスト
                    ScrollView {
                        VStack(spacing: 12) {
                            if events.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(.purple)

                                    Text("まだイベントがありません")
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
                            } else {
                                ForEach(events) { event in
                                    if editingEvent?.id == event.id {
                                        // 編集モード
                                        editingEventView(event)
                                    } else {
                                        // 表示モード
                                        eventRow(event)
                                    }
                                }
                            }

                            // 新規イベント追加エリア
                            if isAddingNew {
                                newEventView
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
            .onAppear {
                loadEvents()
            }
            .onChange(of: allEvents) {
                loadEvents()
            }
        }
    }

    // MARK: - Subviews

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(
                    event.isCompleted ?
                        LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.orange, .pink], startPoint: .top, endPoint: .bottom)
                )

            // イベント名
            Button {
                startEditing(event)
            } label: {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .strikethrough(event.isCompleted, color: .gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            // トグル
            Toggle("", isOn: Binding(
                get: { event.isCompleted },
                set: { newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        event.isCompleted = newValue
                    }
                }
            ))
            .labelsHidden()
            .tint(.green)

            // 削除ボタン
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    deleteEvent(event)
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

    private func editingEventView(_ event: CalendarEvent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(headerGradient)

                TextField("イベント名", text: $editingTitle)
                    .focused($focusedField, equals: .editTitle(event))
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        editingEvent = nil
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
                    saveEdit(event)
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
                .disabled(editingTitle.isEmpty)
                .opacity(editingTitle.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .blue.opacity(0.2), radius: 12, x: 0, y: 4)
        )
    }

    private var newEventView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(headerGradient)

                TextField("新しいイベント", text: $newEventTitle)
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

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAddingNew = false
                        newEventTitle = ""
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
                    addNewEvent()
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
                .disabled(newEventTitle.isEmpty)
                .opacity(newEventTitle.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .purple.opacity(0.2), radius: 12, x: 0, y: 4)
        )
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
