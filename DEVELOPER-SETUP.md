# MicroCODE App Template

A SaaS template built from the Gravity App Boilerplate.

This template was created from Kyle's GRAVITY-APP product in 2024, when MicroCODE `purchased` it and began modifications.
This template combines the best features from `gravity-current` and `ladders` to serve as a common base for building new MicroCODE SaaS applications.

This template will include all major features:

- **Multi-Lingual Support (i18n)**
- **Shadcn/UI Integration**
- **Express 5 Compatibility**
- **Enhanced Server Architecture** (SIG handling, graceful shutdown, port management)
- **JSDoc Annotations** for automatic API documentation
- **Swagger/OpenAPI Support** for API documentation and testing
- **MicroCODE Packages** (mcode-\* packages)
- **MicroCODE Bootstrap System** for environment initialization
- **MongoDB \_id as Primary Key** (no secondary UUID)

NOTE: For testing multiple Clients against one Server, remove this from `VITE Config`:

```
  strictPort: true
```

## Description

MicroCODE purchased a complete license to the Gravity SaaS Boilerplate in
January 2024. We are free to use it to build as many Web Apps as we like, we
cannot resell the boilerplate nor any derivative of it.

This `app-template` serves as the foundation for building new MicroCODE SaaS applications, including:

- **LADDERS®** - PLC Programming Platform
- **Regatta RC™** - Remote Control Application
- Future MicroCODE SaaS products

## Getting Started

### Dependencies

- Node.js 22+ - execution environment
- MongoDB - database
- Stripe - payments
- Mailgun - email service
- mcode-\* packages - MicroCODE logging, caching, data, and list processing
- ...

### Documentation

We selected Gravity as our SaaS Boilerplate because their code looked super-clean, consistent, and
they had beautiful online documentation, and training...

[Gravity Documentation](https://docs.usegravity.app/)

### Training

- MicroCODE purchased Gravity Training from Kyle, to access course: [Gravity Training Course](https://click.mlflow.com/link/c/YT0yMzg5NDM0OTg0Mzk5MTE1OTM3JmM9Zjd0NSZlPTQ2NzQ0NTIxJmI9OTczMTkwMTA1JmQ9cTFuNHoyeQ==.E8Etpdc01Kz2FeMURvW6oqmj9O6FqnopOVIiujHd1Z8)

### Initial Setup

1. Install MongoDB Community Edition

   - [MongoDB Download Center](https://www.mongodb.com/try/download/community)

2. Install Node Version Manager (NVM)

   - [NVM for Windows](https://github.com/coreybutler/nvm-windows)

3. Install Node.js v22+

   - Using NVM: `nvm install 22.24.0` (or later)
   - Using NVM: `nvm use 22.24.0` (or later)

4. Clone the MicroCODE App Template repository

   - `git clone https://github.com/MicroCODE-App-Template/app-template.git`

5. Create a shared `.env` file

   - Clone `.env.example` to `.env.shared` in the root directory and fill in the required values
   - Note: `DB_CLIENT` controls '`npm run setup`' behavior in Steps 6 and 7
   - the `.env` files should never be committed to source control with real credentials!
   - the `.env` files are ignored by `.gitignore` to prevent accidental commits, **_STORE them securely!_**
   - the `.env` files are required for both `server` and `mission-control` directories.
   - the `.env` files in `server` and `mission-control` must be identical.

6. Created a `.env` file in the `server` directory

   - Clone `.env.shared` to `.env` and fill in the required values

7. Created a `.env` file in the `mission-control` directory

   - Clone `.env.shared` to `.env` and fill in the required values

8. Setup proper DB Models and Install NPM dependencies
   - Move to the SERVER directory (`cd server`)
   - Run the setup script to create DB Models and install dependencies (`npm run setup`)
   - Move to the MISSION-CONTROL directory (`cd mission-control`)
   - Run the setup script to create DB Models and install dependencies (`npm run setup`)
   - Run the script to create the Mission Control Admin Account (`http://localhost:5002/setup`)

#### MongoDB

MongoDB is our chosen DB for our SaaS.

To create a clean database for testing...

- Ensure you have admin privileges in the current MongoDB environment.
- To establish this from nothing...
- Install MongoDB and start with no security...
- Stop MongoDB - to erase current Dev environment

```
net stop mongodb
```

- UNINSTALL MongoDB from ADD/REMOVE PROGRAMS...

- Delete existing MongoDB Data Files...

```
cd "C:\Program Files\MongoDB\Server\<version>\data\db"
cd "C:\Program Files\MongoDB\Server\8.2\data\db"
del *.*
```

- Delete existing MongoDB Log Files...

```
cd "C:\Program Files\MongoDB\Server\<version>\log"
cd "C:\Program Files\MongoDB\Server\6.0\log"
del *.*
```

- DOWNLOAD & INSTALL MongoDB from scratch.
- INSTALL MONGO DB SHELL...

```
winget install MongoDB.Shell
```

- Turn off default security...
  (Edit **mongod.cfg** and comment out these lines _if_ present)

```
cd "C:\Program Files\MongoDB\Server\<version>\bin"
cd "C:\Program Files\MongoDB\Server\8.2\bin"
edit mongod.cfg

#security:
#  authorization: "enabled"
```

- Start MongoDB -- if you just installed as a Windows Service it should have start automatically...

```
net start mongodb
```

- Shell into MongoDB (mongosh) and create your admin and application accounts...

```
mongosh

# First, confirm the existing admin/saas accounts (do not delete them)
use admin
db.getUsers()
# If the `admin` superuser is missing, create it with the command below, otherwise skip.
# db.createUser({ ... })

# Next, create the new application user in the `appDatabase`
use appDatabase
db.createUser({
  user: "appAdmin",
  pwd: "appPassword",
  roles: [
    { role: "readWrite", db: "appDatabase" },
    { role: "dbAdmin", db: "appDatabase" }
  ]
})

# Verify the users were created (admin + appDatabase coexist with existing saasDatabase)
use admin
db.getUsers()
use appDatabase
db.getUsers()
```

- Stop MongoDB

```
net stop mongodb
```

- Enable security... (Edit **mongod.cfg** enable these lines)
- NOTE: Remove `#` characters from both lines

```
security:
  authorization: "enabled"
```

- Restart MongoDB...

```
net start mongodb
```

- (Optional) Test the legacy `saasAdmin` connection if you still use it for other apps...

```
mongosh "mongodb://saasAdmin:saasPassword@localhost:27017/saasDatabase" --eval "db.getName()"
```

- Test the new `appAdmin` connection for this template...

```
mongosh "mongodb://appAdmin:appPassword@localhost:27017/appDatabase" --eval "db.getName()"
```

---

## Configuration Files (⚠️ CRITICAL - DO NOT SKIP)

The application requires proper configuration files in `server/config/` that are **NOT tracked in git** for security. Missing or incomplete configuration will cause runtime errors.

### Required Configuration Files

Create these files in the `server/config/` directory:

#### 1. `default.json` (Development Configuration)

This file is used for local development. Create it with the following structure:

```json
{
  "app": {
    "name": "Your App Name",
    "url": "http://localhost:3000"
  },
  "email": {
    "domain": "sandbox-xxxxxxxxxxxxx.mailgun.org",
    "sender": "noreply@yourdomain.com"
  },
  "database": {
    "connection": "mongodb://appAdmin:appPassword@localhost:27017/appDatabase"
  }
}
```

#### 2. `production.json` (Production Configuration)

This file is used when `NODE_ENV=production`. It should contain production-specific values:

```json
{
  "app": {
    "url": "https://yourdomain.com"
  },
  "email": {
    "domain": "mg.yourdomain.com",
    "sender": "noreply@yourdomain.com"
  }
}
```

### Critical: Mailgun Email Configuration

The `email.domain` field is **required** for email functionality. If missing or empty, you'll see:

- ❌ Red banner in the UI warning about configuration errors
- ❌ Server startup warnings in the console
- ❌ 404 errors when attempting to send emails

**Where to find your Mailgun domain:**

1. Log into your [Mailgun dashboard](https://app.mailgun.com/)
2. Navigate to **Sending** → **Domains**
3. Copy your sandbox domain (format: `sandbox-xxxxxxxxxxxxx.mailgun.org`) for development
4. For production, use your verified custom domain

**Important:** Do not leave `email.domain` as an empty string `""` - this will cause Mailgun to return 404 errors.

### Environment Variables

Create a `.env` file in the `server/` directory with sensitive credentials:

```bash
# Mailgun API credentials
MAILGUN_API_KEY=your_mailgun_api_key_here

# Stripe payment processing
STRIPE_SECRET_API_KEY=sk_test_xxxxxxxxxxxxx

# Session security
SESSION_SECRET=your_random_session_secret

# MongoDB (if not using config files)
MONGO_URI=mongodb://appAdmin:appPassword@localhost:27017/appDatabase
```

**Find your Mailgun API key:**

- Dashboard → **Settings** → **API Keys**
- Copy the **Private API Key** (starts with `key-`)

### Configuration Validation

The application validates configuration on startup:

- ✅ **Green/No banner**: All required configuration is present
- ⚠️ **Orange banner**: Non-critical warnings (check console)
- 🛑 **Red banner**: Critical errors - app may not function (check `/api/health/config`)

If you see validation errors:

1. Check the browser console and server logs
2. Verify `server/config/default.json` exists and has valid JSON
3. Ensure `email.domain` is not empty
4. Verify `MAILGUN_API_KEY` is set in `.env`
5. Restart the server after fixing configuration

---

## Seeding the Database

- Move to the SERVER directory (`cd server`)
- In the SERVER CLI, run the new MicroCODE scripts to create all static DB Tables

```
$env:NODE_OPTIONS = "--openssl-legacy-provider"
docker volume create mcode-app-name-mongodb-volume
npm run seed:all
```

- You should see these messages like these...
<p align="left"><img src=".\images\mongodb-run-seeds.png" width="720" title="Init new MongoDB" style="border: 0.5px solid lightgray;"></p>

- Then check the "saasDatabase" in mongosh for the default tables, similar to these...
<p align="left"><img src=".\images\mongodb-drop-database.png" width="720" title="Delete MongoDB" style="border: 0.5px solid lightgray;"></p>

---

## Mission Control Setup (Manual Configuration)

Mission Control is your admin dashboard for managing users, viewing metrics, and monitoring the application. Instead of using the legacy setup wizard, follow this manual configuration process.

### Prerequisites

- MongoDB running with `appAdmin` user configured (see MongoDB Setup above)
- Mission Control `.env` file configured with proper credentials

### Create Mission Control Admin Account

Navigate to the mission-control directory and create the master admin account:

```bash
cd mission-control
npm run create:admin
```

This will create a master admin account with default credentials:

- **Email**: `admin@mcode.com`
- **Password**: `admin123`

⚠️ **IMPORTANT**: Change this password immediately after first login!

The script will:

1. Connect to MongoDB using credentials from `.env`
2. Create a "Master" account with `master` plan
3. Create an admin user with `master` permissions
4. Set the user as verified and ready to log in

### Start Mission Control

```bash
npm run dev
```

Mission Control will be available at `http://localhost:5002`

### First Login

1. Navigate to `http://localhost:5002/signin`
2. Log in with `admin@mcode.com` / `admin123`
3. **Immediately change your password** in the account settings

### Troubleshooting Mission Control

If you see "ENOENT: no such file or directory, open 'D:\\MicroCODE\\saas\\app-demo\\mission-control\\model\\mongo.js'":

- This means the MongoDB model files haven't been set up
- The `create:admin` script doesn't require these files
- Once the admin account is created, you can log in and manage users

**Database Connection Issues:**

Check your `mission-control/.env` file has:

```bash
DB_CLIENT=mongo
DB_HOST=localhost
DB_USER=appAdmin
DB_PASSWORD=appPassword
DB_NAME=appDatabase
DB_PORT=27017
```

Or use the MONGO_URI format:

```bash
MONGO_URI=mongodb://appAdmin:appPassword@localhost:27017/appDatabase
```

---

# BIN/ Utilities

The `bin/` directories contain utility scripts for scaffolding, setup, and maintenance. All scripts follow the new file naming conventions:

- `{entity}.model.js` for models
- `{entity}.controller.js` for controllers
- `{entity}.route.js` for API routes
- `{entity}.{locale}.json` for locale files

## server/bin/

### Scaffolding & Code Generation

- **`view.js`** — Scaffolds new MVC entities (model, view, controller, API routes, locales).

  - Usage: `node bin/view.js <entity-name> [-ui] [-db]`
  - Creates: `{entity}.model.js`, `{entity}.controller.js`, `{entity}.route.js`, `{entity}.{locale}.json`
  - `-ui` flag: Also creates React UI views and routes
  - `-db` flag: Creates SQL migration file (SQL databases only, not MongoDB)

- **`component.js`** — Creates new React components. Usage: `node bin/component.js <component-name>`

  - Creates component file and adds export to `lib.jsx`

- **`master.js`** — Creates master admin accounts. Usage: `node bin/master.js <email>:<password>`
  - Creates account with `master` plan and admin user with `master` permissions

### Setup & Configuration

- **`setup.js`** — Initial database setup and model file copying

  - Reads `DB_CLIENT` from `.env` to determine database type
  - Copies model files from `model/sql/` or `model/mongo/` to `model/` root
  - Renames files to `.model.js` format during copy
  - Runs database migrations (SQL) or prepares MongoDB models

- **`cleanup.js`** — Removes setup/demo files after initial setup
  - Deletes setup controller, model, route, and locale files
  - Removes setup views from client

### CLI & Tooling

- **`gravity.js`** — Interactive CLI toolbelt for common tasks

  - `gravity create view` — Scaffold new MVC (interactive)
  - `gravity create component` — Create React component (interactive)
  - `gravity create master` — Create master account (interactive)
  - `gravity help` — Show interactive help menu
  - `gravity test` — Run test suite (server only)

- **`start.js`** — Starts development servers concurrently
  - Runs `npm run server`, `npm run app` (if exists), `npm run client` (if exists)

### Installation Checks

- **`installcheck.js`** — Validates Node.js version (requires 15+)
- **`appcheck.js`** — Checks for mobile app directory and renames if needed
  - Looks for: `app`, `client-react-native`, `client-react-native-main`
- **`clientcheck.js`** — Checks for web client directory and renames if needed
  - Looks for: `client`, `client-react-web`, `client-react-web-main`

## mission-control/bin/

### Scaffolding & Code Generation

- **`view.js`** — Scaffolds new MVC entities (same as server version)

  - Creates: `{entity}.model.js`, `{entity}.controller.js`,
  - `{entity}.route.js`, `{entity}.{locale}.json`

- **`component.js`** — Creates new React components (same as server version)

- **`master.js`** — Creates master admin accounts (same as server version)

- **`create-admin.js`** — Creates Mission Control admin account directly in MongoDB
  - Usage: `npm run create:admin` or `node bin/create-admin.js`
  - Creates default admin: `admin@mcode.com` / `admin123`
  - Bypasses setup wizard for manual configuration
  - Uses mongoose schemas directly (no model file dependencies)

### Setup & Configuration

- **`setup.js`** — Initial database setup and model file copying (same as server version)

  - Copies model files and renames to `.model.js` format

- **`cleanup.js`** — Removes setup/demo files (same as server version)

### CLI & Tooling

- **`gravity.js`** — Interactive CLI toolbelt (same as server, without test command)

### Installation Checks

- **`installcheck.js`** — Validates Node.js version (requires 15+)

---

# Production SECURITY

## What's Currently Set Up: ✅

- Authorization enabled
- User authentication required
- Role-based access control (saasAdmin has proper roles)
- Connection authentication working
- What You Should Consider Adding:

## Network Security

MongoDB is bound to 127.0.0.1 (localhost only) ✅ Good for development

- For production, keep it this way or use VPN/firewall rules

## Stronger Password

- Currently using saasPassword - change to a strong, random password for production

## Principle of Least Privilege ✅

- **Admin user (`admin`)**: Full access to all databases - use only for maintenance and user management
- **Application user (`appAdmin`)**: Limited to `appDatabase` only - used by the application
  - This isolation ensures leaked application credentials don't compromise other databases
- Consider creating additional users:
  - Read-only user for reporting
  - Backup user with minimal permissions

## Additional Security Measures (for production):

- Enable TLS/SSL encryption
- Enable audit logging
- Set up IP whitelisting
- Regular backups with encryption
- Rotate credentials periodically
- For your current development setup, you have everything you need. Just remember to:

Use a strong password before going to production
Never commit .env file with real credentials to git
Consider environment-specific users (dev vs production)

### Executing program

- Move to the SERVER directory (`cd server`)
- Start the development server (this also starts the Web Browser Client)

```
npm run dev
```

You should see `Server console` output like this...

<p align="left"><img src=".\images\npm-run-dev-1.png" width="720" title="Server startup" style="border: 0.5px solid lightgray;"></p>

The `Client` launches here, but is not 100% available until the Server completes...

<p align="left"><img src=".\images\npm-run-dev-2.png" width="720" title="Client startup" style="border: 0.5px solid lightgray;"></p>

And the `App` should automatically open to the Login screen, similar to this...

<p align="left"><img src=".\images\npm-run-dev-3.png" width="720" title="App Login" style="border: 0.5px solid lightgray;"></p>

## Help

MicroCODE has a support contract with Gravity Ltd, Kyle Gawley.

## Terminology

| Word or Acronym | Description/Definition                                                                                                                              |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SaaS**        | Software as a Service (SaaS) - subscription based access to a software product or service.                                                          |
| **Gravity**     | A SaaS Boilerplate, from which this App Template is constructed.                                                                                    |
| **API**         | An Application Programming Interface, or API, is the set of functions/objects that a developer will provide in order to make use of their services. |
| **NPM**         | Node Package Manager, actually "Node PM", "Node pkgmakeinst" a system to deploy, install, and maintain NodeJS Apps. (PM was a BASH utility).        |
| **NVM**         | Node Version Manager, a tool that supports changing NodeJS versions.                                                                                |
| **MERN**        | MongoDB, Express, React, Node JS.                                                                                                                   |
| **MongoDB**     | A 'NoSQL' database designed for Cloud applications, also referred to as a 'Document Store'.                                                         |
| **ExpressJS**   | Express is _not_ a database but rather an 'extensible routing language' for communication between a Client and a Server.                            |
| **React**       | A Web UI development system, a JavaScript library developed by Facebook and made public—and Open Source—since 2013.                                 |
| **NodeJS**      | A development stack that executes from a local file store—on a local Server—instead of from a network of servers.                                   |
| **JSDocs**      | A toolset to automatically generate API-style documentation from source code tagging.                                                               |

## Authors

Contributors names and contact info

- Timothy J McGuire [@TimothyMcGuire](https://twitter.com/TimothyMcGuire)

## Version History

- See [CHANGELOG.md](./CHANGELOG.md) for details

## License

This project is licensed under a PRIVATE License - see the LICENSE.md file for details:
[MicroCODE SaaS License](./LICENSE.md)

The App Template it is based upon is licensed under their PRIVATE license,
see [GRAVITY Software License Agreement](./server/LICENSE.md)

## Acknowledgments

- [App Boilerplate](https://usegravity.app/)
