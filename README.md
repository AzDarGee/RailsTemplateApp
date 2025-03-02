# Template App Features
- Rails 8.0.1
- Ruby 3.4.2
- Bootstrap 5.3.3
- Stimulus
- Turbo
- Stimulus
- FontAwesome 5
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
- Active Storage with AWS S3
- Image and Video modifications via Background Jobs
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
- Admin Dashboard
- Tagging
- Pay gem to manage payments

# App Name
Change the app name in `config/application.rb` to match the folder name of your app

# Setup
Install all gems
```
bundle install
```

Install yarn packages
```
yarn install
```
Install necessary libraries for some gems to work:
```
sudo apt-get update
sudo apt-get install build-essential
```
For the mini_magick gem, you'll also need ImageMagick installed:
```
sudo apt-get install imagemagick
```
For video modifications, you need to install:
```
sudo apt install ffmpeg
```

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

# Figma Design to Code
Figma-Context-MCP is not contained within this Repo, store and run it separately.
(https://github.com/GLips/Figma-Context-MCP)

To update Figma-Context-MCP:
* Change directory into mpc_servers/Figma-Context-MCP and pull the latest code
```
git pull origin main
```

Install the dependencies (must have pnpm installed - `sudo npm install -g pnpm`):
```
pnpm install
```

Figma API Key:
* Go to Figma and generate an API key and place it in the .env file within Figma-Context-MCP

In a new terminal, `cd` into mcp_servers/Figma-Context-MCP and run:
```
pnpm run dev
```

Copy a link of your design from Figma and paste it in chat. Give chat some instructions to implement the design into code and make sure to specify to use the get_node directive.

For example:
```
<link_to_figma_design>

Implement this in ruby on rails (.html.erb, scss and js) and make sure to use the get_node
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
* Make sure you have the correct master.key file in the `/config` directory

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

To see all included files of your assets by running:
```
rake assets:reveal
```

# Troubleshooting
If javascript controllers are not loading
```
rails assets:clobber
bin/dev
```

# Useful Commands

To view local branches:
```
git branch
```

To view remote branches:
```
git branch -r
```

To delete local branch (make sure you are on a different branch):
```
git branch -D <branch_name>
```

To delete a remote branch:
```
git push -d <branch-name>
```

To fetch all branches from remote:
```
git fetch --prune
```

To install all gems, navigate to the root of your app:
```
bundle install
```

# Docs for all the gems
- Devise (https://github.com/heartcombo/devise)
- mini_magick (https://github.com/minimagick/minimagick)


# To Fix / To Do
* Trix editor not loading with content on hot reload or initial page visit, something to do with hotwire spark and trix js and esbuild/foreman
* Rails logger not working correctly, check config/initializers/logger.rb 
* Fix disposable email validator, all the files are setup (the rake task, the service, the validator and the user model) but it's not working as expected. 
* Organize and group the Template App Features into sections and Table of Contents in the Readme
* Delete dependabot branches from remote
* Be able to delete User Avatar on the edit page with Turbo (no page refresh)
* Hot reloading going slow - hotwire spark. Happened after I added Active storage. Try removing and re-installing hotwire-spark. Looks like letter_opener gem is reloading all the views for letter_opener web on each reload.
* Visualize the database models in a diagram
* Add markdown for chat messages received from AI