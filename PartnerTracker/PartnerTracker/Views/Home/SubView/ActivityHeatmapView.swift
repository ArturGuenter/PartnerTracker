//
//  ActivityHeatmapView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 06.08.25.
//

import SwiftUI

struct ActivityHeatmapView: View {
    let data: [Date: Int]
    
    @State private var displayedMonth: Date = Date()
    
    var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag
        cal.timeZone = TimeZone.current
        return cal
    }
    
    
    var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    }
    
   
    var currentMonthDates: [Date] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        return range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: monthStart)
        }
    }
    
    
    var weeksInMonth: [[Date]] {
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        
        for date in currentMonthDates {
            let weekday = calendar.component(.weekday, from: date)
            if weekday == calendar.firstWeekday && !currentWeek.isEmpty {
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(date)
        }
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }
        
        return weeks.map { week in
            var padded = week
            while padded.count < 7 {
                padded.append(Date.distantPast)
            }
            return padded
        }
    }
    
    var body: some View {
        VStack {
            
            HStack {
                Button(action: {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthTitle)
                    .font(.headline)
                Spacer()
                Button(action: {
                    if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
          
            HStack(alignment: .top, spacing: 4) {
                
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { offset in
                        let weekdaySymbols = calendar.shortWeekdaySymbols
                        let startIndex = (calendar.firstWeekday - 1 + offset) % 7
                        Text(weekdaySymbols[startIndex].prefix(2))
                            .font(.caption2)
                            .frame(height: 18)
                    }
                }
                
                // Kästchen pro Woche
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(weeksInMonth, id: \.self) { week in
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    let date = week[dayIndex]
                                    if date == Date.distantPast {
                                        Color.clear.frame(width: 18, height: 18)
                                    } else {
                                        let localDay = calendar.startOfDay(for: date)
                                        let count = data[localDay] ?? 0
                                        
                                        Rectangle()
                                            .fill(color(for: count))
                                            .frame(width: 18, height: 18)
                                            .cornerRadius(4)
                                            .overlay(
                                                Text(count > 0 ? "\(count)" : "")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.2)
        case 1: return Color.green.opacity(0.4)
        case 2: return Color.green.opacity(0.6)
        case 3...: return Color.green
        default: return Color.gray.opacity(0.2)
        }
    }
}


#Preview {
    ActivityHeatmapView(data: [Date(): 2])
}





