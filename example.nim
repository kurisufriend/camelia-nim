import sdl2
import sdl2/ttf
import camelia

discard sdl2.init(INIT_EVERYTHING)
discard ttfInit()

var window: WindowPtr = createWindow("hello", 100, 10, 640, 480, SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)
var renderer: RendererPtr = createRenderer(window, -1, Renderer_Accelerated or Renderer_TargetTexture)

var running: bool = true
var e: Event = sdl2.defaultEvent

var c: camelia = newCamelia()

FONT_DEFAULT = openFont("./NotoSans-Regular.ttf".cstring, TEXT_RESOLUTION.cint)

while running:
  while pollEvent(e):
    if e.kind == QuitEvent:
      running = false

  renderer.setDrawColorUnpacked(BACKGROUND_COLOR)
  renderer.clear()

  c.render(renderer)

  renderer.present()

destroy window
destroy renderer
