//
//  MusicScreen.swift
//  Relax
//
//  Created by Илья Кузнецов on 27.06.2024.
//

import SwiftUI
import AVKit
import Kingfisher

struct MusicScreen: View {
    @StateObject private var viewModel = MusicFilesViewModel()
    @State private var isShowing = false
    @State private var isScrolling = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                MusicHeaderView(isShowing: $isShowing)
                    .padding(.top)
                AllMusicPlaylists(isShowing: $isShowing)
                    .environmentObject(viewModel)
                    .modifier(ScrollTrackingModifier(isScrolling: $isScrolling))
            }
            .modifier(HeaderModifier(isScrolling: $isScrolling, title: "Музыка", activeDarkModel: $activeDarkModel, isShowing: $isShowing))
        }
        
        .padding(.bottom)
        .onAppear {
            isShowing = true
        }
        .onDisappear {
            isShowing = false
        }
        .refreshable {
            Task {
                await MainActor.run {
                    viewModel.fetchFiles()
                }
            }
        }
    }
}

struct MusicHeaderView: View {
    
    @Binding var isShowing: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        VStack {
            Text("Насладитесь успокаивающей музыкой, которая поможет вам снять стресс и найти внутреннее спокойствие.")
                .padding()
                .foregroundStyle(activeDarkModel ? .white : Color(uiColor: .init(red: 160/255,
                                                                                 green: 163/255,
                                                                                 blue: 177/255,
                                                                                 alpha: 1)))
                .font(.system(size: 20, weight: .light, design: .rounded))
                .multilineTextAlignment(.center)
                .offset(x: isShowing ? 0 : -1000)
                .animation(.bouncy, value: isShowing)
        }
        .padding(.vertical)
    }
}

struct AllMusicPlaylists: View {
    
    @EnvironmentObject private var musicViewModel: MusicFilesViewModel
    @State private var isSelected = false
    @State var selectedPlaylist: CourseAndPlaylistOfDayModel?
    @Binding var isShowing: Bool
    @AppStorage("toogleDarkMode") private var toogleDarkMode = false
    @AppStorage("activeDarkModel") private var activeDarkModel = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20, content: {
                    ForEach(musicViewModel.files, id: \.name) { file in
                        Button(action: {
                            isSelected = true
                            selectedPlaylist = file
                        }, label: {
                            VStack {
                                KFImage(URL(string: file.imageURL))
                                    .resizable()
                                    .placeholder {
                                        LoadingAnimationButton()
                                    }
                                    .scaledToFit()
                                    .clipShape(.rect(cornerRadius: 16))
                                    .padding(.horizontal)
                                    .frame(width: 200, height: 150)
                                
                                Text(file.name)
                                    .foregroundStyle(activeDarkModel ? .white : .black)
                                    .font(.system(size: 17, design: .rounded)).bold()
                                
                                Text("\(file.duration) мин.")
                                    .padding(.horizontal, 10)
                                    .foregroundStyle(Color(uiColor: .secondaryTextColor))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        })
                    }
                })
            }
            .offset(x: isShowing ? 0 : -1000)
            .animation(.bouncy, value: isShowing)
        }
        .navigationDestination(isPresented: $isSelected) {
            if let selectedPlaylist {
                ReadyCourseDetailView(course: selectedPlaylist)
            }
        }
    }
}
