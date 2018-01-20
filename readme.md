# Twitched

Twitch app for the Roku media player

# Installing

The repo root can be zipped and installed onto a Roku with the developer
 mode enabled.

See [Loading and Running Your Application] on the Roku documentation site.

## secret.json

The secret.json file is required. At minimum it should include an empty JSON
 object `{}`. All fields are located in the **secret.json.example** file.
 
# API

Twitched does not use Twitch API endpoints directly. Instead, it uses an API
 proxy/cache that handles caching requests and modifies some return values to
 make ingesting the API easier.
 
See the [Twitched API].



[Loading and Running Your Application]: https://sdkdocs.roku.com/display/sdkdoc/Loading+and+Running+Your+Application
[Twitched API]: https://github.com/TwitchedApp/TwitchedApi
