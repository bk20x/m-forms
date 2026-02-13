(load "gui.m")
(open SysIo)

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
   {withMode: 'Expand}
   [optionsContainer, textContainer]))


(addChild window mainContainer)
(show window)
(display-gui)

