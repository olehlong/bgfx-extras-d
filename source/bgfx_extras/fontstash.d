module bgfx_extras.fontstash;

private {
    import derelict.freetype.types : FT_Face;
}

//
// Copyright (c) 2009-2013 Mikko Mononen memon@inside.org
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//

enum FONS_INVALID = -1;

enum FONS_SCRATCH_BUF_SIZE = 16000;
enum FONS_HASH_LUT_SIZE = 256;
enum FONS_INIT_FONTS = 4;
enum FONS_INIT_GLYPHS = 256;
enum FONS_INIT_ATLAS_NODES = 256;
enum FONS_VERTEX_COUNT = 1024;
enum FONS_MAX_STATES = 20;

enum FONSflags {
	FONS_ZERO_TOPLEFT = 1,
	FONS_ZERO_BOTTOMLEFT = 2,
}

enum FONSalign {
	// Horizontal align
	FONS_ALIGN_LEFT 	= 1<<0,	// Default
	FONS_ALIGN_CENTER 	= 1<<1,
	FONS_ALIGN_RIGHT 	= 1<<2,
	// Vertical align
	FONS_ALIGN_TOP 		= 1<<3,
	FONS_ALIGN_MIDDLE	= 1<<4,
	FONS_ALIGN_BOTTOM	= 1<<5,
	FONS_ALIGN_BASELINE	= 1<<6, // Default
}

enum FONSerrorCode {
	// Font atlas is full.
	FONS_ATLAS_FULL = 1,
	// Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.		
	FONS_SCRATCH_FULL = 2,
	// Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
	FONS_STATES_OVERFLOW = 3,
	// Trying to pop too many states fonsPopState().
	FONS_STATES_UNDERFLOW = 4,
}

struct FONSparams {
	int width, height;
	ubyte flags;
	void* userPtr;
    int delegate(void* uptr, int width, int height) renderCreate;
	int delegate(void* uptr, int width, int height) renderResize;
	void delegate(void* uptr, int* rect, ubyte* data) renderUpdate;
	void delegate(void* uptr, float* verts, float* tcoords, uint* colors, int nverts) renderDraw;
	void delegate(void* uptr) renderDelete;
}

struct FONSquad {
	float x0,y0,s0,t0;
	float x1,y1,s1,t1;
}

struct FONStextIter {
	float x, y, nextx, nexty, scale, spacing;
	uint codepoint;
	short isize, iblur;
	FONSfont* font;
	int prevGlyphIndex;
	const(char)* str;
	const(char)* next;
	const(char)* end;
	uint utf8state;
}

struct FONSttFontImpl {
	FT_Face font;
}

struct FONSglyph {
	uint codepoint;
	int index;
	int next;
	short size, blur;
	short x0,y0,x1,y1;
	short xadv,xoff,yoff;
}

struct FONSfont {
	FONSttFontImpl font;
	char[64] name;
	ubyte* data;
	int dataSize;
	ubyte freeData;
	float ascender;
	float descender;
	float lineh;
	FONSglyph* glyphs;
	int cglyphs;
	int nglyphs;
	int[FONS_HASH_LUT_SIZE] lut;
}

struct FONSstate {
	int font;
	int align_;
	float size;
	uint color;
	float blur;
	float spacing;
}

struct FONSatlasNode {
    short x, y, width;
}

struct FONSatlas {
	int width, height;
	FONSatlasNode* nodes;
	int nnodes;
	int cnodes;
}

struct FONScontext {
	FONSparams params;
	float itw,ith;
	ubyte* texData;
	int[4] dirtyRect;
	FONSfont** fonts;
	FONSatlas* atlas;
	int cfonts;
	int nfonts;
	float[FONS_VERTEX_COUNT*2] verts;
	float[FONS_VERTEX_COUNT*2] tcoords;
	uint[FONS_VERTEX_COUNT] colors;
	int nverts;
	ubyte* scratch;
	int nscratch;
	FONSstate[FONS_MAX_STATES] states;
	int nstates;
	void delegate(void* uptr, int error, int val) handleError;
	void* errorUptr;
}

// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.

enum FONS_UTF8_ACCEPT = 0;
enum FONS_UTF8_REJECT = 12;