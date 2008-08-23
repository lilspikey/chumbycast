from xml.dom.minidom import parse as parse_xml
from urllib2 import urlopen
import urllib
from httpserver import HTTPHandler, run_server
import shelve as db
from anydbm import error as db_error

def get_text(item, tag_name):
    '''get the text for the named element'''
    txt=[]
    for tag in item.getElementsByTagName(tag_name):
        for node in tag.childNodes:
            if node.nodeType == node.TEXT_NODE:
                txt.append(node.data)
    return ''.join(txt)

def get_node(item, tag_name):
    for node in item.getElementsByTagName(tag_name):
        return node
    return None
        
def find_enclosed_urls(feed_url):
    feed=urlopen(feed_url)
    feed_doc=parse_xml(feed)
    for item in feed_doc.getElementsByTagName('item'):
        title=get_text(item,'title')
        enclosure=get_node(item,'enclosure')
        if enclosure is not None:
            yield enclosure.getAttribute('url'), title

def read_feeds_from_opml(opml_file):
    opml_doc=parse_xml(opml_file)
    outlines=opml_doc.getElementsByTagName('outline')
    for outline in outlines:
        if outline.hasAttribute('type') and outline.hasAttribute('xmlUrl'):
            if outline.getAttribute('type') == 'rss':
                url=outline.getAttribute('xmlUrl')
                text=None
                if outline.hasAttribute('text'):
                    text=outline.getAttribute('text')
                yield (url, text)

def get_podcast_list():
    for feed_url, description in read_feeds_from_opml('Podcasts.opml'):
        print feed_url
        yield Podcast(feed_url, description)

class Podcast(object):
    def __init__(self, url, title):
        self.url=url
        self.title=title
        self.items=[]
    
    def fetch_items(self):
        for url, title in find_enclosed_urls(self.url):
            print url
            item=PodcastItem(url, title)
            if not item in self.items:
                self.items.append(item)

class PodcastItem(object):
    def __init__(self, url, title):
        self.url=url
        self.title=title
        self.played=False
    
    def __cmp__(self,other):
        return self.url.__cmp__(other.url)

def escape_js(s):
    return "\"%s\"" % s.replace('\\','\\\\').replace("\"","\\\"")

_content_types={
    'html': 'text/html',
    'js': 'text/javascript',
    'css': 'text/css'
}

def file_suffix(file_name):
    suffix=''
    dot_index=file_name.rfind('.')
    if dot_index > -1:
        suffix=file_name[dot_index+1:]
    return suffix

class PodcastHTTPHandler(HTTPHandler):
    
    def _serve_file(self,file_name):
        suffix=file_suffix(file_name)
        self.send_response(200)
        self.send_header("Content-type", _content_types.get(suffix,"text/plain") )
        self.end_headers()
        f=open(file_name)
        while True:
            bytes=f.read(1024)
            if bytes:
                self.wfile.write(bytes)
            else:
                break
    
    def do_GET_index(self):
        self._serve_file('index.html')
    
    def do_GET_jquery_js(self):
        self._serve_file('jquery-1.2.6.min.js')
    
    def do_GET_chumbycast_css(self):
        self._serve_file('chumbycast.css')
    
    def do_GET_chumbycast_js(self):
        self._serve_file('chumbycast.js')
    
    def do_GET_chumbycast_swf(self):
        self._serve_file('widget/chumbycast.swf')
    
    def do_GET_flash(self):
        self._serve_file('flash.html')
    
    def do_GET_list(self,**args):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        
        print "listing podcasts"
        
        self.wfile.write("[")
        # only reading from db
        try:
            podcast_list=db.open("podcast_list","r")
            # sort by title
            first=True
            for title, podcast in sorted((podcast.title, podcast) for podcast in podcast_list.values()):
                for item_title, item in sorted((item.title, item) for item in podcast.items):
                    if not first:
                        self.wfile.write(", ")
                    first=False
                    
                    print "listing ", item_title
                    
                    self.wfile.write("[ ")
                    self.wfile.write(escape_js(podcast.title))
                    self.wfile.write(", ")
                    self.wfile.write(escape_js(item.title))
                    self.wfile.write(", ")
                    self.wfile.write(escape_js(item.url))
                    self.wfile.write(", ")
                    if item.played:
                        self.wfile.write('true')
                    else:
                        self.wfile.write('false')
                    self.wfile.write(" ]")
            podcast_list.close()
        except db_error:
            pass # file doesn't exist
        self.wfile.write("]\n")
    
    def _btplay(self, cmd):
        # write command into pipe to trigger btplay
        btplay_pipe=open('/tmp/.btplay-cmdin','a')
        btplay_pipe.write(cmd+"\n")
        btplay_pipe.close()
    
    def _btplay_state(self):
        try:
            btplay_state=open('/var/run/btplay.state','r')
            state=btplay_state.readline()
            btplay_state.close()
            return int(state)
        except:
            return 0
    
    def _mark_url_played(self, url):
        podcast_list=db.open("podcast_list")
        for quoted_url, podcast in podcast_list.items():
            found=False
            for item in podcast.items:
                if item.url == url:
                    item.played=True
                    podcast_list[quoted_url]=podcast
                    found=True
                    break
            if found:
                break
    
    def do_POST_play(self,url=None, **args):
        if url:
            self._btplay('play * %s' % url)
            self._mark_url_played(url)
        
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write("Playing %s" % url)
    
    def do_POST_stop(self, **args):
        self._btplay('stop')
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write("Stopped")
    
    def do_POST_refresh(self, **args):
        podcast_list=db.open("podcast_list")
        live_podcasts=set()
        for podcast in get_podcast_list():
            quoted_url=str(urllib.quote(podcast.url,safe=''))
            podcast=podcast_list.get(quoted_url, podcast)
            podcast.fetch_items()
            podcast_list[quoted_url]=podcast
            live_podcasts.add(quoted_url)
        
        print "got all podcasts"
        
        # remove old podcasts
        for quoted_url in podcast_list.keys():
            if not quoted_url in live_podcasts:
                del podcast_list[quoted_url]
        
        print "removed old podcasts"
        
        podcast_list.close()
        
        self.do_GET_list()
            
    def do_GET_crossdomain_xml(self):
        '''crossdomain file, so flash can access this server'''
        self.send_response(200)
        self.send_header("Content-type", "text/xml")
        self.end_headers()
        self.wfile.write('''<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<allow-access-from domain="*" />
<site-control permitted-cross-domain-policies="master-only" />
</cross-domain-policy>''')


if __name__ == '__main__':
    run_server(('', 3142), PodcastHTTPHandler)