(open Nigui)
(initialize-gui)

(define window (Window "Text box test" 400 400))

(define container (LayoutContainer 'Vertical))
(define label (Label ""))
(addChild container label)

(define textBox (TextBox ""))
(onKeyDown= textBox (-> (event) (if (= event.key 'Key_Return) (text= label (text@ textBox)))))

(addChild container textBox)
(addChild window container)

(show window)
(display-gui)
