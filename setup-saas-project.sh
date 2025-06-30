#!/bin/bash
# Enhanced SaaS project setup with robust Supabase CLI installation

set -e

PROJECT_NAME=${1:-"my-saas-app"}
echo "🚀 Setting up SaaS project: $PROJECT_NAME"

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Enhanced function to install Supabase CLI with fallback
install_supabase_cli() {
    if command -v supabase &> /dev/null; then
        echo "✅ Supabase CLI already installed"
        return 0
    fi
    
    local os=$(detect_os)
    echo "📥 Installing Supabase CLI for $os..."
    
    case $os in
        "macos")
            # Try Homebrew first, fallback to manual installation
            if command -v brew &> /dev/null; then
                echo "🍺 Trying Homebrew installation..."
                if brew install supabase/tap/supabase 2>/dev/null; then
                    echo "✅ Supabase CLI installed via Homebrew"
                    return 0
                else
                    echo "⚠️  Homebrew installation failed, trying manual installation..."
                fi
            fi
            
            # Manual installation fallback
            echo "📦 Installing Supabase CLI manually..."
            ARCH=$(uname -m)
            if [[ "$ARCH" == "arm64" ]]; then
                DOWNLOAD_URL="https://github.com/supabase/cli/releases/latest/download/supabase_darwin_arm64.tar.gz"
            else
                DOWNLOAD_URL="https://github.com/supabase/cli/releases/latest/download/supabase_darwin_amd64.tar.gz"
            fi
            
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            if curl -L "$DOWNLOAD_URL" | tar -xz; then
                echo "🔐 Installing to /usr/local/bin (may require password)..."
                sudo mv supabase /usr/local/bin/
                cd - > /dev/null
                rm -rf "$TEMP_DIR"
                
                if command -v supabase &> /dev/null; then
                    echo "✅ Supabase CLI installed manually"
                    return 0
                fi
            fi
            
            echo "❌ All installation methods failed. Please install manually:"
            echo "   Download from: https://github.com/supabase/cli/releases"
            echo "   Or fix Command Line Tools:"
            echo "   sudo rm -rf /Library/Developer/CommandLineTools"
            echo "   sudo xcode-select --install"
            exit 1
            ;;
        "linux")
            # Install via direct download
            curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
            sudo mv supabase /usr/local/bin/
            ;;
        "windows")
            echo "❌ Windows detected. Please install Supabase CLI manually:"
            echo "   Using Scoop: scoop bucket add supabase https://github.com/supabase/scoop-bucket.git && scoop install supabase"
            echo "   Or download from: https://github.com/supabase/cli/releases"
            exit 1
            ;;
        *)
            echo "❌ Unsupported OS. Please install Supabase CLI manually:"
            echo "   https://supabase.com/docs/guides/cli"
            exit 1
            ;;
    esac
}

# Create main directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create all base directories upfront to avoid path issues
mkdir -p frontend supabase shared/{types,utils} .vscode docs

# ===========================================
# 📁 Frontend Setup (Next.js) - ENHANCED
# ===========================================
echo "📦 Setting up Frontend (Next.js)..."

mkdir -p frontend
cd frontend

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "📦 Installing pnpm..."
    npm install -g pnpm
fi

# Initialize Next.js project
pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Add SaaS-specific dependencies - UPDATED packages
echo "📦 Adding SaaS dependencies..."
pnpm add @supabase/ssr @supabase/supabase-js
pnpm add @stripe/stripe-js stripe
pnpm add resend @react-email/components @react-email/render
pnpm add @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-select
pnpm add @radix-ui/react-toast @radix-ui/react-accordion
pnpm add lucide-react
pnpm add class-variance-authority clsx tailwind-merge
pnpm add zod react-hook-form @hookform/resolvers
pnpm add date-fns
pnpm add next-themes

# Add dev dependencies
pnpm add -D @types/node
pnpm add -D prettier prettier-plugin-tailwindcss
pnpm add -D @types/react @types/react-dom

# Create environment file template
cat > .env.local.example << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Resend
RESEND_API_KEY=re_...

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF

# Create VSCode settings
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  "deno.enable": false,
  "deno.enablePaths": [],
  "typescript.preferences.moduleResolution": "node",
  "typescript.suggest.autoImports": true,
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ]
}
EOF

# Update tsconfig.json for shared types
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/shared/*": ["../shared/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts", 
    "**/*.tsx",
    ".next/types/**/*.ts",
    "../shared/types/**/*.ts"
  ],
  "exclude": ["node_modules", "../supabase/functions"]
}
EOF

# Create prettier config
cat > .prettierrc << 'EOF'
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
EOF

# Create complete directory structure BEFORE writing files
echo "📁 Creating directory structure..."
mkdir -p src/lib/supabase src/components/ui "src/app/(auth)" src/app/dashboard

# Verify directories exist before creating files
if [ ! -d "src/lib/supabase" ]; then
    echo "❌ Failed to create src/lib/supabase directory"
    exit 1
fi

echo "✅ Directory structure created successfully"

# Create Supabase client setup with new @supabase/ssr
cat > src/lib/supabase/client.ts << 'EOF'
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
EOF

cat > src/lib/supabase/server.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
EOF

cat > src/lib/supabase/middleware.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (
    !user &&
    !request.nextUrl.pathname.startsWith('/auth') &&
    !request.nextUrl.pathname.startsWith('/api')
  ) {
    const url = request.nextUrl.clone()
    url.pathname = '/auth/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
EOF

# Create middleware.ts in root
cat > middleware.ts << 'EOF'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: Request) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
EOF

cd ..

# ===========================================
# 📁 Supabase Setup - ENHANCED
# ===========================================
echo "⚡ Setting up Supabase project..."

# Install Supabase CLI with enhanced error handling
install_supabase_cli

# Initialize Supabase
if ! supabase init; then
    echo "❌ Failed to initialize Supabase project"
    echo "💡 This might be due to existing config. Continuing..."
fi

# Add SaaS-specific dependencies - UPDATED packages
echo "📦 Adding SaaS dependencies..."
pnpm add @supabase/ssr @supabase/supabase-js
pnpm add @stripe/stripe-js stripe
pnpm add resend @react-email/components @react-email/render
pnpm add @radix-ui/react-dialog @radix-ui/react-dropdown-menu @radix-ui/react-select
pnpm add @radix-ui/react-toast @radix-ui/react-accordion
pnpm add lucide-react
pnpm add class-variance-authority clsx tailwind-merge
pnpm add zod react-hook-form @hookform/resolvers
pnpm add date-fns
pnpm add next-themes

# Add dev dependencies
pnpm add -D @types/node
pnpm add -D prettier prettier-plugin-tailwindcss
pnpm add -D @types/react @types/react-dom

# Create environment file template
cat > .env.local.example << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Resend
RESEND_API_KEY=re_...

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF

# Create VSCode settings
mkdir -p .vscode
cat > .vscode/settings.json << 'EOF'
{
  "deno.enable": false,
  "deno.enablePaths": [],
  "typescript.preferences.moduleResolution": "node",
  "typescript.suggest.autoImports": true,
  "typescript.preferences.includePackageJsonAutoImports": "on",
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "emmet.includeLanguages": {
    "typescript": "html",
    "typescriptreact": "html"
  },
  "tailwindCSS.experimental.classRegex": [
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"],
    ["cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"]
  ]
}
EOF

# Update tsconfig.json for shared types
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/shared/*": ["../shared/*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts", 
    "**/*.tsx",
    ".next/types/**/*.ts",
    "../shared/types/**/*.ts"
  ],
  "exclude": ["node_modules", "../supabase/functions"]
}
EOF

# Create prettier config
cat > .prettierrc << 'EOF'
{
  "semi": false,
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
EOF

# FIXED: Create complete directory structure BEFORE writing files
echo "📁 Creating directory structure..."
mkdir -p src/lib/supabase src/components/ui "src/app/(auth)" src/app/dashboard

# Verify directories exist before creating files
if [ ! -d "src/lib/supabase" ]; then
    echo "❌ Failed to create src/lib/supabase directory"
    exit 1
fi

echo "✅ Directory structure created successfully"

# Create Supabase client setup with new @supabase/ssr
cat > src/lib/supabase/client.ts << 'EOF'
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
EOF

cat > src/lib/supabase/server.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // The `setAll` method was called from a Server Component.
            // This can be ignored if you have middleware refreshing
            // user sessions.
          }
        },
      },
    }
  )
}
EOF

cat > src/lib/supabase/middleware.ts << 'EOF'
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: Avoid writing any logic between createServerClient and
  // supabase.auth.getUser(). A simple mistake could make it very hard to debug
  // issues with users being randomly logged out.

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (
    !user &&
    !request.nextUrl.pathname.startsWith('/auth') &&
    !request.nextUrl.pathname.startsWith('/api')
  ) {
    // no user, potentially respond by redirecting the user to the login page
    const url = request.nextUrl.clone()
    url.pathname = '/auth/login'
    return NextResponse.redirect(url)
  }

  // IMPORTANT: You *must* return the supabaseResponse object as it is. If you're
  // creating a new response object with NextResponse.next() make sure to:
  // 1. Pass the request in it, like so:
  //    const myNewResponse = NextResponse.next({ request })
  // 2. Copy over the cookies, like so:
  //    myNewResponse.cookies.setAll(supabaseResponse.cookies.getAll())
  // 3. Change the myNewResponse object as you need, but avoid changing
  //    the cookies!

  return supabaseResponse
}
EOF

# Create middleware.ts in root
cat > middleware.ts << 'EOF'
import { updateSession } from '@/lib/supabase/middleware'

export async function middleware(request: Request) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
EOF

cd ..

# ===========================================
# 📁 Supabase Setup - FIXED
# ===========================================
echo "⚡ Setting up Supabase project..."

# Install Supabase CLI properly
install_supabase_cli

# Initialize Supabase
supabase init

# Create enhanced Supabase structure
mkdir -p supabase/functions/_shared

# Create Deno configuration
cat > supabase/deno.json << 'EOF'
{
  "compilerOptions": {
    "allowJs": true,
    "lib": ["deno.window"],
    "strict": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noImplicitOverride": true
  },
  "imports": {
    "supabase": "https://esm.sh/@supabase/supabase-js@2.45.4",
    "stripe": "https://esm.sh/stripe@16.12.0",
    "jose": "https://deno.land/x/jose@v5.2.0/index.ts",
    "std/": "https://deno.land/std@0.208.0/",
    "zod": "https://deno.land/x/zod@v3.22.4/mod.ts"
  },
  "tasks": {
    "dev": "deno run --allow-net --allow-env --allow-read --watch",
    "test": "deno test --allow-net --allow-env",
    "deploy": "supabase functions deploy"
  },
  "fmt": {
    "useTabs": false,
    "lineWidth": 100,
    "indentWidth": 2,
    "semiColons": false,
    "singleQuote": true
  }
}
EOF

# Create VSCode settings for Supabase
mkdir -p supabase/.vscode
cat > supabase/.vscode/settings.json << 'EOF'
{
  "deno.enable": true,
  "deno.enablePaths": ["./functions"],
  "deno.lint": true,
  "deno.unstable": ["kv", "cron"],
  "editor.defaultFormatter": "denoland.vscode-deno",
  "editor.formatOnSave": true,
  "typescript.preferences.includePackageJsonAutoImports": "off",
  "[typescript]": {
    "editor.defaultFormatter": "denoland.vscode-deno"
  }
}
EOF

# Create example stripe webhook function
mkdir -p supabase/functions/stripe-webhook
cat > supabase/functions/stripe-webhook/index.ts << 'EOF'
import { serve } from 'std/http/server.ts'
import { createClient } from 'supabase'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      throw new Error('Missing stripe signature')
    }

    const body = await req.text()
    
    // TODO: Verify Stripe webhook signature
    const event = JSON.parse(body)
    
    console.log('Received webhook:', event.type)
    
    return new Response(
      JSON.stringify({ received: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    )
  }
})
EOF

# ===========================================
# 📁 Shared Types Setup
# ===========================================
echo "📚 Setting up shared types..."

mkdir -p shared/{types,utils}

# Create shared package.json
cat > shared/package.json << 'EOF'
{
  "name": "@my-saas/shared",
  "version": "1.0.0",
  "type": "module",
  "exports": {
    "./types/*": "./types/*.ts",
    "./utils/*": "./utils/*.ts"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
EOF

# Create basic shared types
cat > shared/types/api.ts << 'EOF'
export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

export interface StripeWebhookEvent {
  id: string
  type: string
  data: {
    object: any
  }
  created: number
  livemode: boolean
}
EOF

cat > shared/types/database.ts << 'EOF'
// This file will be generated by: supabase gen types typescript
// For now, creating basic structure

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          full_name: string | null
          avatar_url: string | null
          plan_type: 'free' | 'pro' | 'enterprise'
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          email: string
          full_name?: string | null
          avatar_url?: string | null
          plan_type?: 'free' | 'pro' | 'enterprise'
        }
        Update: {
          email?: string
          full_name?: string | null
          avatar_url?: string | null
          plan_type?: 'free' | 'pro' | 'enterprise'
          updated_at?: string
        }
      }
    }
  }
}
EOF

cat > shared/utils/validation.ts << 'EOF'
export interface ValidationResult {
  isValid: boolean
  errors: string[]
}

export const validateEmail = (email: string): ValidationResult => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return {
    isValid: emailRegex.test(email),
    errors: emailRegex.test(email) ? [] : ['Invalid email format']
  }
}

export const validatePassword = (password: string): ValidationResult => {
  const errors: string[] = []
  
  if (password.length < 8) {
    errors.push('Password must be at least 8 characters')
  }
  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }
  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }
  if (!/\d/.test(password)) {
    errors.push('Password must contain at least one number')
  }
  
  return {
    isValid: errors.length === 0,
    errors
  }
}
EOF

# ===========================================
# 📁 VSCode Workspace Setup
# ===========================================
echo "🔧 Setting up VSCode workspace..."

mkdir -p .vscode

cat > .vscode/saas-app.code-workspace << 'EOF'
{
  "folders": [
    {
      "name": "🎨 Frontend (Next.js)",
      "path": "./frontend"
    },
    {
      "name": "⚡ Supabase (Deno)",
      "path": "./supabase"
    },
    {
      "name": "📚 Shared Types",
      "path": "./shared"
    }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true,
      "**/dist": true,
      "**/.next": true,
      "**/supabase/volumes": true
    },
    "typescript.preferences.includePackageJsonAutoImports": "off"
  },
  "extensions": {
    "recommendations": [
      "denoland.vscode-deno",
      "bradlc.vscode-tailwindcss",
      "ms-vscode.vscode-typescript-next",
      "esbenp.prettier-vscode",
      "formulahendry.auto-rename-tag",
      "ms-vscode.vscode-json"
    ]
  },
  "tasks": {
    "version": "2.0.0",
    "tasks": [
      {
        "label": "🚀 Start Frontend Dev",
        "type": "shell",
        "command": "pnpm dev",
        "options": {
          "cwd": "${workspaceFolder:🎨 Frontend (Next.js)}"
        },
        "group": "build",
        "presentation": {
          "echo": true,
          "reveal": "always",
          "focus": false,
          "panel": "new"
        }
      },
      {
        "label": "⚡ Start Supabase Local",
        "type": "shell",
        "command": "supabase start",
        "options": {
          "cwd": "${workspaceFolder:⚡ Supabase (Deno)}"
        },
        "group": "build"
      },
      {
        "label": "🛑 Stop Supabase Local",
        "type": "shell",
        "command": "supabase stop",
        "options": {
          "cwd": "${workspaceFolder:⚡ Supabase (Deno)}"
        }
      },
      {
        "label": "📊 Generate Database Types",
        "type": "shell",
        "command": "supabase gen types typescript --local > ../shared/types/database.ts",
        "options": {
          "cwd": "${workspaceFolder:⚡ Supabase (Deno)}"
        }
      }
    ]
  }
}
EOF

# ===========================================
# 📄 Documentation
# ===========================================
echo "📖 Creating documentation..."

mkdir -p docs

cat > docs/development.md << 'EOF'
# Development Guide

## Quick Start

1. **Open VSCode workspace**: `code .vscode/saas-app.code-workspace`
2. **Start Supabase**: Run task "⚡ Start Supabase Local" or manually: `cd supabase && supabase start`
3. **Start Frontend**: Run task "🚀 Start Frontend Dev" or manually: `cd frontend && pnpm dev`

## Environment Setup

1. Copy `frontend/.env.local.example` to `frontend/.env.local`
2. Fill in your Supabase credentials
3. Add your Stripe keys
4. Add your Resend API key

## Database Setup

```bash
cd supabase
supabase start
supabase db reset  # Reset with seed data
```

## Type Generation

After database changes, regenerate types:
```bash
cd supabase
supabase gen types typescript --local > ../shared/types/database.ts
```

## Adding New Edge Function

```bash
cd supabase/functions
supabase functions new my-function
# Edit my-function/index.ts
supabase functions deploy my-function
```

## Project Structure

```
├── frontend/           # Next.js app with @supabase/ssr
├── supabase/          # Database, migrations, edge functions
├── shared/            # Shared TypeScript types
└── .vscode/          # Multi-root workspace configuration
```
EOF

cat > docs/troubleshooting.md << 'EOF'
# Troubleshooting Guide

## Supabase CLI Installation Issues

### macOS
```bash
# If Homebrew fails
brew uninstall supabase
brew install supabase/tap/supabase
```

### Linux
```bash
# Manual installation
curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
sudo mv supabase /usr/local/bin/
```

### Windows
```bash
# Using Scoop
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

## TypeScript Issues

### Deno/Node.js conflicts
- Make sure `deno.enable: false` in frontend/.vscode/settings.json
- Make sure `deno.enable: true` only in supabase/.vscode/settings.json

### Import path issues
- Frontend: Use `@/shared/types/api`
- Edge functions: Use `../../../shared/types/api.ts`

## Common Errors

### "Module not found: @supabase/auth-helpers-nextjs"
This package is deprecated. Use `@supabase/ssr` instead.

### "Supabase CLI not found"
Run the installation script again or install manually per OS instructions above.

### "No such file or directory" errors
Make sure all directories are created before writing files. The script now includes proper directory creation checks.
EOF

cat > README.md << 'EOF'
# SaaS Indie Template - Fixed & Enhanced

Cost-optimized SaaS template with Next.js + Supabase, enhanced DX, and proper tooling.

## 🚀 Quick Setup

```bash
chmod +x setup-saas-project-fixed.sh
./setup-saas-project-fixed.sh lean-saas
cd lean-saas
code .vscode/saas-app.code-workspace
```

## ✨ What's Fixed

- ✅ **Directory Creation**: Fixed missing `src/lib/supabase/` directory creation
- ✅ **Supabase CLI**: Proper installation per OS
- ✅ **Auth Package**: Updated to `@supabase/ssr` (not deprecated)
- ✅ **Type Safety**: Shared types between frontend/backend
- ✅ **Development Experience**: Multi-root workspace with proper configs
- ✅ **Error Handling**: Better installation error handling

## 🏗️ Architecture

- **Frontend**: Next.js 14 (App Router) + TypeScript
- **Backend**: Supabase (Database + Auth + Storage)  
- **Edge Functions**: Deno (minimal usage)
- **Styling**: Tailwind CSS + Radix UI
- **Dev Experience**: Multi-root VSCode workspace

## 📁 Structure

```
lean-saas/
├── frontend/          # Next.js app with latest Supabase integration
├── supabase/         # Database, migrations, edge functions (Deno)
├── shared/           # Shared TypeScript types & utilities
└── .vscode/          # Multi-root workspace configuration
```

## 🔧 Development

1. **Environment**: Copy `frontend/.env.local.example` → `frontend/.env.local`
2. **Database**: `supabase start` (local development)
3. **Frontend**: `pnpm dev` (in frontend folder)

## 💰 Cost Optimization

- 80% Direct Supabase calls (free tier friendly)
- 20% Edge Functions (webhooks only)
- Pay-per-use external APIs (Stripe, Resend)

See `docs/` for detailed guides.
EOF

# ===========================================
# 🎉 Final Setup - ENHANCED
# ===========================================
echo ""
echo "✅ SaaS project setup complete!"
echo ""
echo "📂 Project structure:"
echo "   ├── frontend/          # Next.js app (updated packages)"
echo "   ├── supabase/          # Supabase config & functions"  
echo "   ├── shared/            # Shared types & utils"
echo "   └── .vscode/           # Multi-root workspace"
echo ""
echo "🚀 Next steps:"
echo "   1. cd $PROJECT_NAME"
echo "   2. code .vscode/saas-app.code-workspace"
echo "   3. Copy frontend/.env.local.example to frontend/.env.local"
echo "   4. Fill in your Supabase credentials"
echo "   5. Run 'supabase start' to start local database"
echo "   6. Run 'pnpm dev' in frontend folder"
echo ""
echo "📖 See docs/ for detailed guides and troubleshooting"
echo ""
echo "🔧 Fixed issues:"
echo "   ✅ Directory creation before file writing"
echo "   ✅ Supabase CLI installation"
echo "   ✅ Updated to @supabase/ssr (latest auth package)"
echo "   ✅ Better error handling and validation"
echo "   ✅ Complete development setup"