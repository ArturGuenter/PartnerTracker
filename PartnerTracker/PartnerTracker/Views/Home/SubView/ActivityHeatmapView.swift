//
//  ActivityHeatmapView.swift
//  PartnerTracker
//
//  Created by Artur Günter on 06.08.25.
//

import SwiftUI


struct ActivityHeatmapView: View {
    let data: [Date: Int]
    
    var calendar: Calendar {
            var cal = Calendar(identifier: .gregorian)
            cal.firstWeekday = 2 
            cal.timeZone = TimeZone.current
            return cal
        }
    
    var currentMonthDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        let range = calendar.range(of: .day, in: .month, for: today)!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        
        return range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: monthStart)
        }
    }
    
    var weeksInMonth: [[Date]] {
        var weeks: [[Date]] = []
        var currentWeek: [Date] = []
        
        let allDates = currentMonthDates
        
        for date in allDates {
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
            var paddedWeek = week
            while paddedWeek.count < 7 {
                paddedWeek.append(Date.distantPast)
            }
            return paddedWeek
        }
    }
    
    var body: some View {
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
            
        
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(weeksInMonth, id: \.self) { week in
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { dayIndex in
                                let date = week[dayIndex]
                                if date == Date.distantPast {
                                    Color.clear.frame(width: 18, height: 18)
                                } else {
                                    let count = data[calendar.startOfDay(for: date)] ?? 0
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




#Preview {
    ActivityHeatmapView(data: [Date() : 2])
}
