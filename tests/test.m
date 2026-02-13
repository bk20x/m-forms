(load "gui.m")

(define window (Window "Making Gui in M!" 400 400))


(define label (Label "Hello from M!"))
(fontSize= label 24.0)

(define labelContainer
 (layout! Horizontal
   {widthMode: 'Expand, xAlign: 'Center}
   [label]
 )
)


(define buttonContainer
 (layout! Horizontal
   {
     widthMode:  'Expand,
     heightMode: 'Expand,
     xAlign:     'Center
   }
   [
     (button! "Click Me!"
      {
        onClick: (-> () (echo (openFileDialog "Select files")))
      }
     )
   ]
  )
)


(define mainContainer
 (layout! Vertical
   {widthMode: 'Expand}
   [labelContainer, buttonContainer]
 )
)

  

(addChild window mainContainer)

(show window)
(display-gui)











































