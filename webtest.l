(load "web/httpd.l" "web/web.l" "web/htm.l")

(de httpStat @
   (res NIL
      (println (rest))) )

(dh ("/works")
   (res-html "OMG" NIL NIL
      (<h1> NIL (prinl "IT WORKS!!!")) ) )

(de go ()
   (server 8080) )