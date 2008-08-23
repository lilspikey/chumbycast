'''
As Python on the chumby doesn't have BaseHTTPServer we need
to write our own.
'''
import SocketServer
import re
import urllib

_response_codes = {
    200: "OK",
    302: "Found",
    404: "Not Found"
}

def _query_str_to_dict(query_str):
    query={}
    if query_str:
        pairs=query_str.split('&')
        for pair in pairs:
            pair=pair.split('=')
            if len(pair) > 1:
                query[pair[0]]=urllib.unquote(pair[1])
            else:
                query[pair[0]]=None
    return query

class HTTPHandler(SocketServer.StreamRequestHandler):
    def handle(self):
        request_line=self.rfile.readline(1024)
        m=re.match(r'([A-Z]+)\s+([^\s?]+)(?:\?(\S*))?\s+HTTP.*',request_line)
        if m:
            command, path, query=m.groups()
            print command, path, query
            self.command=command
            self.path=path
            if path == '/':
                path='/index'
            path=path.replace('.','_').replace('/','_')
            params=_query_str_to_dict(query)
            
            headers={}
            header_re=re.compile(r'(\S+):\s+(.*)')
            while True:
                line=self.rfile.readline(1024)
                line=line.strip()
                if not line:
                    break
                
                m=header_re.match(line)
                if m:
                    key, value=m.groups()
                    headers[key]=value
            
            self.headers=headers
            
            if 'application/x-www-form-urlencoded' in headers.get('Content-Type',''):
                content_length=int(headers.get('Content-Length', '0'))
                # read post params
                post_params=self.rfile.readline(content_length)
                post_params=_query_str_to_dict(post_params)
                params.update(post_params)
            
            handler_method=getattr(self, 'do_%s%s' % (command, path), None)
            if handler_method:
                # found handler so run it
                handler_method(**params)
                return
        
        # no match so send a 404
        self.send_response(404)
        self.end_headers()
        self.wfile.write("Not found\r\n")
    
    def send_response(self,code):
        response=_response_codes.get(code,"")
        self.wfile.write("HTTP/1.0 %d %s\r\n" % (code,response))
    
    def send_header(self, key, value):
        self.wfile.write("%s: %s\r\n" % (key, value))
    
    def end_headers(self):
        self.wfile.write("\r\n")
        

class TCPServer(SocketServer.TCPServer, SocketServer.ThreadingMixIn):
    allow_reuse_address = True
    daemon_threads = True

def run_server(address, handler=HTTPHandler):
    server=TCPServer( address, handler)
    server.serve_forever()

if __name__ == '__main__':
    run_server(('', 3142))