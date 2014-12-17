# PostgreSQL HTTP Client


## Motivation

Wouldn't it be nice to be able to write a trigger that called a web service? Either to get back a result, or to poke that service into refreshing itself against the new state of the database?

This extension is for that. 

## Examples

    > SELECT content FROM http_get('http://localhost');

                       content                    
    ----------------------------------------------
     <html><body><h1>It works!</h1></body></html>
    (1 row)


    > SELECT status, content_type, content FROM http_get('http://localhost');

     status | content_type |                   content                    
    --------+--------------+----------------------------------------------
        200 | text/html    | <html><body><h1>It works!</h1></body></html>
    (1 row)

  
    > SELECT (unnest(headers)).* FROM http_get('http://localhost');

          field       |                                value                                 
    ------------------+----------------------------------------------------------------------
     Date             | Wed, 17 Dec 2014 21:47:27 GMT
     Server           | Apache/2.2.26 (Unix) DAV/2 PHP/5.4.30 mod_ssl/2.2.26 OpenSSL/0.9.8za
     Content-Location | index.html.en
     Vary             | negotiate
     TCN              | choice
     Last-Modified    | Sat, 30 Nov 2013 03:48:45 GMT
     ETag             | "a2961-2c-4ec5cd2d28140"
     Accept-Ranges    | bytes
     Content-Length   | 44
     Connection       | close
     Content-Type     | text/html
     Content-Language | en

	  
	  > SELECT status,content FROM http_put('http://localhost/resource', 'some text', 'text/plain');
    
     status |                                content                                
    --------+-----------------------------------------------------------------------
        405 | <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">                   +
            | <html><head>                                                         +
            | <title>405 Method Not Allowed</title>                                +
            | </head><body>                                                        +
            | <h1>Method Not Allowed</h1>                                          +
            | <p>The requested method PUT is not allowed for the URL /resource.</p>+
            | </body></html>                                                       +
            | 

    > SELECT status, content FROM http_delete('http://localhost');

     status |                                    content                                    
    --------+-------------------------------------------------------------------------------
        405 | <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">                           +
            | <html><head>                                                                 +
            | <title>405 Method Not Allowed</title>                                        +
            | </head><body>                                                                +
            | <h1>Method Not Allowed</h1>                                                  +
            | <p>The requested method DELETE is not allowed for the URL /index.html.en.</p>+
            | </body></html>                                                               +
            | 


## Concepts

Every HTTP call is a made up of an `http_request` and an `http_response`.

         Composite type "public.http_request"
        Column    |       Type        | Modifiers 
    --------------+-------------------+-----------
     method       | http_method       | 
     uri          | character varying | 
     headers      | http_header[]     | 
     content_type | character varying | 
     content      | character varying | 

        Composite type "public.http_response"
        Column    |       Type        | Modifiers 
    --------------+-------------------+-----------
     status       | integer           | 
     content_type | character varying | 
     headers      | http_header[]     | 
     content      | character varying | 

The utility functions, `http_get()`, `http_post()`, `http_put()`, and `http_delete()` are just wrappers around a master function, `http(http_request)` that returns `http_response`.

The `headers` field for requests and response is a PostgreSQL array of type `http_header` which is just a simple tuple.

      Composite type "public.http_header"
     Column |       Type        | Modifiers 
    --------+-------------------+-----------
     field  | character varying | 
     value  | character varying | 

As seen in the examples, you can easily unspool the array of `http_header` tuples into a result set using the PostgreSQL `unnest()` function on the array. From there you can easily select the particular header you are interested in.

## Installation

### UNIX

If you have PostgreSQL devel packages and CURL devel packages installed, you should have `pg_config` and `curl-config` on your path, so you should be able to just run `make`, then `make install`, then in your database `CREATE EXTENSION http`.

### Windows

Sorry, no story here yet.

## Why This is a Bad Idea

- "What happens if the web page takes a long time to return?" Your SQL call will just wait there until it does. Make sure your web service fails fast.
- "What if the web page returns junk?" Your SQL call will have to test for junk before doing anything with the payload.
- "What if the web page never returns?" I've found this code can really hang a back-end hard. The curl timeout settings need more testing and tweaking for faster failure and timeout.


## To Do

- The new http://www.postgresql.org/docs/9.3/static/bgworker.html background worker support could be used to set up an HTTP request queue, so that pgsql-http can register a request and callback and then return immediately.
- Inevitably some web server will return gzip content (Content-Encoding) without being asked for it. Handling that gracefully would be good.
