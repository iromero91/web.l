(load "web/httpd.l" "web/sockets.l" "web/web.l" "web/htm.l")

(dh ("/chatsocket")
   (setq *UserName *QueryString)
   (unless (ws-handshake)
      (httpStat 400 "Bad Request")
      (bye) )
   (tell *ChatPID 'chat-register *Pid)
   (ws-onmessage
      (tell *ChatPID 'chat-message *Pid (pack *WsPayload)) )
   (ws-send "** Notice: Welcome to the test chat server")
   (loop
      (wait 1000) ) )

(dh ("/chat")
   (setq *JS '("chat.js"))
   (res-html "Chat demo" "chat.css" ()
      (<div> '((id . "chat")))
      (prin "<input id=\"textline\">")
      (prinl "<button id=\"send\" type=\"button\">Send!</button>") ) )


(dh ("/chat.css")
   (res "text/css" (prinl "
#chat {
  width: 500px;
  height: 400px;
  border: 1px solid;
  overflow-y: scroll;
}
p { margin: 0; }
#textline {
  width: 500px;
}
")) )

(dh ("/chat.js")
   (res "text/javascript" (prinl "
window.onload = function () {
   ws = new WebSocket('ws://icz:8080/chatsocket');
   con = document.getElementById('chat');
   ws.onmessage = function (e) {
      con.innerHTML += '<p>'+ e.data +'</p>'
   }; 
   sen = document.getElementById('send');
   ib = document.getElementById('textline');
   sen.onclick = function () {
      ws.send(ib.value);
      ib.value = '';
   };
   ib.onkeypress = function (e) {
      if (e.keyCode == 13) {
        ws.send(ib.value);
        ib.value = '';
      }
   }
}
")))

(dh ("/")
   (res-html "OMG" NIL NIL
      (<h1> NIL (prinl "IT WORKS!!!")) ) )

(de chat-server ()
   (unless (setq *ChatPID (fork))
      (off *Clients)
      (loop (wait)) ) )

(de chat-register (Pid)
   (push '*Clients Pid) )

(de chat-message (Pid M)
   (for X *Clients
      (if (t <> Pid X)
         (tell X 'ws-send (pack Pid ": " M)) ) ) )

(de go ()
   (chat-server)
   (server 8080) )