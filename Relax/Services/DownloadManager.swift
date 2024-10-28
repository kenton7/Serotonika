//
//  DownloadManager.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 04.09.2024.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import SwiftUI

class DownloadManager: ObservableObject {

    @Published var totalProgress: Double = 0.0 {
        didSet {
            // Вызывается каждый раз, когда изменяется общий прогресс
            print("Общий прогресс загрузки: \(totalProgress)%")
        }
    }
        
    // Словарь для хранения прогресса загрузки каждого файла
        private var fileProgress: [String: Double] = [:]
    
    // Метод для обновления прогресса определенного файла
       private func updateProgress(for file: String, progress: Double) {
           fileProgress[file] = progress
           
           // Рассчитываем общий прогресс как среднее арифметическое всех файлов
           let total = fileProgress.values.reduce(0, +)
           totalProgress = total / Double(fileProgress.count)
       }
    
    func downloadAllCourse(course: CourseAndPlaylistOfDayModel, courseType: Types, isFemale: Bool?, lessons: [Lesson]) async throws -> [URL] {
        var results = [URL]()
        
        try await withThrowingTaskGroup(of: URL.self) { [unowned self] group in
            for lesson in lessons {
                group.addTask {
                    return try await self.downloadLesson(course: course, courseType: courseType, isFemale: isFemale ?? true, lesson: lesson)
                }
            }
            for try await result in group {
                results.append(result)
            }
        }
        return results
    }
    
    func downloadLesson(course: CourseAndPlaylistOfDayModel, courseType: Types, isFemale: Bool, lesson: Lesson) async throws -> URL {
        
        var localURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        var storageRef: StorageReference {
            switch courseType {
            case .playlist:
                return Storage.storage().reference(withPath: "music/\(course.id)/\("female")/\(lesson.lessonID).mp3")
            case .meditation:
                return Storage.storage().reference(withPath: "meditations/\(course.id)/\(isFemale ? "female" : "male")/\(lesson.lessonID)\(isFemale ? "Female" : "Male").mp3")
            case .story:
                return Storage.storage().reference(withPath: "stories/\(course.id)/\(isFemale ? "female" : "male")/\(lesson.lessonID)\(isFemale ? "Female" : "Male").mp3")
            case .emergency:
                return Storage.storage().reference(withPath: "emergency/\(course.id)/\(isFemale ? "female" : "male")/\(lesson.lessonID)\(isFemale ? "Female" : "Male").mp3")
            }
        }
        
        localURL.append(path: "\(course.name)/\(lesson.name)", directoryHint: .isDirectory)
        localURL.appendPathExtension(for: .mp3)
        
        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = storageRef.write(toFile: localURL) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: localURL)
                }
            }
            
            downloadTask.observe(.progress) { [weak self] snapshot in
                let percentComplete = 100 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
                print("Загрузка файла \(lesson.lessonID): \(percentComplete)% завершено")
                
                // Обновляем прогресс конкретного файла
                DispatchQueue.main.async { [weak self] in
                    self?.updateProgress(for: lesson.lessonID, progress: percentComplete)
                }
            }
            
            downloadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
