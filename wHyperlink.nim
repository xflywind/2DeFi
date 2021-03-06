import
  winim/[winstr, utils],
  winim/inc/[winuser, shellapi]

import wNim/[wApp, wMacros, wStaticText, wFont, wCursor]

type
  wMyLinkEvent = ref object of wCommandEvent

wEventRegister(wMyLinkEvent):
  wEvent_OpenUrl

type
  wHyperlink* = ref object of wStaticText
    mUrl: string
    mMarkedColor: wColor
    mVisitedColor: wColor
    mNormalColor: wColor
    mHoverFont: wFont
    mNormalFont: wFont
    mIsMouseHover: bool
    mIsPressed: bool
    mIsVisited: bool


wClass(wHyperlink of wStaticText):
  proc getVisitedOrNormalColor(self: wHyperlink): wColor {.validate, property.} =
    result = if self.mIsVisited: self.mVisitedColor else: self.mNormalColor

  proc setFont*(self: wHyperlink, font: wFont) {.validate, property.} =
    self.wWindow.setFont(font)
    self.mNormalFont = font
    self.fit()

  proc getHoverFont*(self: wHyperlink): wFont {.validate, property.} =
    result = self.mHoverFont

  proc setHoverFont*(self: wHyperlink, font: wFont) {.validate, property.} =
    self.mHoverFont = font
    if self.mIsMouseHover:
      self.wWindow.setFont(self.mHoverFont)
      self.fit()

  proc getMarkedColor*(self: wHyperlink): wColor {.validate, property.} =
    result = self.mMarkedColor

  proc setMarkedColor*(self: wHyperlink, color: wColor) {.validate, property.} =
    self.mMarkedColor = color
    if self.mIsPressed:
      self.setForegroundColor(self.mMarkedColor)
      self.refresh()

  proc getNormalColor*(self: wHyperlink): wColor {.validate, property.} =
    result = self.mNormalColor

  proc setNormalColor*(self: wHyperlink, color: wColor) {.validate, property.} =
    self.mNormalColor = color
    if not self.mIsPressed:
      self.setForegroundColor(self.visitedOrNormalColor)
      self.refresh()

  proc getVisitedColor*(self: wHyperlink): wColor {.validate, property.} =
    result = self.mVisitedColor

  proc setVisitedColor*(self: wHyperlink, color: wColor) {.validate, property.} =
    self.mVisitedColor = color
    if not self.mIsPressed:
      self.setForegroundColor(self.visitedOrNormalColor)
      self.refresh()

  proc getUrl*(self: wHyperlink): string {.validate, property.} =
    result = self.mUrl

  proc setUrl*(self: wHyperlink, url: string) {.validate, property.} =
    self.mUrl = url

  proc setVisited*(self: wHyperlink, isVisited = true) {.validate, property.} =
    self.mIsVisited = isVisited

  proc getVisited*(self: wHyperlink): bool {.validate, property.} =
    result = self.mIsVisited

  proc init*(self: wHyperlink, parent: wWindow, id = wDefaultID, label: string,
      url: string, pos = wDefaultPoint, size = wDefaultSize, style: wStyle = 0) =
    echo "wHyperlink init"
    self.wStaticText.init(parent, id, label, pos, size, style)
    self.mUrl = url
    self.mMarkedColor = wRed
    self.mVisitedColor = 0x8B1A55
    self.mNormalColor = wBlue
    self.mIsMouseHover = false
    self.mIsPressed = false
    self.mIsVisited = false

    self.fit()
    self.setCursor(wHandCursor)
    self.setForegroundColor(self.mNormalColor)

    self.mNormalFont = self.getFont()
    self.mHoverFont = Font(self.mNormalFont)
    self.mHoverFont.underlined = true

    self.wEvent_MouseEnter do ():
      self.mIsMouseHover = true
      self.wWindow.setFont(self.mHoverFont)
      if self.mIsPressed:
        self.setForegroundColor(self.mMarkedColor)
      else:
        self.setForegroundColor(self.visitedOrNormalColor)
      self.fit()
      self.refresh()

    self.wEvent_MouseLeave do ():
      self.mIsMouseHover = false
      self.wWindow.setFont(self.mNormalFont)
      self.setForegroundColor(self.visitedOrNormalColor)
      self.fit()
      self.refresh()

    self.wEvent_LeftDown do ():
      self.mIsPressed = true
      self.captureMouse()
      self.setForegroundColor(self.mMarkedColor)
      self.refresh()

    self.wEvent_LeftUp do ():
      let isPressed = self.mIsPressed
      self.mIsPressed = false
      self.releaseMouse()
      self.setForegroundColor(self.visitedOrNormalColor)
      self.refresh()

      if self.mIsMouseHover and isPressed:
        if self.mUrl.len != 0:
          # provide a chance let the user to veto the action.
          let event = Event(window=self, msg=wEvent_OpenUrl)
          if not self.processEvent(event) or event.isAllowed:
            ShellExecute(0, "open", self.mUrl, nil, nil, SW_SHOW)
        self.mIsVisited = true

when isMainModule:
  import wNim/[wApp, wFrame, wIcon, wStatusBar, wPanel, wFont, wFileDialog, wStaticText]

  let app = App()
  let frame = Frame(title="wHyperlink custom control")

  let statusBar = StatusBar(frame)
  let panel = Panel(frame)

  var hints = StaticText(panel, label="shared")
  # var getBestSize = hints.getBestSize()
  # echo "getBestSize: ",getBestSize
  # var getInsertionPoint = hints.getInsertionPoint()
  # echo "getInsertionPoint: ", getInsertionPoint
  var files = FileDialog(panel, style=wFdOpen or wFdFileMustExist).display()
  if files.len != 0:
    let hyperlink = Hyperlink(panel, label=files[0], url=files[0], style=wStayOnTop)
    panel.autolayout """
    H:|-[hints]-[hyperlink]-|
    """
  # hyperlink.font = Font(18)
  # hyperlink.hoverFont = Font(18, weight=wFontWeightBold, underline=true)

  # wEvent_OpenUrl will propagate upward, so we can catch it from it's parent window.
  panel.wEvent_OpenUrl do (event: wEvent):
    if event.ctrlDown:
      event.veto
      statusBar.setStatusText("press ctrl key and then click to open the url.")

  frame.show()
  app.mainLoop()

