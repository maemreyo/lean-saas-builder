#!/bin/bash
# Module 8: Email System Setup

log_info() { echo -e "\033[0;34mℹ️  $1\033[0m"; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m"; }

setup_email_system() {
    log_info "Setting up email system..."
    
    cd frontend/src
    
    # Create email-related directories
    mkdir -p {lib/email,emails,app/api/send-email}
    
    create_email_config
    create_email_templates
    create_email_api_routes
    
    cd ../..
    log_success "Email system setup completed"
}

create_email_config() {
    log_info "Creating email configuration..."
    
    cat > lib/email/config.ts << 'TS'
// lib/email/config.ts
import { Resend } from 'resend'

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY is not set')
}

export const resend = new Resend(process.env.RESEND_API_KEY)

export const emailConfig = {
  from: 'noreply@yourdomain.com',
  replyTo: 'support@yourdomain.com',
  subjects: {
    welcome: 'Welcome to SaaS App!',
    passwordReset: 'Reset your password',
    emailVerification: 'Verify your email address',
    subscriptionConfirmation: 'Subscription confirmed',
    subscriptionCanceled: 'Subscription canceled',
  },
}
TS

    cat > lib/email/utils.ts << 'TS'
// lib/email/utils.ts
import { resend, emailConfig } from './config'
import { WelcomeEmail } from '@/emails/WelcomeEmail'
import { PasswordResetEmail } from '@/emails/PasswordResetEmail'

export interface SendEmailOptions {
  to: string
  subject: string
  react: React.ReactElement
}

export const sendEmail = async ({ to, subject, react }: SendEmailOptions) => {
  try {
    const { data, error } = await resend.emails.send({
      from: emailConfig.from,
      to,
      subject,
      react,
    })

    if (error) {
      console.error('Email sending error:', error)
      throw error
    }

    return data
  } catch (error) {
    console.error('Failed to send email:', error)
    throw error
  }
}

export const sendWelcomeEmail = async (to: string, name: string) => {
  return sendEmail({
    to,
    subject: emailConfig.subjects.welcome,
    react: WelcomeEmail({ name }),
  })
}

export const sendPasswordResetEmail = async (to: string, resetUrl: string) => {
  return sendEmail({
    to,
    subject: emailConfig.subjects.passwordReset,
    react: PasswordResetEmail({ resetUrl }),
  })
}
TS
}

create_email_templates() {
    log_info "Creating email templates..."
    
    cat > emails/WelcomeEmail.tsx << 'TSX'
// emails/WelcomeEmail.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Hr,
  Html,
  Img,
  Preview,
  Section,
  Text,
} from '@react-email/components'
import * as React from 'react'

interface WelcomeEmailProps {
  name: string
}

export const WelcomeEmail = ({ name }: WelcomeEmailProps) => (
  <Html>
    <Head />
    <Preview>Welcome to SaaS App - Get started today!</Preview>
    <Body style={main}>
      <Container style={container}>
        <Section style={logoContainer}>
          <Text style={logo}>SaaS App</Text>
        </Section>
        <Text style={paragraph}>Hi {name},</Text>
        <Text style={paragraph}>
          Welcome to SaaS App! We're excited to have you on board.
        </Text>
        <Text style={paragraph}>
          Your account has been successfully created. You can now start using all the features
          available in your plan.
        </Text>
        <Section style={btnContainer}>
          <Button style={button} href={`${process.env.NEXT_PUBLIC_APP_URL}/dashboard`}>
            Get Started
          </Button>
        </Section>
        <Text style={paragraph}>
          If you have any questions, feel free to reach out to our support team.
        </Text>
        <Text style={paragraph}>
          Best regards,<br />
          The SaaS App Team
        </Text>
        <Hr style={hr} />
        <Text style={footer}>
          If you didn't create this account, you can safely ignore this email.
        </Text>
      </Container>
    </Body>
  </Html>
)

const main = {
  backgroundColor: '#ffffff',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
}

const container = {
  margin: '0 auto',
  padding: '20px 0 48px',
}

const logoContainer = {
  textAlign: 'center' as const,
}

const logo = {
  fontSize: '32px',
  fontWeight: 'bold',
  color: '#1f2937',
}

const paragraph = {
  fontSize: '16px',
  lineHeight: '26px',
}

const btnContainer = {
  textAlign: 'center' as const,
}

const button = {
  backgroundColor: '#5F51E8',
  borderRadius: '3px',
  color: '#fff',
  fontSize: '16px',
  textDecoration: 'none',
  textAlign: 'center' as const,
  display: 'block',
  padding: '12px',
}

const hr = {
  borderColor: '#cccccc',
  margin: '20px 0',
}

const footer = {
  color: '#8898aa',
  fontSize: '12px',
}
TSX

    cat > emails/PasswordResetEmail.tsx << 'TSX'
// emails/PasswordResetEmail.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Hr,
  Html,
  Preview,
  Section,
  Text,
} from '@react-email/components'
import * as React from 'react'

interface PasswordResetEmailProps {
  resetUrl: string
}

export const PasswordResetEmail = ({ resetUrl }: PasswordResetEmailProps) => (
  <Html>
    <Head />
    <Preview>Reset your SaaS App password</Preview>
    <Body style={main}>
      <Container style={container}>
        <Section style={logoContainer}>
          <Text style={logo}>SaaS App</Text>
        </Section>
        <Text style={paragraph}>Hi there,</Text>
        <Text style={paragraph}>
          We received a request to reset your password for your SaaS App account.
        </Text>
        <Text style={paragraph}>
          Click the button below to reset your password. This link will expire in 1 hour.
        </Text>
        <Section style={btnContainer}>
          <Button style={button} href={resetUrl}>
            Reset Password
          </Button>
        </Section>
        <Text style={paragraph}>
          If you didn't request this password reset, you can safely ignore this email.
          Your password will remain unchanged.
        </Text>
        <Text style={paragraph}>
          Best regards,<br />
          The SaaS App Team
        </Text>
        <Hr style={hr} />
        <Text style={footer}>
          If the button doesn't work, copy and paste this link into your browser:<br />
          {resetUrl}
        </Text>
      </Container>
    </Body>
  </Html>
)

const main = {
  backgroundColor: '#ffffff',
  fontFamily:
    '-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Oxygen-Sans,Ubuntu,Cantarell,"Helvetica Neue",sans-serif',
}

const container = {
  margin: '0 auto',
  padding: '20px 0 48px',
}

const logoContainer = {
  textAlign: 'center' as const,
}

const logo = {
  fontSize: '32px',
  fontWeight: 'bold',
  color: '#1f2937',
}

const paragraph = {
  fontSize: '16px',
  lineHeight: '26px',
}

const btnContainer = {
  textAlign: 'center' as const,
}

const button = {
  backgroundColor: '#5F51E8',
  borderRadius: '3px',
  color: '#fff',
  fontSize: '16px',
  textDecoration: 'none',
  textAlign: 'center' as const,
  display: 'block',
  padding: '12px',
}

const hr = {
  borderColor: '#cccccc',
  margin: '20px 0',
}

const footer = {
  color: '#8898aa',
  fontSize: '12px',
}
TSX
}

create_email_api_routes() {
    log_info "Creating email API routes..."
    
    # Create necessary directories first
    mkdir -p app/api/send-email
    
    cat > app/api/send-email/route.ts << 'TS'
// app/api/send-email/route.ts
import { createAuthClient } from '@/lib/auth/server'
import { sendWelcomeEmail } from '@/lib/email/utils'
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const supabase = await createAuthClient()
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    
    const { type, to, data } = await request.json()
    
    switch (type) {
      case 'welcome':
        await sendWelcomeEmail(to, data.name)
        break
      default:
        return NextResponse.json({ error: 'Invalid email type' }, { status: 400 })
    }
    
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Email API error:', error)
    return NextResponse.json(
      { error: 'Failed to send email' },
      { status: 500 }
    )
  }
}
TS
}

setup_email_system
