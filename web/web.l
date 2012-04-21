# Web.l Picolisp mini-framework
# (c) 2012 José I. Romero
# Parts from @lib/http.l by Alexander Burger (c) 2012 Expat License

# *StatusPrefix should be HTTP/version for an HTTP server response
(default *StatusPrefix "Status: ")

# HTTP Response
(de res (Typ . "Prg")
   (prinl *StatusPrefix (or *HTTPStatus "200 OK") "^M")
   (prinl "Content-type: " (or Typ "text/plain; charset=utf-8") "^M")
   (and *Chunked (prinl "Transfer-Encoding: chunked^M"))
   (for H "*Headers"
      (prinl (car H) ": " (glue ", " (cdr H)) "^M") )
   (httpCookies)
   (prinl "^M")
   (ht:Out *Chunked (run "Prg")) )

# Set a header
(de header @
   (if (assoc (next) "*Headers")
      (conc @ (rest))
      (push '"*Headers" (cons (arg) (rest))) ) )

# Set the HTTP status
(de status (S)
   (setq *HTTPStatus S) )

# Cache control headers
(de no-cache ()
   (header "Cache-control" "private" "no-store" "no-cache") )

(de max-age (N)
   (header "Cache-control" (pack "max-age=" N)) )

# Write all the outstanding http cookies.
(de httpCookies ()
   (mapc
      '((L)
         (prin "Set-Cookie: "
            (ht:Fmt (pop 'L)) "=" (ht:Fmt (pop 'L))
            "; path=" (or (pop 'L) "/") )
         (and (pop 'L) (prin "; expires=" @))
         (and (pop 'L) (prin "; domain=" @))
         (and (pop 'L) (prin "; secure"))
         (and (pop 'L) (prin "; HttpOnly"))
         (prinl) )
      "*Cookies" ) )

# Set a cookie
# (cookie 'name 'value 'expires 'domain 'secure 'httponly)
(de cookie @
   (if (assoc (next) "*Cookies")
      (con @ (rest))
      (push '"*Cookies" (cons (arg) (rest))) ) )


(de urlDecode (X)
   (setq X (split X "="))
   (cons (ht:Pack (car X)) (ht:Pack (cadr X))) )


(de httpStat (N Str)
   (status (pack N " " Str))
   (header "Content-length" (+ 68 (length N) (* 2 (length Str))))
   (res "text/html"
      (prinl "<html>")
      (prinl "<head><title>" N " " Str "</title></head>")
      (prinl "<body><h1>" Str "</h1></body>")
      (prinl "</html>") ) )

(de noContent ()
   (httpStat 204 "No Content") )

(de redirect @
   (header "Location" (pass pack))
   (httpStat 303 "See Other") )

(de forbidden ()
   (httpStat 403 "No Permission")
   (throw "http") )

(de http404 ()
   (httpStat 404 "Not Found") )


# Default request handling system

# (dh lst . prg) -> handler
# Define an url handler
# The first argument is an url pattern to match, the second is a prg
# body to run when the request url matches the pattern. For proper
# operation, define the patterns from the most general to the most
# particular.
(de dh X
   (push '*Handlers
      (cons
         (list 'match
            (cons 'quote
               (mapcan '[(S) (if (pat? S) (cons @) (chop S))] (car X)) )
            '*PathInfo )
         (cdr X) ) ) )

# By default we have an unconditonal handler with a 404 error
(default *Handlers
   '((T
        (status "404 Not Found")
        (max-age 5)
        (res NIL
           (prinl "\"" *PathInfo  "\" not found!")
           (prinl "Did you check in your other pocket?")
           (pretty (cons 'cond *Handlers)) ) ) ) )


(de req-handler ()
   # Adapt/decode variables
   (or (= "/" (car *PathInfo)) (push '*PathInfo "/"))
   (setq *Cookies (mapcar urlDecode (split *Cookies) ";"))
   (off "*Headers" "*Cookies")
   (eval (cons 'cond *Handlers)) )
