(open Nigui)

(define window (Window "Text box test" 400 400))

(define container (LayoutContainer 'Vertical))
(define label (Label ""))
(addChild container label)

(define textBox (TextBox ""))
(onKeyDown= textBox (-> (event) (echo event)))

(addChild container textBox)
(addChild window container)
(show window)
