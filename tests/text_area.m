(open Nigui)
(initialize-gui)

(define win (Window "Text area test" 600 600))
(define container (LayoutContainer 'Horizontal))
(addChild container (TextArea ""))

(addChild win container)
(show win)

(display-gui)
