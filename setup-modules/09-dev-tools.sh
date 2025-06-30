#!/bin/bash
# Module 9: Development Tools Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_dev_tools() {
    log_info "Setting up development tools..."
    
    cd frontend
    
    # Add testing and dev dependencies
    pnpm add -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
    pnpm add -D jest jest-environment-jsdom
    pnpm add -D eslint-config-prettier
    pnpm add -D husky lint-staged
    
    create_testing_config
    create_git_hooks
    create_github_workflows
    create_docker_config
    
    cd ..
    log_success "Development tools setup completed"
}

create_testing_config() {
    log_info "Creating testing configuration..."
    
    cat > jest.config.js << 'JS'
// jest.config.js
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './',
})

const customJestConfig = {
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapping: {
    '^@/components/(.*)$': '<rootDir>/src/components/$1',
    '^@/lib/(.*)$': '<rootDir>/src/lib/$1',
    '^@/hooks/(.*)$': '<rootDir>/src/hooks/$1',
    '^@/shared/(.*)$': '<rootDir>/../shared/$1',
  },
  testEnvironment: 'jest-environment-jsdom',
}

module.exports = createJestConfig(customJestConfig)
JS

    cat > jest.setup.js << 'JS'
// jest.setup.js
import '@testing-library/jest-dom'
JS

    # Create __tests__ directory first
    mkdir -p __tests__
    cat > __tests__/example.test.tsx << 'TSX'
// __tests__/example.test.tsx
import { render, screen } from '@testing-library/react'
import { Button } from '@/components/ui/Button'

describe('Button', () => {
  it('renders a button', () => {
    render(<Button>Click me</Button>)
    const button = screen.getByRole('button', { name: /click me/i })
    expect(button).toBeInTheDocument()
  })
})
TSX

    # Update package.json scripts
    cat > package.json.tmp << 'JSON'
{
  "scripts": {
    "dev": "next dev",
    "build": "next build", 
    "start": "next start",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "type-check": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  }
}
JSON
    
    # Merge with existing package.json (simplified approach)
    if [ -f package.json ]; then
        node -e "
            const fs = require('fs');
            const existing = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            const newScripts = JSON.parse(fs.readFileSync('package.json.tmp', 'utf8')).scripts;
            existing.scripts = { ...existing.scripts, ...newScripts };
            fs.writeFileSync('package.json', JSON.stringify(existing, null, 2));
        "
    fi
    rm -f package.json.tmp
}

create_git_hooks() {
    log_info "Creating Git hooks..."
    
    cat > .lintstagedrc.json << 'JSON'
{
  "*.{js,jsx,ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,css}": [
    "prettier --write"
  ]
}
JSON

    # Initialize husky first
    npx husky init
    
    # Create pre-commit hook
    cat > .husky/pre-commit << 'HOOK'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
HOOK

    chmod +x .husky/pre-commit
}

create_github_workflows() {
    log_info "Creating GitHub workflows..."
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'YAML'
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        node-version: [18.x, 20.x]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          
      - uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Get pnpm store directory
        shell: bash
        run: |
          echo "STORE_PATH=$(pnpm store path --silent)" >> $GITHUB_ENV
          
      - uses: actions/cache@v3
        name: Setup pnpm cache
        with:
          path: ${{ env.STORE_PATH }}
          key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pnpm-store-
            
      - name: Install dependencies
        run: pnpm install --frozen-lockfile
        
      - name: Run type check
        run: pnpm type-check
        
      - name: Run linter
        run: pnpm lint
        
      - name: Run tests
        run: pnpm test --coverage
        
      - name: Build application
        run: pnpm build

  supabase:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: supabase/setup-cli@v1
        with:
          version: latest
          
      - name: Validate database schema
        run: |
          cd supabase
          supabase db diff --check
YAML

    cat > .github/workflows/deploy.yml << 'YAML'
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Use Node.js 20.x
        uses: actions/setup-node@v4
        with:
          node-version: 20.x
          
      - uses: pnpm/action-setup@v2
        with:
          version: 8
          
      - name: Install dependencies
        run: pnpm install --frozen-lockfile
        
      - name: Build application
        run: pnpm build
        
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
          vercel-args: '--prod'
YAML
}

create_docker_config() {
    log_info "Creating Docker configuration..."
    
    cat > Dockerfile << 'DOCKER'
# Dockerfile
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Install dependencies based on the preferred package manager
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm install -g pnpm
RUN pnpm build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
DOCKER

    cat > .dockerignore << 'IGNORE'
# .dockerignore
Dockerfile
.dockerignore
node_modules
npm-debug.log
README.md
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.git
.gitignore
.next
.vercel
coverage
__tests__
*.test.js
*.test.ts
*.test.tsx
IGNORE

    cat > docker-compose.yml << 'COMPOSE'
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: saas_app
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
COMPOSE
}

setup_dev_tools
