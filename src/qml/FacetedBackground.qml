import QtQuick

Canvas {
    id: bgCanvas
    anchors.fill: parent
    renderTarget: Canvas.FramebufferObject // Renders once to GPU, 0% CPU impact

    onPaint: {
        var ctx = getContext("2d");
        var w = width;
        var h = height;

        // Base dark teal vignette
        var radGrad = ctx.createRadialGradient(w / 2, h / 2, 40, w / 2, h / 2, w / 2);
        radGrad.addColorStop(0, "#103d52");
        radGrad.addColorStop(0.7, "#081d28");
        radGrad.addColorStop(1, "#030a0e");
        ctx.fillStyle = radGrad;
        ctx.fillRect(0, 0, w, h);

        // Low-Poly Faceted Geometric Triangulation (Matching AsteroidOS Image 2)
        var cols = 5;
        var rows = 5;
        var points = [];

        for (var r = 0; r <= rows; r++) {
            points[r] = [];
            for (var c = 0; c <= cols; c++) {
                var jitterX = (r > 0 && r < rows && c > 0 && c < cols) ? (Math.random() - 0.5) * 22 : 0;
                var jitterY = (r > 0 && r < rows && c > 0 && c < cols) ? (Math.random() - 0.5) * 22 : 0;
                points[r][c] = {
                    x: (c / cols) * w + jitterX,
                    y: (r / rows) * h + jitterY
                };
            }
        }

        var colors = [
            "#0d384d", "#0b2f42", "#0f425c", "#082433", 
            "#124b69", "#0e3b52", "#071f2b", "#145475"
        ];

        for (var r = 0; r < rows; r++) {
            for (var c = 0; c < cols; c++) {
                var p1 = points[r][c];
                var p2 = points[r][c + 1];
                var p3 = points[r + 1][c];
                var p4 = points[r + 1][c + 1];

                // Triangle 1
                ctx.beginPath();
                ctx.moveTo(p1.x, p1.y);
                ctx.lineTo(p2.x, p2.y);
                ctx.lineTo(p3.x, p3.y);
                ctx.closePath();
                ctx.fillStyle = colors[Math.floor(Math.random() * colors.length)];
                ctx.globalAlpha = 0.45;
                ctx.fill();

                // Triangle 2
                ctx.beginPath();
                ctx.moveTo(p2.x, p2.y);
                ctx.lineTo(p4.x, p4.y);
                ctx.lineTo(p3.x, p3.y);
                ctx.closePath();
                ctx.fillStyle = colors[Math.floor(Math.random() * colors.length)];
                ctx.globalAlpha = 0.45;
                ctx.fill();
            }
        }
    }
}
