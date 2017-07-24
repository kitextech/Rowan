//
//  LogView.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-07-16.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

class LogView: UIView {
    // Input
    public var data: [LogData] = [] { didSet { dataChanged(oldValue) } }

    // Private
    enum LabelType { case name(String), min, max, value }

    private var labels: [(name: UILabel, min: UILabel, max: UILabel, value: UILabel)] = []
    private var bars: [UIView] = []
    private let font = UIFont.systemFont(ofSize: 14)

    private let topMargin: CGFloat = 20
    private let margin: CGFloat = 5
    private let inset: CGFloat = 2
    private let rowHeight: CGFloat = 30
    private let nameWidth: CGFloat = 60
    private let valueWidth: CGFloat = 50
    private let minMaxWidth: CGFloat = 50
    private var barMin: CGFloat { return 3*margin + nameWidth + valueWidth }
    private var barMax: CGFloat { return bounds.width - margin }
    private var barMid: CGFloat { return (barMin + barMax)/2 }
    private var barWidth: CGFloat { return barMax - barMin }

    private func dataChanged(_ oldData: [LogData]) {
        if data.count != labels.count {
            createRows()
        }

        for row in data.indices where oldData.count != data.count || data[row] != oldData[row] {
            updateRow(row, data[row])
        }
    }

    private func createRows() {
        (bars + labels.flatMap { [$0.name, $0.min, $0.max, $0.value] }).forEach { $0.removeFromSuperview() }
        bars.removeAll()
        labels.removeAll()

        data.enumerated().forEach { splatMe in let (row, data) = splatMe
            bars.append(createBar(row))
            labels.append(createLabels(row, data))
        }
    }

    private func updateRow(_ row: Int, _ data: LogData) {
        updateBar(row, data)
        updateValueLabel(row, data.value)
    }

    // Bars
    private func createBar(_ row: Int) -> UIView {
        let bar = UIView()
        bar.backgroundColor = .darkGray
        bar.frame.size.height = rowHeight - 2*inset
        bar.frame.origin.y = topMargin + margin + CGFloat(row)*rowHeight - inset
        addSubview(bar)
        return bar
    }

    private func updateBar(_ row: Int, _ data: LogData) {
        let scale = barWidth/CGFloat(data.max - data.min)
        let width = scale*CGFloat(data.value)
        bars[row].frame.origin.x = min(barMid, barMid + width)
        bars[row].frame.size.width = abs(width)
    }

    // Labels

    private func createLabels(_ row: Int, _ data: LogData) -> (UILabel, UILabel, UILabel, UILabel) {
        return (createLabel(.name(data.name), row, data), createLabel(.min, row, data), createLabel(.max, row, data), createLabel(.value, row, data))
    }

    private func createLabel(_ type: LabelType, _ row: Int, _ data: LogData) -> UILabel {
        let label = UILabel()
        label.font = font

        if case .name(let string) = type {
            label.text = string
        }

        let param: (x: CGFloat, width: CGFloat, alignment: NSTextAlignment)
        switch type {
        case .name: param = (margin, nameWidth, .right)
        case .min: param = (barMin, minMaxWidth, .left); label.text = String(format: "%.1f", data.min)
        case .max: param = (barMax - minMaxWidth, minMaxWidth, .right); label.text = String(format: "%.1f", data.max)
        case .value: param = (2*margin + nameWidth, valueWidth, .left)
        }
        label.frame.origin = CGPoint(x: param.x, y: topMargin + margin + CGFloat(row)*rowHeight)
        label.frame.size = CGSize(width: param.width, height: rowHeight)
        label.textAlignment = param.alignment
        label.textColor = .lightGray

        addSubview(label)
        return label
    }

    private func updateValueLabel(_ row: Int, _ value: Scalar) {
        labels[row].value.text = String(format: "%.3f", value)
    }
}
