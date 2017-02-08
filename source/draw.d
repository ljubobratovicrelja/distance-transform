module draw;

import std.stdio : writeln;
import std.math : cos, sin;
import std.conv : to;
import std.range : lockstep;
import std.algorithm : map, filter, each;
import std.string : toStringz;

import dcv;

import derelict.freetype.ft;

FT_Library library;
FT_Face face;

immutable fontPath = "/System/Library/Fonts/Menlo.ttc";
immutable black = Color(0f, 0f, 0f);
immutable white = Color(1f, 1f, 1f);
immutable red = Color(1f, 0f, 0f);
immutable green = Color(0f, 1f, 0f);
immutable blue = Color(0f, 0f, 1f);

struct Color
{
    float r, g, b, a;

    @disable this();

    this(float r, float g, float b, float a = 1f)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    this(inout Color other)
    {
        this.r = other.r;
        this.g = other.g;
        this.b = other.b;
        this.a = other.a;
    }

    @property getRed() const
    {
        return r.getColor;
    }

    @property getGreen() const
    {
        return g.getColor;
    }

    @property getBlue() const
    {
        return b.getColor;
    }

    @property ubyte[3] rgb() const
    {
        ubyte[3] _rgb;
        _rgb[0] = getRed();
        _rgb[1] = getGreen();
        _rgb[2] = getBlue();
        return _rgb;
    }

    void drawOn(Pixel)(Pixel pixel)
    {
        auto _rgb = this.rgb;
        pixel[0] = cast(ubyte)(cast(float)pixel[0] * (1f - a) + cast(float)_rgb[0] * a);
        pixel[1] = cast(ubyte)(cast(float)pixel[1] * (1f - a) + cast(float)_rgb[1] * a);
        pixel[2] = cast(ubyte)(cast(float)pixel[2] * (1f - a) + cast(float)_rgb[2] * a);
    }
}

auto getColor(float c)
{
    return c > 1f ? ubyte(255) : c <= 0f ? ubyte(0) : cast(ubyte)(c * 255f);
}

auto drawGrid(size_t cellSize, size_t cellCount, size_t margin, Color color)
{
    auto pmargin = margin * cellSize;
    auto im = slice!ubyte([cellSize * cellCount + pmargin * 2,
        cellSize * cellCount + pmargin * 2, 3], ubyte(255));

    auto imp = im.pack!1;

    foreach (i; 0 .. cellCount)
    {
        auto cellColRow = i * cellSize + pmargin;

        imp[cellColRow, pmargin .. $ - pmargin].each!(v => v[] = color.rgb[]);
        imp[pmargin .. $ - pmargin, cellColRow].each!(v => v[] = color.rgb[]);
    }

    imp[$ - 1 - pmargin, pmargin .. $ - pmargin].each!(v => v[] = color.rgb[]);
    imp[pmargin .. $ - pmargin, $ - 1 - pmargin].each!(v => v[] = color.rgb[]);

    return im;
}

auto drawBorder(Slice!(3, ubyte*) cell, Color color)
{
    cell[0, 0 .. $, 0 .. $].pack!1.ndEach!((e) => color.drawOn(e));
    cell[$ - 1, 0 .. $, 0 .. $].pack!1.ndEach!((e) => color.drawOn(e));
    cell[0 .. $, 0, 0 .. $].pack!1.ndEach!((e) => color.drawOn(e));
    cell[0 .. $, $ - 1, 0 .. $].pack!1.ndEach!((e) => color.drawOn(e));
}

auto getCell(Slice!(3, ubyte*) image, size_t x, size_t y, size_t cellSize)
{
    return image[y * cellSize .. (y + 1) * cellSize, x * cellSize .. (x + 1) * cellSize,
        0 .. $];
}

void drawOnCell(Slice!(3, ubyte*) image, string text, Color color, size_t x,
    size_t y, size_t cellSize)
{
    auto px = x * cellSize;
    auto py = (y + 1) * cellSize - (cellSize / 5) - (cellSize / 8);

    auto scale = 0.004f;

    if (text.length == 1)
        px += cellSize / 3;
    else if (text.length == 2)
        px += cellSize / 6;

    drawText(image, text, color, px, py, scale * cast(float)cellSize);
}

void selectCell(Slice!(3, ubyte*) image, Color color, size_t x, size_t y, size_t cellSize)
{
    image[y * cellSize .. (y + 1) * cellSize, x * cellSize .. (x + 1) * cellSize, 0 .. $].pack!1.ndEach!(
        (p) { color.drawOn(p); });
}

void drawText(Slice!(3, ubyte*) image, string text, Color color, size_t x,
    size_t y, float scale = 1f, int dpi = 100)
{
    import std.math : round;

    FT_GlyphSlot slot;
    FT_Matrix matrix; /* transformation matrix */
    FT_Vector pen; /* untransformed origin  */
    FT_Error error;
    immutable target_height = cast(int)image.length!0;
    immutable width = cast(int)(image.length!1);
    immutable height = cast(int)(image.length!0);
    immutable c_width = cast(int)round(100f * scale);
    immutable c_height = cast(int)round(100f * scale);

    error = FT_Set_Char_Size(face, c_width * 64, c_height * 64, 100, 0); /* set character size */
    /* error handling omitted */

    slot = face.glyph; /* set up matrix */
    matrix.xx = cast(FT_Fixed)(cos(0f) * 0x10000L);
    matrix.xy = cast(FT_Fixed)(-sin(0f) * 0x10000L);
    matrix.yx = cast(FT_Fixed)(sin(0f) * 0x10000L);
    matrix.yy = cast(FT_Fixed)(cos(0f) * 0x10000L);

    /* the pen position in 26.6 cartesian space coordinates; */
    pen.x = x * 64;
    pen.y = (target_height - y) * 64;

    // draw characters
    foreach (c; text)
    {
        drawCharacter(c, image, color, face, matrix, slot, pen);
    }
}

void drawCharacter(immutable char c, Slice!(3, ubyte*) image, Color color,
    ref FT_Face face, ref FT_Matrix matrix, ref FT_GlyphSlot slot, ref FT_Vector pen)
{
    FT_Error error; /* set transformation */
    FT_Set_Transform(face, &matrix, &pen); /* load glyph image into the slot (erase previous one) */
    error = FT_Load_Char(face, c, FT_LOAD_RENDER);

    if (error)
        return;
    error = FT_Render_Glyph(face.glyph, FT_RENDER_MODE_NORMAL);
    if (error)
        return;

    renderBitmap(&slot.bitmap, slot.bitmap_left,
        cast(int)image.length!0 - slot.bitmap_top, image, color); /* increment pen position */
    pen.x += slot.advance.x;
    pen.y += slot.advance.y;
}

static void renderBitmap(FT_Bitmap* bitmap, int x, int y, Slice!(3, ubyte*) image,
    Color color)
{

    int width = cast(int)image.length!1;
    int height = cast(int)image.length!0;
    int x_max = x + bitmap.width;
    int y_max = y + bitmap.rows;
    if (x < 0)
        x = 0;
    if (y < 0)
        y = 0;
    if (x >= width || y >= height)
        return;
    if (x_max >= width)
        x_max = width - 1;
    if (y_max >= height)
        y_max = height - 1;
    auto bw = x_max - x;
    auto bh = y_max - y;

    if (bw < 1 || bh < 1)
        return;

    auto roi = image[y .. y_max, x .. x_max, 0 .. $];
    auto alpha = bitmap.buffer[0 .. bh * bw].map!(e => cast(float)e / 255f).sliced(bh,
        bw);
    foreach (o, a; lockstep(roi.pack!1.byElement, alpha.byElement))
    {
        auto c = Color(color);
        c.a *= a;
        c.drawOn(o);
        //o = cast(T)((a * color) + (1f - a) * o);
    }
}

static this()
{
    DerelictFT.load();
    auto fp = fontPath.toStringz;

    FT_Error error = FT_Init_FreeType(&library);

    if (error)
    {
        writeln("FT error initialization.");
        return;
    }

    error = FT_New_Face(library, fp, 0, &face);
    if (error == FT_Err_Unknown_File_Format)
    {
        writeln(
            `the font file could be opened and read, but it appears that its font format is unsupported`);
    }
    else if (error)
    {
        writeln(
            `another error code means that the font file could not be opened or read, or that it is broken...`);
    }

    error = FT_New_Face(library, fp, 0, &face); /* create face object */
    if (error)
    {
        writeln("Unable to create the font face.");
    }
}

void drawDemoResult(ref Slice!(3, ubyte*) buffer, Slice!(2, float*) data,
    Slice!(2, float*) dt, size_t cellResolution, size_t margin)
{
    size_t[3] shape = [
        (dt.length!0 + margin * 2) * cellResolution, (dt.length!1 + margin * 2) * cellResolution,
        3
    ];

    if (buffer.shape != shape)
        buffer = slice!ubyte(shape, ubyte(255));
    else
        buffer[] = ubyte(255);

    foreach (i; 0 .. dt.length!0)
    {
        foreach (j; 0 .. dt.length!1)
        {
            auto x = margin + j;
            auto y = margin + i;

            auto c = Color(black);
            c.a = 0.1f + 0.2f * dt[i, j];
            if (c.a > 1f)
                c.a = 1f;

            buffer.getCell(x, y, cellResolution).drawBorder(black);
            buffer.drawOnCell(dt[i, j].to!string, c, x, y, cellResolution);

            if (data[i, j] > 0f)
                buffer.selectCell(Color(0f, 0f, 0f, 0.15f), x, y, cellResolution);
        }
    }
}
