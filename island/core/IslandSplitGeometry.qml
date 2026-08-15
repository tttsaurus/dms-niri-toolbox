import QtQuick

QtObject {
    id: root

    // keep these values in lock-step with dynamic_island.frag
    readonly property real minimumPercentage: 0.1
    readonly property real maximumPercentage: 0.9
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
            leftWidth = requestedShapeWidth
            rightWidth = availableWidth - leftWidth
        } else {
            rightWidth = requestedShapeWidth
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
            requestedShapeWidth / root.maximumPercentage
        )

        let candidateWidth = Math.max(minimumWidth, Math.ceil(minimumAvailableWidth + inset * 2 + gap))

        if (candidateWidth > maximumWidth)
            return root.failedPlan("required island width exceeds the allowed maximum", candidateWidth)

        const maximumAvailableWidth = requestedShapeWidth / root.minimumPercentage
        const candidateAvailableWidth = candidateWidth - inset * 2 - gap

        if (candidateAvailableWidth > maximumAvailableWidth)
            return root.failedPlan("requested piece would be below the shader's 10% minimum", candidateWidth)

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