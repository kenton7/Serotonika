//
//  UniversalGridScreen.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 21.10.2024.
//

import SwiftUI
import Kingfisher

//MARK: - UniversalGridScreen
struct UniversalGridScreen<T: Identifiable>: View {
    
    let title: String
    let items: [T]
    let isNightStories: Bool
    let colorProvider: (T) -> UIColor
    let imageProvider: (T) -> String
    let nameProvider: (T) -> String
    let destinationViewProvider: (T) -> AnyView
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    @Environment(\.currentTab) private var selectedTab
    
    @State private var isSelected = false
    @State private var selectedItem: T?
    @Binding var isShowing: Bool
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .padding(.top)
                        .padding(.horizontal)
                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                         green: 65/255,
                                                                                         blue: 78/255,
                                                                                         alpha: 1)))
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(230))], spacing: 0, content: {
                        ForEach(items, id: \.id) { item in
                            Button(action: {
                                selectedItem = item
                                isSelected = true
                            }, label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    ZStack {
                                        Color(uiColor: colorProvider(item))
                                        
                                        KFImage(URL(string: imageProvider(item)))
                                            .resizable()
                                            .placeholder {
                                                LoadingAnimationButton()
                                            }
                                            .scaledToFill()
                                            .clipShape(.rect(cornerRadius: 10))
                                    }
                                    .frame(width: 200, height: 150)
                                    .clipShape(.rect(cornerRadius: 10))
                                    
                                    Text(nameProvider(item))
                                        .padding(.top)
                                        .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 63/255,
                                                                                                         green: 65/255,
                                                                                                         blue: 78/255,
                                                                                                         alpha: 1)))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .frame(maxWidth: 200, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)  // Позволяет тексту расширяться по вертикали
                                    
                                }
                            })
                            .padding(.horizontal)
                        }
                        if isNightStories {
                            Button {
                                selectedTab.wrappedValue = .sleep
                            } label: {
                                ZStack {
                                    Circle()
                                        .frame(width: 70, height: 70)
                                        .foregroundStyle(Color.indigo)
                                    Text("См. \nвсё")
                                        .foregroundStyle(.white)
                                        .font(.system(size: 15, design: .rounded)).bold()
                                }
                            }
                            .padding(.horizontal)
                        }
                    })
                }
            }
            .offset(x: isShowing ? 0 : 700)
            .animation(.bouncy, value: isShowing)
            .navigationDestination(isPresented: $isSelected) {
                if let selectedItem = selectedItem {
                    destinationViewProvider(selectedItem)
                }
            }
        }
        .padding(.bottom)
    }
}
