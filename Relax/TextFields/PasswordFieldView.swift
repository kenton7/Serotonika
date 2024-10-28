//
//  PasswordFieldView.swift
//  Relax
//
//  Created by Илья Кузнецов on 21.06.2024.
//

import SwiftUI

struct PasswordFieldView: View {
    
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    @FocusState private var isFocused: Bool
    
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isSecured {
                ZStack(alignment: .leading) {
                SecureField("", text: $text)
                    .padding()
                    .background(activeDarkModel ? Color(uiColor: .init(red: 41/255,
                                                                       green: 42/255,
                                                                       blue: 47/255,
                                                                       alpha: 1)) : Color(uiColor: .init(red: 242/255, green: 243/255, blue: 247/255, alpha: 1)))
                    .clipShape(.rect(cornerRadius: 8))
                    .padding()
                    .autocorrectionDisabled(true)
                    .focused($isFocused)
                    .onTapGesture {
                        isFocused = true
                    }
                
                Text(title)
                    .padding()
                    .offset(x: 10)
                    .offset(y: (isFocused || !text.isEmpty) ? -40 : 0)
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .animation(.spring, value: isFocused)
            }
                } else {
                    ZStack(alignment: .leading) {
                        TextField("", text: $text)
                            .padding()
                            .background(activeDarkModel ? Color(uiColor: .init(red: 41/255,
                                                                               green: 42/255,
                                                                               blue: 47/255,
                                                                               alpha: 1)) : Color(uiColor: .init(red: 242/255, green: 243/255, blue: 247/255, alpha: 1)))
                            .clipShape(.rect(cornerRadius: 8))
                            .padding()
                            .autocorrectionDisabled(true)
                            .focused($isFocused)
                            .onTapGesture {
                                isFocused = true
                            }
                        
                        Text(title)
                            .padding()
                            .offset(x: 10)
                            .offset(y: (isFocused || !text.isEmpty) ? -40 : 0)
                            .foregroundStyle(isFocused && activeDarkModel ? .white : .secondary)
                            .foregroundStyle(isFocused ? .black : .secondary)
                            .animation(.spring, value: isFocused)
                    }
                }
                
                Button(action: {
                    isSecured.toggle()
                }) {
                    Image(systemName: isSecured ? "eye.slash" : "eye")
                        .padding(.horizontal)
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal)
        }
        .font(.system(size: 17, weight: .light, design: .rounded))
    }
}

