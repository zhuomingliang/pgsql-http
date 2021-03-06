CREATE EXTENSION http;

set http.timeout_msec = 10000;
SELECT http_set_curlopt('CURLOPT_TIMEOUT', '10');

-- Status code
SELECT status
FROM http_get('http://httpbin.org/status/202');

-- Headers
SELECT *
FROM (
	SELECT (unnest(headers)).*
	FROM http_get('http://httpbin.org/response-headers?Abcde=abcde')
) a
WHERE field = 'Abcde';

-- GET
SELECT status,
content::json->'args' AS args,
content::json->'url' AS url,
content::json->'method' AS method
FROM http_get('http://httpbin.org/anything?foo=bar');

-- GET with data
SELECT status,
content::json->'args' as args,
content::json->>'data' as data,
content::json->'url' as url,
content::json->'method' as method
from http(('GET', 'http://httpbin.org/anything', NULL, 'application/json', '{"search": "toto"}'));

-- DELETE
SELECT status,
content::json->'args' AS args,
content::json->'url' AS url,
content::json->'method' AS method
FROM http_delete('http://httpbin.org/anything?foo=bar');

-- PUT
SELECT status,
content::json->'data' AS data,
content::json->'args' AS args,
content::json->'url' AS url,
content::json->'method' AS method
FROM http_put('http://httpbin.org/anything?foo=bar','payload','text/plain');

-- PATCH
SELECT status,
content::json->'data' AS data,
content::json->'args' AS args,
content::json->'url' AS url,
content::json->'method' AS method
FROM http_patch('http://httpbin.org/anything?foo=bar','{"this":"that"}','application/json');

-- POST
SELECT status,
content::json->'data' AS data,
content::json->'args' AS args,
content::json->'url' AS url,
content::json->'method' AS method
FROM http_post('http://httpbin.org/anything?foo=bar','payload','text/plain');

-- HEAD
SELECT *
FROM (
	SELECT (unnest(headers)).*
	FROM http_head('http://httpbin.org/response-headers?Abcde=abcde')
) a
WHERE field = 'Abcde';

-- Follow redirect
SELECT status,
content::json->'args' AS args,
content::json->'url' AS url
FROM http_get('http://httpbin.org/redirect-to?url=http%3A%2F%2Fhttpbin%2Eorg%2Fget%3Ffoo%3Dbar');

-- Request image
WITH
  http AS (
    SELECT * FROM http_get('http://httpbin.org/image/png')
  ),
  headers AS (
    SELECT (unnest(headers)).* FROM http
  )
SELECT
  http.content_type,
  length(textsend(http.content)) AS length_binary,
  headers.value AS length_headers
FROM http, headers
WHERE field = 'Content-Length';

-- Alter options and and reset them and throw errors
SELECT http_set_curlopt('CURLOPT_PROXY', '127.0.0.1');
-- Error because proxy is not there
SELECT status FROM http_get('http://httpbin.org/status/555');
-- Still an error
SELECT status FROM http_get('http://httpbin.org/status/555');
SELECT http_reset_curlopt();
-- Now it should work
SELECT status FROM http_get('http://httpbin.org/status/555');

