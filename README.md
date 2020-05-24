## Jumpstart Rails API
Get started with rails 6 API easily.

### Requirements
- Bundler - `gem install bundler`
- Rails - `gem install rails`
- Ruby - version 2.5 or higher

### Creating a new application
```
rails new app_name -d postgresql -m https://raw.githubusercontent.com/beyode/jumpstart-rails-api/master/template.rb --api
```
Or reference `template.rb` locally if you have cloned this repo

```
rails new app_name -d postgresql -m /path/to/jumpstart-rails-api/template.rb
```

### Features
1. Authentication
 - JWT
 - Simple Token

 All of this are used together with your favorite Authentication gem `devise`

2. Json API
This template uses `fast_jsonapi` a gem from neflix which make serialization of objects lightining fast.

3. Foreman

### Authentication
__Registration__

Request

```bash
http --form POST 127.0.0.1:3000/api/v1/registration first_name='moses' last_name='gathuku' email='hello2@gathuku.com' password='secret'
```

Registration Sucess
```json
{
    "data": {
        "attributes": {
            "email": "hello2@gathuku.com",
            "first_name": "moses",
            "last_name": "gathuku"
        },
        "id": "3",
        "type": "registration"
    }
}
```

Registration Failure
```json
{
    "errors": {
        "code": 422,
        "details": [
            "Email has already been taken"
        ]
    }
}
```

__Sign In__

Sign In Success - Returns a JWT token

```json
{
    "data": {
        "attributes": {
            "email": "hello2@gathuku.com",
            "jwt_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjMsImV4cCI6MTU5MDQyODgxOH0.KQuzW2Yrtm8VL7kwlJlx9ipoVbd1jPlYez__wHzByck"
        },
        "id": "3",
        "type": "sessions"
    }
}
```

Sign In Failure  
```json
{
    "errors": {
        "code": 401,
        "details": [
            "Invalid email or password"
        ]
    }
}
```
