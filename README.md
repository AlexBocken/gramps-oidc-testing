# Gramps Web OIDC Testing Environment

This repository contains a complete testing environment for the Gramps Web OIDC integration. It includes scripts, configuration files, and documentation to quickly set up and test OIDC authentication with Keycloak.

## 🚀 Quick Start

### Prerequisites

- Docker installed and running
- Python 3.8+ with venv support
- Node.js 16+ and npm
- Git

### Setup

1. **Clone the Gramps repositories**:
   ```bash
   # Clone the main repositories alongside this testing environment
   git clone https://github.com/gramps-project/gramps-web-api.git
   git clone https://github.com/gramps-project/gramps-web.git
   ```

2. **Create Python virtual environment**:
   ```bash
   python -m venv gramps_venv
   source gramps_venv/bin/activate  # On Windows: gramps_venv\Scripts\activate
   ```

3. **Install backend dependencies**:
   ```bash
   cd gramps-web-api
   pip install -e .
   cd ..
   ```

4. **Install frontend dependencies**:
   ```bash
   cd gramps-web
   npm install
   cd ..
   ```

5. **Start Keycloak**:
   ```bash
   ./start-keycloak.sh
   ```
   Wait for Keycloak to start (30-60 seconds), then follow the [Keycloak Setup Guide](KEYCLOAK_SETUP.md).

6. **Start the backend** (in a new terminal):
   ```bash
   ./start-backend.sh
   ```

7. **Start the frontend** (in another new terminal):
   ```bash
   ./start-frontend.sh
   ```

   This automatically sets `API_URL=http://localhost:5000` to connect to the backend.

8. **Test the integration**:
   - Open http://localhost:8001
   - You should see a "Login with OIDC" button
   - Click it to test the authentication flow

## 📁 Files Included

| File | Description |
|------|-------------|
| `start-keycloak.sh` | Starts Keycloak Docker container for testing |
| `start-backend.sh` | Starts Gramps Web API with OIDC configuration |
| `start-frontend.sh` | Starts Gramps Web frontend |
| `.env.local` | Environment configuration with OIDC settings (automatic role mapping) |
| `.env.manual-roles` | Example configuration for manual role management |
| `KEYCLOAK_SETUP.md` | Step-by-step Keycloak configuration guide |

## 🔧 Configuration

The `.env.local` file contains all necessary configuration for OIDC testing:

### Key OIDC Settings

- **GRAMPSWEB_OIDC_ENABLED**: `true` - Enables OIDC authentication
- **GRAMPSWEB_OIDC_CLIENT_ID**: `gramps-web` - Must match Keycloak client
- **GRAMPSWEB_OIDC_CLIENT_SECRET**: Configure in Keycloak and update here
- **GRAMPSWEB_OIDC_OPENID_CONFIG_URL**: Points to Keycloak realm configuration
- **GRAMPSWEB_OIDC_USERNAME_CLAIM**: `preferred_username` - OIDC claim to use for username
- **GRAMPSWEB_OIDC_ROLE_CLAIM**: `groups` - OIDC claim to use for role mapping

### Role Mapping

Users can be automatically assigned roles based on their group membership, or roles can be managed manually in Gramps:

| Environment Variable | Gramps Role | Permissions |
|---------------------|-------------|-------------|
| `GRAMPSWEB_OIDC_GROUP_ADMIN` | Admin (5) | Full system administration |
| `GRAMPSWEB_OIDC_GROUP_OWNER` | Owner (4) | Tree management, user management |
| `GRAMPSWEB_OIDC_GROUP_EDITOR` | Editor (3) | Edit genealogical data |
| `GRAMPSWEB_OIDC_GROUP_CONTRIBUTOR` | Contributor (2) | Add new data |
| `GRAMPSWEB_OIDC_GROUP_MEMBER` | Member (1) | View private data |
| `GRAMPSWEB_OIDC_GROUP_GUEST` | Guest (0) | Basic read access |

#### Role Management Modes

**1. Automatic Role Mapping (Default)**
When OIDC_GROUP_* environment variables are configured, roles are automatically assigned/updated based on OIDC group membership on every login.

**2. Manual Role Management**
If no OIDC_GROUP_* environment variables are set, user roles are preserved and can be managed manually in the Gramps Web admin interface:
- **New OIDC users**: Start with Guest role (can be changed by admin)
- **Existing OIDC users**: Keep their current role (no automatic updates)

To test manual role management, copy the example configuration:
```bash
cp .env.manual-roles .env.local
```

This allows administrators to choose between automatic group-based role assignment or manual role control.

### Authentication Modes

You can test different authentication modes by modifying `.env.local`:

1. **Mixed Mode** (default):
   ```bash
   GRAMPSWEB_OIDC_DISABLE_LOCAL_AUTH=false
   GRAMPSWEB_OIDC_AUTO_REDIRECT=false
   ```

2. **OIDC-Only with Auto-redirect**:
   ```bash
   GRAMPSWEB_OIDC_DISABLE_LOCAL_AUTH=true
   GRAMPSWEB_OIDC_AUTO_REDIRECT=true
   ```

3. **OIDC-Only Manual**:
   ```bash
   GRAMPSWEB_OIDC_DISABLE_LOCAL_AUTH=true
   GRAMPSWEB_OIDC_AUTO_REDIRECT=false
   ```

### Username Claim Configuration

Different OIDC providers use different claims for usernames. Configure the appropriate claim:

| OIDC Provider | Recommended Username Claim | Configuration |
|---------------|----------------------------|---------------|
| **Keycloak** | `preferred_username` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=preferred_username` |
| **Authentik** | `preferred_username` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=preferred_username` |
| **Auth0** | `nickname` or `email` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=nickname` |
| **Azure AD** | `preferred_username` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=preferred_username` |
| **Google** | `email` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=email` |
| **GitHub** | `login` | `GRAMPSWEB_OIDC_USERNAME_CLAIM=login` |
| **Generic** | `sub` (fallback) | Always used as fallback if primary claim is empty |

**Note**: The system automatically falls back to the `sub` claim if the configured username claim is empty or missing.

## 🧪 Testing Scenarios

### 1. Basic OIDC Login
- Navigate to http://localhost:8001
- Click "Login with OIDC"
- Login with Keycloak test user
- Verify successful authentication and redirect

### 2. Role-Based Access
- Create users in different Keycloak groups
- Login and verify appropriate permissions
- Test role precedence (users with multiple groups get highest role)

### 3. Manual Role Management
- Remove all `GRAMPSWEB_OIDC_GROUP_*` environment variables
- Restart backend to disable automatic role mapping
- Login with OIDC user (will get Guest role)
- Use admin interface to manually assign appropriate role
- Verify role persists across subsequent logins

### 4. Authentication Modes
- Test mixed authentication (both OIDC and local login available)
- Test OIDC-only mode (local login disabled)
- Test auto-redirect functionality

### 5. Error Handling
- Test with invalid credentials
- Test with disabled user accounts
- Test with missing group memberships

## 🐛 Troubleshooting

### Backend Won't Start
```bash
# Check if virtual environment is activated
which python
# Should show path in gramps_venv

# Check if dependencies are installed
pip list | grep gramps
```

### Frontend Won't Start
```bash
# Check Node.js version
node --version
# Should be 16+

# Reinstall dependencies
cd gramps-web
rm -rf node_modules package-lock.json
npm install
```

### OIDC Authentication Fails
1. Verify Keycloak is running: http://localhost:8080
2. Check client configuration in Keycloak matches `.env.local`
3. Verify redirect URI: `http://localhost:5000/api/oidc/callback/*`
4. Check logs in backend terminal for detailed errors

### No OIDC Button Visible
1. Check backend logs for OIDC configuration errors
2. Verify `GRAMPSWEB_OIDC_ENABLED=true` in `.env.local`
3. Restart backend after configuration changes
4. Check browser console for API errors

## 🔍 Debug Mode

Enable detailed logging by modifying `.env.local`:

```bash
GRAMPSWEB_LOG_LEVEL=DEBUG
FLASK_DEBUG=true
```

Then restart the backend to see detailed OIDC flow information.

## 🌐 Ports Used

| Service | Port | URL |
|---------|------|-----|
| Keycloak | 8080 | http://localhost:8080 |
| Gramps API | 5000 | http://localhost:5000 |
| Gramps Frontend | 8001 | http://localhost:8001 |

## ⚙️ Frontend Configuration

The frontend's API connection is configurable via environment variables:

- **Development**: The `start-frontend.sh` script sets `API_URL=http://localhost:5000`
- **Production**: Set `API_URL` during build: `API_URL=https://your-api.com npm run build`
- **Default**: Without `API_URL`, it defaults to `http://localhost:5555` (hardcoded fallback)

The build process automatically replaces the hardcoded API host with your specified `API_URL`.

## 📚 Additional Resources

- [Keycloak Setup Guide](KEYCLOAK_SETUP.md) - Detailed Keycloak configuration
- [Gramps Web Documentation](https://gramps-web.readthedocs.io/)
- [OIDC Specification](https://openid.net/connect/)

## 🤝 Contributing

This testing environment is designed to be:
- Easy to set up and use
- Self-contained with minimal dependencies
- Well-documented for troubleshooting

If you encounter issues or have improvements, please:
1. Check existing documentation
2. Enable debug logging
3. Report issues with full logs and configuration details

## 📄 License

This testing environment follows the same license as the main Gramps Web project.