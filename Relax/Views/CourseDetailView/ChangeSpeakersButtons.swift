//
//  ChangeSpeakersButtons.swift
//  Relax
//
//  Created by Илья Кузнецов on 05.07.2024.
//

import SwiftUI

struct ChangeSpeakersButtons: View {
    
    let course: CourseAndPlaylistOfDayModel
    @Binding var isFemale: Bool
    
    var body: some View {
        VStack {
            if course.type != .playlist {
                HStack {
                    Button(action: {
                        withAnimation {
                            isFemale = true
                        }
                    }, label: {
                        Text("Женский")
                            .underline(color: isFemale ? Color(uiColor: .init(red: 142/255,
                                                                              green: 151/255,
                                                                              blue: 253/255,
                                                                              alpha: 1)) : .clear)
                            .foregroundStyle(isFemale ? Color(uiColor: .init(red: 142/255,
                                                                             green: 151/255,
                                                                             blue: 253/255,
                                                                             alpha: 1)) : Color(uiColor: .init(red: 161/255,
                                                                                                               green: 164/255,
                                                                                                               blue: 178/255, alpha: 1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        
                    })
                    .padding()
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        withAnimation {
                            isFemale = false
                        }
                    }, label: {
                        Text("Мужской")
                            .underline(color: isFemale == false ? Color(uiColor: .init(red: 142/255,
                                                                                       green: 151/255,
                                                                                       blue: 253/255,
                                                                                       alpha: 1)) : .clear)
                            .foregroundStyle(isFemale == false  ? Color(uiColor: .init(red: 142/255,
                                                                                       green: 151/255,
                                                                                       blue: 253/255,
                                                                                       alpha: 1)) : Color(uiColor: .init(red: 161/255,
                                                                                                                         green: 164/255,
                                                                                                                         blue: 178/255, alpha: 1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    })
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
            Divider()
        }
    }
}


