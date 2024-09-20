//
//  SwiftUIView.swift
//  swiftuiVideoPlayer
//
//  Created by Василий Гуркин on 13.08.2024.
//

import SwiftUI
import AVKit

struct MainView: View {
    
    var size: CGSize
    var safeArea: EdgeInsets
    
    @State private var player: AVPlayer? = {
        guard let path = Bundle.main.path(forResource: "IMG_9085", ofType: "MOV") else {
            return nil
        }
        let url = URL(filePath: path)
        let player = AVPlayer(url: url)
        return player
    } ()
    
    @State private var isPlaying = false
    @State private var showControls = false
    @State private var timeoutTask: DispatchWorkItem?
    
    // Slider properties
    @State private var isSeeking = false
    @State private var isVideoFinished = false
    @State private var progress: CGFloat = 0
    @State private var lastProgress: CGFloat = 0
    @GestureState private var isDragging = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            let playerSize = CGSize(width: size.width, height: size.height/3.4)
            
            ZStack{
                if let player {
                    VideoPlayer(player: player)
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showControls ? 1 : 0)
                                .animation(.easeInOut, value: isDragging)
                                .overlay{
                                    if showControls {
                                        playControls()
                                    }
                                }
                        }.onTapGesture {
                            withAnimation {
                                showControls.toggle()
                            }
                        }.overlay(alignment: .bottom) {
                            sliderView(forVideoSize: playerSize)
                        }
                }
            }.frame(width: playerSize.width, height: playerSize.height)
        }
        .padding(.top, safeArea.top)
        .onAppear {
            addTimeObservers()
        }
        Spacer()
    }
    
    @ViewBuilder private func playControls() -> some View {
        HStack(spacing: 40) {
            
            // Кнопка назад
            Button {
                
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .tint(.white)
                    .padding()
                    .background() {
                        Circle().fill(.black.opacity(0.4))
                    }
            }.disabled(true).opacity(0.6)
            
            // Кнопка плей
            Button {
                
                if isVideoFinished {
                    isVideoFinished = false
                    player?.seek(to: .zero)
                    progress = .zero
                    lastProgress = .zero
                    
                }
                
                if isPlaying {
                    player?.pause()
                    
                    if let timeoutTask {
                        timeoutTask.cancel()
                    }
                } else {
                    player?.play()
                    hideControls()
                }
                withAnimation {
                    isPlaying.toggle()
                }
                
                
            } label: {
                Image(systemName: isVideoFinished ? "arrow.clockwise" : (isPlaying ? "pause.fill": "play.fill"))
                    .font(.title)
                    .fontWeight(.ultraLight)
                    .tint(.white)
                    .padding(20)
                    .background() {
                        Circle().fill(.black.opacity(0.4))
                    }
            }
            
            // Кнопка вперед
            Button {
                
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .tint(.white)
                    .padding()
                    .background() {
                        Circle().fill(.black.opacity(0.4))
                    }
            }.disabled(true).opacity(0.6)
        }
    }
        
    @ViewBuilder private func sliderView(forVideoSize size: CGSize) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.gray)
            Rectangle()
                .fill(.red)
                .frame(width: size.width * progress)
        }.frame(height: 3)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(.red)
                    .frame(width: 16, height: 16)
                    .scaleEffect(showControls || isDragging ? 1 : 0)
                    .frame(width: 50, height: 50)
                    .contentShape(Rectangle())
                    .offset(x: size.width * progress - 25)
                    .gesture(
                        DragGesture()
                            .updating($isDragging, body: { _, out, _ in
                                out = true
                            })
                            .onChanged({ value in
                                if let timeoutTask {
                                    timeoutTask.cancel()
                                }
                                
                                let dx = value.translation.width
                                let newValue = dx / size.width + lastProgress
                                progress = max(min(newValue, 1), 0)
                                isSeeking = true
                            })
                            .onEnded({ value in
                                lastProgress = progress
                                if let currentItem = player?.currentItem {
                                    let duration = currentItem.duration.seconds
                                    player?.seek(to: CMTime(seconds: duration * progress, preferredTimescale: 1))
                                }
                                
                                if isPlaying {
                                    hideControls()
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isSeeking = false
                                }
                            })
                           
                    )
            }
        
    }
        
    private func hideControls() {
        if let timeoutTask {
            timeoutTask.cancel()
        } else {
            timeoutTask = DispatchWorkItem {
                withAnimation(.easeInOut) {
                    showControls = false
                }
            }
        }
        if let timeoutTask {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.hideControlDuration, execute: timeoutTask)
        }
    }
    
    private func addTimeObservers() {
        player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main) {
            time in
            if let currentItem = player?.currentItem {
                let duration = currentItem.duration.seconds
                guard let currentTime = player?.currentTime().seconds else {
                    return
                }
                
                let currentProgress = currentTime / duration
                if !isSeeking {
                    progress = currentProgress
                    lastProgress = currentProgress
                }
                
                if currentProgress == 1 {
                    isVideoFinished = true
                    isPlaying = false
                }
            }
        }
    }
    
    private enum Constants {
        static let hideControlDuration = 3.0
    }
}

#Preview {
    ContentView()
}
