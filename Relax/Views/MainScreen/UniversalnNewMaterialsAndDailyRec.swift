//
//  UniversalnNewMaterialsAndDailyRec.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 24.10.2024.
//

import SwiftUI
import Kingfisher

//MARK: - UniversalnNewMaterialsAndDailyRec
struct UniversalnNewMaterialsAndDailyRec<T: Identifiable>: View {
    
    let title: String
    let subtitle: String
    let items: [T]
    let colorProvider: (T) -> UIColor
    let imageProvider: (T) -> String
    let nameProvider: (T) -> String
    let durationProvider: (T) -> String
    let destinationViewProvider: (T) -> AnyView
    let isNewMaterial: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    @State private var isSelected = false
    @State private var selectedItem: T?
    @State private var isMovingAround = true
    @Binding var isShowing: Bool
    
    private let currentDate: String = {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "dd.MM"
        return df.string(from: date)
    }()
    
    var body: some View {
        NavigationStack {
            VStack {
                Group {
                    HStack {
                        Text(title)
                            .foregroundStyle(activeDarkModel ? .white : .black)
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 17, weight: .light, design: .rounded))
                            .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 161/255,
                                                                                             green: 164/255,
                                                                                             blue: 178/255,
                                                                                             alpha: 1)))
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .offset(y: isShowing ? 0 : -700)
                .animation(.bouncy, value: isShowing)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    
                    LazyHGrid(rows: [GridItem(.flexible())], spacing: 0, content: {
                        ForEach(items, id: \.id) { item in
                            Button {
                                selectedItem = item
                                isSelected = true
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(uiColor: colorProvider(item)))
                                        .frame(maxWidth: .infinity)
                                    
                                    VStack {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(isNewMaterial ? .yellow : .red)
                                                    .frame(maxWidth: 60, maxHeight: 40)
                                                    .shadow(radius: 5)
                                                    .overlay {
                                                        Text(isNewMaterial ? "NEW" : currentDate)
                                                            .bold()
                                                            .frame(height: 40)
                                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    }
                                                if isNewMaterial {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .strokeBorder(style: StrokeStyle(lineWidth: 4,
                                                                                         lineCap: .round,
                                                                                         lineJoin: .round,
                                                                                         dash: [40, 400],
                                                                                         dashPhase: isMovingAround ? 220 : -200))
                                                        .frame(maxWidth: 60, maxHeight: 40)
                                                        .foregroundStyle(
                                                            LinearGradient(gradient: .init(colors: [.indigo, .white, .purple, .mint, .white, .orange, .indigo]),
                                                                           startPoint: .trailing,
                                                                           endPoint: .leading))
                                                }
                                            }
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    
                                    VStack {
                                        HStack {
                                            Spacer()
                                            KFImage(URL(string: imageProvider(item)))
                                                .resizable()
                                                .placeholder {
                                                    LoadingAnimationButton()
                                                }
                                                .scaledToFit()
                                                .frame(width: 200, height: 150)
                                        }
                                        Spacer()
                                        
                                        if isNewMaterial {
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.yellow)
                                                .frame(height: 50)
                                                .shadow(radius: 5)
                                                .overlay {
                                                    Text(nameProvider(item))
                                                        .padding(.horizontal)
                                                        .foregroundStyle(.white)
                                                        .minimumScaleFactor(0.8)
                                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                                        .multilineTextAlignment(.center)
                                                }
                                                .padding(.horizontal)
                                        } else {
                                            HStack {
                                                Text(nameProvider(item))
                                                    .padding(.horizontal)
                                                    .foregroundStyle(.white)
                                                    .minimumScaleFactor(0.8)
                                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                                    .multilineTextAlignment(.leading)
                                                Spacer()
                                            }
                                        }
                                        
                                        if !isNewMaterial {
                                            HStack {
                                                Spacer()
                                                Text(durationProvider(item) + " " + "мин.")
                                                    .padding(.horizontal)
                                                    .foregroundStyle(.white)
                                                    .font(.system(size: 15, design: .rounded))
                                                    .shadow(radius: 7)
                                                
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.white)
                                                    .frame(width: 80, height: 40)
                                                    .overlay {
                                                        Text("Начать")
                                                            .foregroundStyle(.black)
                                                            .font(.system(size: 18, design: .rounded))
                                                    }
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                            .clipShape(.rect(cornerRadius: 20))
                            .padding(.horizontal)
                            .frame(width: items.count > 1 ? UIScreen.main.bounds.width * 0.9 : UIScreen.main.bounds.width)
                        }
                    })
                    .frame(maxWidth: .infinity)
                    .offset(x: isShowing ? 0 : 700)
                    .animation(.bouncy, value: isShowing)
                    .navigationDestination(isPresented: $isSelected) {
                        if let selectedItem = selectedItem {
                            destinationViewProvider(selectedItem)
                        }
                    }
                }
            }
            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isMovingAround)
            .padding(.vertical)
            .offset(x: isShowing ? 0 : 700)
            .animation(.bouncy, value: isShowing)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isMovingAround = false
            }
        }
    }
}
