//
//  FileManagerSerivce.swift
//  Relax
//
//  Created by Илья Кузнецов on 31.07.2024.
//

import Foundation

protocol IFileManagerSerivce: AnyObject {
    func getDownloadFiles() -> [FileItem]
    func getContentsOfFolder(at url: URL) -> [FileItem] 
    func deleteFile(at url: URL) -> Bool
    func isDownloaded(lesson: Lesson, course: CourseAndPlaylistOfDayModel) -> Bool
    func isCourseDownloaded(course: CourseAndPlaylistOfDayModel) throws -> Bool
}

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
}

final class FileManagerSerivce: IFileManagerSerivce {
    
    let fileManager = FileManager.default
    
    func getDownloadFiles() -> [FileItem] {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
            let folderURLs = fileURLs.filter { url in
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDir)
                return isDir.boolValue
            }
            return folderURLs.map { FileItem(url: $0) }
        } catch {
            print("Ошибка при получении скачанных файлов из файлового менеджера")
            return []
        }
    }
    
    func isDownloaded(lesson: Lesson, course: CourseAndPlaylistOfDayModel) -> Bool {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Путь не найден")
            return false
        }
        let fileURLStrDecoded = documentsDirectory.appendingPathComponent(course.name).appendingPathComponent(lesson.name).appendingPathExtension(for: .mp3).absoluteString.decodeURL() ?? ""
        let fileURL = URL(string: fileURLStrDecoded)!
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    func isCourseDownloaded(course: CourseAndPlaylistOfDayModel) throws -> Bool {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        let lessonsCount = course.lessons?.values.count
        let fileURL = documentsDirectory.appendingPathComponent(course.name)
        return try! fileManager.fileExists(atPath: fileURL.path) && lessonsCount == fileManager.contentsOfDirectory(at: fileURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).count
    }
    
    func getContentsOfFolder(at url: URL) -> [FileItem] {
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            return fileURLs.map { FileItem(url: $0) }
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteFile(at url: URL) -> Bool {
            do {
                try fileManager.removeItem(at: url)
                print("Файл успешно удален: \(url)")
                return true
            } catch {
                print("Ошибка при удалении файла: \(error.localizedDescription)")
                return false
            }
        }
    
}
