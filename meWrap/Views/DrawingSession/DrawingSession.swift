//
//  DrawingSession.swift
//  meWrap
//
//  Created by Sergey Maximenko on 2/25/16.
//  Copyright © 2016 Ravenpod. All rights reserved.
//

import Foundation

protocol DrawingSessionDelegate: class {
    func drawingSessionDidBeginDrawing(session: DrawingSession)
    func drawingSessionDidEndDrawing(session: DrawingSession)
}

protocol Drawing: class {
    func render()
}

class DrawingSession {
    
    var brush = DrawingBrush(width: 1, opacity: 1, color: UIColor.whiteColor())
    
    weak var delegate: DrawingSessionDelegate?
    
    var drawings = [Drawing]()
    
    var empty: Bool {
        return drawings.isEmpty
    }
    
    var drawing: Drawing?
    
    func undo() {
        drawings.removeLast()
    }
    
    func render() {
        for drawing in drawings {
            drawing.render()
        }
    }
    
    func beginDrawing(drawing: Drawing) {
        self.drawing = drawing
        delegate?.drawingSessionDidBeginDrawing(self)
    }
    
    func endDrawing() {
        if let drawing = drawing {
            drawings.append(drawing)
            delegate?.drawingSessionDidEndDrawing(self)
        }
        drawing = nil
    }
    
    func cancelDrawing() {
        drawing = nil
    }
    
    func erase() {
        drawings.removeAll()
        drawing = nil
    }
}

private var pathPoints = [CGPoint]()

class Line: Drawing {
    
    var brush = DrawingBrush(width: 1, opacity: 1, color: UIColor.whiteColor()) {
        willSet {
            path.lineWidth = newValue.width
        }
    }
    
    var path = specify(UIBezierPath()) {
        $0.lineCapStyle = .Round
        $0.lineJoinStyle = .Round
    }
    
    func addPoint(point: CGPoint) {
        if path.empty {
            path.moveToPoint(point)
            path.addLineToPoint(point)
        } else if path.currentPoint != point {
            path.addLineToPoint(point)
        }
    }
    
    func interpolate() {
        
        pathPoints.removeAll()
        CGPathApply(self.path.CGPath, UnsafeMutablePointer<Void>(nil), { _, element in
            let points = element.memory.points
            let type = element.memory.type
            switch type {
            case .MoveToPoint:
                pathPoints.append(points[0])
            case .AddLineToPoint:
                pathPoints.append(points[0])
            case .AddQuadCurveToPoint:
                pathPoints.append(points[0])
                pathPoints.append(points[1])
            case .AddCurveToPoint:
                pathPoints.append(points[0])
                pathPoints.append(points[1])
                pathPoints.append(points[2])
            default: break
            }
        })
        
        var point: CGPoint?
        
        let points = pathPoints.filter {
            let remove = point == $0
            point = $0
            return !remove
        }
        pathPoints.removeAll()
        
        if let path = UIBezierPath.hermiteIntepolation(points, closed: false) {
            path.lineCapStyle = self.path.lineCapStyle
            path.lineJoinStyle = self.path.lineJoinStyle
            path.lineWidth = self.path.lineWidth
            self.path = path
        }
    }
    
    func render() {
        brush.color.colorWithAlphaComponent(brush.opacity).setStroke()
        path.stroke()
    }
    
    func intersectsRect(rect: CGRect) -> Bool {
        return path.bounds.intersects(rect.insetBy(dx: -brush.width/2, dy: -brush.width/2))
    }
}

func ==(lhs: DrawingBrush, rhs: DrawingBrush) -> Bool {
    return lhs.color.isEqual(rhs.color) && lhs.width == rhs.width && lhs.opacity == rhs.opacity
}

struct DrawingBrush: Equatable {
    var width: CGFloat
    var opacity: CGFloat = 1
    var color: UIColor
}