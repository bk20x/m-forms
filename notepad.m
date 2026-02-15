(load "gui.m")
(open SysIo Seq Strings)

(define window (Window "notepad" 800 600))
(define textArea (TextArea ""))

(define optionsContainer
 (layout! Horizontal
   {}
   [
    (button! "open"
     {
        onClick: (-> ()
	          (let ((filename (openFileDialog "Select a file...")))
		    (if (!= filename "")
		     (text= textArea (readFile filename)))))
     }),
    (button! "save"
     {
        onClick: (-> ()
                  (let ((filename (saveFileDialog "Save as...")))
		   (if (!= filename "")
		    (writeFile filename (text@ textArea)))))
     })
   ]
))


(define textContainer
 (layout! Horizontal
   {widthMode: 'Expand, heightMode: 'Expand}
   [textArea]))

(define mainContainer
 (layout! Vertical
   {widthMode: 'Expand}
   [optionsContainer, textContainer]))

(if (safe (if (>= (length ~args) 2)
 (text= textArea (readFile ~args[1])))).success
 ()
 (echo (fmt"Couldn't open file $" ~args[1])))

(addChild window mainContainer)
(show window)
(display-gui)

