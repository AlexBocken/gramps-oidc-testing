# Setting up Authentik for Gramps Web OIDC Authentication

## Prerequisites

This setup assumes you're using the included Docker Compose configuration. To start Authentik along with other services:

```bash
./start-auxiliary-services.sh
```

This will start PostgreSQL, Redis, Keycloak, and Authentik. Authentik will be available at http://localhost:9000

### First-Time Authentik Setup

On first run, you'll need to create an admin account:

1. Visit http://localhost:9000/if/flow/initial-setup/
2. Set your admin email and password
3. Complete the initial setup wizard

**Note:** The `AUTHENTIK_SECRET_KEY` in docker-compose.yml is set to a default value. For production use, generate a random string with:
```bash
openssl rand -base64 32
```

## 1. Create an OAuth2/OpenID Provider in Authentik

1. Log into your Authentik admin interface
2. Go to **Applications** → **Providers**
3. Click **Create** and select **OAuth2/OpenID Provider**
4. Configure the provider:
   - **Name**: `gramps-web-provider`
   - **Authorization flow**: Choose your preferred flow (typically `default-authorization-flow`)
   - **Client type**: `Confidential`
   - **Client ID**: Generate or set a custom client ID (save this for later)
   - **Client secret**: Generate a secret (save this for later)
   - **Redirect URIs**: `http://localhost:5555/api/oidc/callback/?provider=custom`
   - **Signing Key**: Select an appropriate signing key
   - **Scopes**: Ensure `openid`, `email`, `profile` are included
   - **Subject mode**: `Based on the User's hashed ID`
   - **Include claims in id_token**: Enable this
   - **Issuer mode**: `Each provider has a different issuer`

## 2. Create an Application in Authentik

1. Go to **Applications** → **Applications**
2. Click **Create**
3. Configure the application:
   - **Name**: `Gramps Web`
   - **Slug**: `gramps-web`
   - **Provider**: Select the provider created in step 1
   - **Backchannel providers**: Leave empty unless needed
   - **Policy engine mode**: `any`

## 3. Configure Property Mappings

Ensure the following property mappings are active for your provider:

1. Go to **Customization** → **Property Mappings**
2. Make sure these OIDC mappings exist and are enabled:
   - **OpenID 'email'**: Maps to user email
   - **OpenID 'profile'**: Maps to user profile info
   - **OpenID 'openid'**: Basic OpenID mapping

## 4. Set up Groups for Role Mapping (Optional)

If you want to map Authentik groups to Gramps roles:

1. Go to **Directory** → **Groups**
2. Create groups matching your Gramps roles:
   - `gramps-admin`
   - `gramps-owner`
   - `gramps-editor`
   - `gramps-contributor`
   - `gramps-member`
   - `gramps-guest`

3. Add users to appropriate groups
4. Ensure the `groups` claim is included in tokens by checking your property mappings

## 5. Update Your .env.local Configuration

For the Docker setup on localhost:

```bash
# OIDC Configuration
GRAMPSWEB_OIDC_ENABLED=true
GRAMPSWEB_OIDC_DISABLE_LOCAL_AUTH=true  # Optional: disable local login
GRAMPSWEB_OIDC_NAME="Authentik SSO"  # Custom display name
GRAMPSWEB_OIDC_AUTO_REDIRECT=false  # Set to true for auto-redirect

# Get these from step 1
GRAMPSWEB_OIDC_CLIENT_ID=your-client-id-here
GRAMPSWEB_OIDC_CLIENT_SECRET=your-client-secret-here

# Important: Use the correct issuer URL for localhost
GRAMPSWEB_OIDC_ISSUER=http://localhost:9000/application/o/gramps-web/
GRAMPSWEB_OIDC_REDIRECT_URI=http://localhost:5555/api/oidc/callback/

# Auto-discovery (recommended)
GRAMPSWEB_OIDC_OPENID_CONFIG_URL=http://localhost:9000/application/o/gramps-web/.well-known/openid-configuration

# Standard scopes
GRAMPSWEB_OIDC_SCOPES="openid email profile"
GRAMPSWEB_OIDC_ROLE_CLAIM=groups
GRAMPSWEB_OIDC_USERNAME_CLAIM=preferred_username

# Role mapping (if using groups)
GRAMPSWEB_OIDC_GROUP_ADMIN=gramps-admin
GRAMPSWEB_OIDC_GROUP_OWNER=gramps-owner
GRAMPSWEB_OIDC_GROUP_EDITOR=gramps-editor
GRAMPSWEB_OIDC_GROUP_CONTRIBUTOR=gramps-contributor
GRAMPSWEB_OIDC_GROUP_MEMBER=gramps-member
GRAMPSWEB_OIDC_GROUP_GUEST=gramps-guest
```

For production deployments, replace `http://localhost:9000` with your actual Authentik domain (e.g., `https://auth.yourdomain.com`).

## 6. Key Configuration Points

### Issuer URL Format
The issuer URL should be: `http://localhost:9000/application/o/your-app-slug/` (for Docker setup)

Or for production: `https://your-authentik-domain/application/o/your-app-slug/`

**Important**: Replace `your-app-slug` with the actual slug from step 2, not necessarily `gramps-web`.

### Redirect URI
Must exactly match: `http://localhost:5555/api/oidc/callback/?provider=custom`

### Client Authentication
Authentik supports both `client_secret_post` and `client_secret_basic`. The Gramps Web OIDC client should automatically negotiate the correct method.

## 7. Troubleshooting Steps

1. **Verify the well-known configuration**:
   ```bash
   curl http://localhost:9000/application/o/gramps-web/.well-known/openid-configuration
   ```

2. **Check the issuer field** in the response matches your `GRAMPSWEB_OIDC_ISSUER`

3. **Test the redirect URI** by manually visiting:
   ```
   http://localhost:9000/application/o/authorize/?client_id=YOUR_CLIENT_ID&response_type=code&scope=openid%20email%20profile&redirect_uri=http://localhost:5555/api/oidc/callback/?provider=custom
   ```

4. **Check Authentik logs**:
   ```bash
   docker-compose logs -f authentik-server
   docker-compose logs -f authentik-worker
   ```

5. **Common Issues**:
   - **405 errors**: Usually indicate wrong endpoint URLs or missing trailing slashes
   - **Invalid client**: Client ID/secret mismatch
   - **Invalid grant**: Authorization code expired or redirect URI mismatch
   - **Access denied**: User not authorized or missing required scopes

## 8. Testing the Configuration

1. Restart your Gramps Web backend after updating `.env.local`
2. Visit the Gramps Web login page
3. You should see your custom OIDC provider button
4. Click it to test the full flow

If you encounter issues, check the Authentik logs in **Events** → **Logs** for detailed error messages.

## 9. Docker Deployment Notes

### Managing Services

Start all services (PostgreSQL, Redis, Keycloak, and Authentik):
```bash
./start-auxiliary-services.sh
```

Stop all services:
```bash
docker-compose down
```

Reset everything (removes all data):
```bash
./reset-docker.sh
```

### Service Ports

- **Authentik HTTP**: http://localhost:9000
- **Authentik HTTPS**: https://localhost:9443 (self-signed cert)
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **Keycloak**: http://localhost:8080

### Database Information

Authentik uses a separate database (`authentik`) in the same PostgreSQL instance as Gramps Web. The database is automatically created on first run.

### Persistence

All Authentik data is stored in Docker volumes:
- `authentik_media` - User uploads and media
- `authentik_templates` - Custom templates
- `authentik_certs` - SSL certificates

These volumes persist across container restarts but are removed when running `./reset-docker.sh`.
