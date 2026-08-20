import QtQuick

Item {
    id: root

    property url source: ""

    property int sampleSize: 24

    property bool darkBackgroundBoostEnabled: false
    property real darkBackgroundBoostStrength: 1.0

    readonly property var colorHint: {
        if (!root._ready)
            return null

        return root.processColor(root._rawRed, root._rawGreen, root._rawBlue)
    }

    property bool _ready: false

    property real _rawRed: 0.0
    property real _rawGreen: 0.0
    property real _rawBlue: 0.0

    property string _loadedSource: ""

    width: 0
    height: 0

    function clamp(value, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, value))
    }

    function smoothstep(edge0, edge1, value) {
        if (edge0 === edge1)
            return value < edge0 ? 0.0 : 1.0

        const t = root.clamp((value - edge0) / (edge1 - edge0), 0.0, 1.0)

        return t * t * (3.0 - 2.0 * t)
    }

    function luminance(red, green, blue) {
        return red * 0.2126 + green * 0.7152 + blue * 0.0722
    }

    function processColor(red, green, blue) {
        if (!root.darkBackgroundBoostEnabled)
            return Qt.rgba(red, green, blue, 1.0)

        const strength = root.clamp(Number(root.darkBackgroundBoostStrength), 0.0, 1.0)

        if (strength <= 0.0)
            return Qt.rgba(red, green, blue, 1.0)

        const currentLuminance = root.luminance(red, green, blue)

        if (currentLuminance <= 0.0001)
            return Qt.rgba(red, green, blue, 1.0)

        const darknessFactor = 1.0 - root.smoothstep(0.16, 0.42, currentLuminance)

        if (darknessFactor <= 0.0)
            return Qt.rgba(red, green, blue, 1.0)

        const targetLuminance = 0.38
        const maximumScale = 1.85
        const desiredScale = root.clamp(targetLuminance / currentLuminance, 1.0, maximumScale)
        const boostAmount = darknessFactor * strength
        const finalScale = 1.0 + (desiredScale - 1.0) * boostAmount

        return Qt.rgba(
            root.clamp(red * finalScale, 0.0, 1.0),
            root.clamp(green * finalScale, 0.0, 1.0),
            root.clamp(blue * finalScale, 0.0, 1.0),
            1.0
        )
    }

    function reload() {
        const nextSource = String(root.source ?? "")

        root._ready = false

        if (root._loadedSource.length > 0) {
            canvas.unloadImage(root._loadedSource)
            root._loadedSource = ""
        }

        if (nextSource.length === 0)
            return

        root._loadedSource = nextSource

        canvas.loadImage(root.source, Qt.size(root.sampleSize, root.sampleSize))
    }

    function extractColor(pixelData) {
        const buckets = ({})

        for (let i = 0; i < pixelData.length; i += 4) {
            const redByte = pixelData[i]
            const greenByte = pixelData[i + 1]
            const blueByte = pixelData[i + 2]
            const alpha = pixelData[i + 3] / 255.0

            if (alpha < 0.35)
                continue

            const red = redByte / 255.0
            const green = greenByte / 255.0
            const blue = blueByte / 255.0

            const maximum = Math.max(red, green, blue)
            const minimum = Math.min(red, green, blue)

            const chroma = maximum - minimum
            const saturation = maximum > 0.0001 ? chroma / maximum : 0.0
            const pixelLuminance = root.luminance(red, green, blue)

            if (pixelLuminance < 0.035)
                continue

            const quantizedRed = redByte >> 4
            const quantizedGreen = greenByte >> 4
            const quantizedBlue = blueByte >> 4

            const key = (quantizedRed << 8) | (quantizedGreen << 4) | quantizedBlue

            let bucket = buckets[key]
            if (bucket === undefined) {
                bucket = {
                    score: 0.0,
                    weight: 0.0,
                    red: 0.0,
                    green: 0.0,
                    blue: 0.0
                }

                buckets[key] = bucket
            }

            const saturationWeight = 0.55 + saturation * 0.45
            const luminanceWeight = 0.55 + root.clamp(pixelLuminance / 0.5, 0.0, 1.0) * 0.45
            const scoreWeight = alpha * saturationWeight * luminanceWeight

            bucket.score += scoreWeight
            bucket.weight += alpha
            bucket.red += red * alpha
            bucket.green += green * alpha
            bucket.blue += blue * alpha
        }

        let bestBucket = null
        let bestScore = -1.0

        for (const key in buckets) {
            const bucket = buckets[key]
            if (bucket.score <= bestScore)
                continue

            bestScore = bucket.score
            bestBucket = bucket
        }

        if (bestBucket === null || bestBucket.weight <= 0.0) {
            root._ready = false
            return
        }

        root._rawRed = bestBucket.red / bestBucket.weight
        root._rawGreen = bestBucket.green / bestBucket.weight
        root._rawBlue = bestBucket.blue / bestBucket.weight

        root._ready = true
    }

    onSourceChanged: root.reload()
    onSampleSizeChanged: root.reload()

    Canvas {
        id: canvas

        width: root.sampleSize
        height: root.sampleSize

        opacity: 0.0
        renderTarget: Canvas.Image

        onImageLoaded: {
            if (root._loadedSource.length === 0)
                return

            if (canvas.isImageLoaded(root.source))
                canvas.requestPaint()
        }

        onPaint: {
            if (root._loadedSource.length === 0 || !canvas.isImageLoaded(root.source))
                return

            const context = canvas.getContext("2d")

            context.clearRect(0, 0, width, height)
            context.drawImage(root.source, 0, 0, width, height)

            const imageData = context.getImageData(0, 0, width, height)

            root.extractColor(imageData.data)
        }
    }

    Component.onCompleted: root.reload()
}
