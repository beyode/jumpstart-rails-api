## Jumpstart Rails API
Get started with rails 6 API easily.

### Requirements
- Bundler - `gem install bundler`
- Rails - `gem install rails`
- Ruby - version 2.5 or higher

### Createting a new application
```
rails new app_name -d postgres -m https://raw.githubusercontent.com/beyode/jumpstart-rails-api/master/template.rb --api
```
Or referene `template.rb` locally if you have cloned this repo

```
rails new app_name -d postgres -m /path/to/jumpstart-rails-api/template.rb
```

### Features
1. Authentication
 - JWT
 - Simple Token

 All of this are used together with your favorite Authentication gem `devise`

2. Json API
This template uses `fast_json` a gem from neflix which make serialization of objects lightining fast.

3. Foreman
