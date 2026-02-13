(open Nigui)

(define window (Window "Making Gui in M!" 400 400))

(define mainContainer (LayoutContainer 'Vertical))
  (widthMode= mainContainer 'Expand)

(define labelContainer (LayoutContainer 'Horizontal))
  (xAlign= labelContainer 'Center)
  (widthMode= labelContainer 'Expand)

  (define label (Label "Hello from M!"))
  (fontSize= label 24.0)
  (addChild labelContainer label)
  (addChild labelContainer (TextBox ""))


(define buttonContainer (LayoutContainer 'Horizontal))
  (xAlign= buttonContainer 'Center)
  (widthMode= buttonContainer 'Expand)
  (heightMode= buttonContainer 'Expand)

  (define button (Button "Click Me!"))
  (onClick= button (-> () (echo "Ive been Clicked!")))
  (addChild buttonContainer button)


(addChild mainContainer labelContainer)
(addChild mainContainer buttonContainer)
(addChild window mainContainer)

(show window)


