# Keycloak Setup Guide for Gramps Web OIDC Integration

This guide provides step-by-step instructions for setting up Keycloak as an OIDC provider for Gramps Web authentication.

## Prerequisites

- Docker installed and running
- Gramps Web with OIDC integration installed
- Basic understanding of OIDC/OAuth2 concepts

## 1. Start Keycloak

Use the provided script to start Keycloak in development mode:

```bash
./start-keycloak.sh
```

This will:
- Start Keycloak container on port 8080
- Set admin credentials to `admin/admin`
- Use in-memory H2 database (suitable for testing)

Wait for Keycloak to fully start (usually 30-60 seconds). You'll see "Started Keycloak" in the logs.

## 2. Access Keycloak Admin Console

1. Open your browser and go to: http://localhost:8080
2. Click "Administration Console"
3. Login with credentials: `admin/admin`

## 3. Create a Realm

1. In the Keycloak admin console, click the dropdown next to "master" (top-left)
2. Click "Create Realm"
3. Set realm name: `gramps`
4. Click "Create"

## 4. Create a Client

1. In the `gramps` realm, navigate to **Clients** in the sidebar
2. Click "Create client"
3. Configure the client:
   - **Client type**: OpenID Connect
   - **Client ID**: `gramps-web`
   - Click "Next"
4. **Capability config**:
   - ✅ Client authentication: ON
   - ✅ Authorization: OFF
   - ✅ Standard flow: ON
   - ✅ Direct access grants: ON
   - Click "Next"
5. **Login settings**:
   - Valid redirect URIs: `http://localhost:5000/api/oidc/callback/*`
   - Web origins: `http://localhost:5000`
   - Click "Save"

## 5. Get Client Secret

1. In your `gramps-web` client, go to the **Credentials** tab
2. Copy the **Client secret** value
3. Update your `.env.local` file with this secret:
   ```bash
   GRAMPSWEB_OIDC_CLIENT_SECRET=your-copied-secret-here
   ```

## 6. Create Groups for Role Mapping

1. Navigate to **Groups** in the sidebar
2. Create the following groups by clicking "Create group":
   - `gramps-admin` (highest permissions)
   - `gramps-owner`
   - `gramps-editor`
   - `gramps-contributor`
   - `gramps-member`
   - `gramps-guest` (lowest permissions)

### Group Hierarchy (Optional)

You can create a hierarchy for easier management:
```
gramps-users/
├── gramps-admin
├── gramps-owner
├── gramps-editor
├── gramps-contributor
├── gramps-member
└── gramps-guest
```

## 7. Create Test Users

1. Navigate to **Users** in the sidebar
2. Click "Add user"
3. Create test users:

### Admin User
- **Username**: `testadmin`
- **Email**: `admin@example.com`
- **First name**: `Test`
- **Last name**: `Admin`
- Click "Create"

### Regular User
- **Username**: `testuser`
- **Email**: `user@example.com`
- **First name**: `Test`
- **Last name**: `User`
- Click "Create"

## 8. Set User Passwords

For each user:
1. Go to the **Credentials** tab
2. Click "Set password"
3. Set password: `password` (or your preferred test password)
4. Turn OFF "Temporary" toggle
5. Click "Save"

## 9. Assign Users to Groups

### For Admin User:
1. Go to `testadmin` user
2. Click **Groups** tab
3. Select `gramps-admin` from available groups
4. Click "Join"

### For Regular User:
1. Go to `testuser` user
2. Click **Groups** tab
3. Select `gramps-member` from available groups
4. Click "Join"

## 10. Configure Client Scopes

1. Navigate to **Client scopes** in the sidebar
2. Click on `groups` scope (if it exists) or create it:
   - Click "Create client scope"
   - Name: `groups`
   - Type: Default
   - Click "Save"

3. In the `groups` scope, go to **Mappers** tab
4. Click "Add mapper" → "From predefined mappers"
5. Select "Group Membership" and click "Add"
6. Configure the mapper:
   - **Name**: `groups`
   - **Token Claim Name**: `groups`
   - **Full group path**: OFF (recommended)
   - Click "Save"

## 11. Assign Scope to Client

1. Navigate to **Clients** → `gramps-web`
2. Go to **Client scopes** tab
3. Click "Add client scope"
4. Select `groups` scope
5. Set it as "Default"
6. Click "Add"

## 12. Test Configuration

1. Start your Gramps Web backend:
   ```bash
   ./start-backend.sh
   ```

2. Start your Gramps Web frontend:
   ```bash
   ./start-frontend.sh
   ```

3. Navigate to http://localhost:8001
4. You should see a "Login with OIDC" button
5. Click it to test the authentication flow

## 13. Verify User Roles

After successful OIDC login:
1. Check the Gramps Web logs for role assignment messages
2. Verify the user has appropriate permissions based on their group membership
3. Admin users should have full access, members should have limited access

## Troubleshooting

### Common Issues

1. **"Client not found" error**
   - Verify client ID matches exactly: `gramps-web`
   - Ensure you're in the correct realm (`gramps`)

2. **"Invalid redirect URI" error**
   - Check redirect URI is exactly: `http://localhost:5000/api/oidc/callback/*`
   - Ensure no trailing slashes unless specified

3. **"Groups not found in token" error**
   - Verify `groups` scope is assigned to client as default scope
   - Check group membership mapper is configured correctly
   - Ensure users are actually members of the groups

4. **Authentication works but wrong permissions**
   - Check group names in `.env.local` match Keycloak group names exactly
   - Verify case sensitivity (groups are case-sensitive)
   - Check that role mapping environment variables are set correctly

### Debug Steps

1. **Check Keycloak logs**:
   ```bash
   docker logs gramps-keycloak
   ```

2. **Test OIDC endpoint**:
   ```bash
   curl http://localhost:8080/realms/gramps/.well-known/openid-configuration
   ```

3. **Enable debug logging** in `.env.local`:
   ```bash
   GRAMPSWEB_LOG_LEVEL=DEBUG
   ```

## Production Considerations

When moving to production:

1. **Use persistent database** instead of H2
2. **Configure HTTPS** for both Keycloak and Gramps Web
3. **Use strong passwords** and rotate client secrets
4. **Set up proper backup** for Keycloak configuration
5. **Review security settings** and disable development mode
6. **Configure proper firewall rules**
7. **Use environment-specific realm names**

## Advanced Configuration

### Custom Claims

To add custom claims to tokens:
1. Create custom client scope
2. Add protocol mappers for user attributes
3. Assign scope to gramps-web client

### Multiple Group Sources

If your organization uses nested groups or roles:
1. Create multiple mappers
2. Configure different token claim names
3. Update Gramps Web configuration to check multiple claim sources

### SSO with Multiple Applications

To enable SSO across multiple applications:
1. Create additional clients for other applications
2. Configure shared sessions
3. Set up proper logout flows

## Support

For additional help:
- Keycloak Documentation: https://www.keycloak.org/documentation
- Gramps Web OIDC Issues: Check the application logs
- Test the configuration step by step using this guide