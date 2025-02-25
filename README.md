# Template App Features
- Rails 8.0.1
- Ruby 3.4.2
- Bootstrap 5.3.3
- Stimulus
- Turbo
- Stimulus
- FontAwesome
- Devise for authentication
- NVM for node version management (node 23.8.0)
- ESBuild for js bundling (instead of importmap)
- Yarn (1.22.22)
- Letter Opener for viewing emails in development
- Hotwire Flash messages
- Dockerfile for One-Click setup 
- ActionText - Trix Editor
- ViewComponents
    - Docs: https://viewcomponent.org/
- Active Storage with AWS S3 or Google Cloud Storage 
- MiniTest for testing
- Turbo Streams 
- SOLID Trifecta 
    - SOLID Queue for background jobs (MissionControl Dashboard for jobs monitoring)
    - SOLID Cable for WebSockets / ActionCable 
    - SOLID Cache for caching
- AI Integration (LangChainRB)
    - Open AI
    - Claude
    - Google Gemini

# App Name
Change the app name in `config/application.rb` to match the folder name of your app

# Setup
To migrate the database:
```
rails db:migrate
```

To rollback previous migration (in reverse chronological order):
```
rails db:rollback
```

To rollback a specific migration
```
rails db:migrate:down VERSION=<version_number>
```
* Replace <version_number> witht the string of numbers of the migration you wish to roll back
* Note: If that specific migration depends on later migrations, you will have to rollback the later migrations as well.

To run rails development server:
```
bin/dev
```

# View Emails sent in development
```
http://localhost:3000/letter_opener
```

# Clear Rails cache
```
bin/rails cache:clear
```

# To add js/css packages
```
yarn add <package>
```

# To edit credentials
```
EDITOR="cursor --wait" bin/rails credentials:edit
```
* Make sure you have the correct master.key file in the /config directory

# To see the routes in a browser, navigate to:
```
http://localhost:3000/rails/info/routes
```

# To Generate a new View Component
```
rails g component <component_name>
```

# Debugging
Add this line anywhere in the code to start debugging
```
binding.remote_pry 
```

Open a new terminal and run the below command to start the pry server
```
pry-remote
```

To use rails default debugger, type `console` anywhere in the code and refresh the page.

You can also use, for example, `debug(current_user)` anywhere in the code to get more info on an object

# Troubleshooting
If javascript controllers are not loading
```
rails assets:clobber
bin/dev
```

# To Fix / To Do
* Trix editor not loading with content on hot reload or initial page visit, something to do with hotwire spark and trix js and esbuild/foreman
* Rails logger not working correctly, check config/initializers/logger.rb 
* Fix disposable email validator, all the files are setup (the rake task, the service, the validator and the user model) but it's not working as expected. 
* Organize and group the Template App Features into sections
