use sdl, sdl-image
import sdl/[Core, Image]

use cairo
import cairo/Cairo

use glew
import glew

use glu
import glu

import os/Time, math

main: func {

    app := App new()
    app run()
    app quit()

}

App: class {

    width, height: Int
    context: CairoContext
    cairoSurface: CairoSurface
    image: CairoImageSurface
    imageWidth, imageHeight: Int

    textureID: GLuint

    sdlSurface: SdlSurface*
    screen: SdlSurface*
    surfData: UChar*

    x, y: Int
    angle := 0.0

    init: func {
	SDL init(SDL_INIT_EVERYTHING)

	(width, height) = (800, 600)
	SDL wmSetCaption("cairo bench", null)

	SDL glSetAttribute(SDL_GL_RED_SIZE, 5)
	SDL glSetAttribute(SDL_GL_GREEN_SIZE, 6)
	SDL glSetAttribute(SDL_GL_BLUE_SIZE, 5)
	SDL glSetAttribute(SDL_GL_DEPTH_SIZE, 16)
	SDL glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)
	screen = SDL setMode(width, height, 0, SDL_OPENGL)

	createCairoContext(4)
	initGL()
	reshape()

	image = CairoImageSurface new("assets/block.png")
	(imageWidth, imageHeight) = (image getWidth(), image getHeight())
	"Loaded %dx%d image" printfln(image getWidth(), image getHeight())
    }

    createCairoContext: func (channels: Int) {
	surfData = gc_malloc(channels * width * height * UChar size)
	if (!surfData) {
	    "create_cairo_context - Couldn't allocate buffer" println()
	    exit(1)
	}

	cairoSurface = CairoImageSurface new(surfData, CairoFormat ARGB32,
	    width, height, channels * width)
	if (cairoSurface status() != CairoStatus SUCCESS) {
	    "create_cairo_context - Couldn't create surface" println()
	    exit(1)
	}

	context = CairoContext new(cairoSurface)
	if (context status() != CairoStatus SUCCESS) {
	    "create_cairo_context - Couldn't create context" println()
	    exit(1)
	}
    }

    initGL: func {
	"OpenGL version: %s" printfln(glGetString (GL_VERSION))
	"OpenGL vendor: %s" printfln(glGetString (GL_VENDOR))
	"OpenGL renderer: %s" printfln(glGetString (GL_RENDERER))

	glClearColor(0.0, 0.0, 0.0, 0.0)
	glDisable(GL_DEPTH_TEST)
	glEnable(GL_BLEND)
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	glEnable(GL_TEXTURE_RECTANGLE_ARB)
    }

    reshape: func {
	glViewport(0, 0, width, height)
	glMatrixMode(GL_PROJECTION)
	glLoadIdentity()
	gluOrtho2D(0, width, height, 0)

	glClear(GL_COLOR_BUFFER_BIT)

	glDeleteTextures(1, textureID&)
	glGenTextures(1, textureID&)
	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textureID);
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
		      0,
		      GL_RGBA,
		      width,
		      height,
		      0,
		      GL_BGRA,
		      GL_UNSIGNED_BYTE,
		      null)
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL)
    }

    render: func {
	context setSourceRGB(0, 0, 0)
	context rectangle(0, 0, width, height)
	context paint()
	draw()

	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
	glClear(GL_COLOR_BUFFER_BIT)

	glPushMatrix()

	glBindTexture(GL_TEXTURE_RECTANGLE_ARB, textureID)
	glTexImage2D(GL_TEXTURE_RECTANGLE_ARB,
		     0,
		     GL_RGBA,
		     width,
		     height,
		     0,
		     GL_BGRA,
		     GL_UNSIGNED_BYTE,
		     surfData)

	glColor3f(1.0, 1.0, 1.0)
	glBegin(GL_QUADS)

	glTexCoord2f(0.0, 0.0)
	glVertex2f(0.0, 0.0)

	glTexCoord2f(width as Float, 0.0)
	glVertex2f(width, 0.0)

	glTexCoord2f(width as Float, height as Float)
	glVertex2f(width, height)

	glTexCoord2f(0.0, height as Float)
	glVertex2f(0.0, height)

	glEnd()

	glPopMatrix()

	SDL glSwapBuffers()
    }

    run: func {
	numFrames := 200

	t1 := Time runTime
	for (i in 0..numFrames) {
	    render()
	}
	t2 := Time runTime

	millis := t2 - t1
	"Rendered %d frames in %d milliseconds" printfln(numFrames, millis)
	"Each frame had %d sprites" printfln((numRectanglesX() + 1) * (numRectanglesY() + 1))
	fps := (numFrames as Float)/ (millis / 1000.0)
	"Performance: %.2f FPS" printfln(fps)
    }

    numRectanglesX: func -> Int {
	(width / image getWidth() / 0.5 + 1)
    }

    numRectanglesY: func -> Int {
	(height / image getHeight() / 0.5 + 1)
    }

    draw: func {
	for (x in -1..numRectanglesX()) for (y in -1..numRectanglesY()) {
	    drawRectangle(x, y)
	}

	x = (x + 1) % (image getWidth() / 2)
	angle = angle + (PI * 0.02)
	if (angle > 2 * PI) {
	    angle -= 2 * PI
	}
    }

    drawRectangle: func (offsetX, offsetY: Int) {
	context save()

	context scale(0.5, 0.5)

	context translate(x * 2 + offsetX * image getWidth(),
		    	  y * 2 + offsetY * image getHeight())

	context translate( imageWidth / 2,  imageHeight / 2)
	context rotate(angle)
	context translate(-imageWidth / 2, -imageHeight / 2)

	context setSourceSurface(image, 0, 0)
	context rectangle(0, 0, image getWidth(), image getHeight())
	context paint()

	context restore()
    }

    quit: func {
	SDL quit()
    }

}

