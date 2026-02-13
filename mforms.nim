import nigui
import std/[tables, strformat, sets]
import m/[lispobject, environment, m, alien]

const 
  ParentElems    = toHashSet(["Window", "LayoutContainer", "Container"])
  ChildElems     = toHashSet(["Button", "LayoutContainer", "Container", "TextArea", "Label"])
  ElemsWithText  = toHashSet(["Button", "TextArea", "Label"])

template err(msg: string) =
  raise newException(ValueError, msg)
 
template isContainer(obj: LispObject): bool =
  (obj.kind == AlienObj and (obj.alien.tname == "LayoutContainer" or obj.alien.tname == "Container"))

var interp = newEnv() ## because we will use lambdas as callbacks and these need access to global builtins
app.init() ## initialize nigui

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
    err(fmt"`newWindow` is of type String -> Int -> Int -> Window but got {args}")
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
    err(fmt"`newLayoutContainer` is of type Symbol -> LayoutContainer but got {args}")
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
    err(fmt"`newButton` is of type String -> Button but got {args}")
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
    err(fmt"`newLabel` is of type String -> Label but got {args}")
  let text = args.first.str
  return newAlien(newLabelObj(newLabel(text)))

## End Label

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
  else:
    discard
  return args.first

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
  of "LayoutContainer":
    var cont = LayoutContainerObj(elem).container
    cont.setAux(mode)
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
  else:
    discard
  return args.first
## End Polymorphic builtins

const Module = toTable {
  "addChild"          : BuiltinFn addChild,
  "newWindow"         : BuiltinFn makeWindow,
  "show"              : BuiltinFn showWindow,
  "newLayoutContainer": BuiltinFn makeLayoutContainer,
  "newButton"         : BuiltinFn makeButton,
  "onClick="          : BuiltinFn setOnClick,
  "text="             : BuiltinFn textEq,
  "widthMode="        : BuiltinFn widthModeEq,
  "heightMode="       : BuiltinFn heightModeEq,
  "xAlign="           : BuiltinFn xAlignEq,
  "yAlign="           : BuiltinFn yAlignEq,
  "fontFamily="       : BuiltinFn fontFamilyEq,
  "fontSize="         : BuiltinFn fontSizeEq,
  "newLabel"          : BuiltinFn makeLabel
}

interp.registerModule("Nigui", Module)
Mmain(interp)

app.run()

