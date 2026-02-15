(load "gui.m")

(define window (Window "counter button" 400 400))

(define x 0)

(define buttonContainer 
 (layout! Horizontal
   {xAlign: 'Center, yAlign: 'Center, widthMode: 'Expand, heightMode: 'Expand}
   [
     (button! (image x)
      {
	onClick: (-> (self) (text= self (image (setf x (+ x 1)))))
      }
     )
   ]))

(addChild window buttonContainer)
(onKeyDown= window (-> (event) (if (= event.key 'Key_Escape) (die "You closed the window with escape!"))))
(show window)
(display-gui)
