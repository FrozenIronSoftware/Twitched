# Twitched

Twitch app for the Roku media player

**This repo is no longer maintained.**

# Installing

The repo root can be zipped and installed onto a Roku with the developer
 mode enabled.
 
## Paid/Free (Ads)

Twitched includes two releases: Twitched and Twitched Zero.

### Twitched

- `bs_const=enable_ads=false` is set to false in the main manifest
- `bs_libs_required=roku_ads_lib` is **not** present or commented out in the main manifest
- components/Ads.brs and components/Ads.xml are **not** included in the
    app package

### Twitched Zero

- `bs_const=enable_ads=true` is set to true in the main manifest
- `bs_libs_required=roku_ads_lib` is present in the main manifest
- components/Ads.brs and components/Ads.xml are included in the app package
- Name is changed in the main manifest
- Logo, splash, and channel poster are updated

See [Loading and Running Your Application] on the Roku documentation site.

## secret.json

The secret.json file is required. At minimum it should include an empty JSON
 object `{}`. All fields are located in the **secret.json.example** file.
 
# API

Twitched does not use Twitch API endpoints directly. Instead, it uses an API
 proxy/cache that handles caching requests and modifies some return values to
 make ingesting the API easier.
 
See the [Twitched API].

# License

GPLv2. See license.txt for more information.



[Loading and Running Your Application]: https://sdkdocs.roku.com/display/sdkdoc/Loading+and+Running+Your+Application
[Twitched API]: https://github.com/FrozenIronSoftware/TwitchedApi
