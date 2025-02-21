# Template App Features
- Rails 8.0.1
- Ruby 3.4.2
- Bootstrap 5.3.3
- Stimulus
- Turbo
- Stimulus
- FontAwesome
- Devise
- NVM for node version management (node 23.8.0)
- esbuild for js bundling (instead of importmap)
- Yarn (1.22.22)


# Setup
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

