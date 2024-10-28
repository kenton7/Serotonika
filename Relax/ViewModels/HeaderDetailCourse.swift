//
//  HeaderDetailCourse.swift
//  Relax
//
//  Created by Илья Кузнецов on 04.07.2024.
//

import SwiftUI
import Kingfisher

struct AnyShape: Shape, @unchecked Sendable {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ wrapped: S) {
        self.path = { rect in
            wrapped.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

final class HeaderDetailCourse: ObservableObject {
    
    @Published var offsetY: CGFloat = .zero
    
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    @ViewBuilder
    func createHeaderView(course: CourseAndPlaylistOfDayModel, size: CGSize, safeArea: EdgeInsets) -> some View {
        let headerHeight = (size.height * 0.30) + safeArea.top
        let minimumHeaderHeight = 64 + safeArea.top
        let progress = max(min(-offsetY / (headerHeight - minimumHeaderHeight), 1), 0)
        
        GeometryReader { _ in
            ZStack {
                if course.type == .story {
                    Color(uiColor: .init(red: 3/255, green: 23/255, blue: 76/255, alpha: 1)).ignoresSafeArea()
                }
                Rectangle()
                    .fill(Color(uiColor: .init(red: CGFloat(course.color.red) / 255,
                                               green: CGFloat(course.color.green) / 255,
                                               blue: CGFloat(course.color.blue) / 255,
                                               alpha: 1)))
                    .clipShape(.rect(topLeadingRadius: 0,
                                     bottomLeadingRadius: 16,
                                     bottomTrailingRadius: 16,
                                     topTrailingRadius: 0,
                                     style: .continuous))
                    //.shadow(color: .black.opacity(0.7), radius: 5, x: 0, y: 3)
                    .shadow(color: self.activeDarkModel ? .gray.opacity(0.7) : .black.opacity(0.7), radius: 5, x: 0, y: 3)

                
                VStack(spacing: 15) {
                    GeometryReader {
                        let rect = $0.frame(in: .global)
                        
//                        let halfScaledHeight = (rect.height * 0.2) * 0.5
//                        let midY = rect.midY
//                        
//                        let bottomPadding: CGFloat = 16
                        //let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledHeight - bottomPadding))
                        KFImage(URL(string: course.imageURL))
                            .resizable()
                            .placeholder {
                                LoadingAnimationButton()
                            }
                            .frame(width: rect.width, height: rect.height)
                            .clipShape(self.offsetY < 0 ? AnyShape(.circle) : AnyShape(.rect(bottomLeadingRadius: 16, bottomTrailingRadius: 16, style: .circular)))
                            .scaleEffect(1 - (progress * 0.5), anchor: .center)
                            .padding(.top, self.offsetY < 0 ? 16 : 0)
                    }
                    .onChange(of: progress) { newValue in
                        if self.offsetY > 0 {
                            self.offsetY = .zero
                        }
                        let impactMed = UIImpactFeedbackGenerator(style: .soft)
                        impactMed.impactOccurred()
                    }
                }
            }
            .shadow(color: self.activeDarkModel ? .gray.opacity(0.2) : .black.opacity(0.2), radius: 25)
            .frame(height: max((headerHeight + self.offsetY), minimumHeaderHeight), alignment: .bottom)
            
        }
        .frame(height: headerHeight, alignment: .bottom)
        .offset(y: -offsetY)
    }
    
    //данная функция создает эффект "инерции"
    func needToScroll(offset: CGFloat, velocity: CGFloat, safeArea: EdgeInsets, size: CGSize) -> Bool {
        let headerHeight = (size.height * 0.10) + safeArea.top
        let minimumHeaderHeight = 64 + safeArea.top
        let targetEnd = offset + (velocity * 45)
        return targetEnd < (headerHeight - minimumHeaderHeight) && targetEnd > 0
    }
}

