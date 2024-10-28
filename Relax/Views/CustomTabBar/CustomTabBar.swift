//
//  CustomTabBar.swift
//  Relax
//
//  Created by Илья Кузнецов on 11.07.2024.
//

import SwiftUI
import UIKit

//MARK: - CurrentTabKey
struct CurrentTabKey: EnvironmentKey {
    static let defaultValue: Binding<TabbedItems> = .constant(.home)
}

private struct TabsEnvironmentKey: EnvironmentKey {
    static let defaultValue: [TabbedItems] = []
}

extension EnvironmentValues {
    var tabs: [TabbedItems] {
        get { self[TabsEnvironmentKey.self] }
        set { self[TabsEnvironmentKey.self] = newValue }
    }
}


enum TabbedItems: Hashable, CaseIterable {
    case home
    case sleep
    case meditation
    case music
    case profile
    
    var title: String {
        switch self {
        case .home:
            return "Главная"
        case .sleep:
            return "Сон"
        case .meditation:
            return "Медитация"
        case .music:
            return "Музыка"
        case .profile:
            return "Профиль"
        }
    }
    
    var iconName: String {
        switch self {
        case .home:
            return "house"
        case .sleep:
            return "powersleep"
        case .meditation:
            return "figure.mind.and.body"
        case .music:
            return "music.note"
        case .profile:
            return "person.fill"
        }
    }    
}

extension TabbedItems {
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .home:
            HomeScreen()
        case .sleep:
            SleepScreen()
        case .meditation:
            MeditationScreen()
        case .music:
            MusicScreen()
                .tint(.black)
        case .profile:
            ProfileScreen()
                .tint(.black)
                .environmentObject(EmailService())
        }
    }
}

struct CustomTabBar: View {
    
    @State private var selection: TabbedItems = .home
    @StateObject private var config2 = PlayerConfig2.shared
    
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    private let tabBarHeight: CGFloat = 65
    
    private var selectionBinding: Binding<TabbedItems> {
            Binding(get: {
                selection
            }, set: {
                if $0 == selection {
                    /*
                     Сброс навигационного стека до корневого экрана:

                     Для этого кода используется стандартный метод UIKit для нахождения текущего окна приложения:
                     (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first — находит первое окно текущей сцены.
                     Затем с помощью расширения recursiveChildren() находим первый UINavigationController, который отображается в этом окне.
                     Наконец, вызываем метод popToRootViewController(animated: true) на navigationController, чтобы сбросить стек до корневого экрана.
                     */
                    let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
                    let navigationController = window?.rootViewController?.recursiveChildren().first(where: { $0 is UINavigationController && $0.view.window != nil }) as? UINavigationController
                    navigationController?.popToRootViewController(animated: true)
                }
                selection = $0
            })
        }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: selectionBinding) {
                ForEach(TabbedItems.allCases, id: \.self) { screen in
                    screen.destination
                        .tag(selectionBinding.wrappedValue as TabbedItems?)
                }
            }
            .environment(\.currentTab, $selection)
            
            HStack(spacing: 10) {
                ForEach(TabbedItems.allCases, id: \.self) { tab in
                    Button {
                        withAnimation {
                            selectionBinding.wrappedValue = tab
                        }
                    } label: {
                        customTabItem(imageName: tab.iconName,
                                      title: tab.title,
                                      isActive: (selectionBinding.wrappedValue == tab as TabbedItems?)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: tabBarHeight)
            .background(
                withAnimation(.easeInOut(duration: 0.7), {
                    selectionBinding.wrappedValue == .sleep ? Color(uiColor: .init(red: 3/255,
                                                               green: 23/255,
                                                               blue: 77/255,
                                                               alpha: 1)) : toogleDarkMode ? .black : .white
                })
            )
        }
        .shadow(color: activeDarkModel ? .white.opacity(0.4) : .black.opacity(0.4), radius: 10, x: 0, y: 5)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

extension CustomTabBar {
    
    @ViewBuilder
    func customTabItem(imageName: String, title: String, isActive: Bool) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(isActive ? Color(uiColor: .init(red: 142/255,
                                                          green: 151/255,
                                                          blue: 253/255,
                                                          alpha: 1)) : .clear)
                    .frame(width: 40, height: 40)
                
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(isActive ? .white : .gray).bold()
            }
            .frame(height: 50)
            
            Text(title)
                .padding(.horizontal, 0)
                .foregroundStyle((isActive && selection == .sleep) ? .white
                                 : (isActive && selection != .sleep ?
                                    Color(uiColor: .init(red: 142/255,
                                                         green: 151/255,
                                                         blue: 253/255,
                                                         alpha: 1))
                                    : .gray))
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
    }
}


extension UIViewController {
    //Предназначен для получения всех вложенных дочерних представлений (child view controllers) во всех иерархиях UIViewController.
    /*
     Как это работает:
     children: UIViewController имеет свойство children, которое возвращает массив всех дочерних представлений текущего контроллера.
     flatMap: Для каждого дочернего представления (child view controller), мы рекурсивно вызываем метод recursiveChildren(), чтобы получить всех его дочерних потомков.
     Рекурсия: Метод recursiveChildren() вызывает сам себя для каждого дочернего представления, что позволяет пройти по всей иерархии UIViewController и собрать все UIViewController в одном массиве.
     Этот метод используется для поиска всех дочерних контроллеров в иерархии представлений, чтобы потом найти нужный UINavigationController
     */
    func recursiveChildren() -> [UIViewController] {
        return children + children.flatMap({ $0.recursiveChildren() })
    }
}
