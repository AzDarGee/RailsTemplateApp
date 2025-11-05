# Template App Features
- Rails 8.1.1
- Ruby 3.4.7
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
    - Openrouter
- Admin Dashboard (Avo)
- Search (ransack)
- Tagging
- Pay gem to manage payments (Stripe and PayPal)

# App Name
* Change the app name in `config/application.rb` to match the folder name of your app
* Change the name of the app in `.devcontainer/devcontainer.json` & `.devcontainer/compose.yaml` to the new app name
* Change the description in `app/views/pwa/manifest.json.erb` to the new app name
* Change `app/views/shared/_navbar.html.erb` name of app to new app name
* Change `config/environments/production.rb` Action Mailer default url options to your new domain name
* Update all environment variables to reflect the new app name

# PostGreSQL Setup
To start the postgresql server:
```
sudo systemctl start postgresql
```

To restart the postgresql server:
```
sudo systemctl restart postgresql
```

Connect as postgres user:
```
sudo -u postgres psql
```

# Install ImageMagick
```
sudo apt-get install imagemagick
```

# Server Setup
Start the ssh-agent in the background:
```
eval "$(ssh-agent -s)"
```

Make sure to add your private key to the ssh-agent:
```
ssh-add ~/.ssh/id_ed25519
```

SSH with specified port to server:
```
ssh newuser@your_server_ip -p NEW_PORT_NUMBER
```
- Replace newuser with your username on the server. Replace your_server_ip with your actual server ip. Replace NEW_PORT_NUMBER with the correct ssh port.

Update Repository, on your server, run:
```
sudo apt-get update
sudo apt-get upgrade
```

View Auth Attempts to server:
```
sudo tail -n 10 -f /var/log/auth.log
```

Add non-root user
```
adduser ashishdarji
usermod -aG sudo ashishdarji
```

Don't require password for sudo for new user. In `/etc/sudoers` file:
```
your-non-root-user ALL=(ALL) NOPASSWD: ALL
```
- Replace your-non-root-user for your username

Setup SSH Keys and Disable Password Logins:
Add your local ssh public key to ~/.ssh/authorized_keys on the server
```
nano ~/.ssh/authorized_keys
```

In `/etc/ssh/sshd_config` on your server:
```
Set PubkeyAuthentication yes
Set PasswordAuthentication no
Set PermitEmptyPasswords no
Set PermitRootLogin prohibit-password
```

In `/etc/ssh/sshd_config.d/50-cloud-init.conf` on your server:
```
Set PasswordAuthentication no
```

Uncomment the PORT number and pick a port to run ssh on (this step is crucial):
```
sudo nano /etc/ssh/sshd_config
```

You might need these extra settings for coolify in the `/etc/ssh/sshd_config` file:
```
AllowGroups admin root
PubkeyAcceptedAlgorithms +ssh-ed25519
HostKeyAlgorithms +ssh-ed25519
```

Restart SSHD:
```
sudo systemctl restart sshd
```

## UFW Firewall Linux Setup
To enable ufw firewall:
```
sudo ufw enable
```

Restart UFW:
```
sudo systemctl restart ufw
```

Check status:
```
sudo ufw status verbose
```

Check status and display numbered rules:
```
sudo ufw statuas numbered
```

Delete rule:
```
ufw delete <RULE_NUMBER>
```
- Where the <RULE_NUMBER> is the number you got from the previous command

Set UFW Logging Level:
```
sudo ufw logging full
```

Deny all incoming traffic and allow all outgoing traffic:
```
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow essential ports (this step is crucial):
```
sudo ufw allow NEW_SSH_PORT_NUMBER/tcp
```
- NEW_SSH_PORT_NUMBER replace with your new ssh port number
```
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

For Coolify:
```
sudo ufw allow 8000/tcp
sudo ufw allow 6001/tcp
sudo ufw allow 6002/tcp
```

Restart UFW:
```
sudo ufw disable
sudo ufw enable
```

Reload UFW:
```
sudo ufw reload
```

Reset UFW Rules to default:
```
sudo ufw reset
```

Remember to restart your ssh service or you might get locked out:
```
sudo service ssh restart
```

## Install Fail2Ban:
```
sudo apt install fail2ban
```

Copy jail.conf to jail.local and specify changes:
```
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Add the following lines under the [ssh] & [sshd] directive in `/etc/fail2ban/jail.local`: Make sure to specify your new ssh port number.
```
[ssh]
enabled = true
port = <NEW_SSH_PORT>
filter = sshd
maxretry = 5
findtime = 10m
bantime = 1w
```

Restart & enable SSH:
```
sudo systemctl restart ssh
sudo systemctl enable ssh
```

Restart & enable Fail2Ban:
```
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

Tail the Fail2Ban Logs:
```
sudo tail -f /var/log/fail2ban.log
```

To ban a user's IP address from Fail2Ban:
```
sudo fail2ban-client set sshd banip <IP_ADDRESS>
```
- replace <IP_ADDRESS> with the correct IP address


To unban a user's IP address from Fail2Ban:
```
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>
```
- replace <IP_ADDRESS> with the correct IP address

To view banned IPs:
```
sudo fail2ban-client status sshd
```

# Automatic Updates
Install package:
```
sudo apt install unattended-upgrades
```

Run this and select YES:
```
sudo dpkg-reconfigure unattended-upgrades
```

### Coolify Server IP Address:
```
host.docker.internal
```

# App Setup
# Setup
Install latest nodejs LTS:
```
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
```

Upgrade NPM:
```
npm install -g npm@latest
```

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

Setup credentials for Mission Control Jobs:
```
bin/rails mission_control:jobs:authentication:configure
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

If the server is still running and `bin/dev` won't work:
```
lsof -wni tcp:3000
kill -9 <pid_number>
```
* Replace <pid_number> with the number you got from the first command

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

To switch to a branch on remote:
```
git checkout -b <branch_name> origin/<branch_name>
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
