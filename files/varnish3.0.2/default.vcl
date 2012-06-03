# Default backend definition. The Seting is just for varnish3.0.X 2012/5/15
backend default {
.host = "127.0.0.1";
.port = "8080";
.connect_timeout = 600s;
.first_byte_timeout = 600s;
.between_bytes_timeout = 600s;
#.max_connections = 800;
}

# (1) varnish accept request from cleint
sub vcl_recv {
set req.backend = default;
set req.grace = 5m;
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
           set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
         }
         else {
            set req.http.X-Forwarded-For = client.ip;
         }
     }

     # http://varnish-cache.org/wiki/FAQ/Compression
    if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm|gz|tgz|bz2|tbz|mp3|ogg)$") {
            # No point in compressing these
           remove req.http.Accept-Encoding;
        } elsif (req.http.Accept-Encoding ~ "gzip") {
              set req.http.Accept-Encoding = "gzip";}
          elsif (req.http.Accept-Encoding ~ "deflate") {
              set req.http.Accept-Encoding = "deflate";}
        else {
         remove req.http.Accept-Encoding;
      }
    }

    if (req.http.Cache-Control ~ "no-cache" || req.http.Pragma ~ "no-cache") {
        return (pass);
    }
    if (req.request != "GET" &&
       req.request != "HEAD" &&
       req.request != "PUT" &&
       req.request != "POST" &&
       req.request != "TRACE" &&
       req.request != "OPTIONS" &&
       req.request != "DELETE") {
#/* Non-RFC2616 or CONNECT which is weird. */
       return (pipe);
     }
     if (req.request != "GET" && req.request != "HEAD") {
#/* We only deal with GET and HEAD by default */
         return (pass);
     }
#  Pipe these paths directly to Apache for streaming.
     if (req.url ~ "^/admin/content/backup_migrate/export") {
        return (pipe);
     }
## This would make varnish skip caching for this particular site
# if (req.http.host ~ "internet-safety.yoursphere.com$") {
#   return (pass);
# }

# This makes varnish skip caching for every site except this one
# Commented out here, but shown for sake of some use cases
# if (req.http.host != "sitea.com") {
#   return (pass);
#}

if (req.url ~ "/nocachetest.aws") {
     return (pass);
}
if(req.url ~ "^/users/*") {
   return (pass);
}

## Remove has_js and Google Analytics cookies.
set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js)=[^;]*", "");
set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(__[a-z]+|has_js|Drupal.toolbar.collapsed)=[^;]*", "");

## Remove empty cookies.
  if (req.http.Cookie ~ "^\s*$") {
     unset req.http.Cookie;
   }
   if (req.http.Authorization) {
      return (pass);
   }

## Pass server-status
if (req.url ~ ".*/server-status$") {
   return (pass);
}

## Skip the Varnish cache for install, update, and cron
if (req.url ~ "install\.php|update\.php|cron\.php|admin\.php|batch\.php") {
   return (pass);
}

# Don't cache Drupal logged-in user sessions
# LOGGED_IN is the cookie that earlier version of Pressflow sets
# VARNISH is the cookie which the varnish.module sets
if (req.http.Cookie ~ "(VARNISH|DRUPAL_UID|LOGGED_IN)") {
   return (pass);
}

# Do not cache these paths
if (req.url ~ "^/status\.php$" ||
    req.url ~ "^/update\.php$" ||
    req.url ~ "^/ooyala/ping$" ||
    req.url ~ "^/admin/build/features" ||
    req.url ~ "^/info/.*$" ||
    req.url ~ "^/batch/.*$" ||
    req.url ~ "^/flag/.*$" ||
    req.url ~ "^.*/ajax/.*$" ||
    req.url ~ "^.*/ahah/.*$") {
     return (pass);
}

# Always cache the following file types for all users,No point to cache their cookie
if (req.url ~ "\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm|gz|tgz|bz2|tbz|mp3|ogg)(\?[a-z0-9]+)?$") {
   set req.url=regsub(req.url,"\?.*$","");
   unset req.http.Cookie;
}

# Remove all cookies that Drupal doesn't need to know about. any remaining cookie will cause the request to pass-through to Apache.
# # For the most part we always set the NO_CACHE cookie after any POST request, disabling the Varnish cache temporarily.
# # The session cookie allows all authenticated users to pass through as long as they're logged in.

  if (req.url ~ "node\?page=[0-9]+$") {
      set req.url = regsub(req.url, "node(\?page=[0-9]+$)", "\1");
       return (lookup);
   }
return (lookup);
 }

# (2) Code determining what to do when serving items from the Apache servers.
sub vcl_fetch {

# Grace to allow varnish to serve content if backend is lagged
set beresp.grace = 5m;

if (req.url ~ "^/$") {
   unset beresp.http.Set-Cookie;
 }

# Don't allow static files to set cookies.
if (req.url ~ "\.(png|gif|jpeg|jpg|ico|swf|css|js|html|htm|gz|tgz|bz2|tbz|mp3|ogg)$") {
 #beresp == Back-end response from the web server.
  unset beresp.http.Set-Cookie;
}

# These status codes should always pass through and never cache.
if (beresp.status == 404 || beresp.status == 503 || beresp.status == 500) {
  set beresp.http.X-Cacheable = "NO: beresp.status";
  set beresp.http.X-Cacheable-status = beresp.status;
  return (hit_for_pass);
}
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##with below  (req.url ~ "(^/files/)||(^/sites/)") will not login http://www.splashtop.com/splashtopadmin
##if (req.url ~ "(^/files/)||(^/sites/)") {
##   unset beresp.http.Set-Cookie;
##}
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Varnish3 determined the object was not cacheable
    if (beresp.ttl <= 0s) {
        set beresp.http.X-Cacheable = "NO:Not Cacheable";
# You don't wish to cache content for logged in users
    } elsif (req.http.Cookie ~ "(UserID|_session)") {
        set beresp.http.X-Cacheable = "NO:Got Session";
        return(hit_for_pass);

# You are respecting the Cache-Control=private header from the backend
    } elsif (beresp.http.Cache-Control ~ "private") {
        set beresp.http.X-Cacheable = "NO:Cache-Control=private";
        return(hit_for_pass);

# Varnish determined the object was cacheable
    } else {
        set beresp.http.X-Cacheable = "YES";
    }
 # unset beresp.http.expires;
  if (req.url ~ "(.js|.css)$") {
      set beresp.ttl = 60m; // js and css files ttl 60 minutes
   }
      elsif (req.url ~ "(^/articles/)|(^/tags/)|(^/taxonomy/)") {
      set beresp.ttl = 10m; // list page ttl 10 minutes
   }
   elsif (req.url ~ "^/article/") {
      set beresp.ttl = 5m; // article ttl 5 minutes
   }
   else{
      set beresp.ttl = 45m; // default ttl 45 minutes
   }
  set beresp.http.magicmarker = "1";
  set beresp.http.X-Cacheable = "YES";

return (deliver);

}

sub vcl_deliver {
if (resp.http.magicmarker) {
     /* Remove the magic marker */
     unset resp.http.magicmarker;

     /* By definition we have a fresh object */
     set resp.http.age = "0";
 }

# add cache hit data
if (obj.hits > 0) {
  /*if hit add hit count */
   set resp.http.X-Cache = "HIT";
   set resp.http.X-Cache-Hits = obj.hits;
}
else {
     set resp.http.X-Cache = "MISS";
}

# hidden some sensitive http header returning to client, when the cache server received from backend server response
#remove resp.http.X-Varnish;
#remove resp.http.Via;
##remove resp.http.Age;
#remove resp.http.X-Powered-By;
#remove resp.http.X-Drupal-Cache;
return (deliver);
}

sub vcl_error {
 if (obj.status == 503 && req.restarts < 5) {
   set obj.http.X-Restarts = req.restarts;
   return (restart);
 }
}

sub vcl_hit {

if (req.http.Cache-Control ~ "no-cache") {
    #Ignore requests via proxy caches,  IE users and badly behaved crawlers
    #like msnbot that send no-cache with every request.
  if (! (req.http.Via || req.http.User-Agent ~ "bot|MSIE")) {
      set obj.ttl = 0s;
      return (restart);
   }
}
  return(deliver);
}

 sub vcl_miss {
  return (fetch);
}

#sub vcl_hash {
# if (req.http.Cookie) {
#  hash_data(req.http.Cookie);
# }
#}
