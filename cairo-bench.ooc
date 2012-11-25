use sdl, sdl-image
import sdl/[Core, Image]

use cairo
import cairo/Cairo

import os/Time

main: func {

    app := App new()
    app run()
    app quit()

}

App: class {

    width, height: Int
    context: CairoContext
    image: CairoImageSurface

    sdlSurface: SdlSurface*
    screen: SdlSurface*

    x, y: Int

    init: func {
	SDL init(SDL_INIT_EVERYTHING)

	(width, height) = (800, 600)
	screen = SDL setMode(width, height, 0, SDL_HWSURFACE)
	SDL wmSetCaption("cairo bench", null)

	sdlSurface = SDL createRgbSurface(SDL_HWSURFACE, width, height, 32,
	    0x00FF0000, 0x0000FF00, 0x000000FF, 0)

	cairoSurface := CairoImageSurface new(sdlSurface@ pixels, CairoFormat RGB24,
	    sdlSurface@ w, sdlSurface@ h, sdlSurface@ pitch)

	context = CairoContext new(cairoSurface)

	image = CairoImageSurface new("assets/block.png")
	"Loaded %dx%d image" printfln(image getWidth(), image getHeight())
    }

    render: func {
	context setSourceRGB(0, 0, 0)
	context rectangle(0, 0, width, height)
	context paint()

	draw()

	SDL blitSurface(sdlSurface, null, screen, null)
	SDL flip(screen)
    }

    run: func {
	numFrames := 2_000

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
    }

    drawRectangle: func (offsetX, offsetY: Int) {
	context save()
	context translate(x + offsetX * image getWidth() * 0.5,
		    	  y + offsetY * image getHeight() * 0.5)
	context scale(0.5, 0.5)

	context setSourceSurface(image, 0, 0)
	context rectangle(0, 0, image getWidth(), image getHeight())
	context clip()
	context paint()

	context restore()
    }

    quit: func {
	SDL quit()
    }

}

