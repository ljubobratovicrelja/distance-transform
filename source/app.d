import std.stdio;
import std.getopt;
import std.range;
import std.path;
import std.file;
import std.conv;
import std.string;
import std.algorithm;
import std.math;
import std.typecons;
import std.typetuple;
import core.stdc.stdlib;

import mir.ndslice.iteration : reversed;
import mir.ndslice.algorithm;

import dcv;
import draw;

immutable WIN_TITLE = "Distance Transform Demo";

enum Program
{
    none, // null program, default
    animation, // animation program - shows how the distance transform algorithm works.
    visualization // visualization program - demonstrates distance transform functionality, step-by-step.
}

enum DemoResult
{
    show, // show resulting images on screen.
    write // write resulting images in sequence on the file system.
}

void main(string[] args)
{
    Program program = Program.none;

    auto result = getopt(args, std.getopt.config.passThrough, "program|p",
        "Which program to run - animation or visualization.", &program);

    if (result.helpWanted)
    {
        args ~= "-h";
    }

    if (program == Program.animation)
        animDemo(args);
    else if (program == Program.visualization)
        visualizationDemo(args);
    else
    {
        defaultGetoptPrinter("Distance Transform Program", result.options);
    }

}

/*
Animation demo.

Runs Rosenfeld and Phaltz 2-pass distance transform algorithm on a simple
binary image, and visualizes the process.

Program arguments:
-s            --size Size of the binary image used in the demo.
-b          --border Border size.
-c --cell-resolution Resolution (pixel size) of the matrix cell in the demo.
-m          --margin Margin in animation drawing.
-w       --wait-time Wait time between each algoritm step in the demo.
-r     --demo-result Result type of the demo (show, or write). If write, output must be given.
-o          --output Output path.
-h            --help This help information.

*/
void animDemo(string[] args)
{
    // demo arguments
    size_t matsize = 20;
    size_t cellResolution = 50;
    size_t bborder = 3;
    size_t margin = 2;
    size_t waitTime = 0;
    DemoResult demoResultType = DemoResult.show;
    string outputPath = "";

    // demo variables
    size_t frameNum = 0;
    size_t imres = (matsize + margin) * cellResolution;

    auto result = getopt(args, "size|s",
        "Size of the binary image used in the demo.", &matsize, "border|b",
        "Border size (cell count).", &bborder, "cell-resolution|c",
        "Resolution (pixel size) of the matrix cell in the demo.",
        &cellResolution, "margin|m", "Margin in animation drawing.", &margin,
        "wait-time|w", "Wait time between each algoritm step in the demo.",
        &waitTime,
        "demo-result|r",
        "Result type of the demo (show, or write). If write, output must be given.",
        &demoResultType, "output|o", "Output path.", &outputPath);

    auto printHelp = () {
        defaultGetoptPrinter("Distance Transform Animation.", result.options);
        exit(0);
    };

    if (result.helpWanted)
    {
        printHelp();
    }

    if (demoResultType == DemoResult.write && !outputPath.exists)
    {
        writeln("Given output path does not exist.");
        printHelp();
    }

    // Create buffers
    auto data = slice!float([matsize, matsize], 1f);
    auto dt = slice!float([matsize, matsize], 0f);
    auto viz = slice!ubyte([imres, imres, 3], ubyte(255));

    // Create central hole in the input data.
    data[bborder .. $ - bborder, bborder .. $ - bborder] = 0f;

    // Run the demo.
    drawDemoResult(viz, data, dt, cellResolution, margin);

    writeln("Running the demo. Press \"q\" to exit.");

    // Forward scanning
    foreach (i; 1 .. data.length!0 - 1)
        foreach (j; 1 .. data.length!1 - 1)
        {
            if (data[i, j] < 1f)
            {
                auto dtw = dt[i - 1 .. i + 2, j - 1 .. j + 2];
                auto mindist = min(dtw[0, 1], dtw[1, 0]);
                dtw[1, 1] = mindist + 1f;

                auto cns = Color(black);
                cns.a = 0.1f;
                auto cs = Color(red);
                cs.a = 0.2f;

                viz.selectCell(Color(0.0f, 0.75f, 0.75f, 0.4f), margin + j,
                    margin + i, cellResolution);

                if (dt[i - 1, j] > dt[i, j - 1])
                {
                    viz.selectCell(cs, margin + j - 1, margin + i, cellResolution);
                    viz.selectCell(cns, margin + j, margin + i - 1, cellResolution);
                }
                else if (dt[i - 1, j] < dt[i, j - 1])
                {
                    viz.selectCell(cns, margin + j - 1, margin + i, cellResolution);
                    viz.selectCell(cs, margin + j, margin + i - 1, cellResolution);
                }
                else
                {
                    viz.selectCell(cs, margin + j - 1, margin + i, cellResolution);
                    viz.selectCell(cs, margin + j, margin + i - 1, cellResolution);
                }

                viz.drawOnCell(dt[i, j - 1].to!string, black, margin + j - 1,
                    margin + i, cellResolution);
                viz.drawOnCell(dt[i - 1, j].to!string, black, margin + j,
                    margin + i - 1, cellResolution);

                viz.drawOnCell(dt[i, j].to!string, black, margin + j, margin + i, cellResolution);

                if (demoResultType == DemoResult.show)
                {
                    viz.imshow(WIN_TITLE);
                    char c = cast(char)waitKey(waitTime * 3);
                    if (c == 'q')
                        exit(0);
                }
                else
                {
                    writeFrame(viz, outputPath, frameNum++);
                }

                drawDemoResult(viz, data, dt, cellResolution, margin);

                if (demoResultType == DemoResult.show)
                {
                    viz.imshow(WIN_TITLE);
                    char c = cast(char)waitKey(waitTime);
                    if (c == 'q')
                        exit(0);
                }
                else
                {
                    writeFrame(viz, outputPath, frameNum++);
                }
            }
        }

    // Backward scanning
    foreach_reverse (i; 1 .. data.length!0 - 1)
        foreach_reverse (j; 1 .. data.length!1 - 1)
        {
            if (data[i, j] < 1f)
            {
                auto dtw = dt[i - 1 .. i + 2, j - 1 .. j + 2];
                auto mindist = min(dtw[2, 1], dtw[1, 2]);
                dtw[1, 1] = min(dtw[1, 1], mindist + 1f);

                auto cns = Color(black);
                cns.a = 0.1f;
                auto cs = Color(blue);
                cs.a = 0.2f;

                viz.selectCell(Color(0.0f, 0.75f, 0.75f, 0.4f), margin + j,
                    margin + i, cellResolution);

                if (dt[i + 1, j] > dt[i, j + 1])
                {
                    viz.selectCell(cs, margin + j + 1, margin + i, cellResolution);
                    viz.selectCell(cns, margin + j, margin + i + 1, cellResolution);
                }
                else if (dt[i + 1, j] < dt[i, j + 1])
                {
                    viz.selectCell(cns, margin + j + 1, margin + i, cellResolution);
                    viz.selectCell(cs, margin + j, margin + i + 1, cellResolution);
                }
                else
                {
                    viz.selectCell(cs, margin + j + 1, margin + i, cellResolution);
                    viz.selectCell(cs, margin + j, margin + i + 1, cellResolution);
                }

                viz.drawOnCell(dt[i, j + 1].to!string, black, margin + j + 1,
                    margin + i, cellResolution);
                viz.drawOnCell(dt[i + 1, j].to!string, black, margin + j,
                    margin + i + 1, cellResolution);

                viz.drawOnCell(dt[i, j].to!string, black, margin + j, margin + i, cellResolution);

                if (demoResultType == DemoResult.show)
                {
                    viz.imshow(WIN_TITLE);
                    char c = cast(char)waitKey(waitTime);
                    if (c == 'q')
                        exit(0);
                }
                else
                {
                    writeFrame(viz, outputPath, frameNum++);
                }

                drawDemoResult(viz, data, dt, cellResolution, margin);

                if (demoResultType == DemoResult.show)
                {
                    viz.imshow(WIN_TITLE);
                    char c = cast(char)waitKey(waitTime);
                    if (c == 'q')
                        exit(0);
                }
                else
                {
                    writeFrame(viz, outputPath, frameNum++);
                }
            }
        }

    writeln("Done! Press any key to exit...");
    waitKey;
}

// Distance transform forward kernel.
static void cityBlockForward(Slice!(2, float*) w)
{
    auto mindist = min(w[0, 1], w[1, 0]);
    if (w[1, 1] < 1f && mindist > 0f)
    {
        w[1, 1] = mindist + 1f;
    }
}

// Distance transform bachward kernel.
static void cityBlockBackward(Slice!(2, float*) w)
{
    auto mindist = min(w[0, 1], w[1, 0]);
    if (mindist > 0f)
    {
        w[1, 1] = min(w[1, 1], mindist + 1f);
    }
}

/*
Distance transform visualization demo.

Load an image, binarize it and apply distance transform algorithm on it.
Algorithm evaluation is visualized after evaluation.

Program arguments:
-i         --input Path to the input image. Image should be easy for binarization.
-p --process-scale Image scaling for processing.
-v     --viz-scale Image scaling for visualization.
-w  --viz-win-size Visualization window size.
-r   --demo-result Result type of the demo (show, or write). If write, output must be given.
-o        --output Output path.
-h          --help This help information.
*/
void visualizationDemo(string[] args)
{

    string imagePath = "";
    float processingScale = 1f;
    float visualizationScale = 1f;
    size_t vizWinSize = 9;
    DemoResult demoResultType = DemoResult.show;
    string outputPath;

    size_t frameNum = 0;
    Image image;

    auto result = getopt(args, "input|i",
        "Path to the input image. Image should be easy for binarization.",
        &imagePath, "process-scale|p", "Image scaling for processing.",
        &processingScale, "viz-scale|v", "Image scaling for visualization.",
        &visualizationScale, "viz-win-size|w", "Visualization window size.",
        &vizWinSize,
        "demo-result|r",
        "Result type of the demo (show, or write). If write, output must be given.",
        &demoResultType, "output|o", "Output path.", &outputPath);

    auto printHelp = () {
        defaultGetoptPrinter("Distance Transform Visualization.", result.options);
        exit(0);
    };

    try
    {
        image = imread(imagePath);
    }
    catch
    {
        writeln("Unable to read image from: " ~ imagePath);
        printHelp();
    }

    if (result.helpWanted)
    {
        printHelp();
    }

    if (demoResultType == DemoResult.write && !outputPath.exists)
    {
        writeln("Given output path does not exist.");
        printHelp();
    }

    // Take the image data and binarize it.
    auto data = image.sliced[0 .. $, 0 .. $, 1].as!float.slice.threshold!float(150f);
    auto dt = data.slice; // distance transform result buffer
    auto viz = data.mapSlice!(e => (e > 0.0f) ? cast(ubyte)255 : cast(ubyte)0).slice; // visualization buffer.

    viz.imshow("Input Image");

    // Forward scanning
    dt.windows(3, 3).ndEach!cityBlockForward;

    // Show(or write) the result step-by-step
    auto dtshow = dt.slice.ranged(0f, 255f).as!ubyte.slice;
    viz = visualizeForwardDt(viz, dtshow, vizWinSize, demoResultType, frameNum, outputPath);

    // Backward scanning
    dt.reversed!(0, 1).windows(3, 3).ndEach!cityBlockBackward;
    dtshow = dt.slice.ranged(0f, 255f).as!ubyte.slice;

    visualizeBackwardDt(viz, dtshow, vizWinSize, demoResultType, frameNum, outputPath);

    dtshow = dt.ranged(0f, 255f).as!ubyte.slice;
    dtshow.imshow(WIN_TITLE);

    waitKey;
}

auto visualizeForwardDt(Slice!(2, ubyte*) input, Slice!(2, ubyte*) dt,
    size_t vizWindowSize, DemoResult demoResultType, ref size_t frameNum, string outputPath)
{
    auto draw = input.slice;
    auto pack = assumeSameStructure!("draw", "dt")(draw, dt).blocks(vizWindowSize,
        vizWindowSize);
    auto pbe = pack.byElement;
    pbe.front.byElement.each!(e => e.draw = e.dt);
    pbe.popFront;
    foreach (p; pbe)
    {
        if (p.byElement.map!(a => a.dt).reduce!max)
        {
            if (demoResultType == DemoResult.show)
            {
                p[0 .. $, 1].byElement.each!(e => e.draw = cast(ubyte)255);
                p[0 .. $, $ - 1].byElement.each!(e => e.draw = cast(ubyte)255);
                p[1, 0 .. $].byElement.each!(e => e.draw = cast(ubyte)255);
                p[$ - 1, 0 .. $].byElement.each!(e => e.draw = cast(ubyte)255);

                draw.imshow(WIN_TITLE);
                int c = waitKey(30);

                if (cast(char)c == 'q')
                    exit(0);
            }
            else
            {
                writeFrame(draw, outputPath, frameNum++);
            }
        }

        p.byElement.each!(e => e.draw = e.dt);
    }

    return draw;
}

void visualizeBackwardDt(Slice!(2, ubyte*) input, Slice!(2, ubyte*) dt,
    size_t vizWindowSize, DemoResult demoResultType, ref size_t frameNum, string outputPath)
{
    auto draw = input.slice;
    auto pack = assumeSameStructure!("draw", "dt")(draw, dt).blocks(vizWindowSize,
        vizWindowSize);
    auto pbe = pack.byElement;
    pbe.back.byElement.each!(e => e.draw = e.dt);
    pbe.popBack;

    foreach_reverse (p; pbe)
    {
        if (p.byElement.map!(a => a.dt).reduce!max)
        {
            if (demoResultType == DemoResult.show)
            {
                p[0 .. $, 1].byElement.each!(e => e.draw = cast(ubyte)255);
                p[0 .. $, $ - 1].byElement.each!(e => e.draw = cast(ubyte)255);
                p[1, 0 .. $].byElement.each!(e => e.draw = cast(ubyte)255);
                p[$ - 1, 0 .. $].byElement.each!(e => e.draw = cast(ubyte)255);

                draw.imshow(WIN_TITLE);
                int c = waitKey(30);

                if (cast(char)c == 'q')
                    exit(0);
            }
            else
            {
                writeFrame(draw, outputPath, frameNum++);
            }

            p.byElement.each!(e => e.draw = e.dt);
        }
    }
}

void writeFrame(size_t N)(Slice!(N, ubyte*) image, string outpath, size_t f)
{
    auto fs = f.to!string;
    auto p = ('0'.repeat(5 - fs.length).array ~ fs).to!string;
    auto o = outpath ~ "/frame_" ~ p ~ ".png";
    image.asImage.imwrite(o);
    writeln(o);
}
