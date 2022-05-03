import std/strformat
import std/sugar

import sdl2
import sdl2/ttf

##################################################

proc setDrawColorUnpacked*(r: RendererPtr, c: Color): void =   
  discard r.setDrawColor(c.r, c.g, c.b, c.a)

proc `+`*(a, b: Color): Color =  
  (uint8(a.r+b.r), uint8(a.g+b.g), uint8(a.b+b.b), uint8(a.a+b.a))

proc `+`*(a: Color, b: uint8): Color =  
  (uint8(a.r+b), uint8(a.g+b), uint8(a.b+b), uint8(a.a+b))

proc shrink*(r: Rect, amt: int): Rect =  
  ((r.x+amt).cint, (r.y+amt.cint), (r.w-amt).cint, (r.h-amt).cint)

##################################################

const TEXT_RESOLUTION*: int = 100
const TEXT_REFIT_TO*: int = 20
const TEXT_REFIT*: float = TEXT_REFIT_TO/TEXT_RESOLUTION
const TEXT_VERT_DILATION*: float = 0.8

const LEFTWARD_ORIGIN*: cint = 10
const VERTICAL_PADDING*: cint = TEXT_REFIT_TO+5
const BACKGROUND_COLOR*: Color = (13.uint8, 11.uint8, 15.uint8, 255.uint8).Color
const HIGHLIGHT_COLOR*: Color = BACKGROUND_COLOR+100
const FOREGROUND_COLOR*: Color = BACKGROUND_COLOR+40
const FORESTGROUND_COLOR*: Color = (255.uint8, 255.uint8, 255.uint8, 255.uint8).Color

var FONT_DEFAULT*: FontPtr = openFont("./liberation-sans.ttf".cstring, TEXT_RESOLUTION.cint)

##################################################

type
  camelia* = object
    xbounds: Rect
    mouse: tuple[x, y: cint, buttons: uint8]

    verticalTracker: int
    currentTab: int

proc newCamelia*(): camelia = 
  result.xbounds = (x: 0.cint, y: 0.cint, w: 100.cint, h: 100.cint).Rect
  result.mouse = (x: 0.cint, y: 0.cint, buttons: 0.uint8)

  result.verticalTracker = 0
  result.currentTab = -1

proc isMouseInRect(c: var camelia, testee: Rect): bool =  
  (c.mouse.x > testee.x and
  c.mouse.y > testee.y and
  c.mouse.x < testee.x + testee.w and
  c.mouse.y < testee.y + testee.h)

proc textSize(f: FontPtr, label: string): tuple[w, h: int] =  
  var cw, ch: cint
  discard f.sizeText(label.cstring, addr cw, addr ch)
  (cw.int, ch.int)

proc easyText(r: RendererPtr, re: var Rect, label: string): void =   
  let surf: SurfacePtr = ttf.renderTextSolid(FONT_DEFAULT, label.cstring, FORESTGROUND_COLOR)
  let tex: TexturePtr = r.createTextureFromSurface(surf)
  r.copy(tex, nil, addr re)
  surf.freeSurface()
  tex.destroy()

proc drawButton(c: var camelia, r: RendererPtr, label: string, action: () -> void, rightSide: int = -1): void =  
  r.setDrawColorUnpacked(FOREGROUND_COLOR)
  c.verticalTracker += VERTICAL_PADDING
  let textWidth = FONT_DEFAULT.textSize(label).w
  var re: Rect = (x: LEFTWARD_ORIGIN, y: c.verticalTracker.cint, w: (TEXT_VERT_DILATION*TEXT_REFIT*textWidth.float).cint, h: (TEXT_REFIT*TEXT_RESOLUTION.float).cint).Rect
  var modRe = re
  if rightSide != -1:
    modRe.w = rightSide.cint
  if isMouseInRect(c, modRe):
    r.setDrawColorUnpacked(HIGHLIGHT_COLOR)
    if c.mouse.buttons == 1:
      action()
  r.fillRect(modRe)
  r.easyText(re, label)

proc drawToggle(c: var camelia, r: RendererPtr, label: string, value: var bool): void =  
  r.setDrawColorUnpacked(FOREGROUND_COLOR)
  c.verticalTracker += VERTICAL_PADDING
  var textWidth = FONT_DEFAULT.textSize("#").w
  var re: Rect = (x: LEFTWARD_ORIGIN, y: c.verticalTracker.cint, w: (TEXT_VERT_DILATION*TEXT_REFIT*textWidth.float).cint, h: (TEXT_REFIT*TEXT_RESOLUTION.float).cint).Rect
  if isMouseInRect(c, re):
    r.setDrawColorUnpacked(HIGHLIGHT_COLOR)
    if c.mouse.buttons == 1:
      value = not value
  r.fillRect(re)
  r.easyText(re, (if value: "X" else: " "))
  textWidth = FONT_DEFAULT.textSize(label).w
  var textRe: Rect = (x: LEFTWARD_ORIGIN+(TEXT_REFIT*TEXT_RESOLUTION.float).cint, y: c.verticalTracker.cint, w: (TEXT_VERT_DILATION*TEXT_REFIT*textWidth.float).cint, h: (TEXT_REFIT*TEXT_RESOLUTION.float).cint).Rect
  r.easyText(textRe, label)

proc drawMutex(c: var camelia, r: RendererPtr, label: string, entries: seq[string], value: var int): void =  
  r.setDrawColorUnpacked(FOREGROUND_COLOR)
  c.verticalTracker += VERTICAL_PADDING
  let textWidth = FONT_DEFAULT.textSize(label).w
  var re: Rect = (x: LEFTWARD_ORIGIN, y: c.verticalTracker.cint, w: (TEXT_VERT_DILATION*TEXT_REFIT*textWidth.float).cint, h: (TEXT_REFIT*TEXT_RESOLUTION.float).cint).Rect
  r.easyText(re, label)
  for ent_idx, ent in entries:
    var temp: bool = false
    c.verticalTracker -= VERTICAL_PADDING-(TEXT_REFIT*TEXT_RESOLUTION.float).int
    c.drawButton(r, entries[ent_idx], () => (temp = true), rightSide = (TEXT_VERT_DILATION*TEXT_REFIT*textWidth.float).int)
    if temp:
      value = ent_idx
  discard

proc render*(c: var camelia, r: RendererPtr): void = 
  c.verticalTracker = 0
  var mx, my: cint
  let buttons = getMouseState(mx, my)
  var oldButtons {.global.}: uint8
  c.mouse = (x: mx, y: my, buttons: buttons)
  if buttons == oldButtons:
    c.mouse.buttons = 0
  oldButtons = buttons

  r.setDrawColorUnpacked(FOREGROUND_COLOR)
  var a {.global.}: bool = false
  c.drawToggle(r, fmt"toggle test ({$a})", a)
  c.drawButton(r, "button test (reset toggle to false)", () => (a = false))
  var b {.global.}: int = 0
  let choices: seq[string] = @["ayy", "bee", "cee"]
  c.drawMutex(r, fmt"mutex test ({choices[b]})", choices, b)

##################################################
