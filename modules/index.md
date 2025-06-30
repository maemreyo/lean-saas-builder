# SaaS Setup Modules

## Core Modules
Essential modules required for basic SaaS setup.

- **project-structure** - Creates basic project directory structure
- **frontend-setup** - Sets up Next.js frontend with dependencies  
- **supabase-setup** - Configures Supabase database and authentication

## Feature Modules
Feature-specific modules that add functionality.

- **auth-system** - Sets up authentication with Supabase
- **ui-components** - Creates base UI component library
- **payment-system** - Integrates Stripe payment processing
- **dashboard-setup** - Creates dashboard pages and layouts

## Advanced Modules
Advanced features for production-ready applications.

- **email-system** - Sets up email with Resend and templates
- **dev-tools** - Configures testing, CI/CD, and Docker

## Usage

Each module can be run independently:
```bash
# Run individual module
./modules/core/project-structure.sh my-project

# Or through the orchestrator
./saas-setup.sh my-project lean-saas
```

## Module Development

See [module-development.md](../docs/module-development.md) for guidelines on creating new modules.
