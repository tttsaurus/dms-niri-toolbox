import QtQuick

QtObject {
    id: root

    // keep these values in lock-step with dynamic_island.frag
    readonly property real minimumPercentage: 0.01
    readonly property real maximumPercentage: 0.99
    readonly property real minimumPieceEpsilon: 0.001

    function finitePositive(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) && number > 0 ? number : fallback
    }

    function normalizeSide(side) {
        return String(side) === "left" ? "left" : "right"
    }

    function failedPlan(reason, islandWidth) {
        return {
            success: false,
            reason: reason || "unsupported geometry",
            islandWidth: Number(islandWidth) || 0,
            percentage: 0.5,
            side: "right",
            gap: 0,
            shapeInset: 0,
            leftWidth: 0,
            rightWidth: 0,
            leftStartOffset: 0,
            rightStartOffset: 0,
            leftContentStartOffset: 0,
            rightContentStartOffset: 0,
            leftContentWidth: 0,
            rightContentWidth: 0,
            pieceStartOffset: 0,
            pieceContentStartOffset: 0,
            pieceWidth: 0,
            pieceContentWidth: 0,
            otherStartOffset: 0,
            otherContentStartOffset: 0,
            otherWidth: 0,
            otherContentWidth: 0
        }
    }

    function layoutForSplitProgress(
        islandWidth,
        radiusDip,
        shapeInset,
        percentage,
        splitProgress,
        side,
        piecePadding
    ) {
        const width = Math.max(Number(islandWidth) || 0, 0)
        const radius = Math.max(Number(radiusDip) || 0, 0)
        const inset = Math.max(Number(shapeInset) || 0, 0)
        const padding = Math.max(Number(piecePadding) || 0, 0)
        const normalizedSide = root.normalizeSide(side)
        const normalizedPercentage = Math.max(root.minimumPercentage, Math.min(root.maximumPercentage, Number(percentage) || 0.5))
        let progress = Math.max(0, Math.min(1, Number(splitProgress) || 0))

        const fullWidth = Math.max(width - inset * 2, 2)
        const gap = Math.max(inset * 2, 2)
        const availableWidth = fullWidth - gap
        const shaderRadius = Math.max(radius - inset, 0)
        const minimumPieceWidth = shaderRadius * 2 + root.minimumPieceEpsilon

        if (availableWidth <= minimumPieceWidth * 2)
            progress = 0

        const targetLeftWidth = availableWidth > 0 ? Math.max(minimumPieceWidth, Math.min(availableWidth - minimumPieceWidth, availableWidth * normalizedPercentage)) : fullWidth
        const targetRightWidth = Math.max(availableWidth - targetLeftWidth, 0)

        const targetLeftCenter = -fullWidth * 0.5 + targetLeftWidth * 0.5
        const targetRightCenter = fullWidth * 0.5 - targetRightWidth * 0.5

        const leftWidth = fullWidth + (targetLeftWidth - fullWidth) * progress
        const rightWidth = fullWidth + (targetRightWidth - fullWidth) * progress
        const leftCenter = targetLeftCenter * progress
        const rightCenter = targetRightCenter * progress

        const leftStart = width * 0.5 + leftCenter - leftWidth * 0.5
        const rightStart = width * 0.5 + rightCenter - rightWidth * 0.5
        const leftContentStart = leftStart + padding
        const rightContentStart = rightStart + padding
        const leftContentWidth = Math.max(leftWidth - padding * 2, 0)
        const rightContentWidth = Math.max(rightWidth - padding * 2, 0)

        const pieceIsLeft = normalizedSide === "left"
        return {
            success: true,
            reason: "",
            islandWidth: width,
            percentage: normalizedPercentage,
            side: normalizedSide,
            progress: progress,
            gap: gap,
            shapeInset: inset,
            availableWidth: availableWidth,
            minimumPieceWidth: minimumPieceWidth,
            leftWidth: leftWidth,
            rightWidth: rightWidth,
            leftStartOffset: leftStart,
            rightStartOffset: rightStart,
            leftContentStartOffset: leftContentStart,
            rightContentStartOffset: rightContentStart,
            leftContentWidth: leftContentWidth,
            rightContentWidth: rightContentWidth,
            pieceStartOffset: pieceIsLeft ? leftStart : rightStart,
            pieceContentStartOffset: pieceIsLeft ? leftContentStart : rightContentStart,
            pieceWidth: pieceIsLeft ? leftWidth : rightWidth,
            pieceContentWidth: pieceIsLeft ? leftContentWidth : rightContentWidth,
            otherStartOffset: pieceIsLeft ? rightStart : leftStart,
            otherContentStartOffset: pieceIsLeft ? rightContentStart : leftContentStart,
            otherWidth: pieceIsLeft ? rightWidth : leftWidth,
            otherContentWidth: pieceIsLeft ? rightContentWidth : leftContentWidth
        }
    }

    function planForPiece(
        islandWidth,
        radiusDip,
        shapeInset,
        requestedPieceWidth,
        side,
        otherMinimumWidth,
        piecePadding
    ) {
        const width = Number(islandWidth)
        const radius = Math.max(Number(radiusDip) || 0, 0)
        const inset = Math.max(Number(shapeInset) || 0, 0)
        const padding = Math.max(Number(piecePadding) || 0, 0)
        const requestedContent = Math.max(Number(requestedPieceWidth) || 0, 0)
        const otherContentMinimum = Math.max(Number(otherMinimumWidth) || 0, 0)
        const normalizedSide = root.normalizeSide(side)

        if (!Number.isFinite(width) || width <= 0)
            return root.failedPlan("island width is not positive", width)

        const shapeFullWidth = width - inset * 2
        const gap = Math.max(inset * 2, 2)
        const availableWidth = shapeFullWidth - gap

        const shaderRadius = Math.max(radius - inset, 0)
        const minimumPieceWidth = shaderRadius * 2 + root.minimumPieceEpsilon

        if (availableWidth <= minimumPieceWidth * 2)
            return root.failedPlan("not enough width for two shader pieces", width)

        const requestedShapeWidth = Math.max(requestedContent + padding * 2, minimumPieceWidth)
        const otherRequiredShapeWidth = Math.max(otherContentMinimum + padding * 2, minimumPieceWidth)

        if (requestedShapeWidth + otherRequiredShapeWidth > availableWidth)
            return root.failedPlan("the requested piece leaves too little room for the other piece", width)

        let leftWidth
        let rightWidth

        if (normalizedSide === "left") {
            leftWidth = Math.max(requestedShapeWidth, availableWidth * root.minimumPercentage)
            rightWidth = availableWidth - leftWidth
        } else {
            rightWidth = Math.max(requestedShapeWidth, availableWidth * root.minimumPercentage)
            leftWidth = availableWidth - rightWidth
        }

        const percentage = leftWidth / availableWidth
        if (percentage < root.minimumPercentage || percentage > root.maximumPercentage)
            return root.failedPlan("split percentage would be outside shader range", width)

        if (leftWidth < minimumPieceWidth || rightWidth < minimumPieceWidth)
            return root.failedPlan("one shader piece would be smaller than 2 * radius", width)

        if (normalizedSide === "left" && rightWidth < otherRequiredShapeWidth)
            return root.failedPlan("right piece is smaller than the required companion content", width)
        if (normalizedSide === "right" && leftWidth < otherRequiredShapeWidth)
            return root.failedPlan("left piece is smaller than the required companion content", width)

        const leftStart = inset
        const rightStart = inset + leftWidth + gap

        const leftContentStart = leftStart + padding
        const rightContentStart = rightStart + padding
        const leftContentWidth = Math.max(leftWidth - padding * 2, 0)
        const rightContentWidth = Math.max(rightWidth - padding * 2, 0)

        const pieceIsLeft = normalizedSide === "left"

        return {
            success: true,
            reason: "",
            islandWidth: width,
            percentage: percentage,
            side: normalizedSide,
            gap: gap,
            shapeInset: inset,
            availableWidth: availableWidth,
            minimumPieceWidth: minimumPieceWidth,

            leftWidth: leftWidth,
            rightWidth: rightWidth,
            leftStartOffset: leftStart,
            rightStartOffset: rightStart,
            leftContentStartOffset: leftContentStart,
            rightContentStartOffset: rightContentStart,
            leftContentWidth: leftContentWidth,
            rightContentWidth: rightContentWidth,

            pieceStartOffset: pieceIsLeft ? leftStart : rightStart,
            pieceContentStartOffset: pieceIsLeft ? leftContentStart : rightContentStart,
            pieceWidth: pieceIsLeft ? leftWidth : rightWidth,
            pieceContentWidth: pieceIsLeft ? leftContentWidth : rightContentWidth,

            otherStartOffset: pieceIsLeft ? rightStart : leftStart,
            otherContentStartOffset: pieceIsLeft ? rightContentStart : leftContentStart,
            otherWidth: pieceIsLeft ? rightWidth : leftWidth,
            otherContentWidth: pieceIsLeft ? rightContentWidth : leftContentWidth
        }
    }

    function findClampedPlanForPiece(
        minimumIslandWidth,
        maximumIslandWidth,
        radiusDip,
        shapeInset,
        requestedPieceWidth,
        side,
        otherMinimumWidth,
        piecePadding
    ) {
        const preferred = root.findPlanForPiece(
            minimumIslandWidth,
            maximumIslandWidth,
            radiusDip,
            shapeInset,
            requestedPieceWidth,
            side,
            otherMinimumWidth,
            piecePadding
        )
        if (preferred.success)
            return preferred

        const maximumWidth = Math.max(Number(maximumIslandWidth) || 0, Math.max(Number(minimumIslandWidth) || 0, 1))
        const radius = Math.max(Number(radiusDip) || 0, 0)
        const inset = Math.max(Number(shapeInset) || 0, 0)
        const padding = Math.max(Number(piecePadding) || 0, 0)
        const requestedContent = Math.max(Number(requestedPieceWidth) || 0, 0)
        const otherContent = Math.max(Number(otherMinimumWidth) || 0, 0)
        const gap = Math.max(inset * 2, 2)
        const availableWidth = maximumWidth - inset * 2 - gap
        const minimumPieceWidth = Math.max(radius - inset, 0) * 2 + root.minimumPieceEpsilon
        const otherRequiredShapeWidth = Math.max(otherContent + padding * 2,minimumPieceWidth)
        const maximumPieceShapeWidth = Math.min(availableWidth * root.maximumPercentage, availableWidth - otherRequiredShapeWidth)

        if (maximumPieceShapeWidth < minimumPieceWidth)
            return preferred

        const fittedContentWidth = Math.min(requestedContent, Math.max(maximumPieceShapeWidth - padding * 2, 0))
        
        return root.planForPiece(
            maximumWidth,
            radius,
            inset,
            fittedContentWidth,
            side,
            otherContent,
            padding
        )
    }

    function findPlanForPiece(
        minimumIslandWidth,
        maximumIslandWidth,
        radiusDip,
        shapeInset,
        requestedPieceWidth,
        side,
        otherMinimumWidth,
        piecePadding
    ) {
        const minimumWidth = Math.max(Number(minimumIslandWidth) || 0, 1)
        const maximumWidth = Math.max(Number(maximumIslandWidth) || 0, minimumWidth)
        const radius = Math.max(Number(radiusDip) || 0, 0)
        const inset = Math.max(Number(shapeInset) || 0, 0)
        const padding = Math.max(Number(piecePadding) || 0, 0)
        const requestedContent = Math.max(Number(requestedPieceWidth) || 0, 0)
        const otherContentMinimum = Math.max(Number(otherMinimumWidth) || 0, 0)

        const shaderRadius = Math.max(radius - inset, 0)
        const minimumPieceWidth = shaderRadius * 2 + root.minimumPieceEpsilon
        const requestedShapeWidth = Math.max(requestedContent + padding * 2, minimumPieceWidth)
        const otherRequiredShapeWidth = Math.max(otherContentMinimum + padding * 2, minimumPieceWidth)
        const gap = Math.max(inset * 2, 2)

        const minimumAvailableWidth = Math.max(
            requestedShapeWidth + otherRequiredShapeWidth,
            minimumPieceWidth * 2 + root.minimumPieceEpsilon,
            requestedShapeWidth / root.maximumPercentage,
            otherRequiredShapeWidth / root.maximumPercentage
        )

        let candidateWidth = Math.max(minimumWidth, Math.ceil(minimumAvailableWidth + inset * 2 + gap))

        if (candidateWidth > maximumWidth)
            return root.failedPlan("required island width exceeds the allowed maximum", candidateWidth)

        return root.planForPiece(
            candidateWidth,
            radius,
            inset,
            requestedContent,
            side,
            otherContentMinimum,
            padding
        )
    }
}