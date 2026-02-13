import nigui
import std/[tables, strformat, sets, sequtils, sugar]
import m/[lispobject, environment, m, alien]

const 
  ParentElems    = toHashSet(["Window", "LayoutContainer", "Container"])
  ChildElems     = toHashSet(["Button", "LayoutContainer", "Container", "TextArea", "Label", "TextBox"])
  ElemsWithText  = toHashSet(["Button", "TextArea", "Label", "TextBox"])

template err(msg: string) =
  raise newException(ValueError, msg)
 
template isContainer(obj: LispObject): bool =
  (obj.kind == AlienObj and (obj.alien.tname == "LayoutContainer" or obj.alien.tname == "Container"))

var interp = newEnv() ## because we will use lambdas as callbacks and these need access to global builtins


## Window
type
  WindowObj = ref object of Alien
    win: Window
    
template isWindow(obj: LispObject): bool =
  (obj.kind == AlienObj and obj.alien.tname == "Window")

template isGuiElement(obj: LispObject): bool =
  (obj.kind == AlienObj and (obj.alien.tname in ParentElems or obj.alien.tname in ChildElems))

proc newWindowObj(window: Window): WindowObj =
  return WindowObj(tname: "Window", win: window)
    
proc makeWindow(args: LispObject): LispObject =
  if args.len != 3 or not (args.first.kind  == String and
                           args.second.kind == Int    and
                           args.third.kind  == Int):
    err(fmt"`Window` is of type String -> Int -> Int -> Window but got {args}")
  var win    = newWindow(args.first.str)
  win.width  = args.second.intVal
  win.height = args.second.intVal
  return newAlien(newWindowObj(win))

proc showWindow(args: LispObject): LispObject =
  if args.len != 1 or not args.first.isWindow:
    err(fmt"`show` expects an object of type Window but got {args}")
  result = NIL()
  var win = WindowObj(args.first.alien)
  win.win.show()    
## End Window


## Layout Container
type
  LayoutContainerObj = ref object of Alien
    container: LayoutContainer

proc newLayoutContainerObj(cont: LayoutContainer): LayoutContainerObj =
  return LayoutContainerObj(tname: "LayoutContainer", container: cont)

proc makeLayoutContainer(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == Symbol):
    err(fmt"`LayoutContainer` is of type Symbol -> LayoutContainer but got {args}")
  let layout = args.first.sym.name
  case layout
  of "Vertical":
    return newAlien(newLayoutContainerObj(newLayoutContainer(Layout_Vertical)))
  of "Horizontal":
    return newAlien(newLayoutContainerObj(newLayoutContainer(Layout_Horizontal)))
  else:
    err(fmt"invalid layout for LayoutContainer {layout}")
     
## End Layout Container


## Button
type 
  ButtonObj = ref object of Alien
    button: Button

proc newButtonObj(button: Button): ButtonObj =
  return ButtonObj(tname: "Button", button: button)

proc makeButton(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`Button` is of type String -> Button but got {args}")
  let text = args.first.str
  return newAlien(newButtonObj(newButton(text)))

proc setOnClick(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind        == AlienObj and 
                           args.first.alien.tname == "Button" and 
                           args.second.kind       == Lambda):
    err(fmt"`onClick=` is of type Button -> Lambda -> Button")
  let
    button = ButtonObj(args.first.alien).button
    fun    = args.second
  button.onClick = proc(event: ClickEvent) = (
    block:
      discard interp.apply(fun, @[])
  )
  return args.first

## End Button

## Label
type
  LabelObj = ref object of Alien
    label: Label

proc newLabelObj(label: Label): LabelObj =
  return LabelObj(tname: "Label", label: label)

proc makeLabel(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`Label` is of type String -> Label but got {args}")
  let text = args.first.str
  return newAlien(newLabelObj(newLabel(text)))

## End Label

## TextBox
type
  TextBoxObj = ref object of Alien
    textBox: TextBox

proc newTextBoxObj(textBox: TextBox): TextBoxObj =
  return TextBoxObj(tname: "TextBox", textBox: textBox)

proc makeTextBox(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`TextBox` is of type String -> TextBox but got {args}")
  let text = args.first.str
  return newAlien(newTextBoxObj(newTextBox(text)))

proc setOnTextChange(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind        == AlienObj  and 
                           args.first.alien.tname == "TextBox" and 
                           args.second.kind       == Lambda):
    err(fmt"`onClick=` is of type TextBox -> Lambda -> TextBox")
  let
    textBox = TextBoxObj(args.first.alien).textBox
    fun     = args.second
  textBox.onTextChange = proc(event: TextChangeEvent) = (
    block:
      discard interp.apply(fun, @[])
  )
  return args.first


## End TextBox


## TextArea
type
  TextAreaObj = ref object of Alien
    textArea: TextArea

proc newTextAreaObj(textArea: TextArea): TextAreaObj =
  return TextAreaObj(tname: "TextArea", textArea: textArea)

proc makeTextArea(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`TextArea` is of type String -> TextArea but got {args}")
  let text = args.first.str
  return newAlien(newTextAreaObj(newTextArea(text)))

## End TextArea
  
## Keyboard stuff
proc onKeyDownEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == AlienObj and (args.first.alien.tname == "Window" or args.first.alien.tname in ChildElems)):
    err(fmt"`onKeyDown=` is of type Window | Control -> Lambda -> Window | Control but got {args}")
  let
    elem = args.first.alien
    fun  = args.second
  if fun.params.len != 1:
    err(fmt"`onKeyDown=` expects a callback with one argument to store the KeyboardEvent table like: (-> (event) ...) but got {fun}")
  let onKeyDown = proc(event: KeyboardEvent) =
    let
      eventTable = lispobject.newTable()
      handled    = newSym("handled")
    eventTable.table[newSym("key")]       = newSym($event.key)
    eventTable.table[newSym("character")] = newStr(event.character)
    eventTable.table[newSym("unicode")]   = newInt(event.unicode)
    eventTable.table[newSym("downKeys")]  = lispobject.newSeq(downKeys().map(key => (newStr $key)))
    eventTable.table[handled] = NIL()
    discard interp.apply(fun, @[eventTable])
    if eventTable.table[handled].isT:
      event.handled = true
  case elem.tname
  of "Window":
    var win = WindowObj(elem).win
    win.onKeyDown = onKeyDown
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.onKeyDown = onKeyDown
  of "TextArea":
    var textArea = TextAreaObJ(elem).textArea
    textArea.onKeyDown = onKeyDown
  else:
    discard
  return args.first
  
## End Keyboard stuff
  
## Polymorphic builtins
proc addChild(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.alien.tname in ParentElems or args.second.alien.tname in ChildElems):
    err(fmt"addChild is of type Window | Container -> Window | Container -> Nil but got {args}")
  let
    parent = args.first.alien
    child  = args.second.alien
  block:
    template addAux(parent: Container | Window, child: Alien) = 
      var childName  = child.tname
      case childName
      of "LayoutContainer":
        parent.add(LayoutContainerObj(child).container)
      of "Button":
        parent.add(ButtonObj(child).button)
      of "Label":
        parent.add(LabelObj(child).label)
      of "TextBox":
        parent.add(TextBoxObj(child).textBox)
      of "TextArea":
        parent.add(TextAreaObj(child).textArea)
      else:
        discard
    case parent.tname
    of "Window":
      var win = WindowObj(parent).win
      win.addAux(child)
    of "LayoutContainer":
      var cont = LayoutContainerObj(parent).container
      cont.addAux(child)
    else:
      discard
  return args.first

proc textEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind        == AlienObj      and 
                           args.first.alien.tname in ElemsWithText and
                           args.second.kind       == String):
    err(fmt"`text=` is of type Control -> String -> Control but got {args}")
  let 
    elem = args.first.alien
    text = args.second.str
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    button.text = text
  of "Label":
    var label = LabelObj(elem).label
    label.text = text
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.text = text
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    textArea.text = text
  else:
    discard
  return args.first


proc getText(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind        == AlienObj      and 
                           args.first.alien.tname in ElemsWithText):
    err(fmt"`text@` is of type Control -> String but got {args}")
  let  elem = args.first.alien
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    return newStr(button.text)
  of "Label":
    var label = LabelObj(elem).label
    return newStr(label.text)
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    return newStr(textBox.text)
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    return newStr(textArea.text)
  else:
    discard


proc widthModeEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == AlienObj and
                           args.first.alien.tname in ChildElems and
                           args.second.kind == Symbol):
    err(fmt"`widthMode=` is of type Control -> Symbol -> Control but got {args}")
  let
    elem = args.first.alien
    mode = args.second.sym.name
  template setAux(elem: Container | Control, mode: string) =
    case mode
    of "Expand":
      elem.widthMode = WidthMode_Expand
    of "Fill":
      elem.widthMode = WidthMode_Fill
    else:
      err(fmt"invalid WidthMode {mode}; expected one of [Expand, Fill]")
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    button.setAux(mode)
  of "Label":
    var label = LabelObj(elem).label
    label.setAux(mode)
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.setAux(mode)
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    textArea.setAux(mode)
  of "LayoutContainer":
    var cont = LayoutContainerObj(elem).container
    cont.setAux(mode)
  else:
    discard 
  return args.first
    
  
proc heightModeEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == AlienObj and
                           args.first.alien.tname in ChildElems and
                           args.second.kind == Symbol):
    err(fmt"`heightMode=` is of type Control -> Symbol -> Control but got {args}")
  let
    elem = args.first.alien
    mode = args.second.sym.name
  template setAux(elem: Container | Control; mode: string) =
    case mode
    of "Expand":
      elem.heightMode = HeightMode_Expand
    of "Fill":
      elem.heightMode = HeightMode_Fill
    else:
      err(fmt"invalid HeightMode {mode}; expected one of [Expand, Fill]")
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    button.setAux(mode)
  of "Label":
    var label = LabelObj(elem).label
    label.setAux(mode)
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.setAux(mode)
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    textArea.setAux(mode)
  of "LayoutContainer":
    var cont = LayoutContainerObj(elem).container
    cont.setAux(mode)
  else:
    discard 
  return args.first

proc fontFamilyEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == AlienObj and
                           args.first.alien.tname in ElemsWithText and
                           args.second.kind == String):
    err(fmt"`fontFamily=` is of type Control -> String -> Control but got {args}")
  let 
    elem = args.first.alien
    font = args.second.str
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    button.fontFamily = font
  of "Label":
    var label = LabelObj(elem).label
    label.fontFamily = font
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.fontFamily = font
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    textArea.fontFamily = font
  else:
    discard
  return args.first


proc fontSizeEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.kind == AlienObj and
                           args.first.alien.tname in ElemsWithText and
                           args.second.kind == Float):
    err(fmt"`fontSize=` is of type Control -> String -> Control but got {args}")
  let 
    elem = args.first.alien
    size = args.second.floatVal
  case elem.tname
  of "Button":
    var button = ButtonObj(elem).button
    button.fontSize = size
  of "Label":
    var label = LabelObj(elem).label
    label.fontSize = size
  of "TextBox":
    var textBox = TextBoxObj(elem).textBox
    textBox.fontSize = size
  of "TextArea":
    var textArea = TextAreaObj(elem).textArea
    textArea.fontSize = size
  else:
    discard
  return args.first

  
proc xAlignEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.isContainer and args.second.kind == Symbol):
    err(fmt"`xAlign=` is of type Container -> Symbol -> Container but got {args}")
  let
    elem  = args.first.alien
    align = args.second.sym.name
  template setAux(elem: Container; align: string) =
    case align
    of "Left":
      elem.xAlign = XAlign_Left
    of "Right":
      elem.xAlign = XAlign_Right
    of "Center":
      elem.xAlign = XAlign_Center
    of "Spread":
      elem.xAlign = XAlign_Spread
    else:
      err(fmt"invalid XAlign {align}; expected one of [Left, Right, Center, Spread]")
  case elem.tname
  of "LayoutContainer":
    var cont = LayoutContainerObj(elem).container
    cont.setAux(align)
  else:
    discard 
  return args.first  


proc yAlignEq(args: LispObject): LispObject =
  if args.len != 2 or not (args.first.isContainer and args.second.kind == Symbol):
    err(fmt"`yAlign=` is of type Container -> Symbol -> Container but got {args}")
  let
    elem  = args.first.alien
    align = args.second.sym.name
  template setAux(elem: Container | Control, align: string) =
    case align
    of "Top":
      elem.yAlign = YAlign_Top
    of "Bottom":
      elem.yAlign = YAlign_Bottom
    of "Center":
      elem.yAlign = YAlign_Center
    of "Spread":
      elem.yAlign = YAlign_Spread
    else:
      err(fmt"invalid YAlign {align}; expected one of [Top, Bottom, Center, Spread]")
  case elem.tname
  of "LayoutContainer":
    var cont = LayoutContainerObj(elem).container
    cont.setAux(align)
  else:
    discard 
  return args.first  
## End Polymorphic builtins

proc openFileDialog(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`openFileDialog` is of type String -> String but got {args}")
  result = newStr("")
  let title = args.first.str
  var dialog = newOpenFileDialog()
  dialog.title = title
  dialog.run()
  if dialog.files.len >= 1:
    result.str = dialog.files[0]

  
proc saveFileDialog(args: LispObject): LispObject =
  if args.len != 1 or not (args.first.kind == String):
    err(fmt"`saveFileDialog` is of type String -> String but got {args}")
  let title = args.first.str
  var dialog = newSaveFileDialog()
  dialog.title = title
  dialog.run()
  result = newStr(dialog.file)
  
proc initGui(args: LispObject): LispObject =
  result = NIL()
  init app
proc displayGui(args: LispObject): LispObject =
  result = NIL()
  run app

const Module = toTable {
  "initialize-gui"    : BuiltinFn initGui,
  "display-gui"       : BuiltinFn displayGui,
  "addChild"          : BuiltinFn addChild,
  "Window"            : BuiltinFn makeWindow,
  "show"              : BuiltinFn showWindow,
  "LayoutContainer"   : BuiltinFn makeLayoutContainer,
  "Button"            : BuiltinFn makeButton,
  "onClick="          : BuiltinFn setOnClick,
  "onKeyDown="        : BuiltinFn onKeyDownEq,
  "Label"             : BuiltinFn makeLabel,
  "TextBox"           : BuiltinFn makeTextBox,
  "TextArea"          : BuiltinFn makeTextArea,
  "onTextChange="     : BuiltinFn setOnTextChange,
  "text="             : BuiltinFn textEq,
  "text@"             : BuiltinFn getText,
  "widthMode="        : BuiltinFn widthModeEq,
  "heightMode="       : BuiltinFn heightModeEq,
  "xAlign="           : BuiltinFn xAlignEq,
  "yAlign="           : BuiltinFn yAlignEq,
  "fontFamily="       : BuiltinFn fontFamilyEq,
  "fontSize="         : BuiltinFn fontSizeEq,
  "openFileDialog"    : BuiltinFn openFileDialog,
  "saveFileDialog"    : BuiltinFn saveFileDialog
}

interp.registerModule("Nigui", Module)
Mmain(interp)

