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
    func drawingSession(session: DrawingSession, isAcceptableLine line: DrawingLine) -> Bool
    func drawingSession(session: DrawingSession, didEndDrawing line: DrawingLine)
}

class DrawingSession {
    
    var brush: DrawingBrush = DrawingBrush(width: 1, opacity: 1, color: UIColor.whiteColor())
    
    weak var delegate: DrawingSessionDelegate?
    
    private var lines = [DrawingLine]()
    
    var line: DrawingLine?
    
    var empty: Bool {
        return lines.isEmpty
    }
    
    var interpolated = false
    
    var drawing = false
    
    func undo() {
        lines.removeLast()
    }
    
    func render() {
        for line in lines {
            line.render()
        }
    }
    
    func beginDrawing() -> DrawingLine {
        let line = DrawingLine()
        line.brush = brush
        lines.append(line)
        self.line = line
        delegate?.drawingSessionDidBeginDrawing(self)
        drawing = true
        return line
    }
    
    func addPoint(point: CGPoint) {
        line?.addPoint(point)
    }
    
    func endDrawing() {
        drawing = false
        
        if let line = line {
            if delegate?.drawingSession(self, isAcceptableLine:line) ?? true {
                if interpolated {
                    line.interpolate()
                }
                line.completed = true
            } else {
                lines.removeLast()
            }
            
            delegate?.drawingSession(self, didEndDrawing:line)
        }
        
        line = nil
    }
    
    func erase() {
        lines.removeAll()
        line = nil
        drawing = false
    }
}

private var pathPoints = [CGPoint]()

class DrawingLine {
    
    var brush: DrawingBrush = DrawingBrush(width: 1, opacity: 1, color: UIColor.whiteColor()) {
        willSet {
            path.lineWidth = newValue.width
        }
    }
    
    var completed = false
    
    var path: UIBezierPath = {
        let path = UIBezierPath()
        path.lineCapStyle = .Round
        path.lineJoinStyle = .Round
        return path
    }()
    
    func addPoint(point: CGPoint) {
        if !completed {
            if path.empty {
                path.moveToPoint(point)
                path.addLineToPoint(point)
            } else if path.currentPoint != point {
                path.addLineToPoint(point)
            }
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
        return path.bounds.intersects(rect)
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