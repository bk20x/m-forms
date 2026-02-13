(open Nigui)

(define window (newWindow "Making Gui in M!" 400 400))

(define mainContainer (newLayoutContainer 'Vertical))
  (widthMode= mainContainer 'Expand)

(define labelContainer (newLayoutContainer 'Horizontal))
  (xAlign= labelContainer 'Center)
  (widthMode= labelContainer 'Expand)

  (define label (newLabel "Hello from M!"))
  (fontSize= label 24.0)
  (addChild labelContainer label)


(define buttonContainer (newLayoutContainer 'Horizontal))
  (xAlign= buttonContainer 'Center)
  (widthMode= buttonContainer 'Expand)
  (heightMode= buttonContainer 'Expand)

  (define button (newButton "Click Me!"))
  (onClick= button (-> () (echo "Ive been Clicked!")))
  (addChild buttonContainer button)


(addChild mainContainer labelContainer)
(addChild mainContainer buttonContainer)
(addChild window mainContainer)

(show window)


