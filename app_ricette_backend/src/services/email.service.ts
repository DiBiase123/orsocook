import sgMail from '@sendgrid/mail';
import dotenv from 'dotenv';

dotenv.config();

export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
}

export class EmailService {
  private fromEmail: string;
  private frontendUrl: string;
  private backendUrl: string;
  private isConfigured: boolean;

  constructor() {
    // Configurazione SendGrid API
    const sendgridApiKey = process.env.SENDGRID_API_KEY;
    const fromEmail = process.env.SMTP_FROM || 'dibiasecompany@gmail.com';

    // Validazione configurazione
    if (!sendgridApiKey) {
      console.warn('⚠️  Configurazione SendGrid incompleta. Email non saranno inviate.');
      console.warn('   Imposta: SENDGRID_API_KEY');
      this.isConfigured = false;
    } else {
      sgMail.setApiKey(sendgridApiKey);
      this.isConfigured = true;
      console.log('✅ SendGrid API configurata con successo');
    }

    this.fromEmail = `"OrsoCook" <${fromEmail}>`;
    
    // Configurazione URL dinamiche per ambiente
    this.backendUrl = this.getBackendUrl();
    this.frontendUrl = this.getFrontendUrl();
    
    console.log('🌐 URL Configurazione:');
    console.log(`   Backend: ${this.backendUrl}`);
    console.log(`   Frontend: ${this.frontendUrl}`);
  }

  /**
   * Ottiene URL backend in base all'ambiente
   */
  private getBackendUrl(): string {
    const nodeEnv = process.env.NODE_ENV || 'development';
    const port = process.env.PORT || '5000';
    const customBackendUrl = process.env.BACKEND_URL;
    
    // Se c'è un URL custom configurato, usalo
    if (customBackendUrl) {
      return customBackendUrl;
    }
    
    // Altrimenti usa logica predefinita
    if (nodeEnv === 'development') {
      return `http://localhost:${port}`;
    }
    
    // Produzione (default Render.com)
    return 'https://orsocook-api.onrender.com';
  }

  /**
   * Ottiene URL frontend in base all'ambiente
   */
  private getFrontendUrl(): string {
    const nodeEnv = process.env.NODE_ENV || 'development';
    const customFrontendUrl = process.env.FRONTEND_URL;
    
    // Se c'è un URL custom configurato, usalo
    if (customFrontendUrl) {
      return customFrontendUrl;
    }
    
    // Altrimenti usa logica predefinita
    if (nodeEnv === 'development') {
      return 'http://localhost:3000'; // Flutter web di default
    }
    
    // Produzione (default Vercel)
    return 'https://orsocook.vercel.app';
  }

  /**
   * Invia email di verifica account
   */
  async sendVerificationEmail(email: string, token: string, username: string): Promise<boolean> {
    const verificationUrl = `${this.backendUrl}/api/auth/verify-email/${token}`;
    
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Verifica Account OrsoCook</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #7E69AB; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none; }
            .button { display: inline-block; background-color: #7E69AB; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
            .code { font-family: monospace; background-color: #f0f0f0; padding: 10px; border-radius: 4px; margin: 10px 0; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>🎉 Benvenuto in OrsoCook!</h1>
          </div>
          <div class="content">
            <h2>Ciao ${username}!</h2>
            <p>Grazie per esserti registrato su <strong>OrsoCook</strong>, la tua community di ricette preferita.</p>
            <p>Per completare la registrazione e iniziare a utilizzare tutte le funzionalità, verifica il tuo indirizzo email cliccando sul pulsante qui sotto:</p>
            
            <div style="text-align: center;">
              <a href="${verificationUrl}" class="button">🔓 Verifica Account</a>
            </div>
            
            <p>Se il pulsante non funziona, copia e incolla questo link nel tuo browser:</p>
            <div class="code">${verificationUrl}</div>
            
            <p><strong>⚠️ Importante:</strong> Questo link scadrà tra <strong>24 ore</strong>.</p>
            
            <p>Se non ti sei registrato su OrsoCook, ignora semplicemente questa email.</p>
            
            <p>A presto,<br>Il team di OrsoCook 🐻👨‍🍳</p>
          </div>
          <div class="footer">
            <p>OrsoCook - La tua community di ricette preferita</p>
            <p>© ${new Date().getFullYear()} OrsoCook. Tutti i diritti riservati.</p>
          </div>
        </body>
      </html>
    `;

    const text = `
      Benvenuto in OrsoCook!
      
      Ciao ${username},
      
      Grazie per esserti registrato su OrsoCook, la tua community di ricette preferita.
      
      Per completare la registrazione, verifica il tuo indirizzo email cliccando sul link qui sotto:
      
      ${verificationUrl}
      
      Il link scadrà tra 24 ore.
      
      Se non ti sei registrato su OrsoCook, ignora semplicemente questa email.
      
      A presto,
      Il team di OrsoCook
    `;

    return this.sendEmail({
      to: email,
      subject: '🎉 Verifica il tuo account OrsoCook',
      html,
      text,
    });
  }

  /**
   * Invia email per reset password
   */
  async sendPasswordResetEmail(email: string, token: string, username: string): Promise<boolean> {
    const resetUrl = `${this.frontendUrl}/reset-password?token=${token}`;
    
    const html = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Reset Password OrsoCook</title>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #E65100; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; border: 1px solid #e0e0e0; border-top: none; }
            .button { display: inline-block; background-color: #E65100; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; margin: 20px 0; }
            .warning { background-color: #FFF3E0; border-left: 4px solid #E65100; padding: 10px; margin: 15px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>🔐 Reset Password OrsoCook</h1>
          </div>
          <div class="content">
            <h2>Ciao ${username}!</h2>
            <p>Abbiamo ricevuto una richiesta per reimpostare la password del tuo account <strong>OrsoCook</strong>.</p>
            
            <div style="text-align: center;">
              <a href="${resetUrl}" class="button">🔑 Reimposta Password</a>
            </div>
            
            <div class="warning">
              <p><strong>⚠️ Attenzione:</strong> Se non hai richiesto il reset della password, ignora questa email. Il tuo account è al sicuro.</p>
            </div>
            
            <p>Il link di reset scadrà tra <strong>1 ora</strong> per motivi di sicurezza.</p>
            
            <p>Se il pulsante non funziona, copia e incolla questo URL nel tuo browser:</p>
            <div style="background-color: #f0f0f0; padding: 10px; border-radius: 4px; margin: 10px 0; font-family: monospace; word-break: break-all;">
              ${resetUrl}
            </div>
            
            <p>Buona cucina! 🐻👨‍🍳</p>
          </div>
          <div class="footer">
            <p>OrsoCook - La tua community di ricette preferita</p>
            <p>© ${new Date().getFullYear()} OrsoCook. Tutti i diritti riservati.</p>
          </div>
        </body>
      </html>
    `;

    const text = `
      Reset Password OrsoCook
      
      Ciao ${username},
      
      Abbiamo ricevuto una richiesta per reimpostare la password del tuo account OrsoCook.
      
      Clicca sul link qui sotto per reimpostare la tua password:
      
      ${resetUrl}
      
      Attenzione: Se non hai richiesto il reset della password, ignora questa email.
      Il link di reset scadrà tra 1 ora per motizi di sicurezza.
      
      Buona cucina!
      Il team di OrsoCook
    `;

    return this.sendEmail({
      to: email,
      subject: '🔐 Reimposta la tua password OrsoCook',
      html,
      text,
    });
  }

  /**
   * Metodo generico per inviare email
   */
  async sendEmail(options: EmailOptions): Promise<boolean> {
    if (!this.isConfigured) {
      console.warn('📧 Email non inviata (SendGrid non configurato):', {
        to: options.to,
        subject: options.subject,
      });
      
      if (process.env.NODE_ENV === 'development') {
        console.log('📧 Contenuto email (sviluppo):');
        console.log('To:', options.to);
        console.log('Subject:', options.subject);
        console.log('Text:', options.text);
        console.log('URL nel testo:', this.extractUrls(options.text || options.html));
        console.log('---');
      }
      
      return true; // In sviluppo, fingiamo che l'email sia stata inviata
    }

    try {
      const msg = {
        to: options.to,
        from: this.fromEmail,
        subject: options.subject,
        html: options.html,
        text: options.text || options.html.replace(/<[^>]*>/g, ''),
      };

      await sgMail.send(msg);
      
      console.log('📧 Email inviata con successo via SendGrid API:', {
        to: options.to,
        subject: options.subject,
      });
      
      return true;
    } catch (error) {
      console.error('❌ Errore invio email via SendGrid API:', {
        to: options.to,
        subject: options.subject,
        error: error instanceof Error ? error.message : error,
      });
      return false;
    }
  }

  /**
   * Estrae URL dal testo per logging in sviluppo
   */
  private extractUrls(text: string): string[] {
    const urlRegex = /(https?:\/\/[^\s]+)/g;
    return text.match(urlRegex) || [];
  }
}

// Esporta un'istanza singleton
export const emailService = new EmailService();