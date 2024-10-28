//
//  UIView+Extension.swift
//  Серотоника
//
//  Created by Илья Кузнецов on 08.09.2024.
//

import UIKit

extension UIView {
    func image(_ size: CGSize) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        return render.image { _ in
            drawHierarchy(in: .init(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}
