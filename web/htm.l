# Monkey-patch xhtml.l
(load "@lib/xhtml.l")
#(mapc undef '(html))
(def 'sesId prog) # Url sesId not implemented
(def 'baseHRef nil) # Not necessary, call depends on *Port and *Host
(def 'srcUrl prog) # Override this for another source URL

(setq "css" (car (fish '((X) (= X "css")) html)))

# Html response
(de res-html (Ttl Css Attr . Prg)
   (res "text/html; charset=utf-8"
      (prinl "<!DOCTYPE html>")
      (prinl "<html lang=\"" (or *Lang "en") "\">")
      (prinl "<head>")
      (and Ttl (<tag> 'title NIL Ttl) (prinl))
      (and *Host *Port (prinl "<base href=\"" (baseHRef) "\"/>"))
      (when Css
         (if (atom Css) ("css" Css) (mapc "css" Css)) )
      (mapc javascript *JS)
      (prinl "</head>")
      (tag 'body Attr 2 Prg)
      (prinl "</html>") ) )